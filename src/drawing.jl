module Drawing

using GMT, Printf

const global paper_sizes = Dict(
	"A0"     => (2384, 3370),
	"A1"     => (1684, 2384),
	"A2"     => (1191, 1684),
	"A3"     => (842, 1191),
	"A4"     => (595, 842),
	"A5"     => (420, 595),
	"A6"     => (298, 420),
	"A"      => (612, 792),
	"Letter" => (612, 792),
	"Legal"  => (612, 1008),
	"Ledger" => (792, 1224),
	"B"      => (612, 1008),
	"C"      => (1584, 1224),
	"D"      => (2448, 1584),
	"E"      => (3168, 2448))

import ..CTRLshapes, ..KW, ..find_in_dict, ..def_fig_axes

export 
	box, circle, cross, custom, diamond, ellipse, ellipseAz, hexagon, itriangle, letter, minus, pentagon,
	plus, square, star, triangle, rect, rotrect, rotrectAz, roundrect, ydash 

circle(x, y, diam;    Vd=0, kw...) = shapes_1par(x, y, diam, "c"; Vd=Vd, kw...)
cross(x, y, diam;     Vd=0, kw...) = shapes_1par(x, y, diam, "x"; Vd=Vd, kw...)
diamond(x, y, diam;   Vd=0, kw...) = shapes_1par(x, y, diam, "d"; Vd=Vd, kw...)
hexagon(x, y, diam;   Vd=0, kw...) = shapes_1par(x, y, diam, "h"; Vd=Vd, kw...)
itriangle(x, y, diam; Vd=0, kw...) = shapes_1par(x, y, diam, "i"; Vd=Vd, kw...)
minus(x, y, diam;     Vd=0, kw...) = shapes_1par(x, y, diam, "-"; Vd=Vd, kw...)
pentagon(x, y, diam;  Vd=0, kw...) = shapes_1par(x, y, diam, "n"; Vd=Vd, kw...)
plus(x, y, diam;      Vd=0, kw...) = shapes_1par(x, y, diam, "+"; Vd=Vd, kw...)
square(x, y, diam;    Vd=0, kw...) = shapes_1par(x, y, diam, "s"; Vd=Vd, kw...)
star(x, y, diam;      Vd=0, kw...) = shapes_1par(x, y, diam, "a"; Vd=Vd, kw...)
triangle(x, y, diam;  Vd=0, kw...) = shapes_1par(x, y, diam, "t"; Vd=Vd, kw...)
ydash(x, y, diam;     Vd=0, kw...) = shapes_1par(x, y, diam, "y"; Vd=Vd, kw...)
box(x, y, a, b;       Vd=0, kw...) = shapes_2par(x, y, a, b, "r", 'c'; Vd=Vd, kw...)
rect(x, y, a, b;      Vd=0, kw...) = shapes_2par(x, y, a, b, "r", 'm'; Vd=Vd, kw...)

ellipse(x, y, dir, a, b;   Vd=0, kw...) = shapes_3par(x, y, dir, a, b, "e"; Vd=Vd, kw...)
ellipseAz(x, y, dir, a, b; Vd=0, kw...) = shapes_3par(x, y, dir, a, b, "E"; Vd=Vd, kw...)
rotrect(x, y, dir, a, b;   Vd=0, kw...) = shapes_3par(x, y, dir, a, b, "j"; Vd=Vd, kw...)
rotrectAz(x, y, dir, a, b; Vd=0, kw...) = shapes_3par(x, y, dir, a, b, "J"; Vd=Vd, kw...)
roundrect(x, y, w, h, r;   Vd=0, kw...) = shapes_3par(x, y, w, h, r, "R";   Vd=Vd, kw...)

function custom(x, y, name::String, par1; Vd=0, kw...)	# Custom symbol
	opt_S = string(" -Sk", name, "/", par1)			# The GMT -S option
	helper_shapes(x, y, opt_S; Vd=Vd, kw...)
