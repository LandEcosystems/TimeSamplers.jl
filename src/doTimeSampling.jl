export do_time_sampling
export time_sampling

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

a temporal sampling/aggregation function to aggregate the data using a vector of aggregators

# Arguments:
- `dat`: a data array/vector to aggregate
- `time_samplers`: a vector of time aggregator structs with indices and function to do sampling/aggregation
- sampling/aggregation_type: a type defining the type of sampling/aggregation to be done as follows:
    - `::TimeNoDiff`: a type defining that the aggregator does not require removing/reducing values from original time series
    - `::TimeDiff`: a type defining that the aggregator requires removing/reducing values from original time series. First aggregator aggregates the main time series, second aggregator aggregates to the time series to be removed.
    - `::TimeIndexed`: a type defining that the aggregator requires indexing the original time series

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

julia> do_time_sampling(data, samplers, TimeNoDiff())
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
