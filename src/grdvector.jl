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
- $(GMT._opt_B)
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
- $(GMT._opt_R)
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

	# Must call parse_R first to get opt_R that is needed in the get_grdinfo() call.
	cmd, opt_R = parse_R(d, "", O)
	#x_min  x_max  y_min  y_max  z_min  z_max  dx(7)  dy(8)  n_cols(9) n_rows(10)  reg(11) isgeog(12)
	info  = get_grdinfo(arg1, opt_R);		n_cols, n_rows = info[9], info[10]
	info2 = get_grdinfo(arg2, opt_R)
	isa(arg1, String) && (CTRL.limits[1:4] = info[1:4]; CTRL.limits[7:10] = info[1:4])

	def_J = " -JX" * split(def_fig_size, '/')[1] * "/0"
	cmd, opt_J = parse_J(d, cmd, def_J, true, O)
	parse_theme(d)		# Must be first because some themes change def_fig_axes
	def_fig_axes_::String = (IamModern[1]) ? "" : def_fig_axes[1]	# def_fig_axes is a global const
	cmd = parse_B(d, cmd, (O ? "" : def_fig_axes_))[1]

	cmd = parse_common_opts(d, cmd, [:UVXY :f :p :t :params], first)[1]
	!(contains(cmd, "-V")) && (cmd *= " -Ve")	# Shut up annoying warnings if -S has no units
	cmd = parse_these_opts(cmd, d, [[:A :polar], [:N :noclip :no_clip], [:T :sign_scale], [:Z :azimuth]])
	opt_S = add_opt(d, "", "S", [:S :vscale :vec_scale],
	                (inverse=("i", nothing, 1), length=("l", arg2str, 1), scale=("",arg2str,2), scale_at_lat="+c", refsize="+s"))
	
	opt_R = (contains(cmd, "-R") && !contains(cmd, " -R ")) ? "" : @sprintf(" -R%.4g/%.14g/%.14g/%.14g", info[1:4]...)
	w,h = get_figsize(opt_R, opt_J)
	max_extrema = max(abs(info[5]), abs(info[6]), abs(info2[5]), abs(info2[6]))	# The max of the absolute extremas
	as = 1.05 * max_extrema * sqrt((n_rows*n_cols) / (w*h))		# Autoscale (approx). Idealy it should be max magnitude.

	opt_I = parse_I(d, "", [:I :inc :increment :spacing], "I")
	multx = multy = 1
	if (opt_I == "")
		# To estimate the "jumping" factor, we use a virtual 'maxlen' that is the maximum length that
		# an arrow will take (times the scale factor). If not given it defaults to fig_width / 20
		maxlen::Float64 = ((val = find_in_dict(d, [:maxlen])[1]) !== nothing) ? val : w/20
		multx = max(1, round(Int, n_cols / (w / maxlen)))
		multy = max(1, round(Int, n_rows / (h / maxlen)))
		opt_I = " -Ix$(multx)/$(multy)"
	else					# Parse the opt_I to get the multx,multy
		ismult = (opt_I[4] == 'x')
		s = (ismult) ? split(opt_I[5:end], "/") : split(opt_I[4:end], "/")
		if (ismult)
			multx = parse(Int, s[1]);	multy = (length(s) > 1) ? parse(Int, s[2]) : multx
		else
			incx = (s[1][end] == 'm') ? parse(Float64, s[1][1:end-1]) / 60 :
			                            (s[1][end] == 's') ? parse(Float64, s[1][1:end-1]) / 3600 : parse(Float64, s[1])
			incy = incx
			if (length(s) > 1)
				incy = (s[2][end] == 'm') ? parse(Float64, s[2][1:end-1]) / 60 :
			                            (s[2][end] == 's') ? parse(Float64, s[2][1:end-1]) / 3600 : parse(Float64, s[2])
			end
			multx = max(1, round(Int, incx/info[7]))
			multy = max(1, round(Int, incy/info[8]))
		end
	end
	as = max(as/multx, as/multy)

	# Now we check if geographical data is used and if yes autoscale must be recomputed. Estimate is a bit worse
	km_u, inv_c = CTRL.proj_linear[1] ? ("", "") : ("k", "i")
	if (!CTRL.proj_linear[1])
		n_plotint = length(1:multx:n_cols) - 1			# number of vectors to plot along horizontal
		km_per_plotint = w / n_plotint * multx * 111.1	# km per plot interval (one for each vec)
		as = km_per_plotint / (max_extrema * 1.05)		# Plus 5% to compensate a bit max_extrema not being max_mag.
	end

	if (opt_S == "")
		opt_S = @sprintf(" -S%s%.8g%s", inv_c, as, km_u)
	elseif (startswith(opt_S, " -S+c") || startswith(opt_S, " -S+s"))	# For legends stuff
		opt_S = @sprintf(" -S%s%.8g%s%s", inv_c, as, km_u, opt_S[4:end])
	end
	cmd *= opt_I * opt_S

	cmd, arg3, = add_opt_cpt(d, cmd, CPTaliases, 'C')
	isa(arg1, String) && (cmd = arg1 * " " * arg2 * cmd; arg1 = arg3; arg2 = arg3 = nothing)

	defLen = @sprintf("%.4g",  sqrt((w*h) / ((length(1:multx:n_cols)-1)*(length(1:multy:n_rows)-1))) / 3)
	defNorm, defHead = @sprintf("%.6g%s", as/2+1e-7, km_u), "yes"

	opt_Q = parse_Q_grdvec(d, [:Q :vec :vector :arrow], defLen, defHead, defNorm)
	!occursin(" -G", opt_Q) && (cmd = add_opt_fill(cmd, d, [:G :fill], 'G'))	# If fill not passed in arrow, try from regular option
	cmd *= add_opt_pen(d, [:W :pen], "W")
	(!occursin(" -C", cmd) && !occursin(" -W", cmd) && !occursin(" -G", opt_Q)) && (cmd *= " -W0.5")	# If still nothing, set -W.
	(opt_Q != "") && (cmd *= opt_Q)

	_cmd = finish_PS_nested(d, ["grdvector " * cmd])
    return finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
