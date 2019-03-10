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
        "Map projections"          => "proj_examples.md",        
        "Manual" => [
            "monolitic.md",
            "modules.md",
            "Common options"       => "common_opts.md",
            "General features" => [
                "arrows_control.md",
                "color.md",
                "decorated.md",
                "symbols.md",
            ],
        ],
        "Modules manuals" => [
            "arrows.md",
            "bar.md",
            "bar3.md",
            "lines.md",
            "scatter.md",
            "scatter3.md",
            "solar.md",
        ],
        "The GMT types"            => "types.md",
        "Index"                    => "index.md",
    ],
    html_prettyurls = true,
)

deploydocs(
    repo   = "github.com/GenericMappingTools/GMT.jl.git",
    target = "build",
    julia = "1.0.3",
    deps   = nothing,
    make   = nothing
)