module GMT

using Printf, Dates, Statistics, Pkg
using Tables: Tables
using PrettyTables
#using SnoopPrecompile

struct CTRLstruct
	limits::Vector{Float64}			# To store the data limits. First 6 store: data limits. Second 6: plot limits
	figsize::Vector{Float64}		# To store the current fig size (xsize,ysize[,zsize]). Needed, for example, in hexbin
	proj_linear::Vector{Bool}		# To know if images sent to GMT need Pad
	callable::Array{Symbol}			# Modules that can be called inside other modules
	pocket_call::Vector{Any}		# To temporarily store data needed by modules sub-calls. Put in [3] for pre-calls
	pocket_B::Vector{String}		# To temporarily store opt_B grid and fill color to be reworked in psclip
	pocket_J::Vector{String}		# To temporarily store opt_J and fig size to eventualy flip directions (y + down, etc)
	pocket_R::Vector{String}		# To temporarily store opt_R
	IamInPaperMode::Vector{Bool}	# A 2 elem vec to know if we are in under-the-hood paper mode. 2nd traces if first call
	gmt_mem_bag::Vector{Ptr{Cvoid}}	# To temporarily store a GMT owned memory to be freed in gmt()
	pocket_d::Vector{Dict}			# To pass the Dict of kwargs, after consumption, to other modules.
end

struct CTRLstruct2
	first::Vector{Bool}				# Signal that we are starting a new plot (used to set params)
	points::Vector{Bool}			# If maps are using points as coordinates
	fname::Vector{String}			# Store the full name of PS being constructed
end

# Function to change data of GMT.jl and hence force a rebuild in next Julia session
force_precompile() = Sys.iswindows() ? run(`cmd /c copy /b "$(pathof(GMT))" +,, "$(pathof(GMT))"`) : run(`touch '$(pathof(GMT))'`)

# Need to know what GMT version is available or if none at all to warn users on how to install GMT.
function get_GMTver()
	out = v"0.0"
	try						# First try to find an existing GMT installation (RECOMENDED WAY)
		(get(ENV, "FORCE_INSTALL_GMT", "") != "") && error("Forcing an automatic GMT install")
		ver = readlines(`gmt --version`)[1]
		out = ((ind = findfirst('_', ver)) === nothing) ? VersionNumber(ver) : VersionNumber(ver[1:ind-1])
		(out < v"6.1") && error("Need at least GMT6.1. The one you have ($out) is not supported.")
		return out, false, "", "", "", ""
	catch err1;		println(err1)		# If not, install GMT
		ENV["INSTALL_GMT"] = "1"
		try
			depfile = joinpath(dirname(@__FILE__),"..","deps","deps.jl")	# File with shared lib names
			if isfile(depfile)
				include(depfile)		# This loads the shared libs names
				if (Sys.iswindows() && !isfile(_GMT_bindir * "\\gmt.exe"))		# If GMT was removed but depfile still exists
					Pkg.build("GMT");	include(depfile)
				end
			else
				Pkg.build("GMT");		include(depfile)
			end
			#ver = readlines(`$(joinpath("$(_GMT_bindir)", "gmt")) --version`)[1]
			ver = first(eachline(`$(joinpath("$(_GMT_bindir)", "gmt")) --version`))
			out = ((ind = findfirst('_', ver)) === nothing) ? VersionNumber(ver) : VersionNumber(ver[1:ind-1])
			return out, true, _libgmt, _libgdal, _libproj, _GMT_bindir
		catch err2;		println(err2)
			return out, false, "", "", "", ""
		end
	end
end
_GMTver, GMTbyConda, _libgmt, _libgdal, _libproj, _GMT_bindir = get_GMTver()

