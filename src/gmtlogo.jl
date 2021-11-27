"""
    logo(cmd0::String=""; kwargs...)

Plots the GMT logo on a map. By default, the GMT logo is 5 cm wide and 2.5 cm high and will be
positioned relative to the current plot origin. Use various options to change this and to place
a transparent or opaque rectangular map panel behind the GMT logo.

Full option list at [`gmtlogo`]($(GMTdoc)gmtlogo.html)

Parameters
----------

- **D** | **pos** | **position** :: [Type => Str]

    Sets reference point on the map for the image using one of four coordinate systems.
    ($(GMTdoc)gmtlogo.html#d)
- **F** | **box** :: [Type => Str]

    Without further options, draws a rectangular border around the GMT logo using `MAP_FRAME_PEN`.
    or map rose (T)
    ($(GMTdoc)gmtlogo.html#f)
- **julia** :: [Type => Number]

    Create the Julia instead of the GMT logo. Provide circle diameter in centimeters
- **GMTjulia** :: [Type => Number]

    Create the GMT Julia GMT logo. Provide circle diameter in centimeters
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_P)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_t)

- Example, make a GMT Julia logo with circles of 1 cm: logo(GMTjulia=1, show=true)
"""
function logo(cmd0::String=""; first=true, kwargs...)

	(cmd0 != "" && length(kwargs) == 0) && return monolitic("gmtlogo", cmd0)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_R(d, "", O)
	cmd, = parse_J(d, cmd, "-Jx1", true, O)
	cmd, = parse_common_opts(d, cmd, [:UVXY :params], first)

	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
	                        (map=("g", arg2str, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str)), 'g')
	cmd = add_opt(d, cmd, 'F', [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))

	do_julia, do_GMTjulia = false, false
	((val_j = find_in_dict(d, [:julia])[1]) !== nothing) && (do_julia = true)
	((val_G = find_in_dict(d, [:GMTjulia])[1]) !== nothing) && (do_GMTjulia = true)
	if (do_julia || do_GMTjulia)
		r = (do_julia) ? val_j : val_G
		c,t,r2 = jlogo(r)			# r2 is the diameter of the inner circle
		if (!occursin("-R", cmd))  cmd = @sprintf("-R0/%f/0/%f ", 2r, 2r) * cmd  end
		if (!occursin("-J", cmd))  cmd = " -Jx1 " * cmd  end
		do_show = false
		if (do_GMTjulia && haskey(d, :show))  delete!(d, :show);  do_show = true  end	# Too soon
		fmt = ""
		if (do_GMTjulia)
			# Too soon to set the format. Need to finish the PS first
			((val = find_in_dict(d, [:fmt])[1]) !== nothing) && (fmt = arg2str(val))
			savefig = nothing
			if ((val = find_in_dict(d, [:savefig :name])[1]) !== nothing)		#  Also too early for savefig
				savefig = val
			end
		end
		r = finish_PS_module(d, "psxy " * c * cmd, "", K, O, true, t)
		(r !== nothing && startswith(r, "psxy")) && return r
		if (do_GMTjulia)
			letter_height = 0.75 * r2 / 2.54 * 72 		# Make the letters 75% of the cicle's diameter
			opt_F = @sprintf("+f%d,NewCenturySchlbk-Italic",letter_height)
			if (fmt != "")
				text!(text_record(t[1:3,1:2], ["M", "T", "G"]), R=[], J=[], F=opt_F, fmt=fmt, name=savefig, show=do_show)
			else
				text!(text_record(t[1:3,1:2], ["M", "T", "G"]), R=[], J=[], F=opt_F, name=savefig, show=do_show)
			end
		end
	else
		(!occursin("-D", cmd)) && (cmd = " -Dx0/0+w5c " * cmd)
		return finish_PS_module(d, "gmtlogo " * cmd, "", K, O, true)
	end
end

# ---------------------------------------------------------------------------------------------------
logo!(cmd0::String=""; first=false, kw...) = logo(cmd0; first=first, kw...)

# -------------------------------------------------------------------------
function jlogo(L=5)
	# Create the Julia "Terminator" 3 colored circles triangle
	# L is the length of the equilateral triangl
	W = 2 * L 					# Region width
	H = L * sind(60) 			# Triangle height
	s_size = 0.8 * L 			# Circle diameter
	l_thick = s_size * 0.06 	# Line thickness

	s1 = s_size					# Outer circle diameter to simulate a line
	s2 = s1 * (1 - 0.06)		# Inner circle diameter. The one that will be filled.
	t = [L/2 L/2 0 s1; L+L/2 L/2 1 s1; L L/2+H 2 s1; L/2 L/2 3 s2; L+L/2 L/2 4 s2; L L/2+H 5 s2]
	return " -Sc -C171/43/33,130/83/171,81/143/24,191/101/95,158/122/190,128/171/93 ", t, s2
end