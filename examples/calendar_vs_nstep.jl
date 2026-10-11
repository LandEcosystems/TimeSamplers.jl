#=
Calendar methods against their n-step equivalents

Compares every calendar method such as `TimeDayMSC` with its n-step equivalent such
as `TimePeriodMSC(Day(1))` or the spec `"1-day_msc"`. For every pair and record it
checks that
- the samplers hold the same index groups,
- `time_resample` gives the same values,
- `time_resample_dates` gives the same labels,
- the spec string resolves to the n-step method,
- `skip_sampling = true` gives the same samplers.

The results are printed and drawn to `examples/output`:
- `calendar_vs_nstep_<record>.png` overlays the output of every pair for a record,
- `calendar_vs_nstep_checks.png` shows every check for every pair and record.

Run from the package folder with:

    julia --project=examples examples/calendar_vs_nstep.jl
=#

using Pkg
Pkg.activate(@__DIR__)
if Base.find_package("TimeSamplers") === nothing
    Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
end
Pkg.instantiate()

using TimeSamplers
using Dates
using Random
using Statistics
using CairoMakie

# ------------------------- settings ---------------------------------------------
const OUTDIR = joinpath(@__DIR__, "output")

# the records include a leap year and do not all start on Jan 1
const RECORDS = (
    hourly=collect(DateTime(2003, 1, 1):Hour(1):DateTime(2004, 12, 31, 23)),
    daily=collect(DateTime(2001, 3, 15):Day(1):DateTime(2004, 12, 31)),
    monthly=collect(DateTime(2001, 1, 1):Month(1):DateTime(2004, 12, 1)),
)

# calendar method, n-step method, n-step spec
const PAIRS = (
    (TimeHour(), TimePeriodSample(Hour(1)), "1-hour"),
    (TimeDay(), TimePeriodSample(Day(1)), "1-day"),
    (TimeMonth(), TimePeriodSample(Month(1)), "1-month"),
    (TimeYear(), TimePeriodSample(Year(1)), "1-year"),
    (TimeHourAnomaly(), TimePeriodAnomaly(Hour(1)), "1-hour_anomaly"),
    (TimeDayAnomaly(), TimePeriodAnomaly(Day(1)), "1-day_anomaly"),
    (TimeMonthAnomaly(), TimePeriodAnomaly(Month(1)), "1-month_anomaly"),
    (TimeYearAnomaly(), TimePeriodAnomaly(Year(1)), "1-year_anomaly"),
    (TimeHourDayMean(), TimePeriodMSC(Hour(1), Day(1)), "1-hour_msc_day"),
    (TimeDayMSC(), TimePeriodMSC(Day(1)), "1-day_msc"),
    (TimeMonthMSC(), TimePeriodMSC(Month(1)), "1-month_msc"),
    (TimeDayMSCAnomaly(), TimePeriodMSCAnomaly(Day(1)), "1-day_msc_anomaly"),
    (TimeMonthMSCAnomaly(), TimePeriodMSCAnomaly(Month(1)), "1-month_msc_anomaly"),
    (TimeDayIAV(), TimePeriodIAV(Day(1)), "1-day_iav"),
    (TimeMonthIAV(), TimePeriodIAV(Month(1)), "1-month_iav"),
    (TimeMean(), TimeMean(), "mean"),
)

# selections pick time steps and have no n-step equivalent
const SELECTIONS = (TimeAllYears(), TimeFirstYear(), TimeRandomYear(), TimeShuffleYears())

# the bins of these methods are shorter than a day, so they need sub-daily data
const SUBDAILY_METHODS = (TimeHour, TimeHourAnomaly, TimeHourDayMean)

const CHECKS = (:groups, :values, :labels, :spec, :skip)

# colors of the reference palette: categorical slots 1 and 2, status critical,
# and neutral ink and fills for the recessive parts
const COLOR_CALENDAR = colorant"#2a78d6"
const COLOR_NSTEP = colorant"#eb6834"
const COLOR_DIFF = colorant"#d03b3b"
const COLOR_OK_FILL = colorant"#ecebe6"
const COLOR_NA_FILL = colorant"#fcfcfb"
const COLOR_INK = colorant"#1a1a19"
const COLOR_MUTED = colorant"#76756f"

# ------------------------- synthetic data ---------------------------------------