if (!GMTbyConda)		# In the other case (the non-existing ELSE branch) lib names already known at this point.
	_libgmt = haskey(ENV, "GMT_LIBRARY") ? ENV["GMT_LIBRARY"] : string(chop(read(`gmt --show-library`, String)))
	@static Sys.iswindows() ?
		(Sys.WORD_SIZE == 64 ? (_libgdal = "gdal_w64.dll") : (_libgdal = "gdal_w32.dll")) : (
			Sys.isapple() ? (_libgdal = string(split(readlines(pipeline(`otool -L $(_libgmt)`, `grep libgdal`))[1])[1])) : (
				Sys.isunix() ? (_libgdal = string(split(readlines(pipeline(`ldd $(_libgmt)`, `grep libgdal`))[1])[3])) :
				error("Don't know how to install this package in this OS.")
			)
		)
	@static Sys.iswindows() ?
		(Sys.WORD_SIZE == 64 ? (_libproj = "proj_w64.dll") : (_libproj = "proj_w32.dll")) : (
			Sys.isapple() ? (_libproj = string(split(readlines(pipeline(`otool -L $(_libgdal)`, `grep libproj`))[1])[1])) : (
				Sys.isunix() ? (_libproj = string(split(readlines(pipeline(`ldd $(_libgdal)`, `grep libproj`))[1])[3])) :
				error("Don't know how to use PROJ4 in this OS.")
			)
		)
end
const GMTver, libgmt, libgdal, libproj, GMT_bindir = _GMTver, _libgmt, _libgdal, _libproj, _GMT_bindir

const global G_API = [C_NULL]
const global PSname = [joinpath(tempdir(), "GMTjl_tmp.ps")]		# The PS file where, in classic mode, all lands.
const global img_mem_layout = [""]			# "TCP"	 For Images.jl. The default is "TRBa"
const global grd_mem_layout = [""]			# "BRP" is the default for GMT PS images.
const global current_view   = [""]			# To store the current viewpoint (-p)
const global multi_col   = Vector{Bool}(undef, 1);multi_col[1] = false	# To allow plottig multiple columns at once.
const global IamModern   = Vector{Bool}(undef, 1);IamModern[1] = false		# To know if we are in modern mode
const global FirstModern = Vector{Bool}(undef, 1);FirstModern[1] = false	# To know
const global IamModernBySubplot = Vector{Bool}(undef, 1);	IamModernBySubplot[1] = false	# To know if set in subpot
const global IamSubplot  = Vector{Bool}(undef, 1);IamSubplot[1]  = false	# To know if we are in subplot mode
const global IamInset    = Vector{Bool}(undef, 1);IamInset[1]    = false	# To know if we are in Inset mode
const global usedConfPar = Vector{Bool}(undef, 1);usedConfPar[1] = false	# Hacky solution for the session's memory trouble
const global ThemeIsOn   = Vector{Bool}(undef, 1);ThemeIsOn[1] = false		# To know if we have an active plot theme
const global convert_syntax = Vector{Bool}(undef, 1);convert_syntax[1] = false	# To only convert to hard core GMT syntax (like Vd=2)
const global show_kwargs = Vector{Bool}(undef, 1);show_kwargs[1] = false	# To just print the kwargs of a option call)
const global isFranklin  = Vector{Bool}(undef, 1);isFranklin[1] = false		# Only set/unset by the Docs building scripts.
const global FMT = ["png"]                         # The default plot format
const global box_str = [""]                        # Used in plotyy to know -R of first call
const def_fig_size  = "14c/9.5c"                   # Default fig size for plot like programs. Approx 16/11
const def_fig_axes_bak     = " -Baf -BWSen"        # Default fig axes for plot like programs
const def_fig_axes3_bak    = " -Baf -Bza"          # 		"" but for 3D views
const global def_fig_axes  = [def_fig_axes_bak]    # This one may be be changed by theme()
const global def_fig_axes3 = [def_fig_axes3_bak]   #		""
const global CTRL = CTRLstruct(zeros(12), zeros(3), [true],
                               [:arrows, :bublechart, :basemap, :band, :clip, :coast, :colorbar, :hband, :hlines, :logo, :lines, :grdvector, :plot, :plot3, :quiver, :scatter, :scatter3, :stairs, :text, :vlines, :vband],
							   [nothing, nothing, nothing], ["",""], ["","", "", "   "], [""], [false,true], [C_NULL], [Dict()])
