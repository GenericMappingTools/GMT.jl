module GMT

using Printf, Dates, Statistics, Downloads
using Tables: Tables
using PrettyTables
using PrecompileTools
using LinearAlgebra

struct CTRLstruct
	limits::Vector{Float64}			# To store the data limits. First 6 store: data limits. Second 6: plot limits, 13th +r
	figsize::Vector{Float64}		# To store the current fig size (xsize,ysize[,zsize]). Needed, for example, in hexbin
	proj_linear::Vector{Bool}		# To know if images sent to GMT need Pad
	returnPS::Vector{Bool}			# To know if returning the PS to Julia
	callable::Array{Symbol}			# Modules that can be called inside other modules
	pocket_call::Vector{Any}		# To temporarily store data needed by modules sub-calls. Put in [3] for pre-calls
	pocket_B::Vector{String}		# To temporarily store opt_B grid and fill color to be reworked in psclip
	pocket_J::Vector{String}		# To temporarily store opt_J and fig size to eventualy flip directions (y + down, etc)
	pocket_R::Vector{String}		# To temporarily store opt_R
	XYlabels::Vector{String}		# To temporarily store the x,y col names to let x|y labels know what to plot (if "auto")
	IamInPaperMode::Vector{Bool}	# A 2 elem vec to know if we are in under-the-hood paper mode. 2nd traces if first call
	gmt_mem_bag::Vector{Ptr{Cvoid}}	# To temporarily store a GMT owned memory to be freed in gmt()
	pocket_d::Vector{Dict}			# To pass the Dict of kwargs, after consumption, to other modules.
end

struct CTRLstruct2
	first::Vector{Bool}				# Signal that we are starting a new plot (used to set params)
	points::Vector{Bool}			# If maps are using points as coordinates
	fname::Vector{String}			# Store the full name of PS being constructed
end

# The file deps/deps.jl is created by compile from the deps/build.jl
# On Windows we use a system wide GMT if it is found from path or install it from a GMT installer. It is a MSVC binary.
# On Unix the default is to use the GMT_jll artifact. However this can be changed to use a system wide GMT installation.
# To swap to a system wide GMT installation, do (in REPL):
# 1- ENV["SYSTEMWIDE_GMT"] = 1;
# 2- import Pkg; Pkg.build("GMT")
# 3- restart Julia
#
# Note the above will work up until some other reason triggers a Julia recompile, where the JLL artifacts 
# will be used again. To make the ENV["SYSTEMWIDE_GMT"] = 1 solution permanent, declare a "SYSTEMWIDE_GMT"
# environment variable permanently in your .bashrc (or whatever).

depfile = joinpath(dirname(@__FILE__),"..","deps","deps.jl")	# File with shared lib names
isfile(depfile) && include(depfile)		# This loads the shared libs names in the case of NON-JLL, otherwise just return

if ((!(@isdefined have_jll) || have_jll == 1) && get(ENV, "SYSTEMWIDE_GMT", "") == "")	# That is, the JLL case
	using GMT_jll, GDAL_jll, PROJ_jll, Ghostscript_jll
	t = split(readlines(`$(GMT_jll.gmt()) "--version"`)[1],'_')
	const GMTver = VersionNumber(t[1])
	const GMTdevdate = (length(t) > 1) ? Date(t[end], dateformat"y.m.d") : Date("0001-01-01")	# For DEV versions
	const GMTuserdir = [readlines(`$(GMT_jll.gmt()) "--show-userdir"`)[1]]
	const GSbin = Ghostscript_jll.gs()[1]
	const isJLL = true
	fname = joinpath(GMTuserdir[1], "ghost_jll_path.txt")
	!isdir(GMTuserdir[1]) && mkdir(GMTuserdir[1])	# When installing on a clean no GMT sys, ~/.gmt doesn't exist
	open(fname,"w") do f
		write(f, GSbin)								# Save this to be used by psconvert.c
	end
else
	const isJLL = false
	const GMTver, libgmt, libgdal, libproj, GMTuserdir = _GMTver, _libgmt, _libgdal, _libproj, [userdir]
	const GMTdevdate = Date(devdate, dateformat"y.m.d")		# 'devdate' comes from reading 'deps.jl'
