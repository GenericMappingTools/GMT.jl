"""
	mask(cmd0::String="", arg1=[]; kwargs...)

Reads (length,azimuth) pairs from file and plot a windmask diagram.

Full option list at [`psmask`](http://gmt.soest.hawaii.edu/doc/latest/mask.html)

Parameters
----------

- **I** : **inc** : -- Str or Number --

    Set a fixed azimuth projection for masks [Default uses track azimuth, but see -A].
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#i)
- $(GMT.opt_R)

- $(GMT.opt_B)
- **C** : **end_clip_path** : -- Bool or [] --

    Mark end of existing clip path. No input file is needed.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#C)
- **D** : **dump** : -- Str --

    Dump the (x,y) coordinates of each clipping polygon to one or more output files
    (or stdout if template is not given).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#d)
- **F** : **oriented_polygons** : -- Str or [] --

    Force clip contours (polygons) to be oriented so that data points are to the left (-Fl [Default]) or right (-Fr) 
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#f)
- **G** : **fill** : -- Number or Str --

    Set fill shade, color or pattern for positive and/or negative masks [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#g)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- **L** : **node_grid** : -- Str --

    Save the internal grid with ones (data constraint) and zeros (no data) to the named nodegrid.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#l)
- **N** : **invert** : -- Bool or [] --

    Invert the sense of the test, i.e., clip regions where there is data coverage.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#n)
- $(GMT.opt_P)
- **Q** : **cut_number** : -- Number or Str --

    Do not dump polygons with less than cut number of points [Dumps all polygons].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#q)
- **S** : **search_radius** : -- Number or Str --

    Sets radius of influence. Grid nodes within radius of a data point are considered reliable.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#s)
- **T** : **tiles** : -- Bool or [] --

    Plot tiles instead of clip polygons. Use -G to set tile color or pattern. Cannot be used with -D.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/psmask.html#t)
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
- $(GMT.opt_r)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function mask(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("psmask", cmd0, arg1)	# Speedy mode
	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/12c")
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :e :h :p :r :t :xy :params])

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)

	cmd = add_opt(cmd, 'C', d, [:C :end_clip_path])
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'F', d, [:F :oriented_polygons])
	cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'L', d, [:L :node_grid])
	cmd = add_opt(cmd, 'N', d, [:N :invert])
	cmd = add_opt(cmd, 'Q', d, [:Q :cut_number])
	cmd = add_opt(cmd, 'S', d, [:S :search_radius])
	cmd = add_opt(cmd, 'T', d, [:T :tiles])

	cmd = finish_PS(d, cmd, output, K, O)
	return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "psmask", arg1)
end

# ---------------------------------------------------------------------------------------------------
mask!(cmd0::String="", arg1=[]; K=true, O=true,  first=false, kw...) =
	mask(cmd0, arg1; K=K, O=O,  first=first, kw...)

mask(arg1=[], cmd0::String=""; K=false, O=false,  first=true, kw...) =
	mask(cmd0, arg1; K=K, O=O,  first=first, kw...)

mask!(arg1=[], cmd0::String=""; K=true, O=true,  first=false, kw...) =
	mask(cmd0, arg1; K=K, O=O,  first=first, kw...)

psmask  = mask			# Alias
psmask! = mask!			# Alias