const global CTRLshapes = CTRLstruct2([true], [true], [""])			# Used in sub-module Drawing
const prj4WGS84 = "+proj=longlat +datum=WGS84 +units=m +no_defs"	# This is used in many places
const CPTaliases = [:C :color :cmap :colormap :colorscale]
const global VMs = Union{Nothing, Vector{Symbol}, Matrix{Symbol}}
const global VMr = Union{AbstractVector{<:Real}, Matrix{<:Real}}
const global StrSymb  = Union{AbstractString, Symbol}
const global GMTuserdir  = [readlines(`$(joinpath("$(GMT_bindir)", "gmt")) --show-userdir`)[1]]
# GItype = Union{GMTgrid, GMTimage} and GDtype = Union{GMTdataset, Vector{GMTdataset}} are edeclared in gmt_main
#const global unused_opts = [()]					# To track consumed options
#const global unused_subopts = [()]					# To track consumed options in sub-options

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
	@eval Base.Experimental.@optlevel 1
end

export
	GMTgrid, GMTimage, GMTdataset, GMTver, FMT, gmt, libgdal,
	arrows, arrows!, bar, bar!, bar3, bar3!, band, band!, bubblechart, bubblechart!, feather, feather!, hband, hband!,
	hlines, hlines!, lines, lines!, legend, legend!, quiver, quiver!, radar, radar!, stairs, stairs!, stem, stem!,vlines,
	vlines!, vband, vband!, hspan, hspan!, vspan, vspan!,
	basemap, basemap!, blockmean, blockmedian, blockmode, clip, clip!,
	coast, coast!, colorbar, colorbar!, colorscale, colorscale!, contour, contour!, contourf, contourf!, events,
	filter1d, fitcircle, gmt2kml, gmtbinstats, binstats,
	gmtconnect, gmtconvert, gmtinfo, gmtmath, gmtregress, gmtread, gmtselect, gmtset, gmtsimplify, gmtspatial,
	gmtvector, gmtwrite, gmtwhich, grd2cpt, grd2kml, grd2xyz, grdblend, grdclip, grdcontour, grdcontour!, grdconvert,
	grdcut, grdedit, grdfft, grdfill, grdfilter, grdgradient, grdhisteq, grdimage, grdimage!, grdinfo, grdinterpolate,
	grdlandmask, grdmath, grdmask, grdpaste, grdproject, grdsample, grdtrack, grdtrend, grdvector, grdvector!,
	grdview, grdview!, grdvolume, greenspline, histogram, histogram!, image, image!, image_alpha!, image_cpt!,
	imshow, ind2rgb, isnodata, kml2gmt, logo, logo!, makecpt, mask, mask!, mapproject, movie, nearneighbor, plot, plot!,
	plot3, plot3!, plot3d, plot3d!, plotyy, project, pscontour, pscontour!, psconvert, psbasemap, psbasemap!,
	psclip, psclip!, pscoast, pscoast!, psevents, pshistogram, pshistogram!,
	psimage, psimage!, pslegend, pslegend!, psmask, psmask!, psrose, psrose!, psscale, psscale!, pssolar, pssolar!,
	psternary, psternary!, pstext, pstext!, pswiggle, pswiggle!, psxy, psxy!, psxyz, psxyz!, regress, resetGMT, rose,
	rose!, sample1d, scatter, scatter!, scatter3, scatter3!, solar, solar!, spectrum1d, sphdistance, sphinterpolate,
	sphtriangulate, surface, ternary, ternary!, text, text!, text_record, trend1d, trend2d, triangulate, gmtsplit,
	decorated, vector_attrib, wiggle, wiggle!, xyz2grd, gmtbegin, gmtend, gmthelp, subplot, gmtfig, inset, showfig,
	earthtide, gravfft, gmtgravmag3d, grdgravmag3d, pscoupe, pscoupe!, coupe, coupe!, psmeca, psmeca!, meca, meca!,
	psvelo, psvelo!, velo, velo!, getbyattrib, inwhichpolygon, pcolor, pcolor!, triplot, triplot!,
	grdrotater, imagesc,

	mbimport, mbgetdata, mbsvplist, mblevitus,

	blendimg!, lonlat2xy, xy2lonlat, mat2ds, mat2grid, mat2img, slicecube, cubeslice, linspace, logspace, fields,
	tic, toc, theme, tern2cart, geodetic2enu, cpt4dcw, gd2gmt, gmt2gd, gdalread, gdalshade, gdalwrite, gadm, xyzw2cube,

	magic, rescale, stackgrids, delrows!, setgrdminmax!, meshgrid, cart2pol, pol2cat, cart2sph, sph2cart,

	arcellipse, arccircle, getband, getdriver, getlayer, getproj, getgeom, getgeotransform, toPROJ4, toWKT,
	importPROJ4, importWKT, importEPSG, gdalinfo, gdalwarp, gdaldem, gdaltranslate, gdalgrid, gdalvectortranslate,
	ogr2ogr, gdalrasterize, gdalbuildvrt, readraster, setgeotransform!, setproj!, destroy,
	delaunay, dither, buffer, centroid, intersection, intersects, polyunion, fromWKT,
	concavehull, convexhull, difference, symdifference, distance, geomarea, pointalongline, polygonize, simplify,
	wkbUnknown, wkbPoint, wkbLineString, wkbPolygon, wkbMultiPoint, wkbMultiLineString, wkbMultiPolygon,
	wkbGeometryCollection,

	buffergeo, circgeo, epsg2proj, epsg2wkt, geod, invgeod, loxodrome, loxodrome_direct, loxodrome_inverse,
	geodesic, orthodrome, proj2wkt, wkt2proj,

	colorzones!, rasterzones!, crop, doy2date, date2doy, yeardecimal, median, mean, quantile, std, nanmean,
	nanstd, skipnan,

	add2PSfile, append2fig, regiongeog, streamlines, wmsinfo, wmstest, wmsread, polygonlevels,

	density, density!, boxplot, boxplot!, ecdfplot, ecdfplot!, parallelplot, parallelplot!, qqplot, qqplot!,
	qqnorm, qqnorm!, violin, violin!, cornerplot, cornerplot!

