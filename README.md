# TimeSamplers.jl

[![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] [![][ci-img]][ci-url] [![][codecov-img]][codecov-url] [![Julia][julia-img]][julia-url] [![License: EUPL-1.2](https://img.shields.io/badge/License-EUPL--1.2-blue)](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12)

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://LandEcosystems.github.io/TimeSamplers.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://LandEcosystems.github.io/TimeSamplers.jl/stable/

[ci-img]: https://github.com/LandEcosystems/TimeSamplers.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/LandEcosystems/TimeSamplers.jl/actions?query=workflow%3ACI

[codecov-img]: https://codecov.io/gh/LandEcosystems/TimeSamplers.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/LandEcosystems/TimeSamplers.jl

[julia-img]: https://img.shields.io/badge/julia-v1.10+-blue.svg
[julia-url]: https://julialang.org/

A Julia package for temporal sampling, aggregation, and resampling of time series data.

## Features

- **Flexible Time Aggregation**: Aggregate data to hourly, daily, monthly, or yearly time steps
- **n-unit Resampling**: Resample to any period such as `"30-sec"`, `"6-hour"`, `"8-day"` or `"3-month"`, including anomalies, MSC and IAV
- **Anomaly Calculations**: Compute anomalies at various time scales
- **Climatological Statistics**: Calculate multi-year seasonal cycles (MSC) and inter-annual variability (IAV)
- **Efficient Views**: Uses array views to avoid unnecessary data copying
- **Multiple Sampling Methods**: Support for various temporal operations including year shuffling and random selection

## Installation

```julia
using Pkg
Pkg.add("TimeSamplers")
```

## Quick Start

```julia
using TimeSamplers
using Dates

# Create a date vector
dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 12, 31))

# Create time samplers for daily aggregation (returns a Vector{TimeSample})
daily_samplers = create_TimeSampler(dates, TimeDay())

# Example data (time is the first dimension, so size(data, 1) == length(dates))
data = rand(length(dates), 2)

# Apply sampling/aggregation (2-arg form defaults to `TimeNoDiff()`)
sampled_data = do_time_sampling(data, daily_samplers)
```

## Resampling to n-unit periods

`time_resample` resamples data to any period given as a base unit and a count. Supported
units are second, minute, hour, day, week, month and year, with aliases such as `sec`,
`min`, `hr`, `mon` and `yr`.

```julia
hourly = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2001, 12, 31, 23))
data = rand(length(hourly), 2)

time_resample(data, hourly, "6-hour")                    # 6-hourly means
time_resample(data, hourly, Hour(6))                     # same, from a Dates.Period
time_resample(data, hourly, :day; sampler_func=sum)      # daily sums
time_resample(data, hourly, "8-day"; origin=:year)       # 8-day bins restarting each Jan 1
time_resample(data, hourly, "3-hour_msc")                # seasonal cycle at 3-hour resolution
time_resample(data, hourly, "3-hour_msc_day")            # mean diurnal cycle, 8 values
time_resample(data, hourly, "8-day_iav")                 # 8-day values minus their seasonal cycle
time_resample(data, hourly, :mean)                       # mean over the whole record
time_resample_dates(hourly, "6-hour")                    # bin start dates of the output
```

A period spec has the form `<n>-<unit>[_<kind>[_<cycle>]]`, where the separator may be
`_` or `-`. The count can also be joined to the unit, so `"3-hour"`, `"3hour"`, `"3h"` and
`"3 hour"` are the same, and `"3h_msc_day"` works too. The kind is one of `anomaly`, `msc`, `msc_anomaly` or `iav`, and the cycle
defaults to `year`. The same specs work with `create_TimeSampler`, and the types
`TimePeriodSample`, `TimePeriodAnomaly`, `TimePeriodMSC`, `TimePeriodMSCAnomaly` and
`TimePeriodIAV` can be used directly.

Bins are aligned to the calendar by default. Use `origin=:start` to count bins from the
first date, or `origin=:year` to restart bins every Jan 1. MSC and IAV bins always
restart at the start of each cycle, and the MSC pools all timesteps at a cycle position
across all cycles. In a yearly cycle, days are matched by calendar date, so Mar 1 is always
averaged with Mar 1, and Feb 29 only has values from leap years.

## Available Time Sampling Methods

### Basic Aggregation
- `TimeHour`: aggregation to hourly time steps
- `TimeDay`: aggregation to daily time steps
- `TimeMonth`: aggregation to monthly time steps
- `TimeYear`: aggregation to yearly time steps
- `TimeMean`: aggregation to mean over all time steps

### Anomalies
- `TimeHourAnomaly`: aggregation to hourly anomalies
- `TimeDayAnomaly`: aggregation to daily anomalies
- `TimeMonthAnomaly`: aggregation to monthly anomalies
- `TimeYearAnomaly`: aggregation to yearly anomalies
- `TimeDayMSCAnomaly`: aggregation to daily MSC anomalies
- `TimeMonthMSCAnomaly`: aggregation to monthly MSC anomalies

### Period Based
- `TimePeriodSample`: aggregation to bins of an n-unit period
- `TimePeriodAnomaly`: aggregation to anomalies of n-unit bins
- `TimePeriodMSC`: aggregation to the mean seasonal or diurnal cycle of n-unit bins
- `TimePeriodMSCAnomaly`: aggregation to anomalies of the mean cycle of n-unit bins
- `TimePeriodIAV`: aggregation to the inter-annual variability of n-unit bins

### Climatological Statistics
- `TimeDayMSC`: aggregation to daily MSC
- `TimeMonthMSC`: aggregation to monthly MSC
- `TimeDayIAV`: aggregation to daily IAV
- `TimeMonthIAV`: aggregation to monthly IAV
- `TimeHourDayMean`: aggregation to mean of hourly data over days

### Time Selection
- `TimeAllYears`: aggregation/slicing to include all years
- `TimeFirstYear`: aggregation/slicing of the first year
- `TimeRandomYear`: aggregation/slicing of a random year
- `TimeShuffleYears`: aggregation/slicing/selection of shuffled years

## Documentation

For detailed documentation, see the [TimeSamplers.jl documentation](https://landecosystems.github.io/TimeSamplers.jl).

## License

This package is licensed under the EUPL-1.2 (European Union Public Licence v. 1.2). See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or pull request in this repository.

## Authors

TimeSamplers.jl Contributors
