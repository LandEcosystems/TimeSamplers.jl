export parse_temporal_resolution
export get_time_period
export format_temporal_resolution
export time_sampling_type
export time_sampling_period

"""
Maps unit names and their aliases to `Dates` period types. Lookup is
case-insensitive. The single letter `m` is not accepted because it could mean
minute or month.
"""
const TIME_PERIOD_UNITS = Dict{String,Type{<:Dates.Period}}(
    "second" => Second, "seconds" => Second, "sec" => Second, "s" => Second,
    "minute" => Minute, "minutes" => Minute, "min" => Minute,
    "hour" => Hour, "hours" => Hour, "hr" => Hour, "h" => Hour,
    "day" => Day, "days" => Day, "d" => Day,
    "week" => Week, "weeks" => Week, "w" => Week,
    "month" => Month, "months" => Month, "mon" => Month,
    "year" => Year, "years" => Year, "yr" => Year, "y" => Year,
)

const TIME_ORIGINS = (:calendar, :start, :year)

"""
    parse_temporal_resolution(resolution)

Parse a temporal resolution string into an integer count and a base unit string.

Accepts either a bare unit such as `"day"` or an n-unit string of the form
`"<positive integer>-<unit>"` such as `"6-hour"`. The count may also be written
directly before the unit, as in `"3hour"` or `"3h"`, or with a space, as in
`"3 hour"`. A bare unit is equivalent to `"1-<unit>"`. The unit is returned as given
and is not validated. Use `get_time_period` to turn a resolution into a
`Dates.Period`.

# Arguments:
- `resolution`: a temporal resolution string or symbol

# Returns:
- `(n::Int, unit::String)`: the count and the base unit string

# Examples
```jldoctest
julia> using TimeSamplers

julia> parse_temporal_resolution("6-hour")
(6, "hour")

julia> parse_temporal_resolution("day")
(1, "day")

julia> parse_temporal_resolution("3h")
(3, "h")
```
"""
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

"""
    get_time_period(spec)
    get_time_period(n, unit)

Convert a temporal resolution into a `Dates.Period`.

# Arguments:
- `spec`: a resolution string or symbol such as `"6-hour"`, `"30-sec"` or `:day`,
  or a `Dates.Period` which is returned unchanged
- `n`: a positive integer count
- `unit`: a unit name or alias from `TIME_PERIOD_UNITS`

# Examples
```jldoctest
julia> using TimeSamplers

julia> get_time_period("6-hour")
6 hours

julia> get_time_period(8, "day")
8 days
```
"""
function get_time_period end

get_time_period(period::Dates.Period) = period

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

# ------------------------- constructors and validation ---------------

function checkTimePeriod(period::Dates.Period)
    Dates.value(period) > 0 || error("time period must be positive, got $(period).")
    return nothing
end

function checkTimeOrigin(origin::Symbol)
    origin in TIME_ORIGINS || error("unsupported origin :$(origin). Use one of $(TIME_ORIGINS).")
    return nothing
end

"""
    checkCyclePeriod(period, cycle)

Check that bins of `period` fit inside a `cycle`. Month bins are only allowed in a
yearly cycle. Month and year cycles must have a count of one. Year bins cannot form a
cycle.
"""
function checkCyclePeriod(period::Dates.Period, cycle::Dates.Period)
    checkTimePeriod(period)
    checkTimePeriod(cycle)
    if period isa Year
        error("cannot build a cycle of $(period) bins. MSC and IAV need bins shorter than the cycle.")
    elseif period isa Month
        cycle == Year(1) || error("month bins need a cycle of one year, got $(cycle).")
    elseif cycle isa Union{Month,Year}
        Dates.value(cycle) == 1 || error("month and year cycles must have a count of 1, got $(cycle).")
        max_days = cycle isa Month ? 28 : 365
        Dates.toms(period) < Dates.toms(Day(max_days)) || error("bins of $(period) do not fit in a cycle of $(cycle).")
    else
        Dates.toms(period) < Dates.toms(cycle) || error("bins of $(period) must be shorter than the cycle of $(cycle).")
    end
    return nothing
