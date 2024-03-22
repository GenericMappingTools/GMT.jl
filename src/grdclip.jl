"""
	grdclip(cmd0::String="", arg1=nothing; kwargs...)

Clip the range of grid values. will set values < low to below and/or values > high to above.
You can also specify one or more intervals where all values should be set to ``between``,
or replace individual values.

See full GMT (not the `GMT.jl` one) docs at [`grdclip`]($(GMTdoc)grdclip.html)

Parameters
----------

- **cmd0** :: [Type => Str]

    The input file name. Do not use this when the grid (a GMTgrid type) is passed via the ``arg1`` argument.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdclip(....) form.
- $(_opt_R)
- **above** | **high** :: [Type => Array | Str]

    Two elements array with ``high`` and ``above`` or a string with "high/above".
    It sets all data[i] > ``high`` to ``above``.
- **below** | **low** :: [Type => Array | Str]

    Two elements array with ``low`` and ``below`` or a string with "low/below".
    It sets all data[i] < ``low`` to ``below``.
- **between** :: [Type => Array | Str]

    Three elements array with ``low, high`` and ``between`` or a string with "low/high/between".
    It sets all data[i] >= ``low`` and <= ``high`` to ``between``.
- **old** | **new** :: [Type => Array | Str]

    Two elements array with ``old`` and ``new`` or a string with "old/new".
    It sets all data[i] == ``old`` to ``new``.
- **S** :: [Type => Str]

    Condense all replacement options above in a single string.
- $(opt_V)

-   Examples:

        G=gmt("grdmath", "-R0/10/0/10 -I1 X");
        G2=grdclip(G, above=[5 6], low=[2 2], between="3/4/3.5")

    or (note the use of -S for second on options because we can't repeat a kwarg name)

        G2=grdclip(G, S="a5/6 -Sb2/2 -Si3/4/3.5")
"""
grdclip(cmd0::String; kwargs...) = grdclip_helper(cmd0, nothing; kwargs...)
grdclip(arg1; kwargs...)         = grdclip_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function grdclip_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:G :R :V_params])
	cmd  = add_opt(d, cmd, "S", [:S])
	cmd  = opt_S(d, cmd, [:high :above], 'a')
	cmd  = opt_S(d, cmd, [:low :below], 'b')
	cmd  = opt_S(d, cmd, [:old :new], 'r')
	cmd  = opt_S(d, cmd, [:between], 'i')

	common_grd(d, cmd0, cmd, "grdclip ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
function opt_S(d::Dict, cmd::String, symbs, flag::Char)
	# This is common to the 4 cases
	val, symb = find_in_dict(d, symbs)
	if (val !== nothing)
		cmd = string(cmd, " -S", flag)
		if (isa(val, String))
			cmd *= val
		elseif (isa(val, Array) || isa(val, Tuple))
			if (symb == :between && length(val) == 3)
				cmd = @sprintf("%s%.16g/%.16g/%.16g", cmd, val[1], val[2], val[3])
			elseif (length(val) == 2)
				cmd = @sprintf("%s%.16g/%.16g", cmd, val[1], val[2])
			else
				error("Wrong number of elements in S option")
			end
		else
			error("OPT_S: argument must be a string or a two elements array.")
		end
	end
	return cmd
end