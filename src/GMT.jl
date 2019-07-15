module GMT

using Printf

# Need to know what GMT version is available or if none at all to warn users on how to
# install GMT.
try
	#write("gmtversion__.txt", read(`gmt --version`))
	#global const GMTver = Meta.parse(read("gmtversion__.txt", String)[1:3])
	#rm("gmtversion__.txt")
	global const GMTver = Meta.parse(readlines(`gmt --version`)[1][1:3])
	global foundGMT = true
catch
	global foundGMT = false
	global const GMTver = 5.0
end

global legend_type = nothing
global img_mem_layout = ""			# "TCP"	 For Images.jl. The default is "TRBa"
global grd_mem_layout = ""			# "BRP" is the default for GMT PS images.
global current_cpt  = nothing		# To store the current palette
global current_view = nothing		# To store the current viewpoint (-p)
global multi_col    = false			# To allow plottig multiple columns at once
global IamModern    = false			# To know if we are in modern mode
global IamSubplot   = false			# To know if we are in subplot mode
global usedConfPar  = false			# Hacky solution for the session's memory trouble
const FMT = "ps"
const def_fig_size  = "12c/8c"              # Default fig size for plot like programs
const def_fig_axes  = " -Baf -BWSen"        # Default fig axes for plot like programs
const def_fig_axes3 = " -Baf -Bza -BWSenZ"  #		"" but for 3D views

export
	GMTver, FMT, gmt,
	arrows, arrows!, bar, bar!, bar3, bar3!, lines, lines!, legend, legend!,
	basemap, basemap!, blockmean, blockmedian, blockmode, clip, clip!, coast, coast!, colorbar, colorbar!,
	contour, contour!, filter1d, fitcircle, gmt2kml,  gmtconnect, gmtconvert, gmtinfo, gmtregress, 
	gmtread, gmtselect, gmtset, gmtsimplify, gmtspatial, gmtvector, gmtwrite, gmtwhich, 
	grd2cpt, grd2kml, grd2xyz, grdblend, grdclip, grdcontour, grdcontour!, grdcut, grdedit, grdfft,
	grdfilter, grdgradient, grdhisteq, grdimage, grdimage!, grdinfo, grdlandmask, grdpaste, grdproject,
	grdsample, grdtrack, grdtrend, grdvector, grdvector!, grdview, grdview!, grdvolume, greenspline,
	mat2ds, mat2grid, mat2img, histogram, histogram!, image, image!, imshow, kml2gmt, logo, logo!,
	makecpt, mask, mask!, mapproject, nearneighbor, plot, plot!, plot3d, plot3d!, project,
	pscontour, pscontour!, psconvert, psbasemap, psbasemap!, psclip, psclip!, pscoast, pscoast!, 
	pshistogram, pshistogram!, psimage, psimage!, psmask, psmask!, psrose, psrose!, psscale, psscale!, 
	pssolar, pssolar!, psternary, psternary!, pstext, pstext!, pswiggle, pswiggle!, psxy, psxy!, psxyz, 
	psxyz!, regress, rose, rose!, sample1d, scatter, scatter!, scatter3, scatter3!, solar, solar!, spectrum1d,
	sphdistance, sphinterpolate, sphtriangulate, surface, ternary, ternary!,
	text, text!, text_record, trend1d, trend2d, triangulate, splitxyz,
	decorated, vector_attrib, wiggle, wiggle!, xyz2grd,
	gmtbegin, gmtend, subplot, gmtfig, inset,
	linspace, logspace, contains, fields, tic, toc

include("common_docs.jl")
include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_main.jl")
include("common_options.jl")
include("gmtbegin.jl")
include("blocks.jl")
include("filter1d.jl")
include("fitcircle.jl")
include("gmt2kml.jl")
include("gmtconnect.jl")
include("gmtconvert.jl")
include("gmtinfo.jl")
include("gmtlogo.jl")
include("gmtreadwrite.jl")
include("gmtset.jl")
include("gmtselect.jl")
include("gmtsimplify.jl")
include("gmtspatial.jl")
include("gmtregress.jl")
include("gmtvector.jl")
include("gmtwich.jl")
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
include("greenspline.jl")
include("grdtrack.jl")
include("grdtrend.jl")
include("grdvector.jl")
include("grdview.jl")
include("grdvolume.jl")
include("imshow.jl")
include("kml2gmt.jl")
include("makecpt.jl")
include("mapproject.jl")
include("nearneighbor.jl")
include("plot.jl")
include("project.jl")
include("psbasemap.jl")
include("psclip.jl")
include("pscoast.jl")
include("pscontour.jl")
include("psconvert.jl")
include("pshistogram.jl")
include("psimage.jl")
include("pslegend.jl")
include("psmask.jl")
include("psscale.jl")
include("psrose.jl")
include("pssolar.jl")
include("pstext.jl")
include("psxy.jl")
include("pswiggle.jl")
include("sample1d.jl")
include("spectrum1d.jl")
include("sphdistance.jl")
include("sphinterpolate.jl")
include("sphtriangulate.jl")
include("splitxyz.jl")
include("surface.jl")
include("subplot.jl")
include("triangulate.jl")
include("trend1d.jl")
include("trend2d.jl")
include("xyz2grd.jl")

if (!foundGMT)
	println("\n\nYou don't seem to have GMT installed and I don't currently install it automatically,")
	println("so you will have to do it yourself. Please follow instructions bellow but please note")
	println("that since GMT is migrating to Github (https://github.com/GenericMappingTools/gmt),")
	println("some of the links may change in a near future.\n\n")
	if (Sys.iswindows() && Sys.WORD_SIZE == 64)
		println("1) Download and install the official version at (the '..._win64.exe':")
		println("\t\t https://gmt.soest.hawaii.edu/projects/gmt/wiki/Download")
		println("\n2) Or even better, download and install the GMT6dev version at:")
		println("\t\t http://w3.ualg.pt/~jluis/downloads/gmt.html")
	elseif (Sys.iswindows() && Sys.WORD_SIZE == 32)
		println("Download and install the official version at (the '..._win32.exe':")
		println("\t\t https://gmt.soest.hawaii.edu/projects/gmt/wiki/Download")
	else
		println("https://gmt.soest.hawaii.edu/projects/gmt/wiki/BuildingGMT")
	end
end

end # module
