"""
	wiggle(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs from file and plot a windwiggle diagram.

See full GMT (not the `GMT.jl` one) docs at [`pswiggle`]($(GMTdoc)wiggle.html)

Parameters
----------

- $(_opt_R)
- **Z** | **ampscale** | **amp_scale** :: [Type => Number | Str]

    Gives anomaly scale in data-units/distance-unit.
- **A** | **azimuth** :: [Type => Str | number]

    Sets the preferred positive azimuth. Positive wiggles will “gravitate” towards that direction.
- $(_opt_B)
- **C** | **center** :: [Type => Number]

    Subtract center from the data set before plotting [0].
- **D** | **scale_bar** :: [Type => Str]

    Defines the reference point on the map for the vertical scale bar using one of four coordinate systems.
- **F** | **box** :: [Type => Str]

    Without further options, draws a rectangular border around the vertical scale bar.
- **G** | **fill** :: [Type => Number | Str]

    Set fill shade, color or pattern for positive and/or negative wiggles [Default is no fill].
- **I** | **fixed_azim** :: [Type => Number]

    Set a fixed azimuth projection for wiggles [Default uses track azimuth, but see -A].
- $(_opt_J)
- $(opt_P)
- **T** | **track** :: [Type => Number or Str | Tuple | []]

    Draw track [Default is no track]. Append pen attributes to use [Defaults: width = 0.25p, color =
    black, style = solid].
- **W** | **pen** :: [Type => Number | Str | tuple | []]

    Specify outline pen attributes [Default is no outline].
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(_opt_t)
- $(opt_w)
- $(opt_swap_xy)
- $(opt_savefig)

To see the full documentation type: ``@? pswiggle``
"""
wiggle(cmd0::String; kw...) = wiggle_helper(cmd0, nothing; kw...)
wiggle(arg1; kw...) = wiggle_helper("", arg1; kw...)
wiggle!(cmd0::String; kw...) = wiggle_helper(cmd0, nothing; first=false, kw...)
wiggle!(arg1; kw...) = wiggle_helper("", arg1; first=false, kw...)

const pswiggle  = wiggle			# Alias
const pswiggle! = wiggle!			# Alias

# ---------------------------------------------------------------------------------------------------
function wiggle_helper(cmd0::String, arg1; first=true, kw...)
	gmt_proggy = (IamModern[1]) ? "wiggle "  : "pswiggle "

	d, K, O = init_module(first, kw...)		# Also checks if the user wants ONLY the HELP mode

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, defaultJ=" -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:c :e :f :g :p :t :w :F :UVXY :margin :params]; first=first)
	cmd  = parse_these_opts(cmd, d, [[:A :azimuth], [:C :center], [:I :fixed_azim], [:S], [:Z :ampscale :amp_scale]])

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)

	cmd = parse_type_anchor(d, cmd, [:D :scale_bar],
                            (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width=("+w", arg2str), justify="+j", label_left="_+al", labels="+l", label="+l", offset=("+o", arg2str)), 'j')
	cmd *= opt_pen(d, 'T', [:T :track])
	cmd *= opt_pen(d, 'W', [:W :pen])
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')

	_cmd = [gmt_proggy * cmd]
	_cmd = frame_opaque(_cmd, gmt_proggy, opt_B, opt_R, opt_J)		# No -t in frame
	finish_PS_module(d, _cmd, "", K, O, true, arg1)
end
