__precompile__()

module GMT

using Printf

const GMTver = 6.0
const FMT = "ps"

export
	gmt, grid_type, basemap, basemap!, blockmean, blockmedian, blockmode, coast, coast!, logo, logo!,
	xy, xy!, grdcontour, grdcontour!, grdimage,
	grdimage!, grdtrack, grdview, grdview!, makecpt, histogram, histogram!, image, image!, psconvert,
	colorbar, colorbar!, rose, rose!, solar, solar!, text, text!, gmtinfo, grdinfo, surface,
	triangulate, nearneighbor, imshow, imshow!, plot, plot!, plot3d, plot3d!, splitxyz, wiggle, wiggle!,
	text_record

include("common_docs.jl")
include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_main.jl")
include("common_options.jl")
include("gmtinfo.jl")
include("blocks.jl")
include("gmtlogo.jl")
include("grdcontour.jl")
include("grdinfo.jl")
include("grdimage.jl")
include("grdtrack.jl")
include("grdview.jl")
include("imshow.jl")
include("makecpt.jl")
include("nearneighbor.jl")
include("psbasemap.jl")
include("pscoast.jl")
include("psconvert.jl")
include("pshistogram.jl")
include("psimage.jl")
include("psscale.jl")
include("psrose.jl")
include("pssolar.jl")
include("pstext.jl")
include("psxy.jl")
include("pswiggle.jl")
include("plot.jl")
include("plot3d.jl")
include("splitxyz.jl")
include("surface.jl")
include("triangulate.jl")

end # module
