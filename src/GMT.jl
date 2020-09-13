module GMT

using Printf
using Dates

# Need to know what GMT version is available or if none at all to warn users on how to install GMT.
try
	#global const GMTver = Meta.parse(readlines(`gmt --version`)[1][1:3])
	v =split(readlines(`gmt --version`)[1][1:5],'.')
	global const GMTver = Meta.parse(v[1] * '.' * v[2]) + (Meta.parse(v[3]) * 0.01)
catch
	global const GMTver = 0.0
end

global legend_type  = nothing
global current_cpt  = nothing		# To store the current palette
const global img_mem_layout = [""]			# "TCP"	 For Images.jl. The default is "TRBa"
const global grd_mem_layout = [""]			# "BRP" is the default for GMT PS images.
const global current_view   = [""]			# To store the current viewpoint (-p)
const global multi_col   = Array{Bool,1}(undef,1)		# To allow plottig multiple columns at once (init to false)
const global IamModern   = Array{Bool,1}(undef,1)		# To know if we are in modern mode
const global FirstModern = Array{Bool,1}(undef,1)		# To know 
const global IamSubplot  = Array{Bool,1}(undef,1)		# To know if we are in subplot mode
const global usedConfPar = Array{Bool,1}(undef,1)		# Hacky solution for the session's memory trouble
const global convert_syntax = Array{Bool,1}(undef,1);convert_syntax[1] = false	# To only convert to hard core GMT syntax (like Vd=2)
const global FMT = ["ps"]
const def_fig_size  = "12c/8c"              # Default fig size for plot like programs
const def_fig_axes  = " -Baf -BWSen"        # Default fig axes for plot like programs
const def_fig_axes3 = " -Baf -Bza"  		#		"" but for 3D views

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

export
	GMTver, FMT, gmt,
	arrows, arrows!, bar, bar!, bar3, bar3!, hlines, hlines!, lines, lines!, legend, legend!, vlines, vlines!,
	basemap, basemap!, blockmean, blockmedian, blockmode, clip, clip!, coast, coast!, colorbar, colorbar!,
	colorscale, colorscale!, contour, contour!, contourf, contourf!, events, filter1d, fitcircle, gmt2kml,
	gmtconnect, gmtconvert, gmtinfo, gmtmath, gmtregress, gmtread, gmtselect, gmtset, gmtsimplify, gmtspatial,
	gmtvector, gmtwrite, gmtwhich, grd2cpt, grd2kml, grd2xyz, grdblend, grdclip, grdcontour, grdcontour!, grdcut,
	grdedit, grdfft, grdfilter, grdgradient, grdhisteq, grdimage, grdimage!, grdinfo, grdfill, grdlandmask, grdmath,
	grdmask, grdpaste, grdproject, grdsample, grdtrack, grdtrend, grdvector, grdvector!, grdview, grdview!, grdvolume,
	greenspline, mat2grid, mat2img, histogram, histogram!, image, image!, image_alpha!, imshow, kml2gmt, logo, logo!,
	makecpt, mask, mask!, mapproject, movie, nearneighbor, plot, plot!, plot3, plot3!, plot3d, plot3d!, project, pscontour,
	pscontour!, psconvert, psbasemap, psbasemap!, psclip, psclip!, pscoast, pscoast!, psevents, pshistogram, pshistogram!,
	psimage, psimage!, pslegend, pslegend!, psmask, psmask!, psrose, psrose!, psscale, psscale!, pssolar, pssolar!,
	psternary, psternary!, pstext, pstext!, pswiggle, pswiggle!, psxy, psxy!, psxyz, psxyz!, regress, resetGMT, rose,
	rose!, sample1d, scatter, scatter!, scatter3, scatter3!, solar, solar!, spectrum1d, sphdistance, sphinterpolate,
	sphtriangulate, surface, ternary, ternary!, text, text!, text_record, trend1d, trend2d, triangulate, splitxyz,
	decorated, vector_attrib, wiggle, wiggle!, xyz2grd, gmtbegin, gmtend, subplot, gmtfig, inset, showfig,
	image_alpha!, mat2ds, mat2grid, mat2img, linspace, logspace, contains, fields, tic, toc

include("common_docs.jl")
include("libgmt_h.jl")
if (GMTver >= 6)
	include("libgmt.jl")
end
include("gmt_main.jl")
include("common_options.jl")
include("gmtbegin.jl")
include("blocks.jl")
include("contourf.jl")
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
include("grdfill.jl")
include("grdfilter.jl")
include("grdgmtmath.jl")
include("grdhisteq.jl")
include("grdinfo.jl")
include("grdimage.jl")
include("grdgradient.jl")
include("grdlandmask.jl")
include("grdmask.jl")
include("grdpaste.jl")
include("grdproject.jl")
include("grdsample.jl")
include("grdtrack.jl")
include("grdtrend.jl")
include("grdvector.jl")
include("grdview.jl")
include("grdvolume.jl")
include("greenspline.jl")
include("imshow.jl")
include("kml2gmt.jl")
include("makecpt.jl")
include("mapproject.jl")
include("movie.jl")
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

function __init__()
	if (GMTver == 0.0)
		println("\n\nYou don't seem to have GMT installed and I don't currently install it automatically,")
		println("so you will have to do it yourself. Please follow instructions bellow.")
		if (Sys.iswindows() && Sys.WORD_SIZE == 64)
			println("1) Download and install the official version at (the '..._win64.exe':")
			println("\t\t https://github.com/GenericMappingTools/gmt/releases")
		elseif (Sys.iswindows() && Sys.WORD_SIZE == 32)
			println("Download and install the official version at (the '..._win32.exe':")
			println("\t\t https://github.com/GenericMappingTools/gmt/releases")
		else
			println("https://github.com/GenericMappingTools/gmt/blob/master/INSTALL.md")
		end
		return
	elseif (5 <= GMTver < 6.0)
		println("\n\tGMT version 5 is no longer supported (support ended at 0.23). Must uptdate.")
		return
	end
	clear_sessions(3600)		# Delete stray sessions dirs older than 1 hour
	global API = GMT_Create_Session("GMT", 2, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_COLMAJOR)
	if (API == C_NULL)  error("Failure to create a GMT Session")  end
	try
		FMT[1] = ENV["JULIA_GMT_IMGFORMAT"]
	catch
	end
end

include("get_enums.jl")

include("precompile_GMT_i.jl")
_precompile_()

end # module