end

const global G_API = [C_NULL]
const global PSname = [""]					# The PS file (filled in __init__) where, in classic mode, all lands.
const global TMPDIR_USR = [tempdir(), "", ""]	# Save the tmp dir and user name (also filled in __init__)
const global TESTSDIR = joinpath(dirname(pathof(GMT))[1:end-4], "test", "")	# To have easy access to test files
const global IMG_MEM_LAYOUT = [""]			# "TCP"	 For Images.jl. The default is "TRBa"
const global GRD_MEM_LAYOUT = [""]			# "BRP" is the default for GMT PS images.
const global CURRENT_VIEW   = [""]			# To store the current viewpoint (-p)
const global MULTI_COL   = Vector{Bool}(undef, 1);MULTI_COL[1] = false	# To allow plottig multiple columns at once.
const global IamModern   = Vector{Bool}(undef, 1);IamModern[1] = false		# To know if we are in modern mode
const global FirstModern = Vector{Bool}(undef, 1);FirstModern[1] = false	# To know
const global IamModernBySubplot = Vector{Bool}(undef, 1);	IamModernBySubplot[1] = false	# To know if set in subpot
const global IamSubplot  = Vector{Bool}(undef, 1);IamSubplot[1]  = false	# To know if we are in subplot mode
const global IamInset    = Vector{Bool}(undef, 1);IamInset[1]    = false	# To know if we are in Inset mode
const global usedConfPar = Vector{Bool}(undef, 1);usedConfPar[1] = false	# Hacky solution for the session's memory trouble
const global ThemeIsOn   = Vector{Bool}(undef, 1);ThemeIsOn[1] = false		# To know if we have an active plot theme
const global CONVERT_SYNTAX = Vector{Bool}(undef, 1);CONVERT_SYNTAX[1] = false	# To only convert to hard core GMT syntax (like Vd=2)
const global SHOW_KWARGS = Vector{Bool}(undef, 1);SHOW_KWARGS[1] = false	# To just print the kwargs of a option call)
const global isFranklin  = Vector{Bool}(undef, 1);isFranklin[1] = false		# Only set/unset by the Docs building scripts.
const global isJupyter   = [Bool(0)]										# Jupyter and Modern need special treatment (Quarto).
const global isPSclosed  = [Bool(0)]										# Modern mode will close the PS at the end. We need to know that
const global noGrdCopy   = Vector{Bool}(undef, 1);noGrdCopy[1] = false		# If true, grids are sent without transpose/copy
const global GMTCONF     = Vector{Bool}(undef, 1);GMTCONF[1] = false		# Flag if gmtset was used and must be 'unused' 
const global FMT = ["png"]                         # The default plot format
const global BOX_STR = [""]                        # Used in plotyy to know -R of first call
const global POSTMAN = Dict{String,String}()       # To pass messages to functions (start with get_dataset) 
const DEF_FIG_SIZE  = "15c/10c"                    # Default fig size for plot like programs. Approx 16/11
const DEF_FIG_AXES_BAK     = " -Baf -BWSen"        # Default fig axes for plot like programs
const DEF_FIG_AXES3_BAK    = " -Baf -Bza"          # 		"" but for 3D views
const global DEF_FIG_AXES  = [DEF_FIG_AXES_BAK]    # This one may be be changed by theme()
const global DEF_FIG_AXES3 = [DEF_FIG_AXES3_BAK]   #		""
const global CTRL = CTRLstruct(zeros(13), zeros(6), [true], [false],
                               [:arrows, :bubblechart, :basemap, :band, :clip, :coast, :colorbar, :hband, :hlines, :logo, :lines, :grdvector, :plot, :plot3, :quiver, :scatter, :scatter3, :stairs, :text, :vlines, :vband],
							   [nothing, nothing, nothing], ["","",""], ["","", "", "   "], [""], ["",""], [false,true], [C_NULL], [Dict()])
