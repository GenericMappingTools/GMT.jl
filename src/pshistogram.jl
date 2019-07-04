"""
	histogram(cmd0::String="", arg1=nothing; kwargs...)

Reads file and examines the first data column to calculate histogram parameters based on the bin-width provided.

Full option list at [`pshistogram`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html)

Parameters
----------

- $(GMT.opt_J)
- **W** : **bin** : **width** : -- Number or Str --

    Sets the bin width used for histogram calculations.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#w)
- **A** : **horizontal** : -- Bool or [] --

    Plot the histogram horizontally from x = 0 [Default is vertically from y = 0].
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#a)
- $(GMT.opt_B)
- **C** : **color** : -- Str or GMTcpt --

    Give a CPT. The mid x-value for each bar is used to look-up the bar color.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#c)
- **D** : **annot** : **annotate** : -- Str or [] --

    Annotate each bar with the count it represents.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#d)
- **F** : **center** : -- Bool or [] --

    Center bin on each value. [Default is left edge].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#f)
- **G** : **fill** : -- Number or Str --

    Select filling of bars [if no G, L or C set G=100].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#g)
- **I** : **inquire** : -- Bool or [] --

    Inquire about min/max x and y after binning.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#i)
- **L** : **labels** : -- Str or [] --

    Draw bar outline using the specified pen thickness [if no G, L or C set L=0.5].
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#l)
- **N** : **normal** : -- Str --

    Draw the equivalent normal distribution; append desired pen [0.5p,black].
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#n)
- $(GMT.opt_P)
- **Q** : **alpha** : -- Number or [] --

    Sets the confidence level used to determine if the mean resultant is significant.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#q)
- **R** : **region** : -- Str --

    Specifies the ‘region’ of interest in (r,azimuth) space. r0 is 0, r1 is max length in units.
    [`-R`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#r)
- **S** : **stairs** : -- Str or number --

    Draws a stairs-step diagram which does not include the internal bars of the default histogram.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#s)
- **Z** : **kind** : -- Number or Str --

    Choose between 6 types of histograms.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#z)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function histogram(cmd0::String="", arg1=nothing; first=true, kwargs...)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	length(kwargs) == 0 && return monolitic("pshistogram", cmd0, arg1, arg2)

	d = KW(kwargs)

	# If inquire, no plotting so do it and return
	cmd = add_opt("", 'I', d, [:I :inquire])
	if (cmd != "")
		cmd = add_opt(cmd, 'W', d, [:W :bin :width])
		(haskey(d, :Vd)) && println(@sprintf("\tpshistogram %s", cmd))
		return gmt("pshistogram " * cmd, arg1)
	end

	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "histogram", O, " -JX12c/12c")
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :p :t :yx :params], first)
	cmd = parse_these_opts(cmd, d, [[:A :horizontal], [:D :annot :annotate], [:F :center],
				[:Q :cumulative], [:S :stairs]])
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd = add_opt(cmd, 'Z', d, [:Z :kind],
		(counts="0", freq="1", log_count="2", log_freq="3", log10_count="4", log10_freq="5", weights="+w"))

	# If file name sent in, read it and compute a tight -R if this was not provided
	if (opt_R == "")  opt_R = " "  end		# So it doesn't try to find the -R in next call
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

	if (GMTver >= 6)
		cmd   = add_opt(cmd, 'T', d, [:T :bin :width])
		cmd   = add_opt(cmd, 'L', d, [:L :out_range])
		cmd  *= add_opt_pen(d, [:W :pen], "W")
		if (!occursin("-G", cmd) && !occursin("-C", cmd) && !occursin("-I", cmd))
			cmd *= " -L0.5p -G150"		# If no -L, -G, -I or -C set these defaults
		end
	else
		cmd = add_opt(cmd, 'W', d, [:W :bin :width]) * add_opt_pen(d, [:L :pen], "L")
		if (!occursin("-G", cmd) && !occursin("-C", cmd) && !occursin("-L", cmd) && !occursin("-I", cmd))
			cmd *= " -L0.5p -G150"		# If no -L, -G, -I or -C set these defaults
		end
	end

	if ((val = find_in_dict(d, [:N :normal])[1]) !== nothing)
		if (isa(val, Number) || isa(val, String))  cmd  = string(cmd, " -N", val)
		elseif (isa(val, Tuple))                   cmd *= " -N" * parse_arg_and_pen(val)
		end
	end

	return finish_PS_module(d, "pshistogram " * cmd, "", output, fname_ext, opt_T, K, O, true, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
histogram!(cmd0::String="", arg1=nothing; first=false, kw...) = histogram(cmd0, arg1; first=first, kw...)

histogram(arg1; first=true, kw...) = histogram("", arg1; first=first, kw...)
histogram!(arg1; first=false, kw...) = histogram("", arg1; first=first, kw...)

const pshistogram  = histogram			# Alias
const pshistogram! = histogram!			# Alias