end

getTimeCycle(cycle) = get_time_period(cycle)

for T in (:TimePeriodSample, :TimePeriodAnomaly)
    @eval begin
        $T(period; origin=:calendar) = $T(get_time_period(period), Symbol(origin))
        $T(n::Integer, unit; origin=:calendar) = $T(get_time_period(n, unit), Symbol(origin))
    end
end

for T in (:TimePeriodMSC, :TimePeriodMSCAnomaly, :TimePeriodIAV)
    @eval begin
        $T(period; cycle=Year(1)) = $T(get_time_period(period), getTimeCycle(cycle))
        $T(n::Integer, unit; cycle=Year(1)) = $T(get_time_period(n, unit), getTimeCycle(cycle))
    end
end

# ------------------------- bin keys ---------------

"""
    toTimeCompatibleDates(date_vector, periods...)

Convert `Date` values to `DateTime` when any of the periods is shorter than a day,
because a `Date` cannot be floored to hours or smaller.
"""
function toTimeCompatibleDates(date_vector, periods...)
    if eltype(date_vector) <: Date && any(p -> p isa Dates.TimePeriod, periods)
        return DateTime.(date_vector)
    end
    return date_vector
end

"""
    getBinCount(dt, period, anchor)

Number of whole `period` bins between `anchor` and `dt`.
"""
getBinCount(dt, period::Dates.FixedPeriod, anchor) = fld(Dates.toms(dt - anchor), Dates.toms(period))
getBinCount(dt, period::Month, anchor) = fld(12 * (year(dt) - year(anchor)) + month(dt) - month(anchor), Dates.value(period))
getBinCount(dt, period::Year, anchor) = fld(year(dt) - year(anchor), Dates.value(period))

"""
    getCycleBinKeys(date_vector, period, cycle; leap_aligned = false)

Bin keys for bins that restart at the start of every cycle.

With `leap_aligned = true`, a yearly cycle of day or sub-day bins is laid out on a
366 day leap year calendar. Every calendar date then has the same position in all
years, and the position of Feb 29 only has data from leap years. Other cycles and
month bins are not affected.

# Returns:
- `bin_starts`: the start of the bin of each date
- `positions`: the zero based position of that bin inside its cycle
"""
function getCycleBinKeys(date_vector, period, cycle; leap_aligned=false)
    _, positions = getCyclePositions(date_vector, period, cycle; leap_aligned=leap_aligned)
    cycle_starts = floor.(toTimeCompatibleDates(date_vector, period, cycle), cycle)
    if isLeapAlignedCycle(period, cycle, leap_aligned)
        bin_starts = getDateFromLeapCalendarOffset.(cycle_starts, positions .* Dates.toms(period))
    else
        bin_starts = cycle_starts .+ positions .* period
    end
    return bin_starts, positions
end

isLeapAlignedCycle(period, cycle, leap_aligned) = leap_aligned && cycle == Year(1) && period isa Dates.FixedPeriod

"""
    getCyclePositions(date_vector, period, cycle; leap_aligned = false)

A key for the cycle of each date and the zero based position of its bin inside that
cycle. The cycle key only identifies the cycle and is not always a date. See
`getCycleBinKeys`, which returns the start of every bin.
"""
function getCyclePositions(date_vector, period, cycle; leap_aligned=false)
    if period isa Month && cycle == Year(1)
        # month bins in a year only need the year and the month of every date
        return year.(date_vector), fld.(month.(date_vector) .- 1, Dates.value(period))
    end
    dates = toTimeCompatibleDates(date_vector, period, cycle)
    cycle_starts = floor.(dates, cycle)
    if isLeapAlignedCycle(period, cycle, leap_aligned)
        positions = fld.(getLeapCalendarOffset.(dates, cycle_starts), Dates.toms(period))
    else
        positions = getBinCount.(dates, period, cycle_starts)
    end
    return cycle_starts, positions
end

const MS_PER_DAY = Dates.toms(Day(1))

