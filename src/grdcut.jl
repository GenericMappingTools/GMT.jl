"""
	grdcut(cmd0::String="", arg1=[], kwargs...)

Produce a new outgrid file which is a subregion of ingrid. The subregion is specified with
``limits`` (the -R); the specified range must not exceed the range of ingrid (but see ``extend``).

Full option list at [`grdcut`]($(GMTdoc)grdcut.html)

Parameters
----------

- **F** | **clip** | **cutline** :: [Type => Str | GMTdaset | Mx2 array | NamedTuple]	`Arg = array|fname[+c] | (polygon=Array|Str, crop2cutline=Bool, invert=Bool)`

    Specify a closed polygon (either a file or a dataset). All grid nodes outside the
    polygon will be set to NaN (>= GMT6.2).
    ($(GMTdoc)grdcut.html#f)
- **G** | **outgrid** | **outfile** | **save** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdcut(....) form.
    ($(GMTdoc)grdcut.html#g)
- **img** | **usegdal** :: [Type => Any]

    Force the cut operation to be done by GDAL. Works for images where GMT fails or even crash.
- $(GMT.opt_J)
- **N** | **extend** :: [Type => Str or []]

    Allow grid to be extended if new region exceeds existing boundaries. Append nodata value
    to initialize nodes outside current region [Default is NaN].
    ($(GMTdoc)grdcut.html#n)
- $(GMT.opt_R)
- **S** | **circ_subregion** :: [Type => Str]    ``Arg = [n]lon/lat/radius[unit]``

    Specify an origin and radius; append a distance unit and we determine the corresponding
    rectangular region so that all grid nodes on or inside the circle are contained in the subset.
    ($(GMTdoc)grdcut.html#s)
- $(GMT.opt_V)
- **Z** | **z_subregion** :: [Type => Str]       ``Arg = [n|N |r][min/max]``

    Determine a new rectangular region so that all nodes outside this region are also outside
    the given z-range.
    ($(GMTdoc)grdcut.html#z)
- $(GMT.opt_f)
"""
function grdcut(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdcut", cmd0, arg1)

	arg2 = nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
    cmd, = parse_common_opts(d, "", [:R :V_params :f])
    opt_J, = parse_J(d, "")
    if (!startswith(opt_J, " -JX"))  cmd *= opt_J  end
	cmd = parse_these_opts(cmd, d, [[:G :outgrid :outfile :save], [:N :extend], [:S :circ_subregion], [:Z :z_subregion]])
	cmd, args, n, = add_opt(d, cmd, 'F', [:F :clip :cutline], :polygon, Array{Any,1}([arg1, arg2]),
	                        (crop2cutline="_+c", invert="_+i"))
	if (n > 0)  arg1, arg2 = args[:]  end
	(show_kwargs[1]) && return print_kwarg_opts([:img :usegdal], "Any")		# Just print the options

	#if (cmd0 != "" && ((find_in_dict(d, [:img :usegdal])[1]) !== nothing))
		#(cmd0[1] == '@') && (cmd0 = gmtwhich(cmd0)[1].text[1])	# A remote file
		#ds = Gdal.read(cmd0)
		#t = split(scan_opt(cmd, "-R"), '/')
		#opts = ["-projwin", t[1], t[4], t[2], t[3]]		# -projwin <ulx> <uly> <lrx> <lry>
		#if ((outname = scan_opt(cmd, "-G")) == "")
			#gd2gmt(gdaltranslate(ds, opts))
		#else
			#gdaltranslate(ds, opts; dest=outname)
			#return nothing				# Since it wrote a file so nothing to return
		#end
	if (cmd0 != "" && (guess_T_from_ext(cmd0) == " -Ti" || (find_in_dict(d, [:usegdal])[1]) !== nothing))
		t = split(scan_opt(cmd, "-R"), '/')
		opts = ["-projwin", t[1], t[4], t[2], t[3]]		# -projwin <ulx> <uly> <lrx> <lry>
		cut_with_gdal(cmd0, opts)
	else
		common_grd(d, cmd0, cmd, "grdcut ", arg1, arg2)	# Finish build cmd and run it
	end
end

function cut_with_gdal(fname::AbstractString, opts::Vector{AbstractString}, outname::String=""; expand::Bool=false)
	if (outname == "")
		G_I = gdaltranslate(fname, opts)	# Layout is "TRB" so all matrices are contrary to Julia order
		if (expand)							# This branch is called only by grdview -G<image>
			W = parse(Float64, opts[2]);	E = parse(Float64, opts[4])
			S = parse(Float64, opts[5]);	N = parse(Float64, opts[3])
			dx_W = G_I.range[1] - W;	dx_E = G_I.range[2] - E
			dy_S = G_I.range[3] - S;	dy_N = G_I.range[4] - N
			pad_W = ceil(Int, abs(dx_W) / G_I.inc[1]);		pad_E = ceil(Int, abs(dx_E) / G_I.inc[1])
			pad_S = ceil(Int, abs(dy_S) / G_I.inc[2]);		pad_N = ceil(Int, abs(dy_N) / G_I.inc[2])
			# Recompute the WESN such that the increments don't change (original -R was in GRID increment multiples)
			W = G_I.range[1] - pad_W * G_I.inc[1];			E = G_I.range[2] + pad_E * G_I.inc[1]
			S = G_I.range[3] - pad_S * G_I.inc[2];			N = G_I.range[4] + pad_N * G_I.inc[2]
			if (pad_W > 0 || pad_E > 0 || pad_S > 0 || pad_N > 0)
				img_new = (size(G_I, 3) == 1) ? fill(UInt8(255), size(G_I,1)+pad_W+pad_E, size(G_I,2)+pad_S+pad_N) :
				                                fill(UInt8(255), size(G_I,1)+pad_W+pad_E, size(G_I,2)+pad_S+pad_N, size(G_I,3))
				n = 0
				for l = 1:size(img_new,3)
					@simd for row = pad_N+1:(size(G_I,2)+pad_N)
						@simd for col = pad_W+1:(size(G_I,1)+pad_W)
							@inbounds img_new[col,row,l] = G_I.image[n += 1]
						end
					end
				end
				G_I = mat2img(img_new, G_I)
				G_I.x = linspace(W, E, size(img_new,1)+G_I.registration)
				G_I.y = linspace(S, N, size(img_new,2)+G_I.registration)
				G_I.inc = [G_I.x[2]-G_I.x[1], G_I.y[2]-G_I.y[1]]
				G_I.range[1:4] = [W, E, S, N]

				#def_name = joinpath(tempdir(), "GMTjl_2grdview.tiff")
				def_name = "/vsimem/tmp/GMTjl_2grdview.tiff"	# I'm amazed that this works
				gdalwrite(def_name, G_I)
				return def_name
			end
			return fname			# If we didn't have to touch the image (rare) just return its name
		end
		G_I
	else
		gdaltranslate(fname, opts; dest=outname)
		return nothing				# Since it wrote a file so nothing to return
	end
end

# ---------------------------------------------------------------------------------------------------
grdcut(arg1, cmd0::String=""; kw...) = grdcut(cmd0, arg1; kw...)