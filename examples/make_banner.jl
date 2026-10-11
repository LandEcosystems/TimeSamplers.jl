#=
Banner for the README and the documentation

Draws one wide figure of synthetic hourly temperature resampled with TimeSamplers:
- one week of hourly data with 6-hour and daily bins,
- three years of daily means with 8-day and monthly bins,
- the mean seasonal cycle at daily, 8-day and monthly resolution.

The figure is written to `docs/src/assets/banner.png`. Run from the package folder
with:

    julia --project=examples examples/make_banner.jl
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
using CairoMakie

# ------------------------- settings ---------------------------------------------
const OUTFILE = joinpath(@__DIR__, "..", "docs", "src", "assets", "banner.png")
const DATES = collect(DateTime(2001, 1, 1):Hour(1):DateTime(2003, 12, 31, 23))
const WEEK = DateTime(2002, 6, 3) .<= DATES .< DateTime(2002, 6, 10)

# input data is neutral, the finer resampling is categorical slot 2 and the coarser
# one is slot 1 of the reference palette
const COLOR_DATA = colorant"#b4b2a9"
const COLOR_FINE = colorant"#eb6834"
const COLOR_COARSE = colorant"#2a78d6"
const COLOR_INK = colorant"#1a1a19"
const COLOR_MUTED = colorant"#76756f"

# ------------------------- synthetic data ---------------------------------------

"""
    synthetic_temperature(dates; rng)

Synthetic air temperature in degC with a seasonal cycle peaking in July, a diurnal
cycle peaking at 15:00 and AR(1) weather noise that persists for about two days.
"""
function synthetic_temperature(dates; rng=MersenneTwister(7))
    phi = exp(-1 / 48)
    noise = 0.0
    temperature = similar(dates, Float64)
    for (i, dt) in enumerate(dates)
        noise = phi * noise + 2.5 * sqrt(1 - phi^2) * randn(rng)
        temperature[i] = 9.0 +
                         10.0 * cospi(2 * (dayofyear(dt) - 200) / 365.25) +
                         4.0 * cospi(2 * (hour(dt) - 15) / 24) +
                         noise
    end
    return temperature
end

# ------------------------- plotting helpers -------------------------------------
days_since(dates, t0) = [(d - t0) / Millisecond(Day(1)) for d in dates]
decimal_year(d) = year(d) + (dayofyear(d) - 1 + hour(d) / 24) / daysinyear(d)

"""
    stairs_xy(bin_starts, values, x_end)

Points for a step line where every value is held from its bin start until the next
bin start, and the last value is held until `x_end`.
"""
stairs_xy(bin_starts, values, x_end) = ([bin_starts; x_end], [values; last(values)])

"""
    banner_axis(position; xticks)

An axis with the recessive styling of the banner: no title or labels, light grid
lines, and only the bottom and left spines.
"""
function banner_axis(position; xticks=Makie.automatic, xtickformat=Makie.automatic)
    return Axis(position; xticks=xticks, xtickformat=xtickformat,
        xgridcolor=(COLOR_MUTED, 0.15), ygridcolor=(COLOR_MUTED, 0.15),
        topspinevisible=false, rightspinevisible=false,
        leftspinecolor=COLOR_MUTED, bottomspinecolor=COLOR_MUTED,
        xtickcolor=COLOR_MUTED, ytickcolor=COLOR_MUTED,
        xticklabelcolor=COLOR_MUTED, yticklabelcolor=COLOR_MUTED,
        xticklabelsize=12, yticklabelsize=12)
end

"""
    panel_legend(position, title, entries)

A one-line legend above a panel with a title in ink and the spec of every series.
"""
function panel_legend(position, title, entries)
    elements = [LineElement(color=color, linewidth=width) for (color, width, _) in entries]
    Legend(position, elements, [label for (_, _, label) in entries], title;
        orientation=:horizontal, titleposition=:left, framevisible=false,
        titlesize=14, titlecolor=COLOR_INK, titlefont=:bold, labelsize=13,
        labelcolor=COLOR_INK, patchsize=(18, 10), colgap=10, titlegap=14,
        padding=(0, 0, 0, 0), halign=:left, tellwidth=false)
end

# ------------------------- data -------------------------------------------------
temperature = synthetic_temperature(DATES)

