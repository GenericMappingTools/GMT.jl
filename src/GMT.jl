module GMT

using Printf, Dates, Statistics, Pkg

struct CTRLstruct
	limits::Vector{Float64}
	proj_linear::Vector{Bool}		# To know if images sent to GMT need Pad
	callable::Array{Symbol}			# Modules that can be called inside other modules
	pocket_call::Vector{Any}		# To temporarilly store data needed by modules sub-calls
	pocket_B::Vector{String}		# To temporarilly store opt_B grid and fill color to be reworked in psclip
	gmt_mem_bag::Vector{Ptr{Cvoid}}	# To temporarilly store a GMT owned memory to be freed in gmt()
end

struct CTRLstruct2
	first::Vector{Bool}				# Signal that we are starting a new plot (used to set params)
	points::Vector{Bool}			# If maps are using points as coordinates
	fname::Vector{String}			# Store the full name of PS being constructed
end

# Need to know what GMT version is available or if none at all to warn users on how to install GMT.
function get_GMTver()
	out = v"0.0"
	try						# First try to find an existing GMT installation (RECOMENDED WAY)
		(get(ENV, "FORCE_INSTALL_GMT", "") != "") && error("Forcing an automatic GMT install")
		ver = readlines(`gmt --version`)[1]
		out = ((ind = findfirst('_', ver)) === nothing) ? VersionNumber(ver) : VersionNumber(ver[1:ind-1])
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
			ver = readlines(`$(joinpath("$(_GMT_bindir)", "gmt")) --version`)[1]
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

global legend_type  = nothing
const global img_mem_layout = [""]			# "TCP"	 For Images.jl. The default is "TRBa"
const global grd_mem_layout = [""]			# "BRP" is the default for GMT PS images.
const global current_view   = [""]			# To store the current viewpoint (-p)
const global multi_col   = Vector{Bool}(undef, 1);multi_col[1] = false	# To allow plottig multiple columns at once (init to false)
const global IamModern   = Vector{Bool}(undef, 1);IamModern[1] = false		# To know if we are in modern mode
const global FirstModern = Vector{Bool}(undef, 1);FirstModern[1] = false	# To know 
const global IamSubplot  = Vector{Bool}(undef, 1);IamSubplot[1]  = false	# To know if we are in subplot mode
const global usedConfPar = Vector{Bool}(undef, 1);usedConfPar[1] = false	# Hacky solution for the session's memory trouble
const global ThemeIsOn   = Vector{Bool}(undef, 1);ThemeIsOn[1] = false	# To know if we have an active plot theme
const global convert_syntax = Vector{Bool}(undef, 1);convert_syntax[1] = false	# To only convert to hard core GMT syntax (like Vd=2)
const global show_kwargs = Vector{Bool}(undef, 1);show_kwargs[1] = false	# To just print the kwargs of a option call)
const global FMT = ["ps"]
const global box_str = [""]
const def_fig_size  = "14c/9.5c"            # Default fig size for plot like programs. Approx 16/11
const def_fig_axes  = " -Baf -BWSen"        # Default fig axes for plot like programs
const def_fig_axes3 = " -Baf -Bza"  		#		"" but for 3D views
const global CTRL = CTRLstruct(zeros(6), [true], [:clip, :coast, :colorbar, :basemap, :logo, :text, :arrows, :lines, :scatter, :scatter3, :plot, :plot3, :hlines, :vlines], [nothing], ["",""], [C_NULL])
const global CTRLshapes = CTRLstruct2([true], [true], [""])

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
	@eval Base.Experimental.@optlevel 1
end

