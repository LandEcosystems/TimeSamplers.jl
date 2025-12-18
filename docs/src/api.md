```@meta
CurrentModule = TimeSamplers
```

# API

```@docs
create_TimeSampler
```

::: details Code

```julia
function create_TimeSampler end


function create_TimeSampler(date_vector, t_step::Union{String, Symbol}, sampler_func=mean, skip_sampling=false)
    return create_TimeSampler(date_vector, get_TimeSampler(t_step), sampler_func, skip_sampling)
end

function create_TimeSampler(date_vector, t_step::Union{String, Symbol}, sampler_func=mean, skip_sampling=false)
    return create_TimeSampler(date_vector, get_TimeSampler(t_step), sampler_func, skip_sampling)
end

function create_TimeSampler(date_vector, ::TimeMean, sampler_func=mean, skip_sampling=false)
    stepvectime = getTimeArray([1:length(date_vector)], getTypeOfTimeIndexArray())
    mean_agg = TimeSample(stepvectime, sampler_func)
    return [mean_agg,]
end

function create_TimeSampler(date_vector, ::TimeDay, sampler_func=mean, skip_sampling=false)
    stepvectime = getIndicesForTimeGroups(day.(date_vector))
    day_agg = TimeSample(stepvectime, sampler_func)
    if skip_sampling
        day_agg = nothing
    end
    return [day_agg,]
end

function create_TimeSampler(date_vector, ::TimeDayAnomaly, sampler_func=mean, skip_sampling=false)
    day_agg = create_TimeSampler(date_vector, TimeDay(), sampler_func, skip_sampling)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [day_agg[1], mean_agg[1]]
end

function create_TimeSampler(date_vector, ::TimeDayIAV, sampler_func=mean, skip_sampling=false)
    days = dayofyear.(date_vector)
    day_aggr = create_TimeSampler(date_vector, TimeDay(), sampler_func, skip_sampling)
    daysMsc = unique(days)
    daysMsc_inds = [findall(==(dd), days) for dd in daysMsc]
    daysIav_inds = [getTimeArray(daysMsc_inds[d], getTypeOfTimeIndexArray()) for d in days]
    dayIav_agg = TimeSample(daysIav_inds, sampler_func)
    return [day_aggr[1], dayIav_agg]
end

function create_TimeSampler(date_vector, ::TimeDayMSC, sampler_func=mean, skip_sampling=false)
    days = dayofyear.(date_vector)
    daysMsc = unique(days)
    days_ind = [getTimeArray(findall(==(dd), days), getTypeOfTimeIndexArray()) for dd in daysMsc]
    dat_msc_agg = TimeSample(days_ind, sampler_func)
    return [dat_msc_agg,]
end

function create_TimeSampler(date_vector, ::TimeDayMSCAnomaly, sampler_func=mean, skip_sampling=false)
    dat_msc_agg = create_TimeSampler(date_vector, TimeDayMSC(), sampler_func, skip_sampling)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [dat_msc_agg[1], mean_agg[1]]
end

function create_TimeSampler(date_vector, ::TimeHour, sampler_func=mean, skip_sampling=false)
    stepvectime = getIndicesForTimeGroups(hour.(date_vector))
    hour_agg = TimeSample(stepvectime, sampler_func)
    if skip_sampling
        hour_agg = nothing
    end
    return [hour_agg,]
end

function create_TimeSampler(date_vector, ::TimeHourAnomaly, sampler_func=mean, skip_sampling=false)
    hour_agg = create_TimeSampler(date_vector, TimeHour(), sampler_func, skip_sampling)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [hour_agg[1], mean_agg[1]]
end

function create_TimeSampler(date_vector, ::TimeHourDayMean, sampler_func=mean, skip_sampling=false)
    hours = hour.(date_vector)
    hours_day = unique(hours)
    t_hour_msc_agg = TimeSample([getTimeArray(findall(==(hh), hours), getTypeOfTimeIndexArray()) for hh in hours_day], sampler_func)
    return [t_hour_msc_agg,]
end

function create_TimeSampler(date_vector, ::TimeMonth, sampler_func=mean, skip_sampling=false)
    stepvectime = getIndicesForTimeGroups(month.(date_vector))
    month_agg = TimeSample(stepvectime, sampler_func)
    return [month_agg,]
end

function create_TimeSampler(date_vector, ::TimeMonthAnomaly, sampler_func=mean, skip_sampling=false)
    month_agg = create_TimeSampler(date_vector, TimeMonth(), sampler_func, skip_sampling)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [month_agg[1], mean_agg[1]]
end

function create_TimeSampler(date_vector, ::TimeMonthIAV, sampler_func=mean, skip_sampling=false)
    months = month.(date_vector) # month for each time step, size = number of time steps
    month_aggr = create_TimeSampler(date_vector, TimeMonth(), sampler_func, skip_sampling) #to get the month per month, size = number of months
    months_series = Int.(view(months, month_aggr[1])) # aggregate the months per time step
    monthsMsc = unique(months) # get unique months
    monthsMsc_inds = [findall(==(mm), months) for mm in monthsMsc] # all timesteps per unique month
    monthsIav_inds = [getTimeArray(monthsMsc_inds[mm], getTypeOfTimeIndexArray()) for mm in months_series] # repeat monthlymsc indices for each month in time range
    monthIav_agg = TimeSample(monthsIav_inds, sampler_func) # generate aggregator
    return [month_aggr[1], monthIav_agg]
end

function create_TimeSampler(date_vector, ::TimeMonthMSC, sampler_func=mean, skip_sampling=false)
    months = month.(date_vector)
    monthsMsc = unique(months)
    t_month_msc_agg = TimeSample([getTimeArray(findall(==(mm), months), getTypeOfTimeIndexArray()) for mm in monthsMsc], sampler_func)
    return [t_month_msc_agg,]
end

function create_TimeSampler(date_vector, ::TimeMonthMSCAnomaly, sampler_func=mean, skip_sampling=false)
    t_month_msc_agg = create_TimeSampler(date_vector, TimeMonthMSC(), sampler_func, skip_sampling)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [t_month_msc_agg[1], mean_agg[1]]
end

function create_TimeSampler(date_vector, ::TimeYear, sampler_func=mean, skip_sampling=false)
    stepvectime = getTimeArray(getIndicesForTimeGroups(year.(date_vector)), getTypeOfTimeIndexArray())
    year_agg = TimeSample(stepvectime, sampler_func)
    return [year_agg,]
end

function create_TimeSampler(date_vector, ::TimeYearAnomaly, sampler_func=mean, skip_sampling=false)
    year_agg = create_TimeSampler(date_vector, TimeYear(), sampler_func, skip_sampling)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [year_agg[1], mean_agg[1]]
end

function create_TimeSampler(date_vector, ::TimeAllYears, sampler_func=mean, skip_sampling=false)
    stepvectime = getTimeArray([1:length(date_vector)], getTypeOfTimeIndexArray())
    all_agg = TimeSample(stepvectime, sampler_func)
    return [all_agg,]
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
```

:::

```@docs
do_time_sampling
```

::: details Code

```julia
function do_time_sampling end

function do_time_sampling(dat, time_samplers, ::TimeIndexed)
    return dat[first(time_samplers).indices...]
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
function get_TimeSampler end

function get_TimeSampler(aggr::Symbol)
    return get_TimeSampler(string(aggr))
end

function get_TimeSampler(aggr::Symbol)
    return get_TimeSampler(string(aggr))
end

function get_TimeSampler(aggr::String)
    # uc_first = String(aggr)
    # uc_first = toUpperCaseFirst(aggr, "Time")
    return getfield(TimeSamplers, Symbol(aggr))()
end
```

:::

```@docs
time_sampling
```

::: details Code

```julia
function time_sampling end

function time_sampling(dat::AbstractArray, time_sampler::TimeSample, dim=1)
    dat = view(dat, time_sampler, dim=dim)
    return getTimeSampledArray(dat)
end

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