function parse_Q_grdvec(d::Dict, symbs::Array{<:Symbol}, len::String="", stop::String="", norm::String="")::String
	# LEN, STOP & NORM are default values (if != "")
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | String")
	cmd::String = ""
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, String))
			(len != "" && !isdigit(val[1])) && (val = len * val)
			cmd = " -Q" * val
		else
			cmd = (len != "" && (findfirst(:len .== fields(val)) === nothing) && (findfirst(:length .== fields(val)) === nothing)) ? " -Q" * len : " -Q"
			cmd *= vector_attrib(val)
		end
		(stop != "" && !contains(cmd, "+e")) && (cmd *= "+e")
		(norm != "" && !contains(cmd, "+n")) && (cmd *= "+n"*norm)
	else
		(len  != "") && (cmd *= len)
		(stop != "") && (cmd *= "+e")
		(norm != "") && (cmd *= "+n"*norm)
		(cmd  != "") && (cmd = " -Q" * cmd)
	end

	if ((ind = findfirst("+g", cmd)) !== nothing)   # -Q0.4+e+gred+n0.4+pcyan+h0
		cmd *= " -G" * split(cmd[ind[1]+2:end], "+")[1]	# Add a -G (does the same) to have at least one of the -G, -W, -C
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
get_grdinfo(grd::String,  opt_R::String) = gmt("grdinfo -C" * opt_R * " " * grd).data
get_grdinfo(grd::GMTgrid, opt_R::String) = gmt("grdinfo -C" * opt_R, grd).data

# ---------------------------------------------------------------------------------------------------
grdvector!(arg1, arg2; kw...) = grdvector(arg1, arg2; first=false, kw...)
grdvector(arg1::Matrix{<:Real}, arg2::Matrix{<:Real}; kw...) = grdvector(mat2grid(arg1), mat2grid(arg2); kw...)
grdvector!(arg1::Matrix{<:Real}, arg2::Matrix{<:Real}; kw...) = grdvector(mat2grid(arg1), mat2grid(arg2); first=false, kw...)
grdvector(arg1::Matrix{<:Real}, arg2::Matrix{<:Real}, arg3::Matrix{<:Real}, arg4::Matrix{<:Real}; kw...) = 
	grdvector(mat2grid(arg3, x=Float64.(arg1[1,:]), y=Float64.(arg2[:,1])), mat2grid(arg4, x=Float64.(arg1[1,:]), y=Float64.(arg2[:,1])); kw...)
grdvector!(arg1::Matrix{<:Real}, arg2::Matrix{<:Real}, arg3::Matrix{<:Real}, arg4::Matrix{<:Real}; kw...) = 
	grdvector(mat2grid(arg3, x=Float64.(arg1[1,:]), y=Float64.(arg2[:,1])), mat2grid(arg4, x=Float64.(arg1[1,:]), y=Float64.(arg2[:,1])); first=false, kw...)

const quiver  = grdvector		# Aliases
const quiver! = grdvector!