"""
    grdview(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

Reads a 2-D grid and produces a 3-D perspective plot by drawing a mesh, painting a
colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons
to a raster image.

Full option list at [`grdview`]($(GMTdoc)grdview.html)

- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **G** | **drape** | **drapefile** :: [Type => Str | GMTgrid | a Tuple with 3 GMTgrid types]

    Drape the image in drapefile on top of the relief provided by relief_file.
    ($(GMTdoc)grdview.html#g)
- **I** | **shade** | **shading** | **intensity** :: [Type => Str | GMTgrid]		``Arg = GMTgrid | filename``

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    ($(GMTdoc)grdview.html#i)
- **N** | **plane** :: [Type => Str | Int]		``Arg = (level [,fill])``

    Draws a plane at this z-level.
    ($(GMTdoc)grdview.html#n)
- $(GMT.opt_P)
- **Q** | **surftype** | **surf** :: [Type => Str | Int] ``Arg = mesh=Bool, surface=Bool, image=Bool, wterfall=(:rows|cols,[fill])``

    Specify **m** for mesh plot, **s** for surface, **i** for image.
    ($(GMTdoc)grdview.html#q)
- **S** | **smoothfactor** :: [Type => Number]

    Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval..
    ($(GMTdoc)grdview.html#s)
- **T** | **tiles** | **no_interp** :: [Type => Str | NT]	``Arg = (skip|skip_nan=Bool, outlines=Bool|pen)``

    Plot image without any interpolation.
    ($(GMTdoc)grdview.html#t)
- **W** | **pens** | **pen** :: [Type => Str]	``Arg = (contour=Bool|pen, mesh=Bool|pen, facade=Bool|pen)``

    Draw contour, mesh or facade. Append pen attributes.
    ($(GMTdoc)grdview.html#w)

- **isgeog** :: [Type => Any]

    When drapping an image that has projection info over a grid that is in geographics but does not carry any
    information about this fact we may need to use this option to help the program finding the common BoundingBox.
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_savefig)
"""
function grdview(cmd0::String="", arg1=nothing; first=true, kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdview", cmd0, arg1)
	arg2 = nothing;	arg3 = nothing;	arg4 = nothing;	arg5 = nothing;

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	common_insert_R!(d, O, cmd0, arg1)			# Set -R in 'd' out of grid/images (with coords) if limits was not used

	has_opt_B = (find_in_dict(d, [:B :frame :axis :axes], false)[1] !== nothing)
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "grdview", O, " -JX" * split(def_fig_size, '/')[1] * "/0")
	(startswith(opt_J, " -JX") && !contains(opt_J, "/")) && (cmd = replace(cmd, opt_J => opt_J * "/0")) # When sub-regions
	(!has_opt_B && isa(arg1, GMTimage) && (isimgsize(arg1) || CTRL.limits[1:4] == zeros(4)) && opt_B == def_fig_axes) &&
		(cmd = replace(cmd, opt_B => ""))	# Dont plot axes for plain images if that was not required

	cmd, = parse_common_opts(d, cmd, [:UVXY :c :f :n :p :t :params], first)
	cmd  = add_opt(d, cmd, "S", [:S :smooth])
	if ((val = find_in_dict(d, [:N :plane])[1]) !== nothing)
		cmd *= " -N" * parse_arg_and_pen(val, "+g", false)
	end
	cmd = add_opt(d, cmd, "Q", [:Q :surf :surftype],
				  (mesh=("m", add_opt_fill), surface="_s", surf="_s", img=("i",arg2str), image="i", nan_alpha="_c", monochrome="_+m", waterfall=(rows="my", cols="mx", fill=add_opt_fill)))
	cmd = add_opt(d, cmd, "W", [:W :pens :pen], (contour=("c", add_opt_pen),
	              mesh=("m", add_opt_pen), facade=("f", add_opt_pen)) )
	cmd = add_opt(d, cmd, "T", [:T :no_interp :tiles], (skip="_+s", skip_nan="_+s", outlines=("+o", add_opt_pen)) )
	(!occursin(" -T", cmd)) ? cmd = parse_JZ(d, cmd)[1] : del_from_dict(d, [:JZ])	# Means, even if we had one, ignore silently
	cmd = add_opt(d, cmd, "%", [:layout :mem_layout], nothing)

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted

	(isa(arg1, Array{<:Real})) && (arg1 = mat2grid(arg1))

	cmd, N_used, arg1, arg2, arg3 = common_get_R_cpt(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, "grdview")
	cmd, arg1, arg2, arg3, arg4 = common_shade(d, cmd, arg1, arg2, arg3, arg4, "grdview")
	cmd, arg1, arg2, arg3, arg4, arg5 = parse_G_grdview(d, [:G :drape :drapefile], cmd0, cmd, arg1, arg2, arg3, arg4, arg5)

	_cmd = finish_PS_nested(d, ["grdview " * cmd])
	finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2, arg3, arg4, arg5)
end

