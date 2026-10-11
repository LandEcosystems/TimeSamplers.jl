#=
Resampling demo for TimeSamplers.jl

Generates synthetic hourly air temperature for a single location and for a small
lat-lon grid over several years, resamples it with `time_resample`, checks a few
results against direct calculations and saves figures to `examples/output`.

Run from the package folder with:

    julia --project=examples examples/resampling_demo.jl

The synthetic temperature is the sum of
- a latitude dependent annual mean,
- a seasonal cycle whose amplitude grows with latitude and flips by hemisphere,
- a diurnal cycle that peaks at 15:00 local solar time,
- a linear warming trend,
- AR(1) weather noise that persists for a few days.
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
const DATE_BEGIN = DateTime(2001, 1, 1)
const DATE_END = DateTime(2004, 12, 31, 23)
const TIMESTEP = Hour(1)
const SITE = (lat=50.9, lon=11.6)
const LATS = collect(-60.0:15.0:60.0)
const LONS = collect(-165.0:30.0:165.0)
const OUTDIR = joinpath(@__DIR__, "output")

# ------------------------- synthetic data ---------------------------------------

"""
    synthetic_temperature(dates, lat, lon; rng, trend_per_year = 0.03)

Synthetic air temperature in degC for one location at the given dates.

# Arguments:
- `dates`: sorted vector of `DateTime` values in UTC
- `lat`: latitude in degrees, which sets the annual mean and the seasonal amplitude
- `lon`: longitude in degrees, which shifts the diurnal cycle to local solar time
- `rng`: random number generator for the weather noise
- `trend_per_year`: linear warming in degC per year
"""
function synthetic_temperature(dates, lat, lon; rng=Random.default_rng(), trend_per_year=0.03)
    annual_mean = 27.0 - 0.45 * abs(lat)
    seasonal_amplitude = 1.0 + 0.3 * abs(lat)
    # the warmest day is in July in the north and in January in the south
    warmest_day = lat >= 0 ? 200 : 17
    diurnal_amplitude = 4.0 + 2.5 * sind(lon)^2
    noise_sd = 1.0 + 0.04 * abs(lat)
    # hourly AR(1) noise with a decorrelation time of about two days
    phi = exp(-1 / 48)
    innovation_sd = noise_sd * sqrt(1 - phi^2)

    t0 = first(dates)
    temperature = similar(dates, Float64)
    noise = noise_sd * randn(rng)
    for (i, dt) in enumerate(dates)
        noise = phi * noise + innovation_sd * randn(rng)
        local_hour = hour(dt) + minute(dt) / 60 + lon / 15
        years_elapsed = Dates.value(dt - t0) / (1000 * 3600 * 24 * 365.25)
        temperature[i] = annual_mean +
                         seasonal_amplitude * cospi(2 * (dayofyear(dt) - warmest_day) / 365.25) +
                         diurnal_amplitude * cospi(2 * (local_hour - 15) / 24) +
                         trend_per_year * years_elapsed +
                         noise
    end
    return temperature
end

"""
    synthetic_temperature_grid(dates, lats, lons; seed = 42)

Synthetic temperature on a lat-lon grid with time as the first dimension, so the
result has size `(length(dates), length(lats), length(lons))`.
"""
function synthetic_temperature_grid(dates, lats, lons; seed=42)
    grid = Array{Float64}(undef, length(dates), length(lats), length(lons))
    for (j, lat) in enumerate(lats), (k, lon) in enumerate(lons)
        rng = MersenneTwister(seed + 1000 * j + k)
        grid[:, j, k] = synthetic_temperature(dates, lat, lon; rng=rng)
    end
    return grid
end

# ------------------------- plotting helpers -------------------------------------

"""
    decimal_time(dates, t0 = first(dates); unit = Day(1))

Convert dates into a float number of `unit` since `t0` for use as a plot axis.
"""
decimal_time(dates, t0=first(dates); unit=Day(1)) = [(DateTime(d) - DateTime(t0)) / Millisecond(unit) for d in dates]

