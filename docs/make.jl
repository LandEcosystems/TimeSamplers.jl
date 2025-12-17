using Documenter
using TimeSamplers

makedocs(
    modules = [TimeSamplers],
    sitename = "TimeSamplers.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "") == "true"),
    pages = [
        "Home" => "index.md",
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
