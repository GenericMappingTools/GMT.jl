"""
	contour(cmd0::String="", arg1=[]; kwargs...)

Reads a table data and produces a raw contour plot by triangulation.

Full option list at [`contour`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html)

Parameters
----------

- $(GMT.opt_J)
- **A** : **annot** : -- Str or Number --       Flags = [-|[+]annot_int][labelinfo]

    *annot_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#a)
- $(GMT.opt_B)
- **C** : **cont** : **contours** : **levels** : -- Str or Number or GMTcpt --  Flags = [+]cont_int

    Contours contours to be drawn may be specified in one of three possible ways.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#c)
- **D** : **dump** : -- Str --

    Dump contours as data line segments; no plotting takes place.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#d)
- **E** : **index** : -- Str or Mx3 array --

    Give name of file with network information. Each record must contain triplets of node
    numbers for a triangle.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#e)
- **G** : **labels** : -- Str --

    Controls the placement of labels along the quoted lines.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#g)
- **I** : **colorize** : -- Bool or [] --

    Color the triangles using the color scale provided via **C**.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#i)
- $(GMT.opt_Jz)
- **L** : **mesh** : -- [] or Str or Number --

    Draw the underlying triangular mesh using the specified pen attributes (if not provided, use default pen)
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#l)
- **N** : **no_clip** : --- Bool or [] --

    Do NOT clip contours or image at the boundaries [Default will clip to fit inside region].
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#n)
- $(GMT.opt_P)
- **Q** : **cut** : -- Str or Number --         Flags = [cut[unit]][+z]]

    Do not draw contours with less than cut number of points.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#q)
- **S** : **skip** : -- Str or [] --            Flags = [p|t]

    Skip all input xyz points that fall outside the region.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#s)
- **T** : **ticks** : -- Str --                 Flags = [+|-][+a][+dgap[/length]][+l[labels]]

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#t)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** : **pen** : -- Str or Number --

    Sets the attributes for the particular line.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** : **scale** : -- Str --

    Use to subtract shift from the data and multiply the results by factor before contouring starts.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_bo)
- $(GMT.opt_d)
- $(GMT.opt_di)
- $(GMT.opt_do)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function contour(cmd0::String="", arg1=[]; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("pscontour", cmd0, arg1)

	arg2 = []       # May will contain a CPT or a Mx3 indices array
	arg3 = []       # May will contain a Mx3 indices array
	N_args = isempty_(arg1) ? 0 : 1

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
    cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd = parse_common_opts(d, cmd, [:UVXY :bo :d :di :do :e :h :p :t :yx :params])
	cmd = parse_these_opts(cmd, d, [[:D :dump], [:G :labels], [:I :colorize], [:L :mesh], [:N :no_clip],
				[:Q :cut], [:S :skip], [:T :ticks], [:W :pen]])

	# If file name sent in, read it and compute a tight -R if this was not provided
    cmd, arg1, opt_R, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)
    cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)
    
	cmd = add_opt(cmd, 'A', d, [:A :annot])
	if (!occursin(" -C", cmd))			# Otherwise ignore an eventual :cont because we already have it
		cmd = add_opt(cmd, 'C', d, [:cont :contours :levels])
	end

	if ((val = find_in_dict(d, [:E :index])[1]) !== nothing)
		if (isa(val, Array{Int}))
			cmd = string(cmd, " -E")
			# Now need to find the free slot where to store the indices array
			if (N_args == 0)      arg1 = val
			elseif (N_args == 1)  arg2 = val
			else                  arg3 = val
			end
		else
			cmd = string(cmd, " -E", arg2str(val))
		end
	end

	if (!occursin(" -W", cmd) && !occursin(" -I", cmd))		# Use default pen
		cmd = cmd * " -W"
	end

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, "-D", output, fname_ext, opt_T, K, "pscontour", arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
contour!(cmd0::String="", arg1=[]; first=false, kw...) = contour(cmd0, arg1; first=false, kw...)
contour(arg1, cmd0::String=""; first=true, kw...) = contour(cmd0, arg1; first=first, kw...)
contour!(arg1, cmd0::String=""; first=false, kw...) = contour(cmd0, arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
const pscontour  = contour
const pscontour! = contour!