const global CTRLshapes = CTRLstruct2([true], [true], [""])			# Used in sub-module Drawing
const prj4WGS84 = "+proj=longlat +datum=WGS84 +units=m +no_defs"	# This is used in many places
const CPTaliases = [:C :color :cmap :colormap :colorscale]
const global VMs = Union{Vector{Symbol}, Matrix{Symbol}}
const global VMr = Union{AbstractVector{<:Real}, Matrix{<:Real}}
const global DictSvS = Dict{String, Union{String, Vector{String}}}
const global StrSymb = Union{AbstractString, Symbol}
const global filesep = Sys.iswindows() ? "\\" : "/"
# GItype = Union{GMTgrid, GMTimage} and GDtype = Union{GMTdataset, Vector{GMTdataset}} are declared in gmt_types
# MatGDsGd = Union{Matrix{<:AbstractFloat}, GMTdataset, Vector{GMTdataset}, Gdal.AbstractDataset}	declared down
#const global unused_opts = [()]					# To track consumed options
#const global unused_subopts = [()]					# To track consumed options in sub-options

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
	@eval Base.Experimental.@optlevel 1
end

export
	GMTgrid, GMTimage, GMTdataset, GMTcpt, GItype, GDtype, GMTver, FMT, TMPDIR_USR, gmt, libgdal,
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
	earthtide, gravfft, gmtgravmag3d, grdgravmag3d, gravprisms, pscoupe, pscoupe!, coupe, coupe!, psmeca, psmeca!,
	meca, meca!, psvelo, psvelo!, velo, velo!, getbyattrib, inwhichpolygon, pcolor, pcolor!, triplot, triplot!,
	trisurf, trisurf!, grdrotater, imagesc, upGMT, boxes,

	find_in_dict, find_in_kwargs,
	mbimport, mbgetdata, mbsvplist, mblevitus,

	blendimg!, lonlat2xy, xy2lonlat, df2ds, mat2ds, mat2grid, mat2img, slicecube, cubeslice, linspace, logspace, fileparts,
	fields, flipud, fliplr, flipdim, flipdim!, grdinterpolate, pow, tic, toc, theme, tern2cart, geodetic2enu, cpt4dcw,
	gd2gmt, gmt2gd, gdalread, gdalshade, gdalwrite, gadm, xyzw2cube, coastlinesproj, graticules, orbits, orbits!,
	plotgrid!, worldrectangular, worldrectgrid,

	earthregions, gridit, magic, rescale, stackgrids, delrows!, setgrdminmax!, meshgrid, cart2pol, pol2cart, cart2sph, sph2cart,

	arcellipse, arccircle, getband, getdriver, getlayer, getproj, getgeom, getgeotransform, gdaldrivers, toPROJ4, toWKT,
	importPROJ4, importWKT, importEPSG, gdalinfo, gdalwarp, gdaldem, gdaltranslate, gdalgrid, gdalvectortranslate,
	ogr2ogr, gdalrasterize, gdalbuildvrt, readraster, setgeotransform!, setproj!, destroy,
	delaunay, dither, buffer, centroid, intersection, intersects, polyunion, overlaps, fromWKT, fillnodata!, fillnodata,
	concavehull, convexhull, difference, symdifference, distance, geomarea, pointalongline, polygonize, simplify,
	wkbUnknown, wkbPoint, wkbPointZ, wkbLineString, wkbPolygon, wkbMultiPoint, wkbMultiPointZ, wkbMultiLineString,
	wkbMultiPolygon, wkbGeometryCollection, wkbPoint25D, wkbLineString25D, wkbPolygon25D, wkbMultiPoint25D,
	wkbMultiLineString25D, wkbMultiPolygon25D, wkbGeometryCollection25D,

	buffergeo, circgeo, epsg2proj, epsg2wkt, geod, invgeod, loxodrome, loxodrome_direct, loxodrome_inverse,
	geodesic, orthodrome, proj2wkt, setcoords!, setfld!, setcrs!, setsrs!, vecangles, wkt2proj,

	colorzones!, rasterzones!, rasterzones, lelandshade, texture_img, crop, doy2date, date2doy, yeardecimal,
	median, mean, quantile, std, nanmean, nanstd, skipnan, zonal_statistics, zonal_stats,

	add2PSfile, append2fig, linearfitxy, regiongeog, streamlines, wmsinfo, wmstest, wmsread, peaks, polygonlevels,
	randinpolygon,

	ablines, ablines!, density, density!, boxplot, boxplot!, cornerplot, cornerplot!, cubeplot, cubeplot!, ecdfplot, ecdfplot!,
	fill_between, fill_between!, marginalhist, marginalhist!, parallelplot, parallelplot!, plotlinefit, plotlinefit!,
	qqplot, qqplot!, qqnorm, qqnorm!, seismicity, sealand, squeeze, terramar, violin, violin!, viz, weather, windbarbs, whereami,

	VSdisp, info, kmeans, pca, mosaic, quadbounds, quadkey, geocoder, getprovider,

	binarize, isodata, rgb2gray,

	Ginnerjoin, Gouterjoin, Gleftjoin, Grightjoin, Gcrossjoin, Gsemijoin, Gantijoin, spatialjoin,

	df2ds, ODE2ds,
	sprintf,
	@?, @dir

