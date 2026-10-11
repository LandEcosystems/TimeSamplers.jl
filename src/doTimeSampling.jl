export do_time_sampling
export time_sampling
export time_resample
export time_resample_dates

"""
    getTimeSampledArray(_dat::AbstractArray{T, 2})

a helper function to instantiate an array from the TimeSampleViewInstance for N-dimensional array
"""
function getTimeSampledArray(_dat::AbstractArray{<:Any,N}) where N
    inds = ntuple(_->Colon(),N)
    inds = map(size(_dat)) do _
        Colon()
    end
    _dat[inds...]
end


"""
    time_sampling(dat::AbstractArray, time_sampler::TimeSample, dim = 1)

a temporal sampling/aggregation function to aggregate the data using a given aggregator when the input data is an array

# Arguments:
- `dat`: a data array/vector to aggregate with function for the following types:
  - `::AbstractArray`: an array
  - `::SubArray`: a view of an array
  - `::Nothing`: a dummy type to return the input and do no sampling/aggregation data
- `time_sampler`: a time aggregator struct with indices and function to do sampling/aggregation
- `dim`: the dimension along which the sampling/aggregation should be done

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 5))
5-element Vector{Date}:
 2000-01-01
 2000-01-02
 2000-01-03
 2000-01-04
 2000-01-05

julia> data = [1.0, 2.0, 3.0, 4.0, 5.0]
5-element Vector{Float64}:
 1.0
 2.0
 3.0
 4.0
 5.0

julia> sampler = create_TimeSampler(dates, TimeDay())[1]
TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:1, 2:2, 3:3, 4:4, 5:5], Statistics.mean)

julia> time_sampling(data, sampler)
5-element Vector{Float64}:
 1.0
 2.0
 3.0
 4.0
 5.0

julia> monthly_sampler = create_TimeSampler(dates, TimeMonth())[1]
TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:5], Statistics.mean)

julia> time_sampling(data, monthly_sampler)
1-element Vector{Float64}:
 3.0
```
"""
function time_sampling end

function time_sampling(dat::AbstractArray, time_sampler::TimeSample, dim=1)
    dat = view(dat, time_sampler, dim=dim)
    return getTimeSampledArray(dat)
end

function time_sampling(dat::SubArray, time_sampler::TimeSample, dim=1)
    dat = view(dat, time_sampler, dim=dim)
    return getTimeSampledArray(dat)
end

function time_sampling(dat, time_sampler::Nothing, dim=1)
    return dat
end

"""
    do_time_sampling(dat, time_samplers, sampling/aggregation_type)
    do_time_sampling(dat, time_samplers)

a temporal sampling/aggregation function to aggregate the data using a vector of aggregators

# Arguments:
- `dat`: a data array/vector to aggregate
- `time_samplers`: a vector of time aggregator structs with indices and function to do sampling/aggregation
- `sampling/aggregation_type`: a type defining the type of sampling/aggregation to be done as follows:
    - `::TimeNoDiff`: a type defining that the aggregator does not require removing/reducing values from original time series
    - `::TimeDiff`: a type defining that the aggregator requires removing/reducing values from original time series. First aggregator aggregates the main time series, second aggregator aggregates to the time series to be removed.
    - `::TimeIndexed`: a type defining that the aggregator requires indexing the original time series

If `sampling/aggregation_type` is omitted, it defaults to `TimeNoDiff()`.

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 5))
5-element Vector{Date}:
 2000-01-01
 2000-01-02
 2000-01-03
 2000-01-04
 2000-01-05

julia> data = [1.0, 2.0, 3.0, 4.0, 5.0]
5-element Vector{Float64}:
 1.0
 2.0
 3.0
 4.0
 5.0

julia> samplers = create_TimeSampler(dates, TimeDay())
1-element Vector{TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}}:
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:1, 2:2, 3:3, 4:4, 5:5], Statistics.mean)

julia> do_time_sampling(data, samplers)
5-element Vector{Float64}:
 1.0
 2.0
 3.0
 4.0
 5.0

julia> anomaly_samplers = create_TimeSampler(dates, TimeDayAnomaly())
2-element Vector{TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}}:
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:1, 2:2, 3:3, 4:4, 5:5], Statistics.mean)
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:5], Statistics.mean)

julia> do_time_sampling(data, anomaly_samplers, TimeDiff())
5-element Vector{Float64}:
 -2.0
 -1.0
  0.0
  1.0
  2.0
```
"""
function do_time_sampling end

