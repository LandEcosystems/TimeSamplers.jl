# TimeSamplers.jl

A Julia package for temporal sampling, aggregation, and resampling of time series data.

## Quick start

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

See the [API](api.md) page for the full list of methods.
