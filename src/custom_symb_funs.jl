# Functions to create custom symbols in postscript
"""
"""
function flower_minho(; name::String="flower_minho", width=14, fmt="", format="", dpi=200, angle=0, cache=true, show=false)
	_fmt, name = helper_cusymb(cache, name, fmt, format, "misc")

	t = linspace(0,2pi,360);
	x = cos.(4*t) .* cos.(t);
	y = cos.(4*t) .* sin.(t);

	opt_p = (angle == 0) ? "180/90" : string(angle,"/90")
	lines([-0.7 -0.25 0], [-1.5 -0.8 0], # The flower stem
		limits=(-1,1,-1.5,1),          # Fig limits
		lw=9,                          # Stem's line width in points
		lc=:darkgreen,                 # Stem's line color
		bezier=true,                   # Smooth the stem polyne as a Bezier curve
		figsize=(width,0),             # Fig size. Second arg = 0 means compute the height keeping aspect ratio
		frame=:none,                   # Do not plot the frame
		p=opt_p)
	plot!(x, y, fill=(pattern=TESTSDIR * "tiling2.jpg", dpi=dpi), name = name * _fmt)
	(show == 1) && showfig()
end

# -------------------------------------------------------------------------------------------------
"""
"""
function matchbox(; name::String="matchbox", width=14, fmt="", format="", angle=0, cache=true, show=false)
	_fmt, name = helper_cusymb(cache, name, fmt, format, "misc")

	opt_p = (angle == 0) ? "180/90" : string(angle,"/90")
	GMT.Drawing.ellipse(300,201,0, 200, 50, units=:points, first=true, fill=:purple, pen=1, p=opt_p)
	GMT.Drawing.ellipse(340,206, 0,130, 66, fill=:purple, pen=1)
	GMT.Drawing.ellipse(318,222,0, 60, 26, fill=:blue)
	GMT.Drawing.box(200, 173, 205, 26, fill=:purple, pen=1)
	GMT.Drawing.circle(305,185,56, fill=:black)
	GMT.Drawing.circle(305,185,36, fill=:gray50)
	GMT.Drawing.circle(400,185,56, fill=:black)
	GMT.Drawing.circle(400,185,36, fill=:gray50, name = name * _fmt)
	(show == 1) && showfig()
end

# ---------------------------------------------------------------
function helper_cusymb(cache, name, fmt, format, subdir="")
	# Returns the format and the name of the file. If CACHE == true, the name is prefaced with
	# ./gmt/cache_csymb/subdir and the format is .eps
	if (cache == 1)
		(subdir != "") && (subdir = filesep * subdir)
		cus_path = joinpath(GMTuserdir[1], "cache_csymb" * subdir)
		!isdir(cus_path) && mkpath(cus_path)
		name = joinpath(cus_path, fileparts(name)[2])
		fmt = ".eps"
	end
	(fmt == "" && format != "") && (fmt = format)
	_fmt::String = (fmt == "" && format == "") ? ".eps" : string(fmt)
	_fmt[1] != '.' && (_fmt = "." * _fmt)
	return _fmt, name
end