"""
    getLeapCalendarOffset(dt, year_start)

Milliseconds between `year_start` and `dt` on a 366 day leap year calendar. In years
without Feb 29, dates from Mar 1 on are moved one day later.
"""
function getLeapCalendarOffset(dt, year_start)
    offset = Dates.toms(dt - year_start)
    if !isleapyear(dt) && offset >= 59 * MS_PER_DAY
        offset += MS_PER_DAY
    end
    return offset
end

"""
    getDateFromLeapCalendarOffset(year_start, offset)

The date at `offset` milliseconds into the year on a 366 day leap year calendar. In
years without Feb 29, an offset that falls on Feb 29 maps to Mar 1.
"""
function getDateFromLeapCalendarOffset(year_start, offset)
    if !isleapyear(year_start) && offset >= 59 * MS_PER_DAY
        offset = max(59 * MS_PER_DAY, offset - MS_PER_DAY)
    end
    if year_start isa Date
        return year_start + Day(fld(offset, MS_PER_DAY))
    end
    return year_start + Millisecond(offset)
end

"""
    getResampleBinKeys(date_vector, period, origin)

The start of the bin of each date, used as its grouping key.

# Arguments:
- `date_vector`: sorted vector of dates
- `period`: the bin length as a `Dates.Period`
- `origin`: `:calendar` floors dates on the calendar, `:start` counts bins from the
  first date and `:year` restarts bins at every Jan 1
"""
function getResampleBinKeys(date_vector, period, origin)
    dates = toTimeCompatibleDates(date_vector, period)
    if origin === :calendar || (origin === :year && period isa Year)
        return floor.(dates, period)
    elseif origin === :year
        return first(getCycleBinKeys(dates, period, Year(1)))
    elseif origin === :start
        anchor = first(dates)
        if period isa Month
            anchor = floor(anchor, Month(1))
        elseif period isa Year
            anchor = floor(anchor, Year(1))
        end
        return anchor .+ getBinCount.(dates, period, anchor) .* period
    end
    checkTimeOrigin(origin)
end

"""
    getPeriodIndices(date_vector, period, origin)

Contiguous index ranges of the bins of `period`, one range per bin.
"""
function getPeriodIndices(date_vector, period, origin)
    return getIndicesForTimeGroups(getResampleBinKeys(date_vector, period, origin))
end

"""
    getIndicesForUniqueKeys(keys; sorted = false)

Indices of every unique key, in order of first appearance or sorted by key.

# Arguments:
- `keys`: one key per timestep
- `sorted`: when true, the unique keys are sorted instead of kept in order of first
  appearance

# Returns:
- `unique_keys`: the unique keys
- `indices`: a vector with the indices of each unique key
"""
function getIndicesForUniqueKeys(keys; sorted=false)
    unique_keys = sorted ? sort!(unique(keys)) : unique(keys)
    lookup = Dict(k => i for (i, k) in enumerate(unique_keys))
    indices = [Int[] for _ in unique_keys]
    for (i, k) in enumerate(keys)
        push!(indices[lookup[k]], i)
    end
    return unique_keys, indices
end

"""
    getAllTimeIndices(date_vector)

A single group with all time indices, used for overall means.
"""
function getAllTimeIndices(date_vector)
    return getTimeArray([1:length(date_vector)], getTypeOfTimeIndexArray())
end

# ------------------------- create_TimeSampler methods ---------------

function create_TimeSampler(date_vector, period::Dates.Period, sampler_func=mean, skip_sampling=false)
    return create_TimeSampler(date_vector, TimePeriodSample(period), sampler_func, skip_sampling)
end

"""
    getPeriodSamplers(date_vector, t_step, sampler_func)

Build the samplers of a period method without any skipping, so the result has a
concrete element type wherever the index types allow it.
"""
function getPeriodSamplers end

function getPeriodSamplers(date_vector, t_step::TimePeriodSample, sampler_func)
    stepvectime = getTimeArray(getPeriodIndices(date_vector, t_step.period, t_step.origin), getTypeOfTimeIndexArray())
    return [TimeSample(stepvectime, sampler_func, length(date_vector)),]
