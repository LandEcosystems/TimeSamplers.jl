# TimeSamplers Types

This page documents all types defined in TimeSamplers.jl, generated using [`get_type_docstring`](https://landecosystems.github.io/OmniTools.jl/dev/api/ForDocStrings/#get_type_docstring) from OmniTools.jl.

```@meta
CurrentModule = TimeSamplers
DocTestSetup = quote
using TimeSamplers
using OmniTools: get_type_docstring, show_methods_of
end
```

## TimeSampler

`TimeSampler`

Abstract type for implementing time subset, sampling, resampling, and aggregation types

```
TimeSampler <: Any
```

## TimeSamplerMethod

`TimeSamplerMethod`

Abstract type for time sampling / aggregation methods

```
TimeSamplerMethod <: Any
```

## Core Types

`TimeSample`

define a type for temporal sampling/aggregation of an array

```
TimeSample <: TimeSampler <: Any
```

`TimeSampleViewInstance`

view of a TimeSample

```
TimeSampleViewInstance <: AbstractArray <: Any
```

## Basic Aggregation

`TimeDay`


aggregation to daily time steps




```
TimeDay <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeHour`


aggregation to hourly time steps




```
TimeHour <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeMean`


aggregation to mean over all time steps




```
TimeMean <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeMonth`


aggregation to monthly time steps




```
TimeMonth <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeYear`


aggregation to yearly time steps




```
TimeYear <: TimeSamplerMethod <: TimeSampler <: Any
```

## Anomalies

`TimeDayAnomaly`


aggregation to daily anomalies




```
TimeDayAnomaly <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeDayMSCAnomaly`


aggregation to daily MSC anomalies




```
TimeDayMSCAnomaly <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeHourAnomaly`


aggregation to hourly anomalies




```
TimeHourAnomaly <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeMonthAnomaly`


aggregation to monthly anomalies




```
TimeMonthAnomaly <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeMonthMSCAnomaly`


aggregation to monthly MSC anomalies




```
TimeMonthMSCAnomaly <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeYearAnomaly`


aggregation to yearly anomalies




```
TimeYearAnomaly <: TimeSamplerMethod <: TimeSampler <: Any
```

## Climatological Statistics

`TimeDayIAV`


aggregation to daily IAV




```
TimeDayIAV <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeDayMSC`


aggregation to daily MSC




```
TimeDayMSC <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeHourDayMean`


aggregation to mean of hourly data over days




```
TimeHourDayMean <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeMonthIAV`


aggregation to monthly IAV




```
TimeMonthIAV <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeMonthMSC`


aggregation to monthly MSC




```
TimeMonthMSC <: TimeSamplerMethod <: TimeSampler <: Any
```

## Time Selection

`TimeAllYears`


aggregation/slicing to include all years




```
TimeAllYears <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeFirstYear`


aggregation/slicing of the first year




```
TimeFirstYear <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeRandomYear`


aggregation/slicing of a random year




```
TimeRandomYear <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeShuffleYears`


aggregation/slicing/selection of shuffled years




```
TimeShuffleYears <: TimeSamplerMethod <: TimeSampler <: Any
```

## Special Methods

`TimeArray`


use array-based time sampling/aggregation




```
TimeArray <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeDiff`


aggregation to time differences, e.g. monthly anomalies




```
TimeDiff <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeIndexed`


aggregation using time indices, e.g., TimeFirstYear




```
TimeIndexed <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeNoDiff`


aggregation without time differences




```
TimeNoDiff <: TimeSamplerMethod <: TimeSampler <: Any
```

---

`TimeSizedArray`


aggregation to a sized array




```
TimeSizedArray <: TimeSamplerMethod <: TimeSampler <: Any
```

## All TimeSampler Types

To list all available time sampler types and their purposes:

```julia
using TimeSamplers
using OmniTools: show_methods_of

# Display all time sampler types
show_methods_of(TimeSampler)
```
