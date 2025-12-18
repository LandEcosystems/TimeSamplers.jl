# TimeSamplers Types

This page documents all types defined in TimeSamplers.jl, generated using `get_type_docstring` from OmniTools.jl.

```@meta
CurrentModule = TimeSamplers
DocTestSetup = quote
using TimeSamplers
using OmniTools: get_type_docstring, show_methods_of
end
```

## TimeSampler


# TimeSampler

Abstract type for implementing time subset, sampling, resampling, and aggregation types

## Type Hierarchy

```TimeSampler <: Any```

-----

# Extended help

## Available methods/subtypes:

 -  `TimeSample`: define a type for temporal sampling/aggregation of an array 
 -  `TimeSamplerMethod`: Abstract type for time sampling / aggregation methods 
     -  `TimeAllYears`: aggregation/slicing to include all years 
     -  `TimeArray`: use array-based time sampling/aggregation 
     -  `TimeDay`: aggregation to daily time steps 
     -  `TimeDayAnomaly`: aggregation to daily anomalies 
     -  `TimeDayIAV`: aggregation to daily IAV 
     -  `TimeDayMSC`: aggregation to daily MSC 
     -  `TimeDayMSCAnomaly`: aggregation to daily MSC anomalies 
     -  `TimeDiff`: aggregation to time differences, e.g. monthly anomalies 
     -  `TimeFirstYear`: aggregation/slicing of the first year 
     -  `TimeHour`: aggregation to hourly time steps 
     -  `TimeHourAnomaly`: aggregation to hourly anomalies 
     -  `TimeHourDayMean`: aggregation to mean of hourly data over days 
     -  `TimeIndexed`: aggregation using time indices, e.g., TimeFirstYear 
     -  `TimeMean`: aggregation to mean over all time steps 
     -  `TimeMonth`: aggregation to monthly time steps 
     -  `TimeMonthAnomaly`: aggregation to monthly anomalies 
     -  `TimeMonthIAV`: aggregation to monthly IAV 
     -  `TimeMonthMSC`: aggregation to monthly MSC 
     -  `TimeMonthMSCAnomaly`: aggregation to monthly MSC anomalies 
     -  `TimeNoDiff`: aggregation without time differences 
     -  `TimeRandomYear`: aggregation/slicing of a random year 
     -  `TimeShuffleYears`: aggregation/slicing/selection of shuffled years 
     -  `TimeSizedArray`: aggregation to a sized array 
     -  `TimeYear`: aggregation to yearly time steps 
     -  `TimeYearAnomaly`: aggregation to yearly anomalies 




## TimeSamplerMethod


# TimeSamplerMethod

Abstract type for time sampling / aggregation methods

## Type Hierarchy

```TimeSamplerMethod <: TimeSampler <: Any```

-----

# Extended help

## Available methods/subtypes:

 -  `TimeAllYears`: aggregation/slicing to include all years 
 -  `TimeArray`: use array-based time sampling/aggregation 
 -  `TimeDay`: aggregation to daily time steps 
 -  `TimeDayAnomaly`: aggregation to daily anomalies 
 -  `TimeDayIAV`: aggregation to daily IAV 
 -  `TimeDayMSC`: aggregation to daily MSC 
 -  `TimeDayMSCAnomaly`: aggregation to daily MSC anomalies 
 -  `TimeDiff`: aggregation to time differences, e.g. monthly anomalies 
 -  `TimeFirstYear`: aggregation/slicing of the first year 
 -  `TimeHour`: aggregation to hourly time steps 
 -  `TimeHourAnomaly`: aggregation to hourly anomalies 
 -  `TimeHourDayMean`: aggregation to mean of hourly data over days 
 -  `TimeIndexed`: aggregation using time indices, e.g., TimeFirstYear 
 -  `TimeMean`: aggregation to mean over all time steps 
 -  `TimeMonth`: aggregation to monthly time steps 
 -  `TimeMonthAnomaly`: aggregation to monthly anomalies 
 -  `TimeMonthIAV`: aggregation to monthly IAV 
 -  `TimeMonthMSC`: aggregation to monthly MSC 
 -  `TimeMonthMSCAnomaly`: aggregation to monthly MSC anomalies 
 -  `TimeNoDiff`: aggregation without time differences 
 -  `TimeRandomYear`: aggregation/slicing of a random year 
 -  `TimeShuffleYears`: aggregation/slicing/selection of shuffled years 
 -  `TimeSizedArray`: aggregation to a sized array 
 -  `TimeYear`: aggregation to yearly time steps 
 -  `TimeYearAnomaly`: aggregation to yearly anomalies 




