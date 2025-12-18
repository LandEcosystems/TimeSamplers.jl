using Pkg
# Ensure OmniTools is available (for CI/CD where it's not registered)
# Add it before any other operations to avoid dependency resolution issues
try
    using OmniTools
catch
    @info "OmniTools not available, adding from git..."
    Pkg.add(url = "https://github.com/LandEcosystems/OmniTools.jl.git", rev = "main")
    using OmniTools
end

using DocumenterVitepress
using Documenter
using TimeSamplers
using OmniTools: get_type_docstring, show_methods_of, purpose
using InteractiveUtils: subtypes

# Generate types.md before building docs by including the generation script
include(joinpath(@__DIR__, "gen_types_md.jl"))

makedocs(;
    sitename = "TimeSamplers.jl",
    authors = "TimeSamplers.jl Contributors",
    clean = true,
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/LandEcosystems/TimeSamplers.jl",
    ),
    remotes = nothing,
    draft = false,
    warnonly = true,
    source = "src",
    build = "build",
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/LandEcosystems/TimeSamplers.jl",
    target = joinpath(@__DIR__, "build"),
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true
)
