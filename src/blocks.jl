"""
    blockmean`(cmd0::String="", arg1=[]; kwargs...)

Block average (x,y,z) data tables by L2 norm.
	
Full option list at [`blockmean`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --
	*x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#i)
- **A** : **fields** : -- Str --
	Select which fields to write to individual grids. Append comma-separated codes for available
	fields: **z** (the mean data z, but see **-S**), **s** (standard deviation), **l** (lowest value),
	**h** (highest value) and **w** (the output weight; requires **-W**). [Default is just **z**].
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#a)
- **C** : **center** : -- Bool --
    Use the center of the block as the output location [Default uses the mean location]. Not used when **-A**
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#c)
- **E** : **extend** : -- Str or [] --
	Provide Extended report which includes s (the standard deviation about the mean), l, the lowest
	value, and h, the high value for each block. Output order becomes x,y,z,s,l,h[,w]. [Default
	outputs x,y,z[,w]. See -W for w output. If -Ep is used we assume weights are 1/(sigma squared)
	and s becomes the propagated error of the mean.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#e)
- **G** : **grid** : -- Str or [] --
	Write one or more fields directly to grids on disk; no table data are return. If more than one
	fields are specified via -A then grdfile must contain the format flag %s so that we can embed the
	field code in the file names. If not provided but **-A** is used, return 1 or more GMTgrid type(s).
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#g)
- **S** : **npts** : **number_of_points** -- Str or [] --  
	Use -Sn to report the number of points inside each block, -Ss to report the sum of all z-values 
	inside a block, -Sw to report the sum of weights [Default (or -Sm reports mean value].
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#s)
- **W** : **weights** : -- Str or [] --
	Unweighted input and output have 3 columns x,y,z; Weighted i/o has 4 columns x,y,z,w. Weights can
	be used in input to construct weighted mean values for each block.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/blockmean.html#w)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
# ---------------------------------------------------------------------------------------------------
function blockmean(cmd0::String="", arg1=[]; data=[], kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("blockmean", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = ""
	cmd = add_opt(cmd, 'E', d, [:E :extended])
	cmd = add_opt(cmd, 'S', d, [:S :npts :number_of_points])
	return common_blocks(cmd0, arg1, data, d, cmd, "blockmean", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    blockmedian`(cmd0::String="", arg1=[]; kwargs...)

Block average (x,y,z) data tables by L1 norm.
	
Full option list at [`blockmedian`](http://gmt.soest.hawaii.edu/doc/latest/blockmedian.html)
"""
function blockmedian(cmd0::String="", arg1=[]; data=[], kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("blockmedian", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = ""
	cmd = add_opt(cmd, 'E', d, [:E :extended])
	cmd = add_opt(cmd, 'Q', d, [:Q :quick])
	cmd = add_opt(cmd, 'T', d, [:T :quantile])
	return common_blocks(cmd0, arg1, data, d, cmd, "blockmedian", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    blockmode`(cmd0::String="", arg1=[]; kwargs...)

Block average (x,y,z) data tables by mode estimation.
	
Full option list at [`blockmode`](http://gmt.soest.hawaii.edu/doc/latest/blockmode.html)
"""
function blockmode(cmd0::String="", arg1=[]; data=[], kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("blockmode", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = ""
	cmd = add_opt(cmd, 'E', d, [:E :extended])
	cmd = add_opt(cmd, 'D', d, [:D :histogram_binning])
	cmd = add_opt(cmd, 'Q', d, [:Q :quick])
	return common_blocks(cmd0, arg1, data, d, cmd, "blockmode", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function common_blocks(cmd0, arg1, data, d, cmd, proggy, kwargs...)

	cmd, opt_R = parse_R(cmd, d)
	cmd = parse_V(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_o(cmd, d)
	cmd = parse_r(cmd, d)
	cmd = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :fields])
	cmd = add_opt(cmd, 'C', d, [:C :center])
	cmd = add_opt(cmd, 'G', d, [:G :grid])
	ff = findfirst("-G", cmd)
    ind = (ff == nothing) ? 0 : first(ff)
	if (ind > 0 && length(cmd) > ind+2)      # A file name was provided
        no_output = true
    else
        no_output = false
    end
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'W', d, [:W :weights])

    cmd, arg1, = read_data(data, cmd, arg1)

	(haskey(d, :Vd)) && println(@sprintf("\t%s %s", proggy, cmd))

	if (no_output)
		if (!isempty_(arg1))  gmt(proggy * " " * cmd, arg1)
		else                  gmt(proggy * " " * cmd)
		end
		return nothing
	else
		if (!isempty_(arg1))  O = gmt(proggy * " " * cmd, arg1)
		else                  O = gmt(proggy * " " * cmd)
		end
		[return O[k] for k=1:length(O)]
	end
end

# ---------------------------------------------------------------------------------------------------
blockmean(arg1::GMTdataset, cmd0::String=""; data=[], kw...) = blockmean(cmd0, arg1; data=data, kw...)
blockmean(arg1::Array, cmd0::String=""; data=[], kw...) = blockmean(cmd0, arg1; data=data, kw...)
# ---------------------------------------------------------------------------------------------------
blockmedian(arg1::GMTdataset, cmd0::String=""; data=[], kw...) = blockmedian(cmd0, arg1; data=data, kw...)
blockmedian(arg1::Array, cmd0::String=""; data=[], kw...) = blockmedian(cmd0, arg1; data=data, kw...)
# ---------------------------------------------------------------------------------------------------
blockmode(arg1::GMTdataset, cmd0::String=""; data=[], kw...) = blockmode(cmd0, arg1; data=data, kw...)
blockmode(arg1::Array, cmd0::String=""; data=[], kw...) = blockmode(cmd0, arg1; data=data, kw...)