include("common_docs.jl")
include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_types.jl")
include("gdal.jl")
include("gdal_utils.jl")
include("proj_utils.jl")
using GMT.Gdal
const global MatGDsGd = Union{Matrix{<:AbstractFloat}, GMTdataset, Vector{GMTdataset}, Gdal.AbstractDataset}
const global CURRENT_CPT = [GMTcpt()]		# To store the current palette

include("gmt_main.jl")
include("utils_types.jl")
include("grd_operations.jl")
include("common_options.jl")
const global LEGEND_TYPE = [legend_bag()]	# To store Legends info
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
include("gmtwhich.jl")
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
include("gridit.jl")
include("img_funs.jl")
include("imgtiles.jl")
include("imshow.jl")
include("kml2gmt.jl")
include("linefit.jl")
include("loxodromics.jl")
include("makecpt.jl")
include("mapproject.jl")
include("movie.jl")
include("nearneighbor.jl")
include("pca.jl")
include("pcolor.jl")
include("orbits.jl")
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
include("sealand.jl")
include("spatial_funs.jl")
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
include("potential/gmtgravmag3d.jl")
include("potential/grdgravmag3d.jl")
include("potential/gravprisms.jl")
include("potential/gravfft.jl")
include("spotter/grdrotater.jl")
include("windbarbs/windbarbs.jl")
include("drawing.jl")
include("get_enums.jl")

