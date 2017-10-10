using Documenter, GMT

makedocs(
    modules = [GMT],
    format = :html,
    sitename = "GMT",
    pages = [
        "Home" => "index.md",
        "Some examples" => "examples.md",
        "Index" => "functionindex.md"
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