decimal_year(dates) = [year(d) + (dayofyear(d) - 1 + hour(d) / 24) / daysinyear(d) for d in dates]

"""
    stairs_xy(bin_starts, values, x_end)

Points for a step line where every value is held from its bin start until the next
bin start, and the last value is held until `x_end`.
"""
stairs_xy(bin_starts, values, x_end) = ([bin_starts; x_end], [values; last(values)])

"""
    period_centres(positions, period_days)

Centre of every cycle position in days since the start of the year.
"""
period_centres(positions, period_days) = positions .* period_days .+ period_days / 2

# ------------------------- data -------------------------------------------------
mkpath(OUTDIR)
dates = collect(DATE_BEGIN:TIMESTEP:DATE_END)
println("time steps: $(length(dates)) from $(first(dates)) to $(last(dates))")

site_temp = synthetic_temperature(dates, SITE.lat, SITE.lon; rng=MersenneTwister(1))
println("generating a $(length(LATS)) x $(length(LONS)) grid ...")
grid_temp = synthetic_temperature_grid(dates, LATS, LONS)

# ------------------------- checks -----------------------------------------------
println("\nchecks")
daily = time_resample(site_temp, dates, :day)
@assert length(daily) == length(unique(Date.(dates)))
@assert daily[1] ≈ mean(site_temp[1:24])
println("  daily mean matches the mean of the first 24 hours")

daily_max = time_resample(site_temp, dates, "day"; sampler_func=maximum)
daily_min = time_resample(site_temp, dates, "day"; sampler_func=minimum)
@assert all(daily_min .<= daily .<= daily_max)
println("  daily min <= mean <= max for every day")

diurnal = time_resample(site_temp, dates, "3-hour_msc_day")
manual_diurnal = [mean(site_temp[hour.(dates) .÷ 3 .== k]) for k in 0:7]
@assert diurnal ≈ manual_diurnal
println("  3-hour diurnal cycle matches a direct group mean")

monthly_grid = time_resample(grid_temp, dates, "month")
monthly_grid_last = time_resample(permutedims(grid_temp, (2, 3, 1)), dates, "month"; dim=3)
@assert monthly_grid ≈ permutedims(monthly_grid_last, (3, 1, 2))
println("  resampling with time as the last dimension gives the same result")

for spec in ("6-hour", "8-day", "month", "8-day_iav", "8-day_msc", "3-hour_msc_day")
    n_out = size(time_resample(site_temp, dates, spec), 1)
    n_labels = length(time_resample_dates(dates, spec))
    @assert n_out == n_labels
    println("  $(rpad(spec, 16)) -> $(n_out) values")
end

# ------------------------- figure 1: one week at several resolutions ------------
week_end = DATE_BEGIN + Day(7)
week = findall(<(week_end), dates)
week_dates = dates[week]
week_temp = site_temp[week]
x_week = decimal_time(week_dates)
x_week_end = (week_end - DATE_BEGIN) / Millisecond(Day(1))

fig = Figure(size=(1100, 500))
ax = Axis(fig[1, 1]; title="One week at $(SITE.lat)N, $(SITE.lon)E",
    xlabel="days since $(Date(DATE_BEGIN))", ylabel="temperature (degC)")
lines!(ax, x_week, week_temp; color=(:gray40, 0.8), linewidth=1, label="hourly")
for (spec, color) in (("3-hour", :orange), ("6-hour", :crimson), ("day", :navy))
    values = time_resample(week_temp, week_dates, spec)
    starts = decimal_time(time_resample_dates(week_dates, spec), DATE_BEGIN)
    stairs!(ax, stairs_xy(starts, values, x_week_end)...; step=:post, color=color,
        linewidth=2, label="$(spec) mean")
