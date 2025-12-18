using Pkg
# Ensure OmniTools is available (for CI/CD where it's not registered)
# Check if it's already in the manifest
if !haskey(Pkg.manifest().deps, "OmniTools")
    @info "OmniTools not in manifest, adding from git..."
    # Use develop to avoid full dependency resolution
    Pkg.develop(url = "https://github.com/LandEcosystems/OmniTools.jl.git", rev = "main")
end

using Documenter
using TimeSamplers
using OmniTools: get_type_docstring, show_methods_of, purpose
using InteractiveUtils: subtypes

# Generate types.md before building docs
function generate_types_doc()
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
        # Use purpose from TimeSamplers (which extends OmniTools.purpose)
        time_sampler_purpose = (typ) -> TimeSamplers.purpose(typ)
        write(io, get_type_docstring(TimeSampler, purpose_function=time_sampler_purpose))
        write(io, "\n\n")
        
        # TimeSamplerMethod abstract type
        write(io, "## TimeSamplerMethod\n\n")
        write(io, get_type_docstring(TimeSamplerMethod, purpose_function=time_sampler_purpose))
        write(io, "\n\n")
        
        # Core types
        write(io, "## Core Types\n\n")
        write(io, "### TimeSample\n\n")
        write(io, get_type_docstring(TimeSample, purpose_function=time_sampler_purpose))
        write(io, "\n\n")
        write(io, "### TimeSampleViewInstance\n\n")
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
                write(io, "### $(nameof(typ))\n\n")
                write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
                write(io, "\n\n")
            end
        end
        
        # Anomalies
        if !isempty(anomalies)
            write(io, "## Anomalies\n\n")
            for typ in anomalies
                write(io, "### $(nameof(typ))\n\n")
                write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
                write(io, "\n\n")
            end
        end
        
        # Climatological Statistics
        if !isempty(climatological)
            write(io, "## Climatological Statistics\n\n")
            for typ in climatological
                write(io, "### $(nameof(typ))\n\n")
                write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
                write(io, "\n\n")
            end
        end
        
        # Time Selection
        if !isempty(time_selection)
            write(io, "## Time Selection\n\n")
            for typ in time_selection
                write(io, "### $(nameof(typ))\n\n")
                write(io, get_type_docstring(typ, purpose_function=time_sampler_purpose))
                write(io, "\n\n")
            end
        end
        
        # Special Methods
        if !isempty(special)
            write(io, "## Special Methods\n\n")
            for typ in special
                write(io, "### $(nameof(typ))\n\n")
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
    @info "Generated types documentation at: $types_path"
end

# Generate types documentation before building
generate_types_doc()

makedocs(
    modules = [TimeSamplers],
    sitename = "TimeSamplers.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "") == "true"),
    pages = [
        "Home" => "index.md",
        "Types" => "types.md",
        "API" => "api.md",
    ],
)

if get(ENV, "GITHUB_ACTIONS", "") == "true"
    deploydocs(
        repo = "github.com/LandEcosystems/TimeSamplers.jl",
        devbranch = "main",
        push_preview = true,
    )
end
