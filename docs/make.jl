using Documenter, GMT

makedocs(
    modules = [GMT],
    format = :html,
    sitename = "GMT.jl",
    pages = [
        "Home" => "index.md",
        "A few examples" => "examples.md"
    ],
    html_prettyurls = true,
)

deploydocs(
    repo   = "github.com/GenericMappingTools/GMT.jl.git",
    target = "build",
    julia = "0.6",
    deps   = nothing,
    make   = nothing
)