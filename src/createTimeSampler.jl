export create_TimeSampler
export get_TimeSampler


"""
    create_TimeSampler(date_vector, t_step, sampler_func = mean, skip_sampling = false)

Create one or more temporal sampling/aggregation objects (`TimeSample`) for a given target time step.

# Arguments
- `date_vector`: A vector of `Dates.TimeType` values (e.g. `Date` or `DateTime`) that define the time axis to be aggregated.
- `t_step`: The target sampling/aggregation specification. Common forms:
  - `::Union{String, Symbol}`: A name that resolves to a time-sampler type in `TimeSampler` (e.g. `"TimeDay"` / `:TimeDay`).
  - `::TimeSampleMethod`: A concrete method instance (e.g. `TimeDay()`), used via multiple dispatch.
  - `::Union{String, Symbol}` period spec: `"6-hour"`, `"8-day_msc"` or `:day`
    resolve to the period methods `TimePeriodSample`, `TimePeriodAnomaly`,
    `TimePeriodMSC`, `TimePeriodMSCAnomaly` and `TimePeriodIAV`. See
    `get_TimeSampler`.
  - `::Dates.Period`: resamples to bins of that period, same as
    `TimePeriodSample(period)`.

`date_vector` must be sorted in ascending order, because bins are formed from
contiguous runs of dates.
- `sampler_func`: Function to apply per group (defaults to `mean`).
- `skip_sampling`: If `true`, return `nothing` for samplers that would be a no-op (defaults to `false`).

# Returns
- `Vector{Union{Nothing, TimeSample}}`: Time-sampling/aggregation objects, with `nothing` entries when `skip_sampling=true`.

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 10))
10-element Vector{Date}:
 2000-01-01
 2000-01-02
 2000-01-03
 2000-01-04
 2000-01-05
 2000-01-06
 2000-01-07
 2000-01-08
 2000-01-09
 2000-01-10

julia> daily_sampler = create_TimeSampler(dates, TimeDay())
1-element Vector{TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}}:
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:1, 2:2, 3:3, 4:4, 5:5, 6:6, 7:7, 8:8, 9:9, 10:10], Statistics.mean)

julia> monthly_sampler = create_TimeSampler(dates, "TimeMonth")
1-element Vector{TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}}:
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:10], Statistics.mean)

julia> anomaly_sampler = create_TimeSampler(dates, TimeDayAnomaly())
2-element Vector{TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}}:
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:1, 2:2, 3:3, 4:4, 5:5, 6:6, 7:7, 8:8, 9:9, 10:10], Statistics.mean)
 TimeSample{Vector{UnitRange{Int64}}, typeof(Statistics.mean)}(UnitRange{Int64}[1:10], Statistics.mean)
```
"""
function create_TimeSampler end


function create_TimeSampler(date_vector, t_step::Union{String, Symbol}, sampler_func=mean, skip_sampling=false)
    return create_TimeSampler(date_vector, get_TimeSampler(t_step), sampler_func, skip_sampling)
end

function create_TimeSampler(date_vector, ::TimeMean, sampler_func=mean, skip_sampling=false)
    mean_agg = TimeSample(getAllTimeIndices(date_vector), sampler_func)
    return [mean_agg,]
end

function create_TimeSampler(date_vector, ::TimeAllYears, sampler_func=mean, skip_sampling=false)
    all_agg = TimeSample(getAllTimeIndices(date_vector), sampler_func)
    return [all_agg,]
end

# Calendar methods are built on the generic period methods. Hourly and daily methods
# honour skip_sampling, while monthly and yearly methods have always ignored it.
const TimeSkippableCalendarMethod = Union{TimeHour,TimeHourAnomaly,TimeHourDayMean,
    TimeDay,TimeDayAnomaly,TimeDayIAV,TimeDayMSC,TimeDayMSCAnomaly,
    TimeMonthMSC,TimeMonthMSCAnomaly}
const TimeNonSkippableCalendarMethod = Union{TimeMonth,TimeMonthAnomaly,TimeMonthIAV,
    TimeYear,TimeYearAnomaly}

function create_TimeSampler(date_vector, t_step::TimeSkippableCalendarMethod, sampler_func=mean, skip_sampling=false)
    return create_TimeSampler(date_vector, getTimePeriodMethod(t_step), sampler_func, skip_sampling)
end

function create_TimeSampler(date_vector, t_step::TimeNonSkippableCalendarMethod, sampler_func=mean, skip_sampling=false)
    return getPeriodSamplers(date_vector, getTimePeriodMethod(t_step), sampler_func)
end


