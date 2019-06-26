"""
    logo(cmd0::String=""; kwargs...)

Plots the GMT logo on a map. By default, the GMT logo is 5 cm wide and 2.5 cm high and will be
positioned relative to the current plot origin. Use various options to change this and to place
a transparent or opaque rectangular map panel behind the GMT logo.

Full option list at [`gmtlogo`](http://gmt.soest.hawaii.edu/doc/latest/gmtlogo.html)

Parameters
----------

- **D** : **pos** : **position** : -- Str --

    Sets reference point on the map for the image using one of four coordinate systems.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtlogo.html#d)
- **F** : **box** : -- Str --

    Without further options, draws a rectangular border around the GMT logo using MAP_FRAME_PEN.
    or map rose (T)
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmtlogo.html#f)
- **julia** : -- Number --

    Create the Julia instead of the GMT logo. Provide circle diameter in centimeters
- **GMTjulia** : -- Number --

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

	length(kwargs) == 0 && return monolitic("gmtlogo", cmd0, arg1)
	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, = parse_R("", d, O)
	cmd, = parse_J(cmd, d, "-Jx1", true, O)

	cmd = add_opt(cmd, 'D', d, [:D :pos :position])
	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))

	cmd = finish_PS(d, cmd, output, K, O)

	do_julia    = haskey(d, :julia)
	do_GMTjulia = haskey(d, :GMTjulia)
	if (do_julia || do_GMTjulia)
		if (do_julia)	r = d[:julia]	else	r = d[:GMTjulia]	end
		c,t,r2 = jlogo(r)			# r2 is the diameter of the inner circle
		if (!occursin("-R", cmd))  cmd = @sprintf("-R0/%f/0/%f ", 2r, 2r) * cmd  end
		if (!occursin("-J", cmd))  cmd = " -Jx1 " * cmd  end
		do_show = false
		if (do_GMTjulia && haskey(d, :show))  delete!(d, :show);  do_show = true  end	# Too soon
		fmt = fname_ext
		if (do_GMTjulia && haskey(d, :fmt))		# Too soon to set the format. Need to finish the PS first
			fmt = d[:fmt];	delete!(d, :fmt);
			fname_ext = "ps"
		end
		r = finish_PS_module(d, "psxy " * c * cmd, "", output, fname_ext, opt_T, K, O, false, t)
		if (r !== nothing && startswith(r, "psxy"))  return r  end
		if (do_GMTjulia)
			letter_height = 0.75 * r2 / 2.54 * 72 		# Make the letters 75% of the cicle's diameter
			opt_F = @sprintf("+f%d,NewCenturySchlbk-Italic",letter_height)
			text!(text_record(t[1:3,1:2], ["G", "T", "M"]), R=[], J=[], F=opt_F, fmt=fmt, show=do_show)
		end
	else
		if (!occursin("-D", cmd))  cmd = " -Dx0/0+w5c " * cmd	end
		return finish_PS_module(d, "gmtlogo " * cmd, "", output, fname_ext, opt_T, K, O, false)
	end
end

# ---------------------------------------------------------------------------------------------------
logo!(cmd0::String=""; first=false, kw...) = logo(cmd0; first=first, kw...)
logo(; first=true, kw...) = logo(""; first=first, kw...)
logo!(; first=false, kw...) = logo(""; first=first, kw...)

# -------------------------------------------------------------------------
function jlogo(L=5)
	# Create the Julia "Terminator" 3 colored circles triangle
	# L is the length of the equilateral triangl
	W = 2 * L 					# Region width
	H = L * sind(60) 			# Triangle height
	s_size = 0.8 * L 			# Circle diameter
	l_thick = s_size * 0.06 	# Line thickness

	s1 = (GMTver < 6) ? s_size / 2.54 : s_size	# Outer circle diameter to simulate a line (was bugged in older versions)
	s2 = s1 * (1 - 0.06)		# Inner circle diameter. The one that will be filled.
	t = [L/2 L/2 0 s1; L+L/2 L/2 1 s1; L L/2+H 2 s1; L/2 L/2 3 s2; L+L/2 L/2 4 s2; L L/2+H 5 s2]
	return " -Sc -C171/43/33,130/83/171,81/143/24,191/101/95,158/122/190,128/171/93 ", t, s2
end