function do_time_sampling(dat, time_samplers)
    return do_time_sampling(dat, time_samplers, TimeNoDiff())
end

function do_time_sampling(dat, time_samplers, ::TimeIndexed)
    return dat[first(time_samplers).indices...]
end

function do_time_sampling(dat, time_samplers, ::TimeNoDiff)
    return time_sampling(dat, first(time_samplers))
end


function do_time_sampling(dat, time_samplers, ::TimeDiff)
    dat_samp = time_sampling(dat, first(time_samplers))
    dat_samp_to_remove = time_sampling(dat, last(time_samplers))
    return dat_samp .- dat_samp_to_remove
end


"""
    toTimePeriodMethod(period; origin = :calendar, cycle = Year(1))

Normalize a period argument of `time_resample` into a time sampling method. Strings
and symbols are resolved with `get_TimeSampler`, a `Dates.Period` becomes a
`TimePeriodSample`, and method instances are returned unchanged. The keywords are
only used when `period` is not already a method instance.
"""
function toTimePeriodMethod end

toTimePeriodMethod(t_step::TimeSamplerMethod; origin=:calendar, cycle=Year(1)) = t_step
toTimePeriodMethod(period::Dates.Period; origin=:calendar, cycle=Year(1)) = TimePeriodSample(period; origin=origin)
toTimePeriodMethod(spec::Union{AbstractString,Symbol}; origin=:calendar, cycle=Year(1)) = get_TimeSampler(String(spec); origin=origin, cycle=cycle)

"""
    time_resample(dat, date_vector, period; sampler_func = mean, dim = 1, origin = :calendar, cycle = Year(1))
    time_resample(dat, rs::TimeResampler; dim = 1)

Resample data along its time dimension. The first form builds the samplers and uses
them once. The second form reuses the samplers of a `TimeResampler`, which is faster
when many arrays on the same time axis are resampled.

# Arguments:
- `dat`: an array whose dimension `dim` matches `date_vector`
- `date_vector`: a sorted vector of `Date` or `DateTime` values
- `period`: the target, given as one of
  - a string or symbol such as `"6-hour"`, `:day`, `"8-day_msc"`, `"3-hour_msc_day"`,
    `"month_iav"` or `:mean`
  - a `Dates.Period` such as `Hour(6)`
  - a time sampling method such as `TimePeriodMSC(Day(8))` or `TimeMonth()`
- `sampler_func`: the function applied to every group, defaults to `mean`
- `dim`: the time dimension of `dat`
- `origin`: bin origin for plain and anomaly bins, see `TimePeriodSample`
- `cycle`: cycle for msc, msc_anomaly and iav when `period` does not name one

Anomaly, MSC anomaly and IAV targets subtract their second sampler automatically.

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> dates = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 1, 11));

julia> time_resample(collect(1.0:12.0), dates, "6-hour")
2-element Vector{Float64}:
 3.5
 9.5

julia> time_resample(collect(1.0:12.0), dates, Hour(4); sampler_func=sum)
3-element Vector{Float64}:
 10.0
 26.0
 42.0
```
"""
function time_resample(dat, date_vector, period; sampler_func=mean, dim=1, origin=:calendar, cycle=Year(1))
    checkTimeLength(dat, length(date_vector), dim)
    rs = TimeResampler(date_vector, period; sampler_func=sampler_func, origin=origin, cycle=cycle)
    return time_resample(dat, rs; dim=dim)
end

function time_resample(dat, rs::TimeResampler; dim=1)
    return doTimeResample(dat, rs.samplers, rs.combine, dim)
end

function checkTimeLength(dat, n_time, dim)
    if size(dat, dim) != n_time
        error("size of data along dimension $(dim) is $(size(dat, dim)), but the time axis has $(n_time) dates.")
    end
    return nothing
end

doTimeResample(dat, time_samplers, ::TimeNoDiff, dim) = time_sampling(dat, first(time_samplers), dim)