@setup_workload begin
	G_API[1] = GMT_Create_Session("GMT", 2, GMT_SESSION_BITFLAGS)
	GMT.parse_B(Dict(:frame => (annot=10, title="Ai Ai"), :grid => (pen=2, x=10, y=20)), "", " -Baf -BWSen")
	GMT.parse_R(Dict(:xlim => (1,2), :ylim => (3,4), :zlim => (5,6)), "")
	GMT.parse_J(Dict(:J => "X", :scale => "1:10"), "")
	GMT.build_opt_J(:X5)
	GMT.theme("dark")
	GMT.theme_modern()
	mat2ds([9 8; 9 8], x=[0 7], pen=["5p,black", "4p,white,20p_20p"], multi=true);
	GMT.cat_2_arg2(rand(3), mat2ds(rand(3,2)));
	GMT.cat_2_arg2(mat2ds(rand(3,2)), mat2ds(rand(3,2)));
	GMT.cat_3_arg2(rand(3),rand(3),rand(3));
	plot(rand(5,2), marker=:point, lc=:red, ls=:dot, lw=1, C=:jet, colorbar=true, Vd=2)
	makecpt(T=(0,10))
	t = joinpath(tempdir(), "lixo.dat");
	gmtwrite(t,[0.0 0; 1 1]);
	gmtread(t);
	rm(t)
	D = mat2ds(rand(3,3), colnames=["Time","b","c"]); D.attrib = Dict("Timecol" => "1");
	D[:Time];	D["Time", "b"];
	grdimage(rand(Float32,32,32), Vd=2);
	grdview(rand(Float32,32,32), Vd=2);
	grdinfo(mat2grid(rand(Float32,4,4)));
	G=gmt("grdmath", "-R0/10/0/10 -I2 X");
	grdcontour(G);
	grd2cpt(G);
	grd2xyz(G);
	grdlandmask(R="-10/4/37/45", res=:c, inc=0.1);
	grdmask([10 20; 40 40; 70 20; 10 20], R="0/100/0/100", out_edge_in=[100 0 0], I=2);
	grdsample(G, inc=0.5);
	grdtrend(G, model=3);
	grdtrack(G, [1 1]);
	mat2img(rand(UInt8, 32, 32, 3));
	coast(R=:g, proj=:guess, W=(level=1,pen=(2,:green)), Vd=2);
	gridit(rand(10,3), preproc=true, I=0.1);
	#earthregions("PT", Vd=2);
	#violin(rand(50), fmt=:ps);
	#boxplot(rand(50), fmt=:ps);
	#qqplot(randn(500), randn(50), fmt=:ps);
	#ecdfplot!(randn(50), fmt=:ps);
	#cornerplot(randn(50,3), scatter=true, fmt=:ps);
	#marginalhist(randn(1000,2), par=(PS_MEDIA="A2",), fmt=:ps);	rm("GMTplot.ps")
	#feather([0.0 0 2.0; 0.0 30 2; 0.0 60 2], rtheta=true, aspect="1:1", arrow=(len=0.5, shape=0.5,), fmt=:ps);
	#orbits(mat2ds(rand(10,3)));
	#pca(rand(Float32, 24, 4));
	#pca(mat2img(rand(UInt8, 64,64,4)));
	#kmeans(rand(100,3), 3, maxiter=10);
	#rm(joinpath(tempdir(), "GMTjl_custom_p_x.txt"))		# This one gets created before username is set.
	theme()
	resetGMT()
end

Base.precompile(Tuple{typeof(upGMT),Bool, Bool})		# Here it doesn't print anything.

function __init__(test::Bool=false)
	if !isfile(libgmt) || (!Sys.iswindows() && (!isfile(libgdal) || !isfile(libproj)))
		println("\nDetected a previously working GMT.jl version but something has broken meanwhile.\n" *
		"(like updating your GMT instalation). Restart Julia and run `import Pkg; Pkg.precompile()`")
		return
	end
	(GMTver < v"6.4.0") && @warn("You should not be using a GMT version older than 6.4. Somethings will not work.")

	clear_sessions(3600)		# Delete stray sessions dirs older than 1 hour
	G_API[1] = GMT_Create_Session("GMT", 2, GMT_SESSION_BITFLAGS)	# (0.010179 sec)
	theme_modern()				# Set the MODERN theme and some more gmtlib_setparameter() calls
	haskey(ENV, "JULIA_GMT_IMGFORMAT") && (FMT[1] = ENV["JULIA_GMT_IMGFORMAT"])
	f = joinpath(GMTuserdir[1], "theme_jl.txt")
	(isfile(f)) && (theme(readline(f));	ThemeIsOn[1] = false)	# False because we don't want it reset in showfig()
	user = (Sys.isunix() || Sys.isapple()) ? Libc.getpwuid(Libc.getuid(), true).username : Sys.iswindows() ? ENV["USERNAME"] : ""
	TMPDIR_USR[2] = replace(user, " " => "_")
	haskey(ENV, "JULIA_GMT_MULTIFILE") && (TMPDIR_USR[3] = string("_", getpid()))
	PSname[1] = TMPDIR_USR[1] * "/" * "GMTjl_" * TMPDIR_USR[2] * TMPDIR_USR[3] * ".ps"
end

"""
GMT manipulating geographic and Cartesian data sets (including filtering, trend fitting, gridding, projecting, etc.)
and producing high quality illustrations.

Full modules list and docs in terse GMT style at $(GMTdoc)

Documentation for GMT.jl at https://www.generic-mapping-tools.org/GMT.jl/latest/
"""
GMT

end # module
