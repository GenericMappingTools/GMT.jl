"""
	clip(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs from file and plot a windclip diagram.

Parameters
----------

- **C** | **endclip** :: [Type => Bool]

    Mark end of existing clip path. No input file is needed.
- $(_opt_J)

- **A** | **steps** :: [Type => Str or []]

    By default, geographic line segments are connected as great circle arcs. To connect them as straight lines, use **A** 
- $(_opt_B)
- $(opt_Jz)
- **N** | **invert** :: [Type => Bool]

    Invert the sense of the test, i.e., clip regions where there is data coverage.
- $(opt_P)
- $(_opt_R)
- **T** | **clipregion** :: [Type => Bool]

    Rather than read any input files, simply turn on clipping for the current map region.

To see the full documentation type: ``@? clip``
"""
clip(cmd0::String; kwargs...)  = clip_helper(cmd0, nothing; kwargs...)
clip(arg1; kwargs...)          = clip_helper("", arg1; kwargs...)
clip!(cmd0::String; kwargs...) = clip_helper(cmd0, nothing; first=false, kwargs...)
clip!(arg1; kwargs...)         = clip_helper("", arg1; first=false, kwargs...)
clip!(; kwargs...)             = clip_helper("", nothing; first=false, kwargs...)
clip(; kwargs...)              = clip_helper("", nothing; first=false, kwargs...)	# For when user forgot to use clip! instead of clip

# ---------------------------------------------------------------------------------------------------
function clip_helper(cmd0::String, arg1; first=true, kwargs...)

	proggy = (IamModern[1]) ? "clip " : "psclip "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")
	cmd, = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :f :g :p :t :yx :params]; first=first)
	cmd  = parse_these_opts(cmd, d, [[:A :steps :straightlines], [:C :endclip], [:N :invert], [:T :clipregion :clip_limits]])
	cmd *= add_opt_pen(d, [:W :pen], opt="W")

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, = read_data(d, cmd0, cmd, arg1, opt_R)

	prep_and_call_finish_PS_module(d, proggy * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
psclip  = clip			# Alias
psclip! = clip!			# Alias
