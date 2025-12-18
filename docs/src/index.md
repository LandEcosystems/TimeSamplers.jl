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

## Available Time Sampling Methods

### Basic Aggregation

- `TimeHour`: Aggregation to hourly time steps
- `TimeDay`: Aggregation to daily time steps
- `TimeMonth`: Aggregation to monthly time steps
- `TimeYear`: Aggregation to yearly time steps
- `TimeMean`: Aggregation to mean over all time steps

### Anomalies

- `TimeHourAnomaly`: Aggregation to hourly anomalies
- `TimeDayAnomaly`: Aggregation to daily anomalies
- `TimeMonthAnomaly`: Aggregation to monthly anomalies
- `TimeYearAnomaly`: Aggregation to yearly anomalies
- `TimeDayMSCAnomaly`: Aggregation to daily MSC (Multi-year Seasonal Cycle) anomalies
- `TimeMonthMSCAnomaly`: Aggregation to monthly MSC anomalies

### Climatological Statistics

- `TimeDayMSC`: Aggregation to daily Multi-year Seasonal Cycle (MSC)
- `TimeMonthMSC`: Aggregation to monthly Multi-year Seasonal Cycle (MSC)
- `TimeDayIAV`: Aggregation to daily Inter-Annual Variability (IAV)
- `TimeMonthIAV`: Aggregation to monthly Inter-Annual Variability (IAV)
- `TimeHourDayMean`: Aggregation to mean of hourly data over days

### Time Selection

- `TimeAllYears`: Aggregation/slicing to include all years
- `TimeFirstYear`: Aggregation/slicing of the first year
- `TimeRandomYear`: Aggregation/slicing of a random year
- `TimeShuffleYears`: Aggregation/slicing/selection of shuffled years

## Usage Examples

### Basic Temporal Aggregation

```julia
using TimeSamplers
using Dates

# Create date vector
dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 12, 31))

# Create samplers for different time scales
daily_sampler = create_TimeSampler(dates, TimeDay())
monthly_sampler = create_TimeSampler(dates, TimeMonth())
yearly_sampler = create_TimeSampler(dates, TimeYear())
```

### Anomaly Calculations

```julia
using TimeSamplers
using Dates

# Create dates for multiple years
dates = collect(Date(2000, 1, 1):Day(1):Date(2002, 12, 31))

# Calculate daily anomalies
daily_anomaly_sampler = create_TimeSampler(dates, TimeDayAnomaly())

# Calculate monthly anomalies
monthly_anomaly_sampler = create_TimeSampler(dates, TimeMonthAnomaly())

# Calculate MSC (Multi-year Seasonal Cycle) anomalies
msc_anomaly_sampler = create_TimeSampler(dates, TimeDayMSCAnomaly())
```

### Climatological Statistics

```julia
using TimeSamplers
using Dates

# Create dates spanning multiple years
dates = collect(Date(2000, 1, 1):Day(1):Date(2010, 12, 31))

# Calculate Multi-year Seasonal Cycle (MSC)
msc_sampler = create_TimeSampler(dates, TimeDayMSC())

# Calculate Inter-Annual Variability (IAV)
iav_sampler = create_TimeSampler(dates, TimeDayIAV())
```

## Integration with Other Packages

TimeSamplers.jl is designed to work seamlessly with other packages in the SINDBAD ecosystem:

- **ErrorMetrics.jl**: Temporal aggregation is often used before calculating metrics
- **Sindbad**: Used in cost options for temporal data aggregation during parameter optimization

Example integration in SINDBAD:

```julia
using TimeSamplers
using ErrorMetrics
using Sindbad

# Define cost options with temporal aggregation
cost_options = (
    variable = :gpp,
    cost_metric = MSE(),
    temporal_data_aggr = TimeDay(),  # From TimeSamplers.jl
    # ... other options
)
```

## Best Practices

1. **Date Alignment**: Ensure your date vector matches the time dimension of your data
2. **Multiple Years**: For anomaly and climatological calculations, use date vectors spanning multiple years
3. **Performance**: TimeSamplers uses efficient array views to avoid unnecessary data copying
4. **Consistency**: Use the same time sampler for both model output and observations when comparing

## Adding New Time Sampling Methods

To add a new time sampling method:

1. Define a new type that subtypes `TimeSampleMethod`
2. Implement the sampling logic
3. Add appropriate documentation and purpose function

See the package source code for examples of existing implementations.
