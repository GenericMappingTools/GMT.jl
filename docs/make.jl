using Documenter, GMT

makedocs(
    modules = [GMT],
    format = :html,
    sitename = "GMT.jl",
    pages = [
        "Home" => "index.md",
    ],
    html_prettyurls = true,
)

deploydocs(
    repo   = "github.com/GenericMappingTools/GMT.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)