"""
TimeSamplers

A package for temporal sampling, aggregation, and resampling of N-dimensional arrays
along their time dimension.

# Overview

`TimeSampler` provides a flexible framework for performing temporal operations on arrays, including:
- Aggregation to different time scales (hourly, daily, monthly, yearly)
- Computation of anomalies and climatological means
- Inter-annual variability (IAV) and multi-year seasonal cycle (MSC) calculations
- Time-based indexing and subsetting
- Year shuffling and random year selection

# Main Types

- `TimeSample`: Core struct containing indices and a sampling function for temporal aggregation
- `TimeSampleViewInstance`: A view of an array with temporal sampling applied
- `TimeSampleMethod`: Abstract type for different time sampling methods

# Available Time Sampling Methods

The package supports various time sampling methods:

## Basic Aggregation
- `TimeHour`: Aggregate to hourly time steps
- `TimeDay`: Aggregate to daily time steps
- `TimeMonth`: Aggregate to monthly time steps
- `TimeYear`: Aggregate to yearly time steps
- `TimeMean`: Aggregate to mean over all time steps

## Anomalies
- `TimeHourAnomaly`: Hourly anomalies (hourly values minus overall mean)
- `TimeDayAnomaly`: Daily anomalies (daily values minus overall mean)
- `TimeMonthAnomaly`: Monthly anomalies (monthly values minus overall mean)
- `TimeYearAnomaly`: Yearly anomalies (yearly values minus overall mean)
- `TimeDayMSCAnomaly`: Daily MSC anomalies (daily values minus multi-year seasonal cycle)
- `TimeMonthMSCAnomaly`: Monthly MSC anomalies (monthly values minus multi-year seasonal cycle)

## Climatological Statistics
- `TimeDayMSC`: Multi-year seasonal cycle for daily data
- `TimeMonthMSC`: Multi-year seasonal cycle for monthly data
- `TimeDayIAV`: Inter-annual variability for daily data
- `TimeMonthIAV`: Inter-annual variability for monthly data
- `TimeHourDayMean`: Mean of hourly data over days

## Resampling to n-unit periods
- `TimePeriodSample`: Aggregate to bins of any n-unit period such as `Hour(6)` or
  `"8-day"`
- `TimePeriodAnomaly`: Bin values minus the overall mean
- `TimePeriodMSC`: Mean seasonal cycle of n-unit bins, or the mean diurnal cycle with
  `cycle = Day(1)`
- `TimePeriodMSCAnomaly`: Mean cycle minus the overall mean
- `TimePeriodIAV`: Bin values minus the mean cycle value at their position

Periods can be given as strings such as `"30-sec"`, `"15-min"`, `"6-hour"`,
`"8-day"`, `"3-month"` or `"year"`. A kind and a cycle can follow, as in
`"8-day_msc"`, `"month_iav"` or `"3-hour_msc_day"`. The calendar methods `TimeHour`,
`TimeDay`, `TimeMonth` and `TimeYear` and their anomaly, MSC and IAV variants are
built on these period methods.

## Time Selection
- `TimeAllYears`: Include all years
- `TimeFirstYear`: Select first year only
- `TimeRandomYear`: Select a random year
- `TimeShuffleYears`: Shuffle years

## Special Methods
- `TimeArray`: Use array-based time sampling
- `TimeSizedArray`: Use sized array for indices
- `TimeIndexed`: Use time indices for selection
- `TimeDiff`: Compute time differences (e.g., anomalies)
- `TimeNoDiff`: No time differences required

# Main Functions

- `create_TimeSampler`: Create one or more `TimeSample` aggregators from a date vector and time step specification
- `do_time_sampling`: Apply temporal sampling/aggregation to data using a vector of time samplers
- `time_sampling`: Apply a single time sampler to an array
- `get_TimeSampler`: Get a time sampler method instance from a string or symbol
- `time_resample`: Resample data to an n-unit period in one call
- `time_resample_dates`: Labels for the output of `time_resample`
- `parse_temporal_resolution`: Parse `"6-hour"` into `(6, "hour")`
- `get_time_period`: Convert `"6-hour"` into `Hour(6)`

# Usage Example

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

# Resampling example

```julia
hourly = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2001, 12, 31, 23))
data = rand(length(hourly), 3)

six_hourly = time_resample(data, hourly, "6-hour")
daily_sum = time_resample(data, hourly, :day; sampler_func=sum)
seasonal_cycle = time_resample(data, hourly, "3-hour_msc")
diurnal_cycle = time_resample(data, hourly, "3-hour_msc_day")
iav = time_resample(data, hourly, "8-day_iav")
out_dates = time_resample_dates(hourly, "6-hour")
```

# Notes

- The package is designed to work efficiently with views, avoiding unnecessary data copying
- Multiple samplers can be chained together for complex temporal operations
- The default aggregation function is `mean`, but custom functions can be provided
- Time dimension is configurable (defaults to dimension 1)

# See Also

- `TimeSample` for the core type
- `create_TimeSampler` for creating samplers
- `do_time_sampling` for applying samplers to data
"""
module TimeSamplers
using Dates
using StatsBase

include("TimeSamplersTypes.jl")
include("utilsTimeSamplers.jl")
include("createTimeSampler.jl")
include("resampleTimeSampler.jl")
include("doTimeSampling.jl")
end # module TimeSamplers
