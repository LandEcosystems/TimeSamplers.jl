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

[julia-img]: https://img.shields.io/badge/julia-v1.6+-blue.svg
[julia-url]: https://julialang.org/

A Julia package for temporal sampling, aggregation, and resampling of time series data.

## Features

- **Flexible Time Aggregation**: Aggregate data to hourly, daily, monthly, or yearly time steps
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

# Create a time sampler for daily aggregation
daily_sampler = create_TimeSampler(dates, TimeDay())

# Apply to data (assuming data is a 2D array with time as first dimension)
# sampled_data = do_time_sampling(data, daily_sampler, TimeNoDiff())
```

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
