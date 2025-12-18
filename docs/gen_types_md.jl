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
    write(io, "This page documents all types defined in TimeSamplers.jl, generated using [`get_type_docstring`](https://landecosystems.github.io/OmniTools.jl/dev/api/ForDocStrings/#get_type_docstring) from OmniTools.jl.\n\n")
    write(io, "```@meta\n")
    write(io, "CurrentModule = TimeSamplers\n")
    write(io, "DocTestSetup = quote\n")
    write(io, "using TimeSamplers\n")
    write(io, "using OmniTools: get_type_docstring, show_methods_of\n")
    write(io, "end\n")
    write(io, "```\n\n")
    
    # Use purpose from TimeSamplers (which extends OmniTools.purpose)
    time_sampler_purpose = (typ) -> TimeSamplers.purpose(typ)
    
    # TimeSampler abstract type
    write(io, "## TimeSampler\n\n")
    write(io, "`TimeSampler`\n\n")
    purpose_text = time_sampler_purpose(TimeSampler)
    write(io, "$(purpose_text)\n\n")
    write(io, "```\n")
    write(io, "TimeSampler <: Any\n")
    write(io, "```\n\n")
    
    # TimeSamplerMethod abstract type
    write(io, "## TimeSamplerMethod\n\n")
    write(io, "`TimeSamplerMethod`\n\n")
    purpose_text = time_sampler_purpose(TimeSamplerMethod)
    write(io, "$(purpose_text)\n\n")
    write(io, "```\n")
    write(io, "TimeSamplerMethod <: Any\n")
    write(io, "```\n\n")
    
    # Core types
    write(io, "## Core Types\n\n")
    # TimeSample
    write(io, "`TimeSample`\n\n")
    purpose_text = time_sampler_purpose(TimeSample)
    write(io, "$(purpose_text)\n\n")
    # Get hierarchy from get_type_docstring and extract it
    sample_docstr = get_type_docstring(TimeSample, purpose_function=time_sampler_purpose)
    hierarchy_match = match(r"```([^`]+)```", sample_docstr)
    if hierarchy_match !== nothing
        write(io, "```\n")
        write(io, "$(strip(hierarchy_match.captures[1]))\n")
        write(io, "```\n\n")
    end
    # TimeSampleViewInstance
    write(io, "`TimeSampleViewInstance`\n\n")
    purpose_text = time_sampler_purpose(TimeSampleViewInstance)
    write(io, "$(purpose_text)\n\n")
    instance_docstr = get_type_docstring(TimeSampleViewInstance, purpose_function=time_sampler_purpose)
    hierarchy_match = match(r"```([^`]+)```", instance_docstr)
    if hierarchy_match !== nothing
        write(io, "```\n")
        write(io, "$(strip(hierarchy_match.captures[1]))\n")
        write(io, "```\n\n")
    end
    
    # Get all TimeSamplerMethod subtypes
    time_sampler_types = subtypes(TimeSamplerMethod)
    sort!(time_sampler_types, by=nameof)
    
    # Helper function to format type docstring without redundant headings
    # Returns (formatted_docstring, hierarchy_line)
    function format_type_docstring(typ, purpose_function)
        docstr = get_type_docstring(typ, purpose_function=purpose_function)
        type_name = string(nameof(typ))
        
        # Remove the # TypeName heading and ## Type Hierarchy heading
        lines = split(docstr, '\n')
        result_lines = String[]
        skip_next_empty = false
        in_type_hierarchy = false
        hierarchy_line = nothing
        
        for line in lines
            # Skip the # TypeName heading
            if startswith(line, "# $(type_name)")
                skip_next_empty = true
                continue
            end
            
            # Skip empty lines after removed heading
            if skip_next_empty && isempty(strip(line))
                skip_next_empty = false
                continue
            end
            skip_next_empty = false
            
            # Skip the ## Type Hierarchy heading
            if startswith(line, "## Type Hierarchy")
                in_type_hierarchy = true
                continue
            end
            
            # Process the type hierarchy line (the ```TypeName <: ...``` line)
            if in_type_hierarchy
                if startswith(line, "```")
                    # Remove code block markers and keep just the content
                    hierarchy_line = replace(line, r"```+" => "")
                    hierarchy_line = strip(hierarchy_line)
                    in_type_hierarchy = false
                    continue
                elseif isempty(strip(line))
                    continue
                end
            end
            
            push!(result_lines, line)
        end
        
        return (join(result_lines, '\n'), hierarchy_line)
    end
    
    # Group by category
    basic_agg = filter(t -> nameof(t) in [:TimeHour, :TimeDay, :TimeMonth, :TimeYear, :TimeMean], time_sampler_types)
    anomalies = filter(t -> occursin("Anomaly", string(nameof(t))), time_sampler_types)
    climatological = filter(t -> nameof(t) in [:TimeDayMSC, :TimeMonthMSC, :TimeDayIAV, :TimeMonthIAV, :TimeHourDayMean], time_sampler_types)
    time_selection = filter(t -> nameof(t) in [:TimeAllYears, :TimeFirstYear, :TimeRandomYear, :TimeShuffleYears], time_sampler_types)
    special = filter(t -> nameof(t) in [:TimeArray, :TimeSizedArray, :TimeIndexed, :TimeDiff, :TimeNoDiff], time_sampler_types)
    
    # Basic Aggregation
    if !isempty(basic_agg)
        write(io, "## Basic Aggregation\n\n")
        for (idx, typ) in enumerate(basic_agg)
            type_name = string(nameof(typ))
            write(io, "`$(type_name)`\n\n")
            formatted, hierarchy = format_type_docstring(typ, time_sampler_purpose)
            write(io, formatted)
            write(io, "\n\n")
            if hierarchy !== nothing && !isempty(strip(hierarchy))
                write(io, "```\n")
                write(io, "$(hierarchy)\n")
                write(io, "```\n\n")
            end
            # Add separator between types, but not after the last one
            if idx < length(basic_agg)
                write(io, "---\n\n")
            end
        end
    end
    
    # Anomalies
    if !isempty(anomalies)
        write(io, "## Anomalies\n\n")
        for (idx, typ) in enumerate(anomalies)
            type_name = string(nameof(typ))
            write(io, "`$(type_name)`\n\n")
            formatted, hierarchy = format_type_docstring(typ, time_sampler_purpose)
            write(io, formatted)
            write(io, "\n\n")
            if hierarchy !== nothing && !isempty(strip(hierarchy))
                write(io, "```\n")
                write(io, "$(hierarchy)\n")
                write(io, "```\n\n")
            end
            # Add separator between types, but not after the last one
            if idx < length(anomalies)
                write(io, "---\n\n")
            end
        end
    end
    
    # Climatological Statistics
    if !isempty(climatological)
        write(io, "## Climatological Statistics\n\n")
        for (idx, typ) in enumerate(climatological)
            type_name = string(nameof(typ))
            write(io, "`$(type_name)`\n\n")
            formatted, hierarchy = format_type_docstring(typ, time_sampler_purpose)
            write(io, formatted)
            write(io, "\n\n")
            if hierarchy !== nothing && !isempty(strip(hierarchy))
                write(io, "```\n")
                write(io, "$(hierarchy)\n")
                write(io, "```\n\n")
            end
            # Add separator between types, but not after the last one
            if idx < length(climatological)
                write(io, "---\n\n")
            end
        end
    end
    
    # Time Selection
    if !isempty(time_selection)
        write(io, "## Time Selection\n\n")
        for (idx, typ) in enumerate(time_selection)
            type_name = string(nameof(typ))
            write(io, "`$(type_name)`\n\n")
            formatted, hierarchy = format_type_docstring(typ, time_sampler_purpose)
            write(io, formatted)
            write(io, "\n\n")
            if hierarchy !== nothing && !isempty(strip(hierarchy))
                write(io, "```\n")
                write(io, "$(hierarchy)\n")
                write(io, "```\n\n")
            end
            # Add separator between types, but not after the last one
            if idx < length(time_selection)
                write(io, "---\n\n")
            end
        end
    end
    
    # Special Methods
    if !isempty(special)
        write(io, "## Special Methods\n\n")
        for (idx, typ) in enumerate(special)
            type_name = string(nameof(typ))
            write(io, "`$(type_name)`\n\n")
            formatted, hierarchy = format_type_docstring(typ, time_sampler_purpose)
            write(io, formatted)
            write(io, "\n\n")
            if hierarchy !== nothing && !isempty(strip(hierarchy))
                write(io, "```\n")
                write(io, "$(hierarchy)\n")
                write(io, "```\n\n")
            end
            # Add separator between types, but not after the last one
            if idx < length(special)
                write(io, "---\n\n")
            end
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
