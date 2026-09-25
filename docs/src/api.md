```@meta
CurrentModule = TimeSamplers
```

# API

```@docs
TimeSamplers
```

```@docs
create_TimeSampler
```

::: details Code

```julia
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

function create_TimeSampler(date_vector, period::Dates.Period, sampler_func=mean, skip_sampling=false)
    return create_TimeSampler(date_vector, TimePeriodSample(period), sampler_func, skip_sampling)
end

function create_TimeSampler(date_vector, t_step::TimePeriodMethod, sampler_func=mean, skip_sampling=false)
    return skipFirstSampler(getPeriodSamplers(date_vector, t_step, sampler_func), t_step, skip_sampling)
end
```

:::

```@docs
do_time_sampling
```

::: details Code

```julia
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
```

:::

```@docs
get_TimeSampler
```

::: details Code

```julia
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
```

:::

```@docs
get_time_period
```

::: details Code

```julia
function get_time_period(spec::Union{AbstractString,Symbol})
    n, unit = parse_temporal_resolution(spec)
    return get_time_period(n, unit)
end

function get_time_period(n::Integer, unit)
    n > 0 || error("invalid time period count $(n): must be a positive integer.")
    unit_type = get(TIME_PERIOD_UNITS, lowercase(String(unit)), nothing)
    if isnothing(unit_type)
        supported = join(sort(collect(keys(TIME_PERIOD_UNITS))), ", ")
        error("unsupported time unit \"$(unit)\". Supported units are: $(supported).")
    end
    return unit_type(n)
end
```

:::

```@docs
parse_temporal_resolution
```

::: details Code

```julia
function parse_temporal_resolution(resolution)
    parts = split(String(resolution), "-")
    if length(parts) == 1
        # a count written directly before the unit, such as 3hour, 3h or 3 hour
        joined = match(r"^\s*(\d+)\s*([A-Za-z]+)\s*$", parts[1])
        if !isnothing(joined)
            n = parse(Int, joined.captures[1])
            n > 0 || error("invalid temporal resolution \"$(resolution)\": count must be a positive integer, got $(n).")
            return n, String(joined.captures[2])
        end
        return 1, String(parts[1])
    elseif length(parts) == 2
        n = tryparse(Int, parts[1])
        if isnothing(n)
            error("invalid temporal resolution \"$(resolution)\": count \"$(parts[1])\" is not an integer. Expected format \"<integer>-<unit>\", e.g. \"6-hour\".")
        elseif n <= 0
            error("invalid temporal resolution \"$(resolution)\": count must be a positive integer, got $(n).")
        end
        return n, String(parts[2])
    else
        error("invalid temporal resolution \"$(resolution)\": expected a bare unit (e.g. \"day\") or \"<integer>-<unit>\" (e.g. \"6-hour\"), got $(length(parts)) dash-separated parts.")
    end
end
```

:::

```@docs
time_resample
```

::: details Code

```julia
function time_resample(dat, date_vector, period; sampler_func=mean, dim=1, origin=:calendar, cycle=Year(1))
    if size(dat, dim) != length(date_vector)
        error("size of data along dimension $(dim) is $(size(dat, dim)), but date_vector has $(length(date_vector)) dates.")
    end
    t_step = toTimePeriodMethod(period; origin=origin, cycle=cycle)
    time_samplers = create_TimeSampler(date_vector, t_step, sampler_func)
    return doTimeResample(dat, time_samplers, getTimeSamplingDiffType(t_step), dim)
end
```

:::

```@docs
time_resample_dates
```

::: details Code

```julia
function time_resample_dates(date_vector, period; origin=:calendar, cycle=Year(1))
    t_step = toTimePeriodMethod(period; origin=origin, cycle=cycle)
    return getTimeResampleLabels(date_vector, getTimePeriodMethod(t_step))
end
```

:::

```@docs
time_sampling
```

::: details Code

```julia
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
```

:::

