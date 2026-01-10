"""
	trend1d(cmd0::String="", arg1=nothing, kwargs...)

Fit a [weighted] [robust] polynomial/Fourier model for y = f(x) to xy[w] data.

See full GMT docs at [`trend1d`]($(GMTdoc)trend1d.html)

Parameters
----------

- **F** | **out** | **output** :: [Type => Str]   ``Arg = xymrw|p|P|c``

    Specify up to five letters from the set {x y m r w} in any order to create columns of output. 
- **N** | **model** :: [Type => Str]      ``Arg = [p|P|f|F|c|C|s|S|x]n[,…][+llength][+oorigin][+r]``

    Specify Specify the number of terms in the model, n_model, and append +r to do a robust fit. E.g., a robust bilinear model is -N4+r.
- **C** | **condition_number** :: [Type => Number]   ``Arg = condition_number``

    Set the maximum allowed condition number for the matrix solution.
- **I** | **conf_level** :: [Type => Number | []]   ``Arg = [conf_level]``

    Iteratively increase the number of model parameters, starting at one, until n_model is reached
    or the reduction in variance of the model is not significant at the conf_level level.
- **T** | **equi_space** :: [Type => Str | List]     ``Arg = [min/max/]inc[+a|n]] or file|list``

    Evaluate the best-fit regression model at the equidistant points implied by the arguments.
- **W** | **weights** :: [Type => Str | []]     ``Arg = [+s]``

    Weights are supplied in input column 3. Do a weighted least squares fit [or start with
    these weights when doing the iterative robust fit].
- $(opt_V)
- $(opt_b)
- $(opt_d)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_i)
- $(opt_w)
- $(opt_swap_xy)

To see the full documentation type: ``@? trend1d``
"""
function trend1d(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :h :i :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :condition_number], [:I :conf_level :confidence_level], [:F :out :output], [:T :equi_space], [:W :weights]])
	opt_F = scan_opt(cmd, "-F")
	((val = find_in_dict(d, [:N :model], false)[1]) === nothing) && error("The option 'model' must be specified")
	if (isa(val, Tuple) && isa(val[1], NamedTuple))
		# Complicated case here -- A mixed model ---. So input must be a Tuple of NamedTuples, and the +l+o+r options
		# can only be used once and in the last NT element. Hence, we must split execution in two parts.
		opt_N = " -N"
		for k = 1:length(val)-1
			t = add_opt(Dict(:N => val[k]), "", "N", [:N],
			            (polynome=("p", arg2str, 1), polynomal=("p", arg2str, 1), fourier=("f", arg2str, 1), cosine=("c", arg2str, 1), sine=("s", arg2str, 1), single="_!"))
			contains(t, "!") && (t = replace(t, "!" => ""); t = replace(t, t[4] => uppercase(t[4])))
			opt_N *= t[4:end] * ","
		end
		t = add_opt(Dict(:N => val[end]), "", "N", [:N],
		            (polynome=("p", arg2str, 1), polynomal=("p", arg2str, 1), fourier=("f", arg2str, 1), cosine=("c", arg2str, 1), sine=("s", arg2str, 1), length="+l", origin="+o", robust="+r", single="_!"))
		contains(t, "!") && (t = replace(t, "!" => ""); t = replace(t, t[4] => uppercase(t[4])))
		opt_N *= t[4:end]
		delete!(d, [:N :model])
	else
		opt_N = add_opt(d, "", "N", [:N :model],
		                (polynome=("p", arg2str, 1), polynomal=("p", arg2str, 1), fourier=("f", arg2str, 1), cosine=("c", arg2str, 1), sine=("s", arg2str, 1), length="+l", origin="+o", robust="+r", single="_!"))
		# If we have a '!' it means we are doing a single term version. Need to replace model code to an upper letter.
		contains(opt_N, "!") && (opt_N = replace(opt_N, "!" => ""); opt_N = replace(opt_N, opt_N[4] => uppercase(opt_N[4])))
	end
	(tryparse(Int, opt_N[4:end]) !== nothing) && (opt_N = " -Np" * opt_N[4:end])	# -N2 is old syntax and will error GMT
	cmd *= opt_N

	R = common_grd(d, cmd0, cmd, "trend1d ", arg1)		# Finish build cmd and run it
	!isa(R, GDtype) && return R							# Should be the output of Vd=2

	if (opt_F != "")		# Extract column names from opt_F
		if (opt_F[1] == 'p' || opt_F[1] == 'P' || opt_F[1] == 'c')
			colnames = ["a$i" for i=0:size(D,2)-1]
		else
			cnames = (isa(arg1, GDtype)) ? (isa(arg1, GMTdataset) ? arg1.colnames : arg1[1].colnames) : String[]
			s = collect(opt_F)
			colnames = Vector{String}(undef, length(s))
			for k = 1:numel(s)
				if     (s[k] == 'x')  colnames[k] = isempty(cnames) ? "x" : cnames[1]
				elseif (s[k] == 'y')  colnames[k] = isempty(cnames) ? "y" : cnames[2]
				elseif (s[k] == 'm')  colnames[k] = "model"
				elseif (s[k] == 'r')  colnames[k] = "residues"
				elseif (s[k] == 'w')  colnames[k] = "weights"
				end
			end
		end
		isa(R, GMTdataset) ? (R.colnames = colnames) : (R[1].colnames = colnames)
		(!isempty(cnames) && cnames[1] == "Time") && settimecol!(R, 1)		# Set time column
	end
	return R
end

# ---------------------------------------------------------------------------------------------------
trend1d(arg1; kw...) = trend1d("", arg1; kw...)