end
day_starts = decimal_time(time_resample_dates(week_dates, "day"), DATE_BEGIN)
week_max = time_resample(week_temp, week_dates, "day"; sampler_func=maximum)
week_min = time_resample(week_temp, week_dates, "day"; sampler_func=minimum)
scatter!(ax, day_starts .+ 0.5, week_max; marker=:utriangle, color=:red, label="daily max")
scatter!(ax, day_starts .+ 0.5, week_min; marker=:dtriangle, color=:blue, label="daily min")
Legend(fig[2, 1], ax; orientation=:horizontal, framevisible=false)
save(joinpath(OUTDIR, "01_week_resolutions.png"), fig)

# ------------------------- figure 2: full record --------------------------------
x_end = decimal_year([DATE_END + TIMESTEP])[1]
fig = Figure(size=(1100, 450))
ax = Axis(fig[1, 1]; title="Full record at several resolutions",
    xlabel="year", ylabel="temperature (degC)")
lines!(ax, decimal_year(time_resample_dates(dates, :day)), daily;
    color=(:gray50, 0.6), linewidth=0.7, label="daily")
for (spec, origin, color) in (("8-day", :year, :darkorange), ("month", :calendar, :crimson),
                              ("year", :calendar, :black))
    values = time_resample(site_temp, dates, spec; origin=origin)
    starts = decimal_year(time_resample_dates(dates, spec; origin=origin))
    stairs!(ax, stairs_xy(starts, values, x_end)...; step=:post, color=color,
        linewidth=2, label="$(spec), origin $(origin)")
end
axislegend(ax; position=:rb)
save(joinpath(OUTDIR, "02_full_record.png"), fig)

# ------------------------- figure 3: climatology --------------------------------
fig = Figure(size=(1200, 850))

ax = Axis(fig[1, 1]; title="Mean seasonal cycle", xlabel="day of year",
    ylabel="temperature (degC)")
for (spec, period_days, color) in (("day_msc", 1, (:gray50, 0.7)), ("8-day_msc", 8, :darkorange),
                                   ("month_msc", 365.25 / 12, :crimson))
    values = time_resample(site_temp, dates, spec)
    positions = time_resample_dates(dates, spec)
    order = sortperm(positions)
    scatterlines!(ax, period_centres(positions[order], period_days), values[order];
        color=color, markersize=spec == "day_msc" ? 0 : 7, label=spec)
end
axislegend(ax; position=:cb)

ax = Axis(fig[1, 2]; title="Mean diurnal cycle in UTC", xlabel="hour of day",
    ylabel="temperature (degC)", xticks=0:3:24)
for (spec, period_hours, color) in (("hour_msc_day", 1, :navy), ("3-hour_msc_day", 3, :crimson),
                                    ("6-hour_msc_day", 6, :darkorange))
    values = time_resample(site_temp, dates, spec)
    positions = time_resample_dates(dates, spec)
    scatterlines!(ax, period_centres(positions, period_hours), values; color=color, label=spec)
end
axislegend(ax; position=:lt)

# the 3-hour seasonal cycle has one value per 3-hour slot of a 366 day calendar, so
# it can be shown as hour of day against day of year, with Feb 29 as day 60
seasonal_3h = time_resample(site_temp, dates, "3-hour_msc")
positions_3h = time_resample_dates(dates, "3-hour_msc")
slots_per_day = 8
n_days = 366
matrix_3h = fill(NaN, slots_per_day, n_days)
for (value, position) in zip(seasonal_3h, positions_3h)
    day_index, slot = divrem(position, slots_per_day)
    day_index < n_days && (matrix_3h[slot+1, day_index+1] = value)
end
ax = Axis(fig[2, 1:2]; title="3-hour_msc: seasonal cycle at 3-hour resolution",
    xlabel="day of year", ylabel="hour of day in UTC", yticks=0:3:24)
hm = heatmap!(ax, 1:n_days, 1.5:3:22.5, permutedims(matrix_3h); colormap=:thermal)
Colorbar(fig[2, 3], hm; label="temperature (degC)")
save(joinpath(OUTDIR, "03_climatology.png"), fig)

# ------------------------- figure 4: anomalies and IAV --------------------------
fig = Figure(size=(1100, 700))
ax = Axis(fig[1, 1]; title="Anomalies of 8-day bins, origin :year",
    ylabel="anomaly (degC)")
