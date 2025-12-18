using Pkg
using Base: DEPOT_PATH
cd(@__DIR__)
Pkg.activate(".")
# Ensure OmniTools is available (for CI/CD where it's not registered)
try
    using OmniTools
catch
    @info "OmniTools not available, adding from git..."
    Pkg.develop(PackageSpec(url = "https://github.com/LandEcosystems/OmniTools.jl.git"))
    # Checkout the main branch after developing
    omni_tools_path = joinpath(DEPOT_PATH[1], "dev", "OmniTools")
    if isdir(omni_tools_path)
        cd(omni_tools_path) do
            run(`git checkout main`)
        end
    end
    using OmniTools
end
Pkg.resolve()
Pkg.instantiate()

using TimeSamplers
using OmniTools: get_type_docstring, show_methods_of, get_definitions, purpose
using InteractiveUtils: subtypes

# Generate types.md
types_path = joinpath(@__DIR__, "src/types.md")
open(types_path, "w") do io
    write(io, "# TimeSamplers Types\n\n")
    write(io, "This page documents all types defined in TimeSamplers.jl, generated using `get_type_docstring` from OmniTools.jl.\n\n")
    write(io, "```@meta\n")
    write(io, "CurrentModule = TimeSamplers\n")
    write(io, "DocTestSetup = quote\n")
    write(io, "using TimeSamplers\n")
    write(io, "using OmniTools: get_type_docstring, show_methods_of\n")
    write(io, "end\n")
    write(io, "```\n\n")
    
    # TimeSampler abstract type
    write(io, "## TimeSampler\n\n")
    write(io, "```@docs\n")
    write(io, "TimeSampler\n")
    write(io, "```\n\n")
    # Use purpose from TimeSamplers (which extends OmniTools.purpose)
    time_sampler_purpose = (typ) -> TimeSamplers.purpose(typ)
    write(io, get_type_docstring(TimeSampler, purpose_function=time_sampler_purpose))
    write(io, "\n\n")
    
    # TimeSamplerMethod abstract type
    write(io, "## TimeSamplerMethod\n\n")
    write(io, "```@docs\n")
    write(io, "TimeSamplerMethod\n")
    write(io, "```\n\n")
    write(io, get_type_docstring(TimeSamplerMethod, purpose_function=time_sampler_purpose))
    write(io, "\n\n")
    
    # Core types
    write(io, "## Core Types\n\n")
    write(io, "```@docs\n")
    write(io, "TimeSample\n")
    write(io, "TimeSampleViewInstance\n")
    write(io, "```\n\n")
    write(io, get_type_docstring(TimeSample, purpose_function=time_sampler_purpose))
    write(io, "\n\n")
    write(io, get_type_docstring(TimeSampleViewInstance, purpose_function=time_sampler_purpose))
    write(io, "\n\n")
    
    # Get all TimeSamplerMethod subtypes
    time_sampler_types = subtypes(TimeSamplerMethod)
    sort!(time_sampler_types, by=nameof)
    
    # Group by category
    basic_agg = filter(t -> nameof(t) in [:TimeHour, :TimeDay, :TimeMonth, :TimeYear, :TimeMean], time_sampler_types)
    anomalies = filter(t -> occursin("Anomaly", string(nameof(t))), time_sampler_types)
    climatological = filter(t -> nameof(t) in [:TimeDayMSC, :TimeMonthMSC, :TimeDayIAV, :TimeMonthIAV, :TimeHourDayMean], time_sampler_types)
    time_selection = filter(t -> nameof(t) in [:TimeAllYears, :TimeFirstYear, :TimeRandomYear, :TimeShuffleYears], time_sampler_types)
    special = filter(t -> nameof(t) in [:TimeArray, :TimeSizedArray, :TimeIndexed, :TimeDiff, :TimeNoDiff], time_sampler_types)
    
    # Basic Aggregation
    if !isempty(basic_agg)
        write(io, "## Basic Aggregation\n\n")
        for typ in basic_agg
            write(io, "```@docs\n")
            write(io, "$(nameof(typ))\n")
            write(io, "```\n\n")
            write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
            write(io, "\n\n")
        end
    end
    
    # Anomalies
    if !isempty(anomalies)
        write(io, "## Anomalies\n\n")
        for typ in anomalies
            write(io, "```@docs\n")
            write(io, "$(nameof(typ))\n")
            write(io, "```\n\n")
            write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
            write(io, "\n\n")
        end
    end
    
    # Climatological Statistics
    if !isempty(climatological)
        write(io, "## Climatological Statistics\n\n")
        for typ in climatological
            write(io, "```@docs\n")
            write(io, "$(nameof(typ))\n")
            write(io, "```\n\n")
            write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
            write(io, "\n\n")
        end
    end
    
    # Time Selection
    if !isempty(time_selection)
        write(io, "## Time Selection\n\n")
        for typ in time_selection
            write(io, "```@docs\n")
            write(io, "$(nameof(typ))\n")
            write(io, "```\n\n")
            write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
            write(io, "\n\n")
        end
    end
    
    # Special Methods
    if !isempty(special)
        write(io, "## Special Methods\n\n")
        for typ in special
            write(io, "```@docs\n")
            write(io, "$(nameof(typ))\n")
            write(io, "```\n\n")
            write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
            write(io, "\n\n")
        end
    end
    
    write(io, "## All TimeSampler Types\n\n")
    write(io, "To list all available time sampler types and their purposes:\n\n")
    write(io, "```julia\n")
    write(io, "using TimeSamplers\n")
    write(io, "using OmniTools: show_methods_of\n\n")
    write(io, "# Display all time sampler types\n")
    write(io, "show_methods_of(TimeSampler)\n")
    write(io, "```\n")
end

println("Generated types documentation at: $types_path")
