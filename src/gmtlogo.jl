"""
    logo(cmd0::String=""; kwargs...)

Plots the GMT logo on a map. By default, the GMT logo is 5 cm wide and 2.5 cm high and will be
positioned relative to the current plot origin. Use various options to change this and to place
a transparent or opaque rectangular map panel behind the GMT logo.

Parameters
----------

- **D** | **pos** | **position** :: [Type => Str]

    Sets reference point on the map for the image using one of four coordinate systems.
- **F** | **box** :: [Type => Str]

    Without further options, draws a rectangular border around the GMT logo using `MAP_FRAME_PEN`.
    or map rose (T)
- **julia** :: [Type => Number]

    Create the Julia instead of the GMT logo. Provide circle diameter in centimeters
- **GMTjulia** :: [Type => Number]

    Create the GMT Julia GMT logo. Provide circle diameter in centimeters
- $(_opt_J)
- $(opt_Jz)
- $(opt_P)
- $(_opt_R)
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_t)
- $(opt_savefig)

- Example, make a GMT Julia logo with circles of 1 cm: logo(GMTjulia=1, show=true)
"""
function logo(cmd0::String=""; first=true, kwargs...)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_R(d, "", O=O)
	cmd, = parse_J(d, cmd, default=" -Jx1", map=true, O=O)
	cmd, = parse_common_opts(d, cmd, [:UVXY :params]; first=first)

	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
	                        (map=("g", arg2str, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str)), 'g')
	cmd = add_opt(d, cmd, "F", [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))

	do_julia, do_GMTjulia = false, false
	((val_j = find_in_dict(d, [:julia])[1]) !== nothing) && (do_julia = true)
	((val_G = find_in_dict(d, [:GMTjulia])[1]) !== nothing) && (do_GMTjulia = true)
	if (do_julia || do_GMTjulia)
		r::Float64 = (do_julia) ? Float64(val_j) : Float64(val_G)
		c,t,r2 = jlogo(r)			# r2 is the diameter of the inner circle
		if (!occursin("-R", cmd))  cmd = @sprintf("-R0/%f/0/%f ", 2r, 2r) * cmd  end
		if (!occursin("-J", cmd))  cmd = " -Jx1 " * cmd  end
		if (do_GMTjulia)			# Too soon to use the show, fmt, ...
			do_show, fmt, savefig = get_show_fmt_savefig(d, true)		# Default is to show
		end
		cmd = "psxy " * c * cmd
		((_r = check_dbg_print_cmd(d, cmd)) !== nothing && startswith(_r, "psxy")) && return _r
		prep_and_call_finish_PS_module(d, cmd, "", K, O, true, t)
		if (do_GMTjulia)
			letter_height = 0.75 * r2 / 2.54 * 72 		# Make the letters 75% of the cicle's diameter
			opt_F::String = @sprintf("+f%d,NewCenturySchlbk-Italic",letter_height)
			if (fmt != "")
				text!(text_record(t[1:3,1:2], ["M", "T", "G"]), F=opt_F, fmt=fmt, name=savefig, show=do_show)
			else
				text!(text_record(t[1:3,1:2], ["M", "T", "G"]), F=opt_F, name=savefig, show=do_show)
			end
		end
	else
		(!occursin("-D", cmd)) && (cmd = " -Dx0/0+w5c " * cmd)
		cmd = "gmtlogo " * cmd
		((_r = check_dbg_print_cmd(d, cmd)) !== nothing) && return _r
		return prep_and_call_finish_PS_module(d, cmd, "", K, O, true)
	end
end

# ---------------------------------------------------------------------------------------------------
logo!(cmd0::String=""; first=false, kw...) = logo(cmd0; first=first, kw...)

# -------------------------------------------------------------------------
function jlogo(L::Float64=5.0)
	# Create the Julia "Terminator" 3 colored circles triangle
	# L is the length of the equilateral triangl
	#W = 2 * L 					# Region width
	#s_size = 0.8 * L 			# Circle diameter
	#l_thick::Float64 = s_size * 0.06 	# Line thickness
	H = L * sind(60) 			# Triangle height

	s1 = 0.8 * L				# Outer circle diameter to simulate a line
	s2 = s1 * (1 - 0.06)		# Inner circle diameter. The one that will be filled.
	t = [L/2 L/2 0 s1; L+L/2 L/2 1 s1; L L/2+H 2 s1; L/2 L/2 3 s2; L+L/2 L/2 4 s2; L L/2+H 5 s2]
	return " -Sc -C171/43/33,130/83/171,81/143/24,191/101/95,158/122/190,128/171/93 ", t, s2
end

const gmtlogo  = logo			# Alias
const gmtlogo! = logo!