end

function getPeriodSamplers(date_vector, t_step::TimePeriodAnomaly, sampler_func)
    period_agg = getPeriodSamplers(date_vector, TimePeriodSample(t_step.period, t_step.origin), sampler_func)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [period_agg[1], mean_agg[1]]
end

function getPeriodSamplers(date_vector, t_step::TimePeriodMSC, sampler_func)
    _, positions = getCyclePositions(date_vector, t_step.period, t_step.cycle; leap_aligned=true)
    # sorted positions keep the cycle in calendar order even when the record starts
    # mid cycle or in a year without Feb 29
    _, position_inds = getIndicesForUniqueKeys(positions; sorted=true)
    msc_inds = [getTimeArray(inds, getTypeOfTimeIndexArray()) for inds in position_inds]
    return [TimeSample(msc_inds, sampler_func, length(date_vector)),]
end

function getPeriodSamplers(date_vector, t_step::TimePeriodMSCAnomaly, sampler_func)
    msc_agg = getPeriodSamplers(date_vector, TimePeriodMSC(t_step.period, t_step.cycle), sampler_func)
    mean_agg = create_TimeSampler(date_vector, TimeMean(), sampler_func)
    return [msc_agg[1], mean_agg[1]]
end

function getPeriodSamplers(date_vector, t_step::TimePeriodIAV, sampler_func)
    cycle_keys, positions = getCyclePositions(date_vector, t_step.period, t_step.cycle; leap_aligned=true)
    # a bin is identified by its cycle and its position in that cycle
    bin_inds = getIndicesForTimeGroups(tuple.(cycle_keys, positions))
    unique_positions, position_inds = getIndicesForUniqueKeys(positions)
    position_lookup = Dict(p => i for (i, p) in enumerate(unique_positions))
    # every bin gets the indices of all timesteps at the cycle position of that bin
    iav_inds = [getTimeArray(position_inds[position_lookup[positions[first(r)]]], getTypeOfTimeIndexArray()) for r in bin_inds]
    bin_agg = TimeSample(getTimeArray(bin_inds, getTypeOfTimeIndexArray()), sampler_func, length(date_vector))
    return [bin_agg, TimeSample(iav_inds, sampler_func, length(date_vector))]
end

"""
    skipFirstSampler(time_samplers, t_step, skip_sampling)

Replace the first sampler with `nothing` when `skip_sampling` is set, for methods
whose first sampler resamples bins. MSC methods never skip.
"""
function skipFirstSampler(time_samplers, t_step, skip_sampling)
    skip_sampling || return time_samplers
    skipped = Vector{Union{Nothing,eltype(time_samplers)}}(time_samplers)
    skipped[1] = nothing
    return skipped
end

skipFirstSampler(time_samplers, ::Union{TimePeriodMSC,TimePeriodMSCAnomaly}, skip_sampling) = time_samplers

function create_TimeSampler(date_vector, t_step::TimePeriodMethod, sampler_func=mean, skip_sampling=false)
    return skipFirstSampler(getPeriodSamplers(date_vector, t_step, sampler_func), t_step, skip_sampling)
end

# ------------------------- spec parsing ---------------

const TIME_CYCLE_KINDS = ("msc", "iav")

