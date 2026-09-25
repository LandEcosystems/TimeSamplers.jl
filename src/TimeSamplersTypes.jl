
export TimeSampler
abstract type TimeSampler end
purpose(::Type{TimeSampler}) = "Abstract type for implementing time subset, sampling, resampling, and aggregation types"

# ------------------------- time aggregator ------------------------------------------------------------
export TimeSamplerMethod
export TimeAllYears
export TimeArray
export TimeHour
export TimeHourAnomaly
export TimeHourDayMean
export TimeDay
export TimeDayAnomaly
export TimeDayIAV
export TimeDayMSC
export TimeDayMSCAnomaly
export TimeDiff
export TimeFirstYear
export TimeIndexed
export TimeMean
export TimeMonth
export TimeMonthAnomaly
export TimeMonthIAV
export TimeMonthMSC
export TimeMonthMSCAnomaly
export TimeNoDiff
export TimeRandomYear
export TimeShuffleYears
export TimeSizedArray
export TimeYear
export TimeYearAnomaly
export TimeSample
export TimeSampleViewInstance
export TimePeriodMethod
export TimePeriodSample
export TimePeriodAnomaly
export TimePeriodMSC
export TimePeriodMSCAnomaly
export TimePeriodIAV


# ------------------------- time aggregator ---------------
"""
    TimeSample{I, sampler_func}

define a type for temporal sampling/aggregation of an array

# Fields:
- `indices::I`: indices to be collected for sampling/aggregation
- `sampler_func::sampler_func`: a function to use for sampling/aggregation, defaults to mean
"""
struct TimeSample{I,sampler_func} <: TimeSampler
    indices::I
    sampler_func::sampler_func
end
purpose(::Type{TimeSample}) = "define a type for temporal sampling/aggregation of an array"

"""
    TimeSampleViewInstance{T, N, D, P, AV <: TimeSample}



# Fields:
- `parent::P`: the parent data
- `agg::AV`: a view of the parent data
- `dim::Val{D}`: a val instance of the type that stores the dimension to be aggregated on
"""
struct TimeSampleViewInstance{T,N,D,P,AV<:TimeSample} <: AbstractArray{T,N}
    parent::P
    agg::AV
    dim::Val{D}
end
purpose(::Type{TimeSampleViewInstance}) = "view of a TimeSample"


abstract type TimeSamplerMethod <: TimeSampler end
purpose(::Type{TimeSamplerMethod}) = "Abstract type for time sampling / aggregation methods"

struct TimeAllYears <: TimeSamplerMethod end
purpose(::Type{TimeAllYears}) = "aggregation/slicing to include all years"

struct TimeArray <: TimeSamplerMethod end
purpose(::Type{TimeArray}) = "use array-based time sampling/aggregation"

struct TimeHour <: TimeSamplerMethod end
purpose(::Type{TimeHour}) = "aggregation to hourly time steps"

struct TimeHourAnomaly <: TimeSamplerMethod end
purpose(::Type{TimeHourAnomaly}) = "aggregation to hourly anomalies"

struct TimeHourDayMean <: TimeSamplerMethod end
purpose(::Type{TimeHourDayMean}) = "aggregation to mean of hourly data over days"

struct TimeDay <: TimeSamplerMethod end
purpose(::Type{TimeDay}) = "aggregation to daily time steps"

struct TimeDayAnomaly <: TimeSamplerMethod end
purpose(::Type{TimeDayAnomaly}) = "aggregation to daily anomalies"

struct TimeDayIAV <: TimeSamplerMethod end
purpose(::Type{TimeDayIAV}) = "aggregation to daily IAV"

struct TimeDayMSC <: TimeSamplerMethod end
purpose(::Type{TimeDayMSC}) = "aggregation to daily MSC"

struct TimeDayMSCAnomaly <: TimeSamplerMethod end
purpose(::Type{TimeDayMSCAnomaly}) = "aggregation to daily MSC anomalies"

struct TimeDiff <: TimeSamplerMethod end
purpose(::Type{TimeDiff}) = "aggregation to time differences, e.g. monthly anomalies"

struct TimeFirstYear <: TimeSamplerMethod end
purpose(::Type{TimeFirstYear}) = "aggregation/slicing of the first year"

struct TimeIndexed <: TimeSamplerMethod end
purpose(::Type{TimeIndexed}) = "aggregation using time indices, e.g., TimeFirstYear"

struct TimeMean <: TimeSamplerMethod end
purpose(::Type{TimeMean}) = "aggregation to mean over all time steps"

struct TimeMonth <: TimeSamplerMethod end
purpose(::Type{TimeMonth}) = "aggregation to monthly time steps"

struct TimeMonthAnomaly <: TimeSamplerMethod end
purpose(::Type{TimeMonthAnomaly}) = "aggregation to monthly anomalies"

struct TimeMonthIAV <: TimeSamplerMethod end
purpose(::Type{TimeMonthIAV}) = "aggregation to monthly IAV"

struct TimeMonthMSC <: TimeSamplerMethod end
purpose(::Type{TimeMonthMSC}) = "aggregation to monthly MSC"

struct TimeMonthMSCAnomaly <: TimeSamplerMethod end
purpose(::Type{TimeMonthMSCAnomaly}) = "aggregation to monthly MSC anomalies"

struct TimeNoDiff <: TimeSamplerMethod end
purpose(::Type{TimeNoDiff}) = "aggregation without time differences"

struct TimeRandomYear <: TimeSamplerMethod end
purpose(::Type{TimeRandomYear}) = "aggregation/slicing of a random year"

struct TimeShuffleYears <: TimeSamplerMethod end
purpose(::Type{TimeShuffleYears}) = "aggregation/slicing/selection of shuffled years"