# ------------------------- figure -----------------------------------------------
fig = Figure(size=(1200, 300), backgroundcolor=:white, figure_padding=(16, 20, 12, 12))

# one week: hourly data with 6-hour and daily bins
week_dates = DATES[WEEK]
week_temp = temperature[WEEK]
t0 = first(week_dates)
week_end = days_since([last(week_dates) + Hour(1)], t0)[1]
ax = banner_axis(fig[2, 1]; xticks=0:1:7,
    xtickformat=values -> [Dates.format(t0 + Day(round(Int, v)), "u d") for v in values])
lines!(ax, days_since(week_dates, t0), week_temp; color=COLOR_DATA, linewidth=1.5)
for (spec, color) in (("6-hour", COLOR_FINE), ("day", COLOR_COARSE))
    values = time_resample(week_temp, week_dates, spec)
    starts = days_since(time_resample_dates(week_dates, spec), t0)
    stairs!(ax, stairs_xy(starts, values, week_end)...; step=:post, color=color, linewidth=2)
end
xlims!(ax, 0, week_end)
panel_legend(fig[1, 1], "zoom in", [
    (COLOR_DATA, 1.5, "hourly"),
    (COLOR_FINE, 2, "\"6-hour\""),
    (COLOR_COARSE, 2, "\"day\""),
])

# three years: daily means with 8-day and monthly bins
daily = time_resample(temperature, DATES, "day")
x_daily = decimal_year.(time_resample_dates(DATES, "day"))
x_end = decimal_year(last(DATES) + Hour(1))
ax = banner_axis(fig[2, 2]; xticks=2001:2004, xtickformat=values -> string.(round.(Int, values)))
lines!(ax, x_daily, daily; color=COLOR_DATA, linewidth=1)
for (spec, origin, color) in (("8-day", :year, COLOR_FINE), ("month", :calendar, COLOR_COARSE))
    values = time_resample(temperature, DATES, spec; origin=origin)
    starts = decimal_year.(time_resample_dates(DATES, spec; origin=origin))
    stairs!(ax, stairs_xy(starts, values, x_end)...; step=:post, color=color, linewidth=2)
end
xlims!(ax, 2001, x_end)
panel_legend(fig[1, 2], "zoom out", [
    (COLOR_DATA, 1.5, "\"day\""),
    (COLOR_FINE, 2, "\"8-day\""),
    (COLOR_COARSE, 2, "\"month\""),
])

# mean seasonal cycle at three resolutions, by day of year
month_starts = cumsum([0; daysinmonth.(Date.(2004, 1:11))])
ax = banner_axis(fig[2, 3]; xticks=(month_starts[1:3:end], ["Jan", "Apr", "Jul", "Oct"]))
for (spec, period_days, color, width) in (("day_msc", 1, COLOR_DATA, 1.5),
                                          ("8-day_msc", 8, COLOR_FINE, 2))
    values = time_resample(temperature, DATES, spec)
    positions = time_resample_dates(DATES, spec)
    order = sortperm(positions)
    lines!(ax, positions[order] .* period_days .+ period_days / 2, values[order];
        color=color, linewidth=width)
end
month_msc = time_resample(temperature, DATES, "month_msc")
month_positions = time_resample_dates(DATES, "month_msc")
month_centres = month_starts[month_positions.+1] .+ daysinmonth.(Date.(2004, month_positions .+ 1)) ./ 2
scatterlines!(ax, month_centres, month_msc; color=COLOR_COARSE, linewidth=2, markersize=8,
    strokecolor=:white, strokewidth=1.5)
xlims!(ax, 0, 366)
panel_legend(fig[1, 3], "cycles", [
    (COLOR_DATA, 1.5, "\"day_msc\""),
    (COLOR_FINE, 2, "\"8-day_msc\""),
    (COLOR_COARSE, 2, "\"month_msc\""),
])

colsize!(fig.layout, 1, Relative(0.29))
colsize!(fig.layout, 2, Relative(0.37))
colgap!(fig.layout, 28)
rowgap!(fig.layout, 6)

mkpath(dirname(OUTFILE))
save(OUTFILE, fig; px_per_unit=2)
println("banner written to $(normpath(OUTFILE))")