"""
    getTimePeriodMethodFromSpec(spec; origin = :calendar, cycle = Year(1))

Build a time sampling method from a spec string with the grammar
`<n-unit>[<sep><kind>[<sep><cycle unit>]]`, where `<sep>` is `_` or `-`. The
n-unit part may be written as `"3-hour"`, `"3hour"`, `"3h"` or `"hour"`.

The kind is one of `anomaly`, `msc`, `msc_anomaly` or `iav`, and without a kind the
spec resamples to bins. A trailing cycle unit is only allowed after `msc`,
`msc_anomaly` and `iav`, and overrides the `cycle` keyword. The spec `mean` gives
`TimeMean()`.

# Examples
- `"6-hour"` gives `TimePeriodSample(Hour(6))`
- `"8-day_msc"` gives `TimePeriodMSC(Day(8))` with a yearly cycle
- `"3-hour-msc-day"` gives a diurnal cycle of 3-hour bins
"""
function getTimePeriodMethodFromSpec(spec; origin=:calendar, cycle=Year(1))
    spec_str = lowercase(strip(String(spec)))
    spec_str == "mean" && return TimeMean()
    tokens = split(spec_str, r"[_-]")
    grammar = "expected \"<n>-<unit>[_<kind>[_<cycle>]]\" with kind in (anomaly, msc, msc_anomaly, iav), e.g. \"6-hour\", \"3h\", \"8-day_msc\" or \"3-hour_msc_day\"."

    spec_cycle = nothing
    if length(tokens) >= 3 && haskey(TIME_PERIOD_UNITS, tokens[end]) && tokens[end-1] in ("msc", "iav", "anomaly")
        spec_cycle = get_time_period(1, pop!(tokens))
    end

    kind = :sample
    if length(tokens) >= 3 && tokens[end-1] == "msc" && tokens[end] == "anomaly"
        kind = :msc_anomaly
        resize!(tokens, length(tokens) - 2)
    elseif length(tokens) >= 2 && tokens[end] in ("anomaly", TIME_CYCLE_KINDS...)
        kind = Symbol(pop!(tokens))
    end

    if !isnothing(spec_cycle) && kind === :anomaly
        error("invalid time sampling spec \"$(spec)\": a cycle is only allowed after msc, msc_anomaly or iav.")
    end
    period, reason = isempty(tokens) || length(tokens) > 2 ? (nothing, "") : tryTimePeriod(join(tokens, "-"))
    if isnothing(period)
        # the reason only helps when the tokens look like one count and unit
        looks_like_resolution = length(tokens) == 1 || (length(tokens) == 2 && all(isdigit, tokens[1]))
        detail = looks_like_resolution ? " $(reason)" : ""
        error("invalid time sampling spec \"$(spec)\": $(grammar)$(detail)")
    end
    cycle = isnothing(spec_cycle) ? getTimeCycle(cycle) : spec_cycle
    kind === :sample && return TimePeriodSample(period, Symbol(origin))
    kind === :anomaly && return TimePeriodAnomaly(period, Symbol(origin))
    kind === :msc && return TimePeriodMSC(period, cycle)
    kind === :msc_anomaly && return TimePeriodMSCAnomaly(period, cycle)
    return TimePeriodIAV(period, cycle)
end

"""
    tryTimePeriod(spec)

The `Dates.Period` of a resolution spec and an empty reason, or `nothing` and the
reason why the spec is not valid.
"""
function tryTimePeriod(spec)
    try
        return get_time_period(spec), ""
    catch err
        err isa ErrorException || rethrow()
        return nothing, err.msg
    end
end

# ------------------------- equivalents and diff types ---------------

"""
    getTimePeriodMethod(method)

The generic period method that a calendar method such as `TimeDay` is built on.
"""
function getTimePeriodMethod end

getTimePeriodMethod(t_step::TimePeriodMethod) = t_step
getTimePeriodMethod(::TimeHour) = TimePeriodSample(Hour(1))
getTimePeriodMethod(::TimeDay) = TimePeriodSample(Day(1))
getTimePeriodMethod(::TimeMonth) = TimePeriodSample(Month(1))
getTimePeriodMethod(::TimeYear) = TimePeriodSample(Year(1))
getTimePeriodMethod(::TimeHourAnomaly) = TimePeriodAnomaly(Hour(1))
getTimePeriodMethod(::TimeDayAnomaly) = TimePeriodAnomaly(Day(1))
getTimePeriodMethod(::TimeMonthAnomaly) = TimePeriodAnomaly(Month(1))
getTimePeriodMethod(::TimeYearAnomaly) = TimePeriodAnomaly(Year(1))
getTimePeriodMethod(::TimeDayMSC) = TimePeriodMSC(Day(1))
getTimePeriodMethod(::TimeMonthMSC) = TimePeriodMSC(Month(1))
getTimePeriodMethod(::TimeDayMSCAnomaly) = TimePeriodMSCAnomaly(Day(1))
getTimePeriodMethod(::TimeMonthMSCAnomaly) = TimePeriodMSCAnomaly(Month(1))
getTimePeriodMethod(::TimeDayIAV) = TimePeriodIAV(Day(1))
getTimePeriodMethod(::TimeMonthIAV) = TimePeriodIAV(Month(1))
getTimePeriodMethod(::TimeHourDayMean) = TimePeriodMSC(Hour(1), Day(1))
getTimePeriodMethod(t_step::TimeMean) = t_step
getTimePeriodMethod(t_step) = error("$(typeof(t_step)) is not a period based time sampling method.")

