using Documenter, GMT

makedocs(
    modules = [GMT],
    format = :html,
    sitename = "GMT",
    pages = Any[
        "Introduction"             => "usage.md",
        "Some examples"            => "examples.md",
        "Draw rectangles examples" => "rectangles.md",
        "Draw frames examples"     => "frames.md",
        "Manual" => [
            "monolitic.md",
            "modules.md",
            "Common options" => [
                "axis.md",
            ],
        ],
        "The GMT types"            => "types.md",
        "Index"                    => "index.md",
    ],
    html_prettyurls = true,
)

deploydocs(
    repo   = "github.com/GenericMappingTools/GMT.jl.git",
    target = "build",
    julia = "0.7",
    deps   = nothing,
    make   = nothing
)