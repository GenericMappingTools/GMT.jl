"""
	grdvector(arg1, arg2, kwargs...)

Takes two 2-D grid files which represents the x- and y-components of a vector field and produces
a vector field plot by drawing vectors with orientation and length according to the information
in the files. Alternatively, polar coordinate r, theta grids may be given instead.

Full option list at [`grdvector`]($(GMTdoc)grdvector.html)

Parameters
----------

- **A** | **polar** :: [Type => Bool]  

    The grid contain polar (r, theta) components instead of Cartesian (x, y) [Default is Cartesian components].
    ($(GMTdoc)grdvector.html#a)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **G** | **fill** :: [Type => Str | Number]

    Sets color or shade for vector interiors [Default is no fill].
    ($(GMTdoc)grdvector.html#g)
- **I** | **inc** :: [Type => Sytr | Number]	``Arg=[x]dx[/dy]``

    Only plot vectors at nodes every x_inc, y_inc apart (must be multiples of original grid spacing).
    ($(GMTdoc)grdvector.html#i)
- **maxlen** :: [Type => Number]

    Set the maximum length in plot units that an arrow will have. By default it's equal to fig width / 20.
	This option is ignored if **inc** is set.
- **N** | **noclip** | **no_clip** :: [Type => Bool]

    Do NOT clip symbols that fall outside map border 
    ($(GMTdoc)grdvector.html#n)
- **Q** | **vec** | **vector** | **arrow** :: [Type => Str]

    Modify vector parameters. For vector heads, append vector head size [Default is 0, i.e., stick-plot].
    ($(GMTdoc)grdvector.html#q)
- $(GMT.opt_P)
- $(GMT.opt_R)
- **S** | **vscale** | **vec_scale** :: [Type => Str | Number]		``Arg = [i|l]scale[unit]``

    Sets scale for vector plot length in data units per plot distance measurement unit [1].
    ($(GMTdoc)grdvector.html#s)
- **T** | **sign_scale** :: [Type => Bool]

    Means the azimuths of Cartesian data sets should be adjusted according to the signs of the
    scales in the x- and y-directions [Leave alone].
    ($(GMTdoc)grdvector.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
    ($(GMTdoc)grdvector.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** | **azimuth** :: [Type => Bool]

    The theta grid provided contains azimuths rather than directions (implies -A).
    ($(GMTdoc)grdvector.html#z)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdvector(arg1, arg2; first=true, kwargs...)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	def_J = " -JX" * split(def_fig_size, '/')[1] * "/0"
	cmd, _, opt_J, opt_R = parse_BJR(d, "", "", O, def_J)
	cmd = parse_common_opts(d, cmd, [:UVXY :f :p :t :params], first)[1]
	!(contains(cmd, "-V")) && (cmd *= " -Ve")	# Shut up annoying warnings if -S has no units
	cmd = parse_these_opts(cmd, d, [[:A :polar], [:N :noclip :no_clip], [:T :sign_scale], [:Z :azimuth]])
	opt_S = add_opt(d, "", "S", [:S :vscale :vec_scale],
	                (inverse=("i", nothing, 1), length=("l", arg2str, 1), scale=("",arg2str,2), scale_at_lat="+c", refsize="+s"))

	#x_min  x_max  y_min  y_max  z_min  z_max  dx  dy  n_cols  n_rows  reg isgeog
	info  = get_grdinfo(arg1);		n_cols, n_rows = info[9], info[10]
	info2 = get_grdinfo(arg2)
	
	opt_R = (contains(cmd, "-R") && !contains(cmd, " -R ")) ? "" : @sprintf(" -R%.4g/%.14g/%.14g/%.14g", info[1:4]...)
	w,h = get_figsize(opt_R, opt_J)
	as = min(max(info[6], info2[6]) * n_rows / h, max(info[6], info2[6]) * n_cols / w)

	opt_I = parse_I(d, "", [:I :inc :increment :spacing], "I")
	if (opt_I == "")
		# maxlen is the maximum length that an arrow will take. If not given it defaults to fig_width / 20
		maxlen::Float64 = ((val = find_in_dict(d, [:maxlen]))[1] !== nothing) ? val : w/20
		multx = round(Int, n_cols / (w / maxlen))
		multy = round(Int, n_rows / (h / maxlen))
		(multx == 0) && (multx == 1);	(multy == 0) && (multy == 1);
		opt_I = " -Ix$(multx)/$(multy)"
		as = max(as/multx, as/multy)
	end
	if (opt_S == "")
		opt_S = @sprintf(" -S%.10g", as)
	elseif (startswith(opt_S, " -S+c") || startswith(opt_S, " -S+s"))
		opt_S = @sprintf(" -S%.10g%s", as, opt_S[4:end])
	end
	cmd *= opt_I * opt_S

	cmd, arg3, = add_opt_cpt(d, cmd, CPTaliases, 'C')
	isa(arg1, String) && (cmd = arg1 * " " * arg2 * cmd; arg1 = arg3; arg2 = arg3 = nothing)

	opt_Q = parse_Q_grdvec(d, [:Q :vec :vector :arrow])
	!occursin(" -G", opt_Q) && (cmd = add_opt_fill(cmd, d, [:G :fill], 'G'))	# If fill not passed in arrow, try from regular option
	cmd *= add_opt_pen(d, [:W :pen], "W", true)									# TRUE to also seek (lw,lc,ls)
	(!occursin(" -C", cmd) && !occursin(" -W", cmd) && !occursin(" -G", opt_Q)) && (cmd *= " -W0.5")	# If still nothing, set -W.
	(opt_Q != "") && (cmd *= opt_Q)

    return finish_PS_module(d, "grdvector " * cmd, "", K, O, true, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
function parse_Q_grdvec(d::Dict, symbs::Array{<:Symbol})::String
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | String")
	cmd::String = ""
    if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, String))  cmd *= " -Q" * val		# An hard core GMT string directly with options
		else                   cmd *= " -Q" * vector_attrib(val)
		end
		if ((ind = findfirst("+g", cmd)) !== nothing)   # -Q0.4+e+gred+n0.4+pcyan+h0
			cmd *= " -G" * split(cmd[ind[1]+2:end], "+")[1]	# Add a -G (does the same) to have at least one of the -G, -W, -C
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
get_grdinfo(grd::String)  = gmt("grdinfo -C " * grd).data
get_grdinfo(grd::GMTgrid)::Vector{Float64} = [grd.range..., grd.inc..., size(grd,2), size(grd,1), grd.registration]

# ---------------------------------------------------------------------------------------------------
grdvector!(arg1, arg2; kw...) = grdvector(arg1, arg2; first=false, kw...)
grdvector(arg1::Matrix{<:Real}, arg2::Matrix{<:Real}; kw...) = grdvector(mat2grid(arg1), mat2grid(arg2); kw...)
grdvector!(arg1::Matrix{<:Real}, arg2::Matrix{<:Real}; kw...) = grdvector(mat2grid(arg1), mat2grid(arg2); first=false, kw...)