"""
    synthetic_temperature(dates; rng)

Synthetic air temperature in degC with a seasonal cycle, a diurnal cycle peaking at
15:00 and AR(1) noise, so every resampled output has a recognisable shape.
"""
function synthetic_temperature(dates; rng=Random.default_rng())
    phi = 0.9
    noise = 0.0
    temperature = similar(dates, Float64)
    for (i, dt) in enumerate(dates)
        noise = phi * noise + 0.8 * randn(rng)
        temperature[i] = 10.0 +
                         9.0 * cospi(2 * (dayofyear(dt) - 200) / 365.25) +
                         4.0 * cospi(2 * (hour(dt) - 15) / 24) +
                         noise
    end
    return temperature
end

# ------------------------- comparison helpers -----------------------------------
# the index groups of every sampler, with nothing for a skipped sampler
sampler_groups(samplers) = [isnothing(s) ? nothing : s.indices for s in samplers]

samplers_of(dates, method; skip=false) =
    sampler_groups(create_TimeSampler(dates, method, mean, skip))

"""
    compare(dates, data, calendar, nstep, spec)

The outputs of a calendar method and its n-step method on one record, with the
result of every check.
"""
function compare(dates, data, calendar, nstep, spec)
    out_calendar = time_resample(data, dates, calendar)
    out_nstep = time_resample(data, dates, nstep)
    checks = (
        groups=samplers_of(dates, calendar) == samplers_of(dates, nstep),
        values=out_calendar == out_nstep,
        labels=time_resample_dates(dates, calendar) == time_resample_dates(dates, nstep),
        spec=get_TimeSampler(spec) == nstep,
        skip=samplers_of(dates, calendar; skip=true) == samplers_of(dates, nstep; skip=true),
    )
    return (; calendar, nstep, spec, checks, out_calendar, out_nstep,
        out_dates=time_resample_dates(dates, nstep))
end

method_name(method) = string(nameof(typeof(method)))

"""
    describe_skip(dates, method)

What `skip_sampling = true` leaves of the samplers of a method.
"""
function describe_skip(dates, method)
    groups = samplers_of(dates, method; skip=true)
    return join([isnothing(g) ? "skipped" : "$(length(g)) groups" for g in groups], ", ")
end

applies(calendar, record) = !(typeof(calendar) in SUBDAILY_METHODS && record != :hourly)

# ------------------------- plotting helpers -------------------------------------
decimal_year(d) = year(d) + (dayofyear(d) - 1 + hour(d) / 24) / daysinyear(d)

"""
    output_axis(out_dates)

The x values of an output and the axis label: decimal years for bins, and the zero
based cycle position for mean cycles.
"""
function output_axis(out_dates)
    eltype(out_dates) <: Integer && return (out_dates, "position in cycle")
    return (decimal_year.(out_dates), "year")
end

"""
    plot_record(record, results)

Small multiples of every pair on one record. The calendar output is a line and the
n-step output is drawn on top as markers, so a mismatch shows as a marker off the
line. Mean cycles are drawn in cycle order.
"""
function plot_record(record, results)
    n_cols = 4
    n_rows = cld(length(results), n_cols)
    fig = Figure(size=(1500, 300 * n_rows + 80), fontsize=13)
    Label(fig[0, 1:n_cols], "Calendar methods and their n-step equivalents, $(record) record";
        fontsize=18, halign=:left, color=COLOR_INK)
    for (i, r) in enumerate(results)
        row, col = fldmod1(i, n_cols)
        x, xlabel = output_axis(r.out_dates)
        order = sortperm(x)
        max_diff = maximum(abs.(r.out_calendar .- r.out_nstep))
        diff_color = max_diff == 0 ? COLOR_MUTED : COLOR_DIFF
        ax = Axis(fig[row, col]; title=method_name(r.calendar), titlealign=:left,
            subtitle="\"$(r.spec)\", max |difference| = $(max_diff)",
            subtitlecolor=diff_color, xlabel=xlabel, ylabel="degC",
            xgridcolor=(COLOR_MUTED, 0.15), ygridcolor=(COLOR_MUTED, 0.15),
            topspinevisible=false, rightspinevisible=false)
        lines!(ax, x[order], r.out_calendar[order]; color=COLOR_CALENDAR, linewidth=2,
            label="calendar method")
        # markers thin out on long outputs so the line stays visible below them
        step = max(1, length(x) ÷ 60)
        shown = order[1:step:end]
        scatter!(ax, x[shown], r.out_nstep[shown]; color=COLOR_NSTEP, markersize=8,
            strokecolor=:white, strokewidth=1, label="n-step equivalent")
        # a single value such as the record mean gets a narrow axis around it
        length(x) == 1 && xlims!(ax, only(x) - 0.5, only(x) + 0.5)
    end
    Legend(fig[n_rows+1, 1:n_cols], [
            LineElement(color=COLOR_CALENDAR, linewidth=2),
            MarkerElement(color=COLOR_NSTEP, marker=:circle, markersize=8),
        ], ["calendar method", "n-step equivalent"];
        orientation=:horizontal, framevisible=false)
    return fig
