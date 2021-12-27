"""
    blockmean(cmd0::String="", arg1=nothing; kwargs...)

Block average (x,y,z) data tables by L2 norm.
	
Full option list at [`blockmean`]($(GMTdoc)blockmean.html)

Parameters
----------

- $(GMT.opt_R)
- $(GMT.opt_I)
    ($(GMTdoc)blockmean.html#i)
- **A** | **field** | **fields** :: [Type => Str]

    Select which fields to write to individual grids. Append comma-separated codes for available
    fields: **z** (the mean data z, but see **statistic**), **s** (standard deviation), **l** (lowest value),
    **h** (highest value) and **w** (the output weight; requires **weights**). [Default is just **z**].
    ($(GMTdoc)blockmean.html#a)
- **C** | **center** :: [Type => Bool]

    Use the center of the block as the output location [Default uses the mean location]. Not used when **-A**
    ($(GMTdoc)blockmean.html#c)
- **E** | **extend** | **extended** :: [Type => Str | []]

    Provide Extended report which includes s (the standard deviation about the mean), l, the lowest
    value, and h, the high value for each block. Output order becomes x,y,z,s,l,h[,w]. [Default
    outputs x,y,z[,w]. See -W for w output. If -Ep is used we assume weights are 1/(sigma squared)
    and s becomes the propagated error of the mean.
    ($(GMTdoc)blockmean.html#e)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Write one or more fields directly to grids on disk; no table data are return. If more than one
    fields are specified via **A** then grdfile must contain the format flag %s so that we can embed the
    field code in the file names. If not provided but **A** is used, return 1 or more GMTgrid type(s).
    ($(GMTdoc)blockmean.html#g)
- **S** | **statistic** :: [Type => Str | Symb] 

    Use `statistic=:n` to report the number of points inside each block, `statistic=:s` to report the sum of all z-values 
    inside a block, `statistic=:w` to report the sum of weights [Default (or `statistic=:m` reports mean value].
    ($(GMTdoc)blockmean.html#s)
- **mean** :: [Type => Any] 

    Report the mean value of points inside each block
- **npts** | **counts** :: [Type => Any] 

    Report the number of points inside each block
- **sum** :: [Type => Any] 

    Report the sum of all z-values inside each block
- **sum_weights** :: [Type => Any] 

    Report the the sum of weights
- **grid** :: [Type => Bool] 

    With any of the above options (`statistic`, `npts`, `sum`) this option makes it return a grid instead of a GMTdataset.
- **W** | **weights** :: [Type => Str | []]

    Unweighted input and output have 3 columns x,y,z; Weighted i/o has 4 columns x,y,z,w. Weights can
    be used in input to construct weighted mean values for each block.
    ($(GMTdoc)blockmean.html#w)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_q)
- $(GMT.opt_r)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function blockmean(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("blockmean", cmd0, arg1)

	d = KW(kwargs)
	help_show_options(d)		# Check if user wants ONLY the HELP mode
	cmd = parse_these_opts("", d, [[:S :statistic]])
	if     (find_in_dict(d, [:npts :count])[1] !== nothing)  cmd = " -Sn"
	elseif (find_in_dict(d, [:mean])[1] !== nothing)         cmd = " -Sm"
	elseif (find_in_dict(d, [:sum])[1] !== nothing)          cmd = " -Ss"
	elseif (find_in_dict(d, [:sum_weights])[1] !== nothing)  cmd = " -Sw"
	end
	opt_A = add_opt(d, "", "A", [:A :field :fields], (mean="_z", std="_s", highest="_h", lowest="_l", weight="_w", weights="_w"))
	(!occursin(" -E", cmd) && (occursin("s", opt_A) || occursin("h", opt_A) || occursin("l", opt_A))) && (opt_A *= " -E")
	cmd *= opt_A

	common_blocks(cmd0, arg1, d, cmd, "blockmean", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    blockmedian(cmd0::String="", arg1=nothing; kwargs...)

Block average (x,y,z) data tables by L1 norm.
	
Full option list at [`blockmedian`]($(GMTdoc)blockmedian.html)
"""
function blockmedian(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("blockmedian", cmd0, arg1)

	d = KW(kwargs)
	help_show_options(d)		# Check if user wants ONLY the HELP mode
	cmd = parse_these_opts("", d, [[:Q :quick], [:T :quantile]])
	opt_A = add_opt(d, "", "A", [:A :field :fields], (median="_z", scale="_s", highest="_h", lowest="_l", weight="_w", weights="_w"))
	(!occursin(" -E", cmd) && (occursin("s", opt_A) || occursin("h", opt_A) || occursin("l", opt_A))) && (opt_A *= " -E")
	cmd *= opt_A
	common_blocks(cmd0, arg1, d, cmd, "blockmedian", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    blockmode(cmd0::String="", arg1=nothing; kwargs...)

Block average (x,y,z) data tables by mode estimation.
	
Full option list at [`blockmode`]($(GMTdoc)blockmode.html)
"""
function blockmode(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("blockmode", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd = parse_these_opts("", d, [[:D :histogram_binning], [:Q :quick]])
	opt_A = add_opt(d, "", "A", [:A :field :fields], (mode="_z", scale="_s", highest="_h", lowest="_l", weight="_w", weights="_w"))
	(!occursin(" -E", cmd) && (occursin("s", opt_A) || occursin("h", opt_A) || occursin("l", opt_A))) && (opt_A *= " -E")
	cmd *= opt_A

	common_blocks(cmd0, arg1, d, cmd, "blockmode", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function common_blocks(cmd0, arg1, d, cmd, proggy, kwargs...)

	cmd = parse_these_opts(cmd, d, [[:C :center], [:E :extend :extended], [:W :weights]])
	opt_G = parse_G(d, "")[1]

	if (opt_G != "" && !occursin("-A", cmd))
		cmd = cmd * " -Az"					    # So that we can use plain -G to mean write grid 
	end
	(length(opt_G) > 3) && (cmd *= opt_G)	    # G=true will give " -G", which we'll ignore  (Have to)
	cmd, = parse_common_opts(d, cmd, [:RIr :V_params :bi :di :e :f :h :i :o :w :yx])

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)
	do_grid = (proggy == "blockmean" && startswith(cmd, " -S") && find_in_dict(d, [:grid])[1] !== nothing)
	R = common_grd(d, proggy * " " * cmd, arg1)		# Finish build cmd and run it
	
	(!do_grid || isa(R, String)) && return R		# Vd = 2 makes R be a string

	# User asked to output the result of -S as a grid (not allowed in GMT), so call xyz2grd
	opt_R = scan_opt(cmd, "-R")
	opt_I = scan_opt(cmd, "-I")
	opt_r = ((r = scan_opt(cmd, "-r")) == "") ? "g" : r
	xyz2grd(R, R=opt_R, I=opt_I, r=opt_r)
end

# ---------------------------------------------------------------------------------------------------
blockmean(arg1, cmd0::String=""; kw...) = blockmean(cmd0, arg1; kw...)
# ---------------------------------------------------------------------------------------------------
blockmedian(arg1, cmd0::String=""; kw...) = blockmedian(cmd0, arg1; kw...)
# ---------------------------------------------------------------------------------------------------
blockmode(arg1, cmd0::String=""; kw...) = blockmode(cmd0, arg1; kw...)