struct TimeSizedArray <: TimeSamplerMethod end
purpose(::Type{TimeSizedArray}) = "aggregation to a sized array"

struct TimeYear <: TimeSamplerMethod end
purpose(::Type{TimeYear}) = "aggregation to yearly time steps"

struct TimeYearAnomaly <: TimeSamplerMethod end
purpose(::Type{TimeYearAnomaly}) = "aggregation to yearly anomalies"


# ------------------------- period based methods ---------------
abstract type TimePeriodMethod <: TimeSamplerMethod end
purpose(::Type{TimePeriodMethod}) = "Abstract type for time sampling methods defined by an n-unit period"

"""
    TimePeriodSample(period; origin = :calendar)
    TimePeriodSample(n, unit; origin = :calendar)

Resample to bins of an n-unit period such as `Hour(6)`, `"6-hour"` or `Day(8)`.

# Fields:
- `period::P`: the bin length as a `Dates.Period`
- `origin::Symbol`: where bins start. `:calendar` floors dates on the calendar,
  `:start` counts bins from the first date, and `:year` restarts bins at every
  Jan 1 so that the last bin of each year may be short.

With `:calendar`, bins of hours, minutes and seconds align to midnight, and month
bins align to Jan 1, so 3-month bins are calendar quarters. Bins of several days or
weeks align to the `Dates` epoch instead of the data. Use `:start` or `:year` to
align such bins to the data.
"""
struct TimePeriodSample{P<:Dates.Period} <: TimePeriodMethod
    period::P
    origin::Symbol
    function TimePeriodSample(period::P, origin::Symbol) where {P<:Dates.Period}
        checkTimePeriod(period)
        checkTimeOrigin(origin)
        return new{P}(period, origin)
    end
end
purpose(::Type{TimePeriodSample}) = "aggregation to bins of an n-unit period"

"""
    TimePeriodAnomaly(period; origin = :calendar)
    TimePeriodAnomaly(n, unit; origin = :calendar)

Anomalies of n-unit bins, computed as each bin value minus the overall mean.

# Fields:
- `period::P`: the bin length as a `Dates.Period`
- `origin::Symbol`: where bins start, see `TimePeriodSample`
"""
struct TimePeriodAnomaly{P<:Dates.Period} <: TimePeriodMethod
    period::P
    origin::Symbol
    function TimePeriodAnomaly(period::P, origin::Symbol) where {P<:Dates.Period}
        checkTimePeriod(period)
        checkTimeOrigin(origin)
        return new{P}(period, origin)
    end
end
purpose(::Type{TimePeriodAnomaly}) = "aggregation to anomalies of n-unit bins"

"""
    TimePeriodMSC(period; cycle = Year(1))
    TimePeriodMSC(n, unit; cycle = Year(1))

Mean cycle of n-unit bins. With the default yearly cycle this is the multi-year
seasonal cycle, and with `cycle = Day(1)` it is the mean diurnal cycle. The value at
each cycle position pools all timesteps at that position across all cycles. Bins
restart at the start of every cycle.

In a yearly cycle of day or sub-day bins, positions follow calendar dates on a 366
day leap year calendar. Every date is grouped with the same date in all years, and
Feb 29 only has data from leap years. Daily bins give 366 values when the record has
a leap year and 365 otherwise.

# Fields:
- `period::P`: the bin length as a `Dates.Period`
- `cycle::C`: the length of the cycle as a `Dates.Period`
"""
struct TimePeriodMSC{P<:Dates.Period,C<:Dates.Period} <: TimePeriodMethod
    period::P
    cycle::C
    function TimePeriodMSC(period::P, cycle::C) where {P<:Dates.Period,C<:Dates.Period}
        checkCyclePeriod(period, cycle)
        return new{P,C}(period, cycle)
    end
end
purpose(::Type{TimePeriodMSC}) = "aggregation to the mean seasonal or diurnal cycle of n-unit bins"

"""
    TimePeriodMSCAnomaly(period; cycle = Year(1))
    TimePeriodMSCAnomaly(n, unit; cycle = Year(1))

Mean cycle of n-unit bins minus the overall mean. See `TimePeriodMSC`.

# Fields:
- `period::P`: the bin length as a `Dates.Period`
- `cycle::C`: the length of the cycle as a `Dates.Period`
"""
struct TimePeriodMSCAnomaly{P<:Dates.Period,C<:Dates.Period} <: TimePeriodMethod
    period::P
    cycle::C
    function TimePeriodMSCAnomaly(period::P, cycle::C) where {P<:Dates.Period,C<:Dates.Period}
        checkCyclePeriod(period, cycle)
        return new{P,C}(period, cycle)
    end
end
purpose(::Type{TimePeriodMSCAnomaly}) = "aggregation to anomalies of the mean cycle of n-unit bins"

"""
    TimePeriodIAV(period; cycle = Year(1))
    TimePeriodIAV(n, unit; cycle = Year(1))

Inter-cycle variability of n-unit bins, computed as each bin value minus the mean
cycle value at the position of that bin. See `TimePeriodMSC`.

# Fields:
- `period::P`: the bin length as a `Dates.Period`
- `cycle::C`: the length of the cycle as a `Dates.Period`
"""
struct TimePeriodIAV{P<:Dates.Period,C<:Dates.Period} <: TimePeriodMethod
    period::P
    cycle::C
    function TimePeriodIAV(period::P, cycle::C) where {P<:Dates.Period,C<:Dates.Period}
        checkCyclePeriod(period, cycle)
        return new{P,C}(period, cycle)
    end
end
purpose(::Type{TimePeriodIAV}) = "aggregation to the inter-annual variability of n-unit bins"