end

function letter(x, y, size, str, font::String="", just::String=""; Vd=0, kw...)
	opts = (font != "") ? "+t" * font : ""
	(just != "") && (opts *= "+j" * just)
	opt_S = @sprintf(" -Sl%g+t%s%s", size, str, opts)
	helper_shapes(x, y, opt_S; Vd=Vd, kw...)
end

function shapes_1par(x, y, par1, scode; Vd=0, kw...)
	opt_S = string(" -S", scode, par1)
	helper_shapes(x, y, opt_S; Vd=Vd, kw...)
end

function shapes_2par(x, y, par1, par2, scode, orig; Vd=0, kw...)
	(orig == 'c') && (x += par1/2;	y += par2/2)		# Origin in lower left corner
	opt_S = string(" -S", scode, par1, "/", par2)
	helper_shapes(x, y, opt_S; Vd=Vd, kw...)
end

function shapes_3par(x, y, par1, par2, par3, scode; Vd=0, kw...)
	opt_S = string(" -S", scode, par1, "/", par2, "/", par3)
	helper_shapes(x, y, opt_S; Vd=Vd, kw...)
end

function helper_shapes(x, y, cmd; Vd=0, kw...)
	# Helper function that takes care to all symbols plotting
	d = KW(kw)
	# Se if we are asked to force the start a new drawing (first= true) or bypass the CTRLshapes.first control
	first = find_in_dict(d, [:first])[1]
	((isa(first, Bool) && first)  || (isa(first, Int) && first != 0)) && (CTRLshapes.first[1] = true)
	((isa(first, Bool) && !first) || (isa(first, Int) && first == 0)) && (CTRLshapes.first[1] = false)

	if (CTRLshapes.first[1])
		CTRLshapes.fname[1] = joinpath(tempdir(), "GMTjl_tmp.ps")
		if ((val = find_in_dict(d, [:units])[1]) !== nothing)
			_cmd, opt_B = GMT.parse_B(d, "", def_fig_axes[1])
			cmd *= " --PROJ_LENGTH_UNIT=p"
			opt_J = " -Jx1"
			if ((val = find_in_dict(d, [:paper])[1]) !== nothing)
				ps = get(paper_sizes, string(val), (595, 842))
				opt_R = string(" -R0/",ps[1],"/0/",ps[2])
				ps_media = string(" --PS_MEDIA=", ps[1], "x", ps[2])
			else
				opt_R, ps_media = " -R0/594/0/841", " --PS_MEDIA=594x841"
			end
			CTRLshapes.points[1] = true
		else
			_cmd, opt_B, opt_J, opt_R = GMT.parse_BJR(d, "", "", false, " ")
			(opt_R == "")  && (opt_R = " -R0/21/0/29")
			(opt_J == " ") && (opt_J = " -Jx1")
		end
		(opt_B == def_fig_axes[1]) && (opt_B = "")			# We don't want a default -B here
		opt_O, opt_P = "", " -P"
		out, opt_T, EXT, = GMT.fname_out(d)
	else
		opt_R, opt_J, opt_B, opt_O, opt_P = " -R", " -J", "", " -O", ""
		(CTRLshapes.points[1]) && (cmd *= " --PROJ_LENGTH_UNIT=p")
	end

	redirect = (CTRLshapes.first[1]) ? " > " : " >> "
	if (length(kw) == 0)
		cmd = "psxy" * cmd * opt_R * opt_J * opt_B * opt_P * opt_O * " -K" * redirect * CTRLshapes.fname[1]
	else
		d[:Vd] = 2
		(opt_J != " -J" && length(opt_J) > 3) && (d[:J] = opt_J[4:end])	# Dirty trick to force assign the J we want
		(opt_R != " -R" && length(opt_R) > 3) && (d[:R] = opt_R[4:end])
		d[:B] = "none"
		cmd = GMT.common_plot_xyz("", nothing, cmd, CTRLshapes.first[1], false, d...)
		(CTRLshapes.first[1] && opt_B != "") && (cmd = replace(cmd, "psxy" => "psxy" * opt_B))
	end
	(0 < Vd < 2) && println(cmd);	(Vd > 1) && return cmd

	if (CTRLshapes.first[1])
		if (CTRLshapes.points[1])  cmd *= ps_media		# When units are points we always set a specific paper size
		elseif (EXT != "ps")       cmd *= " --PS_MEDIA=16840x16840"		# Exptend to a larger paper size (5 x A0)
		end
	end

	in_data = (length(x) == 1) ? [x y] : [x[:] y[:]]
	gmt(cmd, in_data)
	CTRLshapes.first[1] = false				# To signal next calls that they have to append
	fim = ((find_in_dict(d, [:show :fmt :savefig :figname :name], false)[1]) !== nothing) ? true : false
	(!fim) && return nothing

	CTRLshapes.first[1] = true				# Better reset it right now in case next command errors
	CTRLshapes.points[1] = false
	out, opt_T, EXT, fname, = GMT.fname_out(d, true)
	#show_non_consumed(d, cmd)
	GMT.close_PS_file(CTRLshapes.fname[1])
	GMT.showfig(d, CTRLshapes.fname[1], EXT, opt_T, false, fname)
