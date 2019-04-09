using Documenter, GMT

makedocs(
    modules = [GMT],
    format = :html,
    #format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "GMT",
    assets = ["assets/custom.css"],
    pages = Any[
        "Introduction"             => "usage.md",
        "Some examples"            => "examples.md",
        "Draw rectangles examples" => "rectangles.md",
        "Draw frames examples"     => "frames.md",
        "Map projections"          => "proj_examples.md",
        "Gallery"                  => [
            "AGU"                   => "gallery/tables.md",
            "Map projections"       => "gallery/mapprojs.md",
            "Historical collection" => "gallery/historic.md",
        ],
        hide("gallery/scripts_agu/colored_bars.md"),
        hide("gallery/scripts_agu/bars_3D.md"),
        hide("gallery/scripts_agu/bars3_peaks.md"),
        hide("gallery/scripts_agu/flower.md"),
        hide("gallery/scripts_agu/snake.md"),
        hide("gallery/scripts_agu/solar.md"),
        hide("gallery/scripts_agu/scatter_cart.md"),
        hide("gallery/scripts_agu/scatter_polar.md"),
        hide("gallery/scripts_agu/histo_step.md"),
        hide("gallery/historic/ex01.md"),
        hide("gallery/historic/ex02.md"),
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
            "coast.md",
            "grdcontour.md",
            "lines.md",
            "scatter.md",
            "scatter3.md",
            "solar.md",
        ],
        "The GMT types"            => "types.md",
        "Index"                    => "index.md",
    ],
)

deploydocs(
    repo   = "github.com/GenericMappingTools/GMT.jl.git",
    target = "build",
    julia = "1.0.3",
    deps   = nothing,
    make   = nothing
)