export
	GMTver, FMT, gmt, libgdal,
	arrows, arrows!, bar, bar!, bar3, bar3!, hlines, hlines!, lines, lines!, legend, legend!, vlines, vlines!,
	basemap, basemap!, blockmean, blockmedian, blockmode, clip, clip!, coast, coast!, colorbar, colorbar!,
	colorscale, colorscale!, contour, contour!, contourf, contourf!, events, filter1d, fitcircle, gmt2kml,
	gmtconnect, gmtconvert, gmtinfo, gmtmath, gmtregress, gmtread, gmtselect, gmtset, gmtsimplify, gmtspatial,
	gmtvector, gmtwrite, gmtwhich, grd2cpt, grd2kml, grd2xyz, grdblend, grdclip, grdcontour, grdcontour!, grdcut,
	grdedit, grdfft, grdfill, grdfilter, grdgradient, grdhisteq, grdimage, grdimage!, grdinfo, grdinterpolate, grdlandmask, grdmath,
	grdmask, grdpaste, grdproject, grdsample, grdtrack, grdtrend, grdvector, grdvector!, grdview, grdview!, grdvolume,
	greenspline, mat2grid, mat2img, histogram, histogram!, image, image!, image_alpha!, image_cpt!, imshow, kml2gmt,
	logo, logo!, makecpt, mask, mask!, mapproject, movie, nearneighbor, plot, plot!, plot3, plot3!, plot3d, plot3d!,
	plotyy, project, pscontour, pscontour!, psconvert, psbasemap, psbasemap!, psclip, psclip!, pscoast, pscoast!,
	psevents, pshistogram, pshistogram!,
	psimage, psimage!, pslegend, pslegend!, psmask, psmask!, psrose, psrose!, psscale, psscale!, pssolar, pssolar!,
	psternary, psternary!, pstext, pstext!, pswiggle, pswiggle!, psxy, psxy!, psxyz, psxyz!, regress, resetGMT, rose,
	rose!, sample1d, scatter, scatter!, scatter3, scatter3!, solar, solar!, spectrum1d, sphdistance, sphinterpolate,
	sphtriangulate, surface, ternary, ternary!, text, text!, text_record, trend1d, trend2d, triangulate, splitxyz,
	decorated, vector_attrib, wiggle, wiggle!, xyz2grd, gmtbegin, gmtend, gmthelp, subplot, gmtfig, inset, showfig,
	earthtide, gmtgravmag3d, pscoupe, pscoupe!, coupe, coupe!, psmeca, psmeca!, meca, meca!, psvelo, psvelo!, velo, velo!,
	mbimport, mbgetdata, mbsvplist, mblevitus,
	blendimg!, lonlat2xy, xy2lonlat, mat2ds, mat2grid, mat2img, linspace, logspace, contains, fields, tic, toc, geodetic2enu,
	cpt4dcw, gd2gmt, gmt2gd, gdalread, gdalshade, gdalwrite, varspacegrid, MODIS_L2, 

	getband, getdriver, getlayer, getproj, getgeom, getgeotransform, toPROJ4, toWKT, importPROJ4,
	importWKT, importEPSG, gdalinfo, gdalwarp, gdaldem, gdaltranslate, gdalgrid, gdalvectortranslate, ogr2ogr,
	gdalrasterize, gdalbuildvrt, readraster, setgeotransform!, setproj!, destroy,
	delaunay, dither, buffer, centroid, intersection, intersects, polyunion, fromWKT, toWKT,
	convexhull, difference, symdifference, distance, geomarea, pointalongline, polygonize,
	wkbUnknown, wkbPoint, wkbLineString, wkbPolygon, wkbMultiPoint, wkbMultiLineString, wkbMultiPolygon,
	wkbGeometryCollection,

	geod, invgeod

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
include("themes.jl")
include("triangulate.jl")
include("trend1d.jl")
include("trend2d.jl")
include("xyz2grd.jl")
include("utils_project.jl")
include("choropleth_utils.jl")
include("seis/psmeca.jl")
include("geodesy/psvelo.jl")
include("geodesy/earthtide.jl")
include("MB/mbimport.jl")
include("MB/mbgetdata.jl")
include("MB/mbsvplist.jl")
include("MB/mblevitus.jl")
(GMTver > v"6.1.1") && include("potential/gmtgravmag3d.jl")
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
		"(like updating your GMT instalation). Run this command in REPL and restart Julia.\n\n\t\trun(`touch '$(pathof(GMT))'`)\n")
		return
	end

	clear_sessions(3600)		# Delete stray sessions dirs older than 1 hour
	global API = GMT_Create_Session("GMT", 2, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_COLMAJOR)
	if (API == C_NULL)  error("Failure to create a GMT Session")  end
	if haskey(ENV, "JULIA_GMT_IMGFORMAT")  FMT[1] = ENV["JULIA_GMT_IMGFORMAT"]  end
	f = joinpath(readlines(`$(joinpath("$(GMT_bindir)", "gmt")) --show-userdir`)[1], "theme_jl.txt")
	(isfile(f)) && (theme(readline(f));	ThemeIsOn[1] = false)	# False because we don't want it reset in showfig()
	gmtlib_setparameter(API, "COLOR_NAN", "255")			# Stop those uggly grays
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