"""
    time_sampling_type(method)

How the samplers of a method are combined, as the type to pass to
`do_time_sampling`:
- `TimeNoDiff()` applies the first sampler, as for bins and mean cycles
- `TimeDiff()` subtracts the second sampler from the first, as for anomalies and
  IAV
- `TimeIndexed()` selects the time steps of the first sampler, as for
  `TimeFirstYear`, `TimeAllYears`, `TimeRandomYear` and `TimeShuffleYears`

`method` can also be a name or spec that `get_TimeSampler` accepts.

# Examples
```jldoctest
julia> using TimeSamplers

julia> time_sampling_type("8-day_iav")
TimeDiff()

julia> time_sampling_type("first_year")
TimeIndexed()
```
"""
function time_sampling_type end

time_sampling_type(::Union{TimePeriodSample,TimePeriodMSC,TimeMean}) = TimeNoDiff()
time_sampling_type(::Union{TimePeriodAnomaly,TimePeriodMSCAnomaly,TimePeriodIAV}) = TimeDiff()
time_sampling_type(::Union{TimeFirstYear,TimeAllYears,TimeRandomYear,TimeShuffleYears}) = TimeIndexed()
time_sampling_type(t_step::TimeSamplerMethod) = time_sampling_type(getTimePeriodMethod(t_step))
time_sampling_type(spec::Union{AbstractString,Symbol}) = time_sampling_type(get_TimeSampler(String(spec)))

"""
    time_sampling_period(method)

The length of the bins of a method as a `Dates.Period`, or `nothing` for methods
without bins such as `TimeMean` or `TimeFirstYear`. For a mean cycle this is the
length of the bins inside the cycle, not the cycle.

`method` can also be a name or spec that `get_TimeSampler` accepts.

# Examples
```jldoctest
julia> using TimeSamplers

julia> time_sampling_period("3-hour_msc_day")
3 hours

julia> time_sampling_period("day_MSC")
1 day

julia> time_sampling_period("all_years") === nothing
true
```
"""
function time_sampling_period end

time_sampling_period(t_step::TimePeriodMethod) = t_step.period
time_sampling_period(t_step::TimeCalendarMethod) = time_sampling_period(getTimePeriodMethod(t_step))
time_sampling_period(::TimeSamplerMethod) = nothing
time_sampling_period(spec::Union{AbstractString,Symbol}) = time_sampling_period(get_TimeSampler(String(spec)))

"""
    format_temporal_resolution(period)

The canonical resolution string of a period: the bare unit for a count of one,
otherwise `"<n>-<unit>"`. The unit is the full lowercase name, so the result can be
parsed with `parse_temporal_resolution` by other packages without aliases.

# Arguments:
- `period`: a `Dates.Period`, or a resolution string such as `"3h"` that is
  first converted with `get_time_period`

# Examples
```jldoctest
julia> using TimeSamplers, Dates

julia> format_temporal_resolution(Hour(3))
"3-hour"

julia> format_temporal_resolution("d")
"day"
```
"""
function format_temporal_resolution end

function format_temporal_resolution(period::Dates.Period)
    unit = lowercase(string(nameof(typeof(period))))
    n = Dates.value(period)
    return n == 1 ? unit : "$(n)-$(unit)"
end

format_temporal_resolution(spec::Union{AbstractString,Symbol}) = format_temporal_resolution(get_time_period(spec))