# ---------------------------------------------------------------------------------------------------
function parse_G_grdview(d::Dict, symbs::Array{<:Symbol}, cmd0::String, cmd::String, arg1, arg2, arg3, arg4, arg5)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "GMTgrid | Tuple | String"), arg1, arg2, arg3, arg4, arg5
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, String) || isa(val, GMTimage))
			if (isa(val, String) && guess_T_from_ext(val) != " -Ti")
				cmd *= " -G" * val
			else
				if (cmd0 != "")
					prj = (startswith(cmd0, "@earth_r")) ? prj4WGS84 : getproj(cmd0, proj4=true)
				else
					prj = (isa(arg1, GMTgrid)) ? getproj(arg1) : ""
				end
				t = split(scan_opt(cmd, "-R"), '/')
				Iname = drape_prepare(d, val, ["-projwin", t[1], t[4], t[2], t[3]], prj)
				cmd *= " -G" * Iname
				(!contains(cmd, " -Qi")) && (cmd *= " -Qi300")	# Otherwise GMT crashes because grdview goes through the "MESH" branch
			end
		elseif (isa(val, GMTgrid))			# A single drape grid (arg1-3 may be used already)
			cmd, N_used = put_in_slot(cmd, 'G', arg1, arg2, arg3, arg4)
			if     (N_used == 1)  arg1 = val
			elseif (N_used == 2)  arg2 = val
			elseif (N_used == 3)  arg3 = val
			elseif (N_used == 4)  arg4 = val
			end
		elseif (isa(val, Tuple) && length(val) == 3)
			cmd, N_used = put_in_slot(cmd, 'G', arg1, arg2, arg3, arg4, arg5)
			cmd *= " -G -G"					# Because the above only set one -G and we need 3
			if     (N_used == 1)  arg1 = val[1];	arg2 = val[2];		arg3 = val[3]
			elseif (N_used == 2)  arg2 = val[1];	arg3 = val[2];		arg4 = val[3]
			elseif (N_used == 3)  arg3 = val[1];	arg4 = val[2];		arg5 = val[3]
			end
		else
			error("Wrong way of setting the drape (G) option.")
		end
	end
	return cmd, arg1, arg2, arg3, arg4, arg5
end

# ---------------------------------------------------------------------------------------------------
function drape_prepare(d::Dict, fname, opts::Vector{AbstractString}, prj::String)
	# Deal with the option of drapping an image, which can be smaller, larger or with fifferent projection.
	prj_img = getproj(fname, proj4=true)
	(prj_img == "" && isa(fname, AbstractString)) && return fname	# If drape image has no RefSys just return its name and let it all be used

	(prj == "" && find_in_dict(d, [:isgeog])[1] !== nothing) && (prj = prj4WGS84)

	# Layout is "TRB" so all matrices are contrary to Julia order. opts=[-projwin xmin ymax xmax ymin]
	G_I = (prj == "" || prj == prj_img) ? gdaltranslate(fname, opts) :
	                                      gdalwarp(fname, ["-t_srs", prj, "-te", opts[2], opts[5], opts[4], opts[3]])

	W = parse(Float64, opts[2]);	E = parse(Float64, opts[4])
	S = parse(Float64, opts[5]);	N = parse(Float64, opts[3])
	Wbk, Ebk, Sbk, Nbk = W, E, S, N
	dx_W = G_I.range[1] - W;		dx_E = G_I.range[2] - E
	dy_S = G_I.range[3] - S;		dy_N = G_I.range[4] - N
	pad_W = ceil(Int, abs(dx_W) / G_I.inc[1]);		pad_E = ceil(Int, abs(dx_E) / G_I.inc[1])
	pad_S = ceil(Int, abs(dy_S) / G_I.inc[2]);		pad_N = ceil(Int, abs(dy_N) / G_I.inc[2])
	# Recompute the WESN such that the increments don't change (original -R was in GRID increment multiples)
	W = G_I.range[1] - pad_W * G_I.inc[1];			E = G_I.range[2] + pad_E * G_I.inc[1]
	S = G_I.range[3] - pad_S * G_I.inc[2];			N = G_I.range[4] + pad_N * G_I.inc[2]
	if (abs(W - Wbk) > 2*G_I.inc[1] || abs(E - Ebk) > 2*G_I.inc[1] || abs(S - Sbk) > 2*G_I.inc[2] || abs(N - Nbk) > 2*G_I.inc[2])
		img_is_geo = contains(prj_img, "longlat") || contains(prj_img, "latlong")
		msg = "Grid and draping image do not carry enough information about their Referencing Systems"
		(!img_is_geo) && (msg *= "\n\tDraping image is not in geogs but grid probably is. Please use option `isgeog=true`")
		error(msg)
	end
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
	end

	#def_name = joinpath(tempdir(), "GMTjl_2grdview.tiff")
	def_name = "/vsimem/GMTjl_2grdview.tiff"	# I'm amazed that this works
	gdalwrite(def_name, G_I)
	ressurectGDAL()
	return def_name
end

# ---------------------------------------------------------------------------------------------------
grdview!(cmd0::String="", arg1=nothing; first=false, kw...) = grdview(cmd0, arg1; first=first, kw...)
grdview(arg1; first=true, kw...) = grdview("", arg1; first=first, kw...)
grdview!(arg1; first=false, kw...) = grdview("", arg1; first=first, kw...)