function create_TimeSampler(date_vector, ::TimeFirstYear, sampler_func=mean, skip_sampling=false)
    years = year.(date_vector)
    first_year = minimum(years)
    year_inds = getIndexForSelectedYear(years, first_year)
    year_agg = TimeSample(year_inds, sampler_func)
    return [year_agg,]
end

function create_TimeSampler(date_vector, ::TimeRandomYear, sampler_func=mean, skip_sampling=false)
    years = year.(date_vector)
    random_year = rand(unique(years))
    year_inds = getIndexForSelectedYear(years, random_year)
    year_agg = TimeSample(year_inds, sampler_func)
    return [year_agg,]
end

function create_TimeSampler(date_vector, ::TimeShuffleYears, sampler_func=mean, skip_sampling=false)
    years = year.(date_vector)
    unique_years = unique(years)
    shuffled_unique_years = sample(unique_years, length(unique_years), replace=false)
    year_inds = getIndexForSelectedYear.(Ref(years), shuffled_unique_years)
    year_agg = TimeSample(year_inds, sampler_func)
    return [year_agg,]
end


"""
    get_TimeSampler(aggr)

Creates and returns a time aggregator instance based on the provided sampling/aggregation.

# Arguments
- `aggr::Symbol`: Symbol specifying the time sampling/aggregation method type name (e.g. `:TimeDay`)
- `aggr::String`: String specifying the time sampling/aggregation method type name (e.g. `"TimeDay"`)
- `origin`: bin origin used when `aggr` is a period spec, see `TimePeriodSample`
- `cycle`: cycle used when `aggr` is a period spec of kind msc, msc_anomaly or iav

A name that is not a method type is read as a period spec with the grammar
`<n>-<unit>[_<kind>[_<cycle>]]`. The separator may be `_` or `-`, and the kind is one
of `anomaly`, `msc`, `msc_anomaly` or `iav`. The count may also be joined to the
unit, as in `"3h"`. The spec `mean` gives `TimeMean()`.

# Returns
An instance of the corresponding `TimeSamplerMethod` subtype.

# Examples
```jldoctest
julia> using TimeSamplers

julia> get_TimeSampler("TimeDay")
TimeDay()

julia> get_TimeSampler(:TimeMonth)
TimeMonth()

julia> get_TimeSampler("TimeYear")
TimeYear()

julia> get_TimeSampler("6-hour")
TimePeriodSample{Hour}(Hour(6), :calendar)

julia> get_TimeSampler("3-hour_msc_day")
TimePeriodMSC{Hour, Day}(Hour(3), Day(1))
```

# Notes
- A similar approach (`getTypeInstanceForNamedOptions`) is used in `Setup` for creating other named options.
"""
function get_TimeSampler end

function get_TimeSampler(aggr::Symbol; kwargs...)
    return get_TimeSampler(string(aggr); kwargs...)
end

function get_TimeSampler(aggr::String; origin=:calendar, cycle=Year(1))
    aggr_sym = Symbol(aggr)
    if isdefined(TimeSamplers, aggr_sym)
        aggr_type = getfield(TimeSamplers, aggr_sym)
        if aggr_type isa DataType && aggr_type <: TimeSamplerMethod && isconcretetype(aggr_type)
            return aggr_type()
        end
    end
    return getTimePeriodMethodFromSpec(aggr; origin=origin, cycle=cycle)
end


"""
    getTypeOfTimeIndexArray(_type=:array)

Helper to switch the index-container type used in `TimeSample` objects.
"""
function getTypeOfTimeIndexArray(_type=:array)
    time_type = TimeArray()
    if _type == :sized_array
        time_type = TimeSizedArray()
    end
    return time_type
end



"""
    getIndexForSelectedYear(years, sel_year)

Helper to get indices for a selected year within `years`.
"""
function getIndexForSelectedYear(years, sel_year)
    return getTimeArray(findall(==(sel_year), years), getTypeOfTimeIndexArray())
end


"""
    getIndicesForTimeGroups(groups)

Helper to compute contiguous index ranges for run-length-encoded groups.
"""
function getIndicesForTimeGroups(groups)
    _, rl = rle(groups)
    cums = [0; cumsum(rl)]
    stepvectime = [cums[i]+1:cums[i+1] for i in 1:length(rl)]
    return stepvectime
end


"""
    getTimeArray(ar, ::TimeSizedArray || ::TimeArray)

Helper to wrap the provided indices in the configured container type.

# Arguments
- `ar`: Index array/ranges.
- `::TimeSizedArray`: Return indices as a `SizedArray` (static shape metadata).
- `::TimeArray`: Return indices as a normal Julia array/range.
"""
function getTimeArray(ar, ::TimeSizedArray)
    return SizedArray{Tuple{size(ar)...},eltype(ar)}(ar)
end

function getTimeArray(ar, ::TimeArray)
    return ar
end