## Core Types

### TimeSample


# TimeSample

define a type for temporal sampling/aggregation of an array

## Type Hierarchy

```TimeSample <: TimeSampler <: Any```



### TimeSampleViewInstance


# TimeSampleViewInstance

view of a TimeSample

## Type Hierarchy

```TimeSampleViewInstance <: AbstractArray <: Any```



## Basic Aggregation

### TimeDay


# TimeDay

aggregation to daily time steps

## Type Hierarchy

```TimeDay <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeHour


# TimeHour

aggregation to hourly time steps

## Type Hierarchy

```TimeHour <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeMean


# TimeMean

aggregation to mean over all time steps

## Type Hierarchy

```TimeMean <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeMonth


# TimeMonth

aggregation to monthly time steps

## Type Hierarchy

```TimeMonth <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeYear


# TimeYear

aggregation to yearly time steps

## Type Hierarchy

```TimeYear <: TimeSamplerMethod <: TimeSampler <: Any```



## Anomalies

### TimeDayAnomaly


# TimeDayAnomaly

aggregation to daily anomalies

## Type Hierarchy

```TimeDayAnomaly <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeDayMSCAnomaly


# TimeDayMSCAnomaly

aggregation to daily MSC anomalies

## Type Hierarchy

```TimeDayMSCAnomaly <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeHourAnomaly


# TimeHourAnomaly

aggregation to hourly anomalies

## Type Hierarchy

```TimeHourAnomaly <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeMonthAnomaly


# TimeMonthAnomaly

aggregation to monthly anomalies

## Type Hierarchy

```TimeMonthAnomaly <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeMonthMSCAnomaly


# TimeMonthMSCAnomaly

aggregation to monthly MSC anomalies

## Type Hierarchy

```TimeMonthMSCAnomaly <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeYearAnomaly


# TimeYearAnomaly

aggregation to yearly anomalies

## Type Hierarchy

```TimeYearAnomaly <: TimeSamplerMethod <: TimeSampler <: Any```



## Climatological Statistics

### TimeDayIAV


# TimeDayIAV

aggregation to daily IAV

## Type Hierarchy

```TimeDayIAV <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeDayMSC


# TimeDayMSC

aggregation to daily MSC

## Type Hierarchy

```TimeDayMSC <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeHourDayMean


# TimeHourDayMean

aggregation to mean of hourly data over days

## Type Hierarchy

```TimeHourDayMean <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeMonthIAV


# TimeMonthIAV

aggregation to monthly IAV

## Type Hierarchy

```TimeMonthIAV <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeMonthMSC


# TimeMonthMSC

aggregation to monthly MSC

## Type Hierarchy

```TimeMonthMSC <: TimeSamplerMethod <: TimeSampler <: Any```



## Time Selection

### TimeAllYears


# TimeAllYears

aggregation/slicing to include all years

## Type Hierarchy

```TimeAllYears <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeFirstYear


# TimeFirstYear

aggregation/slicing of the first year

## Type Hierarchy

```TimeFirstYear <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeRandomYear


# TimeRandomYear

aggregation/slicing of a random year

## Type Hierarchy

```TimeRandomYear <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeShuffleYears


# TimeShuffleYears

aggregation/slicing/selection of shuffled years

## Type Hierarchy

```TimeShuffleYears <: TimeSamplerMethod <: TimeSampler <: Any```



## Special Methods

### TimeArray


# TimeArray

use array-based time sampling/aggregation

## Type Hierarchy

```TimeArray <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeDiff


# TimeDiff

aggregation to time differences, e.g. monthly anomalies

## Type Hierarchy

```TimeDiff <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeIndexed


# TimeIndexed

aggregation using time indices, e.g., TimeFirstYear

## Type Hierarchy

```TimeIndexed <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeNoDiff


# TimeNoDiff

aggregation without time differences

## Type Hierarchy

```TimeNoDiff <: TimeSamplerMethod <: TimeSampler <: Any```



### TimeSizedArray


# TimeSizedArray

aggregation to a sized array

## Type Hierarchy

```TimeSizedArray <: TimeSamplerMethod <: TimeSampler <: Any```



## All TimeSampler Types

To list all available time sampler types and their purposes:

```julia
using TimeSamplers
using OmniTools: show_methods_of

# Display all time sampler types
show_methods_of(TimeSampler)
```
