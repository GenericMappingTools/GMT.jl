"""
	makecpt(cmd0::String="", arg1=[]; kwargs...)

Make static color palette tables (CPTs).

Full option list at [`makecpt`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html)

- **A** : **alpha** : **transparency** : -- Str --

    Sets a constant level of transparency (0-100) for all color slices.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#a)
- $(GMT.opt_C)
- **D** : -- Str or [] --			Flags = [i|o]

    Select the back- and foreground colors to match the colors for lowest and highest
    z-values in the output CPT. 
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#d)
- **E** : **data_levels** : -- Int or [] --		Flags = [nlevels]

    Implies reading data table(s) from file or arrays. We use the last data column to
    determine the data range
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#e)
- **F** : **force_rgb** : -- Str or [] --		Flags = [R|r|h|c][+c]]

    Force output CPT to written with r/g/b codes, gray-scale values or color name.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#f)
- **G** : **truncate** : -- Str --              Flags = zlo/zhi

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#g)
- **I** : **inverse** : **reverse** : -- Str --	Flags = [c][z]

    Reverse the sense of color progression in the master CPT.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#i)
- **M** : **overrule_bg** -- Bool or [] --

    Overrule background, foreground, and NaN colors specified in the master CPT with the values of
    the parameters COLOR_BACKGROUND, COLOR_FOREGROUND, and COLOR_NAN.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#m)
- **N** : **no_bg** -- Bool or [] --

    Do not write out the background, foreground, and NaN-color fields.
- **Q** : **log** : -- Bool or [] or Str --			Flags = [i|o]

    Selects a logarithmic interpolation scheme [Default is linear].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#q)
- **S** : **auto** : -- Bool or [] or Str --			Flags = [mode]

    Determine a suitable range for the -T option from the input table(s) (or stdin).
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#s)
- **T** : **range** : -- Str --			Flags = [min/max/inc[+b|l|n]|file|list]

    Defines the range of the new CPT by giving the lowest and highest z-value and interval.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#t)
- **W** : **wrap** : **categorical** : -- Bool or Str or [] --      Flags = [w]

    Do not interpolate the input color table but pick the output colors starting at the
    beginning of the color table, until colors for all intervals are assigned.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#w)
- **Z** : **continuous** : -- Bool or [] --

    Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/makecpt.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_i)
"""
function makecpt(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("makecpt", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = parse_V_params("", d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_bi(cmd, d)
	cmd, opt_i = parse_i(cmd, d)

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, " ", opt_i, opt_bi, opt_di)
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1, [])

	for sym in [:E :data_levels]
		if (haskey(d, sym))
			if (isempty_(arg1) && isempty_(data))
				error("E option requires that a data table is provided as well")
			else
				cmd = cmd * " -E" * arg2str(d[sym])
			end
			break
		end
	end

	cmd = add_opt(cmd, 'A', d, [:A :alpha :transparency])
	cmd = add_opt(cmd, 'D', d, [:D :bg :background])
	cmd = add_opt(cmd, 'F', d, [:F :force_rgb])
	cmd = add_opt(cmd, 'G', d, [:G :truncate])
	cmd = add_opt(cmd, 'I', d, [:I :inverse :reverse])
	cmd = add_opt(cmd, 'M', d, [:M :overrule_bg])
	cmd = add_opt(cmd, 'N', d, [:N :no_bg])
	cmd = add_opt(cmd, 'Q', d, [:Q :log])
	cmd = add_opt(cmd, 'S', d, [:S :auto])
	cmd = add_opt(cmd, 'T', d, [:T :range])
	cmd = add_opt(cmd, 'W', d, [:W :wrap :categorical])
	cmd = add_opt(cmd, 'Z', d, [:Z :continuous])

	if (haskey(d, :cptname))
		cmd = cmd * " > " * d[:cptname]
		C = gmt("makecpt " * cmd)
		(haskey(d, :Vd)) && println(@sprintf("\tmakecpt %s", cmd))
	else
		(haskey(d, :Vd)) && println(@sprintf("\tmakecpt %s", cmd))
		if (isempty_(arg1))
			C = gmt("makecpt " * cmd)
		else
			C = gmt("makecpt " * cmd, arg1)
		end
	end
end

# ---------------------------------------------------------------------------------------------------
# Version to use with the -E option
#makecpt(arg1=[]; kw...) = makecpt("", arg1; kw...)