include("common_docs.jl")
include("libgmt_h.jl")
(GMTver >= v"6") && include("libgmt.jl")
include("gmt_main.jl")
include("utils_types.jl")
include("grd_operations.jl")
include("common_options.jl")
include("gmtbegin.jl")
include("blendimg.jl")
include("blocks.jl")
include("contourf.jl")
include("filter1d.jl")
include("fitcircle.jl")
include("gadm.jl")
include("gmt2kml.jl")
include("gmtbinstats.jl")
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
include("grdconvert.jl")
include("grdfft.jl")
include("grdfill.jl")
include("grdfilter.jl")
include("grdgmtmath.jl")
include("grdhisteq.jl")
include("grdimage.jl")
include("grdinfo.jl")
include("grdinterpolate.jl")
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
include("kml2gmt.jl")
include("loxodromics.jl")
include("makecpt.jl")
include("mapproject.jl")
include("movie.jl")
include("nearneighbor.jl")
include("pcolor.jl")
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
include("rasterpolygonfuns.jl")
include("sample1d.jl")
include("spectrum1d.jl")
include("sphdistance.jl")
include("sphinterpolate.jl")
include("sphtriangulate.jl")
include("splitxyz.jl")
include("streamlines.jl")
include("surface.jl")
include("subplot.jl")
include("show_pretty_datasets.jl")
include("statplots.jl")
include("tables_gmt.jl")
include("themes.jl")
include("triangulate.jl")
include("trend1d.jl")
include("trend2d.jl")
include("xyz2grd.jl")
include("utils.jl")
include("utils_project.jl")
include("choropleth_utils.jl")
include("webmapserver.jl")
include("seis/psmeca.jl")
include("geodesy/psvelo.jl")
include("geodesy/earthtide.jl")
include("MB/mbimport.jl")
include("MB/mbgetdata.jl")
include("MB/mbsvplist.jl")
include("MB/mblevitus.jl")
if (GMTver > v"6.1.1")
	include("potential/gmtgravmag3d.jl")
	include("potential/grdgravmag3d.jl")
	include("potential/gravfft.jl")