starts_8d = decimal_year(time_resample_dates(dates, "8-day"; origin=:year))
lines!(ax, starts_8d, time_resample(site_temp, dates, "8-day_anomaly"; origin=:year);
    color=:gray40, label="8-day minus overall mean")
lines!(ax, decimal_year(time_resample_dates(dates, "8-day_iav")),
    time_resample(site_temp, dates, "8-day_iav"); color=:crimson, linewidth=2,
    label="8-day minus its seasonal cycle")
Legend(fig[2, 1], ax; orientation=:horizontal, framevisible=false)

ax = Axis(fig[3, 1]; title="Monthly IAV with a linear fit", xlabel="year",
    ylabel="anomaly (degC)")
iav_monthly = time_resample(site_temp, dates, "month_iav")
x_monthly = decimal_year(time_resample_dates(dates, "month_iav"))
slope = cov(x_monthly, iav_monthly) / var(x_monthly)
barplot!(ax, x_monthly, iav_monthly; width=1 / 12, color=ifelse.(iav_monthly .> 0, :crimson, :steelblue))
lines!(ax, x_monthly, slope .* (x_monthly .- mean(x_monthly)) .+ mean(iav_monthly);
    color=:black, label="fitted trend $(round(slope; digits=3)) degC per year")
Legend(fig[4, 1], ax; orientation=:horizontal, framevisible=false)
save(joinpath(OUTDIR, "04_anomalies_iav.png"), fig)
println("\nfitted trend of the monthly IAV: $(round(slope; digits=3)) degC per year, synthetic trend is 0.03")

# ------------------------- figure 5: spatial fields -----------------------------
record_mean = dropdims(time_resample(grid_temp, dates, :mean); dims=1)
monthly_msc = time_resample(grid_temp, dates, "month_msc")
seasonal_range = dropdims(maximum(monthly_msc; dims=1) .- minimum(monthly_msc; dims=1); dims=1)
diurnal_msc = time_resample(grid_temp, dates, "hour_msc_day")
diurnal_range = dropdims(maximum(diurnal_msc; dims=1) .- minimum(diurnal_msc; dims=1); dims=1)
iav_sd = dropdims(std(time_resample(grid_temp, dates, "month_iav"); dims=1); dims=1)

fig = Figure(size=(1200, 800))
fields = (("Mean over the record, :mean", record_mean, :thermal, "degC"),
          ("Seasonal range of month_msc", seasonal_range, :viridis, "degC"),
          ("Diurnal range of hour_msc_day", diurnal_range, :magma, "degC"),
          ("Standard deviation of month_iav", iav_sd, :cividis, "degC"))
for (i, (title, field, colormap, unit)) in enumerate(fields)
    row, col = fldmod1(i, 2)
    field_ax = Axis(fig[row, 2col-1]; title=title, xlabel="longitude", ylabel="latitude")
    field_hm = heatmap!(field_ax, LONS, LATS, permutedims(field); colormap=colormap)
    Colorbar(fig[row, 2col], field_hm; label=unit)
end
save(joinpath(OUTDIR, "05_spatial.png"), fig)

# monthly seasonal cycle for every latitude, averaged over longitude
fig = Figure(size=(900, 450))
ax = Axis(fig[1, 1]; title="month_msc by latitude, mean over longitude",
    xlabel="month", ylabel="temperature (degC)", xticks=1:12)
month_positions = time_resample_dates(dates, "month_msc")
colors = cgrad(:roma, length(LATS); categorical=true)
for (j, lat) in enumerate(LATS)
    zonal = vec(mean(monthly_msc[:, j, :]; dims=2))
    lines!(ax, month_positions .+ 1, zonal; color=colors[j], label="$(lat)")
end
Legend(fig[1, 2], ax, "latitude")
save(joinpath(OUTDIR, "06_zonal_seasonal_cycle.png"), fig)

println("figures written to $(OUTDIR)")