end

"""
    plot_checks(all_results)

A grid of every check for every pair and record. Passing checks are plain cells,
failing checks are red cells marked DIFF and pairs that do not apply are blank.
"""
function plot_checks(all_results)
    records = collect(keys(RECORDS))
    n_methods = length(PAIRS)
    n_cols = length(records) * length(CHECKS)
    fig = Figure(size=(1300, 90 + 34 * n_methods), fontsize=13)
    ax = Axis(fig[1, 1]; title="Checks of every calendar method against its n-step equivalent",
        titlealign=:left, yreversed=true,
        xticks=(1:n_cols, repeat(string.(collect(CHECKS)), length(records))),
        yticks=(1:n_methods, [method_name(p[1]) for p in PAIRS]),
        xticklabelrotation=0.0,
        xgridvisible=false, ygridvisible=false,
        topspinevisible=false, bottomspinevisible=false,
        leftspinevisible=false, rightspinevisible=false,
        xticksvisible=false, yticksvisible=false)
    for (k, record) in enumerate(records)
        x_mid = (k - 1) * length(CHECKS) + (length(CHECKS) + 1) / 2
        text!(ax, x_mid, 0.05; text="$(record) record", align=(:center, :center),
            color=COLOR_INK, fontsize=14)
        for i in eachindex(PAIRS), (j, check) in enumerate(CHECKS)
            x = (k - 1) * length(CHECKS) + j
            result = get(all_results, (record, i), nothing)
            fill, label, ink = if isnothing(result)
                (COLOR_NA_FILL, "n/a", COLOR_MUTED)
            elseif getfield(result.checks, check)
                (COLOR_OK_FILL, "ok", COLOR_INK)
            else
                (COLOR_DIFF, "DIFF", colorant"#ffffff")
            end
            # a 2px surface gap between the cells comes from the inset rectangle
            poly!(ax, Rect2f(x - 0.47, i - 0.44, 0.94, 0.88); color=fill)
            text!(ax, x, i; text=label, align=(:center, :center), color=ink, fontsize=12)
        end
    end
    xlims!(ax, 0.5, n_cols + 0.5)
    ylims!(ax, n_methods + 0.5, -0.4)
    return fig
end

# ------------------------- run --------------------------------------------------
mkpath(OUTDIR)
rng = MersenneTwister(1)
all_results = Dict{Tuple{Symbol,Int},Any}()
mismatches = []

println(rpad("calendar method", 22), rpad("record", 9), rpad("n-step spec", 22),
    rpad("n out", 7), join(rpad.(string.(CHECKS), 8)))
println("-"^100)
for (record, dates) in pairs(RECORDS)
    data = synthetic_temperature(dates; rng=rng)
    record_results = []
    for (i, (calendar, nstep, spec)) in enumerate(PAIRS)
        applies(calendar, record) || continue
        result = compare(dates, data, calendar, nstep, spec)
        all_results[(record, i)] = result
        push!(record_results, result)
        marks = [getfield(result.checks, c) ? "ok" : "DIFF" for c in CHECKS]
        println(rpad(method_name(calendar), 22), rpad(record, 9), rpad(spec, 22),
            rpad(size(result.out_nstep, 1), 7), join(rpad.(marks, 8)))
        for check in CHECKS
            getfield(result.checks, check) ||
                push!(mismatches, (calendar, nstep, record, dates, check))
        end
    end
    save(joinpath(OUTDIR, "calendar_vs_nstep_$(record).png"), plot_record(record, record_results))
end
save(joinpath(OUTDIR, "calendar_vs_nstep_checks.png"), plot_checks(all_results))

println("\nSelections, no n-step equivalent")
for method in SELECTIONS
    println("  ", rpad(method_name(method), 18), "time_sampling_type = ",
        time_sampling_type(method))
end

if isempty(mismatches)
    println("\nEvery calendar method matches its n-step equivalent.")
else
    println("\nMismatches")
    for (calendar, nstep, record, dates, check) in mismatches
        print("  $(method_name(calendar)) vs $(repr(nstep)) on $(record) data: $(check)")
        if check == :skip
            print(", calendar gives ", describe_skip(dates, calendar),
                ", n-step gives ", describe_skip(dates, nstep))
        end
        println()
    end
end
println("\nfigures written to $(OUTDIR)")
