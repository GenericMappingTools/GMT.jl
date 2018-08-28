#__precompile__()

module GMT

using Printf

# Need to have this function here so that one can automatically detect the GMT version available. Similar
# functions in libgmt.jl cannot be called yet (due to convoluted interdependencies)
function GMT_Get_Version_()
	#@static Sys.iswindows() ? (Sys.WORD_SIZE == 64 ? (thelib = "gmt_w64") : (thelib = "gmt_w32")) : (thelib = "libgmt")
	#ver = ccall((:GMT_Get_Version, "gmt_w64"), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, C_NULL, C_NULL, C_NULL)
	if (Sys.iswindows())
		if (Sys.WORD_SIZE == 64)
			ver = ccall((:GMT_Get_Version, "gmt_w64"), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, C_NULL, C_NULL, C_NULL)
		else
			ver = ccall((:GMT_Get_Version, "gmt_w32"), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, C_NULL, C_NULL, C_NULL)
		end
	else
		ver = ccall((:GMT_Get_Version, "libgmt"), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, C_NULL, C_NULL, C_NULL)
	end
end

# Shit, the try is not "strong enough" to catch the case where the function does not exist
# Wrapp it in a try catch because GMT_Get_version() does not exist in GMT5
try
	global const GMTver = GMT_Get_Version_()
catch
	global const GMTver = 5.0
end
#

#const GMTver = 6.0
const FMT = "ps"

export
	GMTver, FMT, gmt,
	basemap, basemap!, blockmean, blockmedian, blockmode, coast, coast!, colorbar, colorbar!, filter1d,
	filter2d, fitcircle, gmtinfo, gmtregress, gmtread, gmtselect, gmtsimplify, gmtspatial, gmtvector,
	gmtwrite, gmtwich, grd2cpt, grd2kml, grd2xyz, grdblend, grdclip, grdcontour, grdcontour!, grdcut, grdedit,
	grdfft, grdfilter, grdgradient, grdhisteq, grdimage, grdimage!, grdinfo, grdlandmask, grdpaste,
	grdproject, grdsample, grdtrack, grdtrend, grdview, grdview!, grdvolume, grid_type, histogram,
	histogram!, image, image!, imshow, imshow!, logo, logo!, makecpt, nearneighbor, plot, plot!,
	plot3d, plot3d!, project, psconvert, rose, rose!, sample1d, solar, solar!, spectrum1d,
	sphdistance, sphinterpolate, sphtriangulate, surface, text, text!, text_record, trend1d, trend2d,
	triangulate, splitxyz, wiggle, wiggle!, xy, xy!, xyz2grd

include("common_docs.jl")
include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_main.jl")
include("common_options.jl")
include("blocks.jl")
include("filter1d.jl")
include("fitcircle.jl")
include("gmtinfo.jl")
include("gmtlogo.jl")
include("gmtreadwrite.jl")
include("gmtset.jl")
include("gmtselect.jl")
include("gmtsimplify.jl")
include("gmtspatial.jl")
include("gmtregress.jl")
include("gmtvector.jl")
include("grd2cpt.jl")
include("grd2kml.jl")
include("grd2xyz.jl")
include("grdblend.jl")
include("grdclip.jl")
include("grdcut.jl")
include("grdedit.jl")
include("grdcontour.jl")
include("grdfft.jl")
include("grdfilter.jl")
include("grdhisteq.jl")
include("grdinfo.jl")
include("grdimage.jl")
include("grdgradient.jl")
include("grdlandmask.jl")
include("grdpaste.jl")
include("grdproject.jl")
include("grdsample.jl")
include("grdtrack.jl")
include("grdtrend.jl")
include("grdview.jl")
include("grdvolume.jl")
include("imshow.jl")
include("makecpt.jl")
include("nearneighbor.jl")
include("project.jl")
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
include("sample1d.jl")
include("spectrum1d.jl")
include("sphdistance.jl")
include("sphinterpolate.jl")
include("sphtriangulate.jl")
include("splitxyz.jl")
include("surface.jl")
include("triangulate.jl")
include("trend1d.jl")
include("trend2d.jl")
include("xyz2grd.jl")

end # module
