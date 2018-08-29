"""
	grdcontour(cmd0::String="", arg1=[]; kwargs...)

Reads a 2-D grid file or a GMTgrid type and produces a contour map by tracing each
contour through the grid.

Full option list at [`pscontour`](http://gmt.soest.hawaii.edu/doc/latest/pscontour.html)

Parameters
----------

- $(GMT.opt_J)
- **A** : **annot** : -- Str or Number --

    Save an image in a raster format instead of PostScript.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#a)
- $(GMT.opt_B)
- **C** : **cont** : **contours** : **levels** : -- Str or Number --

    Contours to be drawn.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#c)
- **D** : **dump** : -- Str --

    Dump contours as data line segments; no plotting takes place.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#d)
- **F** : **force** : -- Str or [] --

    Force dumped contours to be oriented so that higher z-values are to the left (-Fl [Default]) or right.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#f)
- **G** : **labels** : -- Str --

    Controls the placement of labels along the quoted lines.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#g)
- $(GMT.opt_Jz)
- **L** : **range** : -- Str --

    Limit range: Do not draw contours for data values below low or above high.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#l)
- $(GMT.opt_P)
- **Q** : **cut** : -- Str or Number --

    Do not draw contours with less than cut number of points.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#q)
- **S** : **smooth** : -- Number --

    Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#s)
- **T** : **ticks** : -- Str --

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#t)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** : **pen** : -- Str or Number --

    Sets the attributes for the particular line.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** : **scale** : -- Str --

    Use to subtract shift from the data and multiply the results by factor before contouring starts.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#z)
- $(GMT.opt_bo)
- $(GMT.opt_do)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function grdcontour(cmd0::String="", arg1=[], arg2=[]; data=[], K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("grdcontour", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	cmd  = ""
    cmd, opt_B, opt_J, = parse_BJR(d, cmd0, cmd, "", O, " -JX12c/0")
	cmd  = parse_UVXY(cmd, d)
	cmd, = parse_bo(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd  = parse_params(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt(cmd, 'A', d, [:A :annot])
	cmd = add_opt(cmd, 'C', d, [:C :cont :contours :levels])
	for sym in [:color :cmap]		# If a CPT is being used
		if (haskey(d, sym))
			if (isa(d[sym], GMTcpt))
				cmd, N_cpt = put_in_slot(cmd, d[sym], 'C', [arg1, arg2])
				if (N_cpt == 1)     arg1 = d[sym]
				elseif (N_cpt == 2) arg2 = d[sym]
				end
			end
			break
		end
	end
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'F', d, [:F :force])
	cmd = add_opt(cmd, 'G', d, [:G :labels])
	cmd = add_opt(cmd, 'L', d, [:L :range])
	cmd = add_opt(cmd, 'Q', d, [:Q :cut])
	cmd = add_opt(cmd, 'S', d, [:S :smooth])
	cmd = add_opt(cmd, 'T', d, [:T :ticks])
	cmd = add_opt(cmd, 'W', d, [:W :pen])
	cmd = add_opt(cmd, 'Z', d, [:Z :scale])

	# In case DATA holds a grid file name, copy it into cmd. If Grids put them in ARG1
	cmd, arg1, = read_data(data, cmd, arg1)

	cmd = finish_PS(d, cmd0, cmd, output, K, O)
    return finish_PS_module(d, cmd, "-D", arg1, arg2, [], [], [], [], output, fname_ext, opt_T, K, "grdcontour")
end

# ---------------------------------------------------------------------------------------------------
grdcontour!(cmd0::String="", arg1=[], arg2=[]; data=[], K=true, O=true, first=false, kw...) =
	grdcontour(cmd0, arg1, arg2; data=data, K=true, O=true, first=false, kw...)

grdcontour(arg1::GMTgrid, cmd0::String="", arg2=[]; data=[], K=false, O=false, first=true, kw...) =
	grdcontour(cmd0, arg1, arg2; data=data, K=K, O=O, first=first, kw...)

grdcontour!(arg1::GMTgrid, cmd0::String="", arg2=[]; data=[], K=true, O=true, first=false, kw...) =
	grdcontour(cmd0, arg1, arg2; data=data, K=true, O=true, first=false, kw...)