function doTimeResample(dat, time_samplers, ::TimeDiff, dim)
    return time_sampling(dat, first(time_samplers), dim) .- time_sampling(dat, last(time_samplers), dim)
end

"""
    TimeResampler(date_vector, period; sampler_func = mean, origin = :calendar, cycle = Year(1), skip_sampling = false)

A time sampling method with its samplers built once for a time axis, so that many
arrays on that axis can be resampled with `time_resample(dat, rs)` without building
the samplers again.

# Arguments:
- `date_vector`: a sorted vector of `Date` or `DateTime` values
- `period`: the target, given as for `time_resample`, such as `"8-day_iav"`,
  `Hour(6)` or `TimeMonthMSC()`
- `sampler_func`: the function applied to every group, defaults to `mean`
- `origin`: bin origin for plain and anomaly bins, see `TimePeriodSample`
- `cycle`: cycle for msc, msc_anomaly and iav when `period` does not name one
- `skip_sampling`: when `true`, the first sampler is skipped and the data is
  used as it is, which is meant for data that is already at the target
  resolution

Methods that select time steps, such as `TimeFirstYear`, are not accepted because
they do not resample.

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> dates = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 1, 11));

julia> rs = TimeResampler(dates, "6-hour");

julia> time_resample(collect(1.0:12.0), rs)
2-element Vector{Float64}:
 3.5
 9.5

julia> time_resample(collect(12.0:-1.0:1.0), rs)
2-element Vector{Float64}:
 9.5
 3.5
```
"""
function TimeResampler(date_vector, period; sampler_func=mean, origin=:calendar, cycle=Year(1), skip_sampling=false)
    t_step = toTimePeriodMethod(period; origin=origin, cycle=cycle)
    combine = time_sampling_type(t_step)
    if combine isa TimeIndexed
        error("$(nameof(typeof(t_step))) selects time steps and cannot resample. Use create_TimeSampler for index based selection.")
    end
    samplers = Tuple(create_TimeSampler(date_vector, t_step, sampler_func, skip_sampling))
    out_dates = time_resample_dates(date_vector, t_step)
    return TimeResampler(t_step, samplers, combine, out_dates)
end

"""
    time_resample_dates(date_vector, period; origin = :calendar, cycle = Year(1))
    time_resample_dates(rs::TimeResampler)

Labels for the output of `time_resample`, one per slice along the time dimension.

For plain, anomaly and IAV targets every label is the start of a bin. For MSC and
MSC anomaly targets the labels are the zero based cycle positions in output order.
In a yearly cycle of day or sub-day bins the positions count on a 366 day calendar,
so position 59 is Feb 29 for daily bins.
For `TimeMean` the label is the first date. The arguments are the same as for
`time_resample`.

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> dates = collect(DateTime(2000, 1, 1, 3):Hour(1):DateTime(2000, 1, 1, 13));

julia> time_resample_dates(dates, "6-hour")
3-element Vector{DateTime}:
 2000-01-01T00:00:00
 2000-01-01T06:00:00
 2000-01-01T12:00:00
```
"""
time_resample_dates(rs::TimeResampler) = rs.out_dates

function time_resample_dates(date_vector, period; origin=:calendar, cycle=Year(1))
    t_step = toTimePeriodMethod(period; origin=origin, cycle=cycle)
    return getTimeResampleLabels(date_vector, getTimePeriodMethod(t_step))
end

function getTimeResampleLabels(date_vector, t_step::Union{TimePeriodSample,TimePeriodAnomaly})
    bin_starts = getResampleBinKeys(date_vector, t_step.period, t_step.origin)
    return bin_starts[first.(getIndicesForTimeGroups(bin_starts))]
end

function getTimeResampleLabels(date_vector, t_step::TimePeriodIAV)
    bin_starts, _ = getCycleBinKeys(date_vector, t_step.period, t_step.cycle; leap_aligned=true)
    return bin_starts[first.(getIndicesForTimeGroups(bin_starts))]
end

function getTimeResampleLabels(date_vector, t_step::Union{TimePeriodMSC,TimePeriodMSCAnomaly})
    _, positions = getCyclePositions(date_vector, t_step.period, t_step.cycle; leap_aligned=true)
    return unique(positions)
end

getTimeResampleLabels(date_vector, ::TimeMean) = [first(date_vector)]