end
include("spotter/grdrotater.jl")
include("drawing.jl")

if (GMTver >= v"6")			# Needed to cheat the autoregister autobot
	include("get_enums.jl")
	include("gdal.jl")
	include("gdal_utils.jl")
	include("proj_utils.jl")
	using GMT.Gdal
end
include("imshow.jl")		# Include later because one method depends on knowing about GDAL

const global current_cpt = [GMTcpt()]		# To store the current palette
const global legend_type = [legend_bag()]	# To store Legends info

#=
import SnoopPrecompile
@SnoopPrecompile.precompile_all_calls begin
	G_API[1] = GMT_Create_Session("GMT", 2, GMT_SESSION_BITFLAGS)
	plot(rand(5,2))
	makecpt(T=(0,10))
	grdimage(rand(Float32,32,32))
end
=#

function __init__(test::Bool=false)
	if (GMTver == v"0.0" || test)
		println("\n\nYou don't seem to have GMT installed and the automatic installation also failed.\nYou will have to do it yourself.")
		t = Sys.iswindows() ? "Download and install the official version at (the '..._win64.exe':" *
		                      "\n\t\t https://github.com/GenericMappingTools/gmt/releases" : (
		                      Sys.isapple() ? "Install GMT with Homebrew: brew install gmt ghostscript ffmpeg" :
		                      "https://github.com/GenericMappingTools/gmt/blob/master/INSTALL.md#linux")
		println(t)
		return
	end

	if !isfile(libgmt) || ( !Sys.iswindows() && (!isfile(libgdal) || !isfile(libproj)) )
		println("\nDetected a previously working GMT.jl version but something has broken meanwhile.\n" *
		"(like updating your GMT instalation). Run this command in REPL and restart Julia.\n\n\t\tGMT.force_precompile()\n")
		return
	end

	clear_sessions(3600)		# Delete stray sessions dirs older than 1 hour
	G_API[1] = GMT_Create_Session("GMT", 2, GMT_SESSION_BITFLAGS)	# (0.010179 sec)
	(GMTver >= v"6.2.0") && theme_modern()			# Set the MODERN theme and some more gmtlib_setparameter() calls
	haskey(ENV, "JULIA_GMT_IMGFORMAT") && (FMT[1] = ENV["JULIA_GMT_IMGFORMAT"])
	f = joinpath(GMTuserdir[1], "theme_jl.txt")
	(isfile(f)) && (theme(readline(f));	ThemeIsOn[1] = false)	# False because we don't want it reset in showfig()
	(GMTver < v"6.2.0") && extra_sets()		# some calls to gmtlib_setparameter() (theme_modern already called this)
end

include("precompile_GMT_i.jl")
_precompile_()

"""
GMT manipulating geographic and Cartesian data sets (including filtering, trend fitting, gridding, projecting, etc.)
and producing high quality illustrations.

Full modules list and docs in terse GMT style at $(GMTdoc)

Documentation for GMT.jl at https://www.generic-mapping-tools.org/GMT.jl/latest/
"""
GMT

end # module
