"""
    logo(cmd0::String=""; kwargs...)

Plots the GMT logo on a map. By default, the GMT logo is 5 cm wide and 2.5 cm high and will be
positioned relative to the current plot origin. Use various options to change this and to place
a transparent or opaque rectangular map panel behind the GMT logo.

Full option list at [`pslogo`](http://gmt.soest.hawaii.edu/doc/latest/pslogo.html)

Parameters
----------

- **D** : **inset** : -- Str --
	Sets reference point on the map for the image using one of four coordinate systems.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pslogo.html#d)
- **F** : **box** : -- Str --
	Without further options, draws a rectangular border around the GMT logo using MAP_FRAME_PEN.
    or map rose (T)
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pslogo.html#f)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_P)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_t)
"""
# ---------------------------------------------------------------------------------------------------
function logo(cmd0::String=""; K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("pslogo", cmd0, arg1)	# Speedy mode
	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

    cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", "", O, "")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_gmtconf_MAP(cmd, d)

	cmd, K, O = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt(cmd, 'D', d, [:D :position])
	cmd = add_opt(cmd, 'F', d, [:F :box])

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	if (haskey(d, :julia))
		r = d[:julia]
		c,t = jlogo(r)
		if (!contains(cmd, "-R"))  cmd = @sprintf("-R0/%f/0/%f ", 2r, 2r) * cmd  end
		if (!contains(cmd, "-J"))  cmd = " -Jx1 " * cmd  end
		cmd = c * cmd
		return finish_PS_module(d, cmd, "", t, [], output, fname_ext, opt_T, K, "psxy")
	else
		return finish_PS_module(d, cmd, "", [], [], output, fname_ext, opt_T, K, "gmtlogo")
	end
end

# ---------------------------------------------------------------------------------------------------
logo!(cmd0::String=""; K=true, O=true, first=false, kw...) = logo(cmd0; K=K, O=O, first=first, kw...)
logo(; K=false, O=false, first=true, kw...) = logo(""; K=K, O=O, first=first, kw...)
logo!(; K=true, O=true, first=false, kw...) = logo(""; K=K, O=O, first=first, kw...)

# -------------------------------------------------------------------------
function jlogo(L=5)
	# Create the Julia "Terminator" 3 colored circles triangle
	# L is the length of the equilateral triangl
	W = 2 * L 					# Region width
	H = L * sind(60) 			# Triangle height
	s_size = 0.8 * L 			# Circle diameter
	l_thick = s_size * 0.06 	# Line thickness

	s1 = s_size					# Outer circle diameter. To simulate a line.
	if (GMTver < 6)  s1 = s1 / 2.54  end	# There is a bug in older versions
	s2 = s1 * (1 - 0.06)		# Inner circle diameter. The one that will be filled.
	t = [L/2 L/2 0 s1; L+L/2 L/2 1 s1; L L/2+H 2 s1; L/2 L/2 3 s2; L+L/2 L/2 4 s2; L L/2+H 5 s2]
	cmd = " -Sc -C171/43/33,130/83/171,81/143/24,191/101/95,158/122/190,128/171/93 "
	return cmd, t
end