"""
	histogram(cmd0::String="", arg1=[]; kwargs...)

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
# ---------------------------------------------------------------------------------------------------
function histogram(cmd0::String="", arg1=[]; caller=[], data=[], K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	length(kwargs) == 0 && isempty(data) && return monolitic("pshistogram", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", caller, O, " -JX12c/12c")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_swap_xy(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If data is a file name, read it and compute a tight -R if this was not provided
	if (isempty(opt_R))  opt_R = " "  end		# So it doesn't try to find the -R in next call
	cmd, arg1, opt_R, opt_i = read_data(data, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)

	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

	cmd = add_opt(cmd, 'A', d, [:A :horizontal])
	cmd = add_opt(cmd, 'D', d, [:D :annot :annotate])
	cmd = add_opt(cmd, 'F', d, [:F :center])
	cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :inquire])
	opt_L = opt_pen(d, 'L', [:L :pen])
	cmd = add_opt(cmd, 'Q', d, [:Q :cumulative])
	cmd = add_opt(cmd, 'S', d, [:S :stairs])
	cmd = add_opt(cmd, 'W', d, [:W :bin :width])
	cmd = add_opt(cmd, 'Z', d, [:Z :kind])
	if (isempty(opt_L) && !contains(cmd, "-G") && !contains(cmd, "-C"))		# If no -L, -G or -C set these defaults
		cmd = cmd * " -G150" * " -L0.5p"
	elseif (!isempty(opt_L))
		cmd = cmd * opt_L
	end

	for symb in [:N :normal]
		if (haskey(d, symb))
			if (isa(d[symb], Number))      cmd = @sprintf("%s -N%d", cmd, d[symb])
			elseif (isa(d[symb], String))  cmd = cmd * " -N" * d[symb]
			elseif (isa(d[symb], Tuple))   cmd = cmd * " -N" * parse_arg_and_pen(d[symb])
			end
			break
		end
	end

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	return finish_PS_module(d, cmd, "", arg1, arg2, [], [], [], [], output, fname_ext, opt_T, K, "pshistogram")
end

# ---------------------------------------------------------------------------------------------------
histogram!(cmd0::String="", arg1=[]; caller=[], data=[], K=true, O=true, first=false, kw...) =
	histogram(cmd0, arg1; caller=caller, data=data, K=K, O=O, first=first, kw...)

histogram(arg1=[]; caller=[], data=[], K=false, O=false, first=true, kw...) =
	histogram("", arg1; caller=caller, data=data, K=K, O=O, first=first, kw...)

histogram!(arg1=[]; caller=[], data=[], K=true, O=true, first=false, kw...) =
	histogram("", arg1; caller=caller, data=data, K=K, O=O, first=first, kw...)