end

"""
Submodule where the symbols of `plot` were elevated to the category of functions.
The functions that are currently available are:

- circle(x, y, diameter,    kw...)
- cross(x, y, diameter;     kw...)
- custom(x, y, name, size;  kw...)
- diamond(x, y, diameter;   kw...)
- hexagon(x, y, diameter;   kw...)
- itriangle(x, y, diameter; kw...)
- letter(x, y, size, str, font, just; kw...)
- minus(x, y, length;       kw...)
- pentagon(x, y, diameter;  kw...)
- plus(x, y, diameter;      kw...)
- square(x, y, diameter;    kw...)
- star(x, y, diameter;      kw...)
- triangle(x, y, diameter;  kw...)
- ydash(x, y, length;       kw...)
- box(x, y, width, height;  kw...)
- rect(x, y, width, height; kw...)
- ellipse(x, y, angle, majoraxis, minoraxis;     kw...)
- ellipseAz(x, y, azimuth, majoraxis, minoraxis; kw...)
- rotrect(x, y, angle, width, height;     kw...)
- rotrectAz(x, y, azimuth, width, height; kw...)
- roundrect(x, y, width, height, radius;  kw...)

For all symbols, except `box`, `diameter` is the diametr of the circumscribing circle and `x,y`
the coordinates of its center. `box` is the exception in that those are the coordinates of the
lower left corner.

This submodule uses global variables to track the first, middle and last layers in the stack plot but
in case of errors that track may be left in error state too. So, when one want to force the begining
of a new figure use the kwarg `first=true`. Likewise, if we want to add to a previously, still open fig,
use `first=false`.

By default the plot unites is ``cm`` but we can select ``points`` by doing `units=:points`. This takes care
of setting the appropriate `region` (A4 by default) and fig scale. If other then A4 size is wished, use
`paper=:A3` (or any of the common paper sizes). When units is left to ``cm`` the normal paper size ruple
applies (i.e. A4 for PS format or ~unlimitted for others.)

The `kw...` in the functions arguments are the normal kwargs that one can use in the `plot` module.

### Example, to draw a cute litte car:

	ellipse(300,201,0, 200, 50, units=:points, fill=:purple, pen=1)
	ellipse(340,206, 0,130, 66, fill=:purple, pen=1)
    ellipse(318,222,0, 60, 26, fill=:blue)
    box(200, 173, 205, 26, fill=:purple, pen=1)
    circle(305,185,56, fill=:black)
    circle(305,185,36, fill=:gray50)
    circle(400,185,56, fill=:black)
    circle(400,185,36, fill=:gray50, show=true)
"""
Drawing

end			# End module