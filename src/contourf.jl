"""
	contourf(cmd0::String="", arg1=nothing; kwargs...)

Reads one or more ASCII [or binary] files (or standard input) containing x,y[,z] and performs Delaunay
triangulation, i.e., it find how the points should be connected to give the most equilateral
triangulation possible. 

Full option list at [`triangulate`]($(GMTdoc)triangulate.html)

Parameters
----------
- **A** | **annot** :: [Type => Str | Number]       ``Arg = [-|[+]annot_int][labelinfo]``

    *annot_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
    ($(GMTdoc)contour.html#a)
- $(GMT.opt_B)
- **C** | **cont** | **contour** | **contours** | **levels** :: [Type => Str | Number | GMTcpt]  ``Arg = [+]cont_int``

    Contours to be drawn may be specified in one of three possible ways.
    ($(GMTdoc)grdcontour.html#c)
- **E** | **index** :: [Type => Str | Mx3 array]

    Give name of file with network information. Each record must contain triplets of node
    numbers for a triangle.
    ($(GMTdoc)contour.html#e)
- **G** | **labels** :: [Type => Str]

    Controls the placement of labels along the quoted lines.
    ($(GMTdoc)contour.html#g)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_P)
- **Q** | **cut** :: [Type => Str | Number]         ``Arg = [cut[unit]][+z]]``

    Do not draw contours with less than cut number of points.
    ($(GMTdoc)contour.html#q)
- **S** | **skip** :: [Type => Str | []]            ``Arg = [p|t]``

    Skip all input xyz points that fall outside the region.
    ($(GMTdoc)contour.html#s)
- **T** | **ticks** :: [Type => Str]                 ``Arg = [+|-][+a][+dgap[/length]][+l[labels]]``

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
    ($(GMTdoc)contour.html#t)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
    ($(GMTdoc)contour.html#w)
- **Z** | **xyz** | **triplets** :: [Type => Bool]

    ($(GMTdoc)triangulate.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_bo)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)

Examples
--------

G = GMT.peaks();
C = makecpt(T=(-7,9,2));

contourf(G, fmt=:png, show=1)
contourf(G, C, contour=[-2, 0, 2, 5], fmt=:png, show=1)
contourf(G, C, annot=[-2, 0, 2, 5], fmt=:png, show=1)
contourf(G, C, annot=2, fmt=:png, show=1)
contourf(G, C, contour=1, annot=[-2, 0, 2, 5], fmt=:png, show=1)
contourf(G, C, annot=:none, fmt=:png, show=1)

d = [0 2 5; 1 4 5; 2 0.5 5; 3 3 9; 4 4.5 5; 4.2 1.2 5; 6 3 1; 8 1 5; 9 4.5 5];
contourf(d, limits=(-0.5,9.5,0,5), pen=0.25, labels=(line=(:min,:max),), fmt=:png, show=1)
"""
function contourf(cmd0::String="", arg1=nothing, arg2=nothing; first=true, kwargs...)

	d = KW(kwargs)
	CPT_arg = (isa(arg1, GMTcpt)) ? arg1 : (isa(arg2, GMTcpt) ? arg2 : nothing)		# Fish a CPT, if any.

	CPT = nothing;		C_contours = "";	C_int = 0;
	if ((val = find_in_dict(d, [:C :cont :contour :contours :levels])[1]) !== nothing)
		if (isa(val, GMTcpt))
			CPT = val
		elseif (isa(val, Array{<:Number}))
			if (CPT_arg === nothing)	# No CPT yet, compute one
				CPT = makecpt(T=arg2str(val,','), M=true, par=(COLOR_BACKGROUND="white", COLOR_FOREGROUND="white"))
			else						# We already have one CPT so VAL is interpreted as contours values
				C_contours = arg2str(val,',')
			end
		else
			t = string(val)
			if     (occursin(".cpt", t)) CPT = gmtread(t)
			elseif ((x = parse(Float64, t)) != NaN)  C_int = x
			else   error("Bad levels option")
			end
		end
	end

	if (cmd0 != "")		# Then it must be a file name. Of what?
		if     ((val = find_in_dict(d, [:grd :grid])[1]) !== nothing) X = gmtread(cmd0, grd=true)
		elseif ((val = find_in_dict(d, [:data :dataset :table])[1]) !== nothing) X = gmtread(cmd0, data=true)
		elseif ((val = find_in_dict(d, [:ogr])[1]) !== nothing)  X = gmtread(cmd0, ogr=true)
		else                                                     X = gmtread(cmd0, ignore_grd=1) # Try luck with guessing
		end
		if (X !== nothing)		# X === nothing when a recognized grid was passed by name
			if (arg1 !== nothing)  arg2 = arg1  end		# Then arg1 MUST be a CPT
			arg1 = X
			cmd0 = ""
		end
	end

	if (isa(arg1, GMTgrid) || cmd0 != "")
		# All of these are grdcontour options also, so must fish them, store and use later.
		opt_A = find_in_dict(d, [:A :annot])[1]			# Will either have something or nothing
		opt_G = find_in_dict(d, [:G :labels])[1]
		opt_T = find_in_dict(d, [:T :ticks])[1]
		opt_W = find_in_dict(d, [:W :pen])[1]
		opt_L = find_in_dict(d, [:L :range])[1]
		opt_Q = find_in_dict(d, [:Q :cut])[1]
		opt_S = find_in_dict(d, [:S :smooth])[1]
	end

	if (isa(arg1, GMTgrid) || cmd0 != "")
		#isa(arg2, GMTcpt) ? d[:N] = arg2 : (isa(arg1, GMTcpt) ? d[:N] = arg1 : d[:N] = true)
		if (CPT === nothing && CPT_arg === nothing)
			if (cmd0 != "")
				info = grdinfo(cmd0 * " -C")
				C_inc, min, max = gen_contour_vals(info[1].data[5:6])
			else
				C_inc, min, max = gen_contour_vals(arg1)
			end
			CPT = makecpt(T=(min, max, C_inc))
		elseif (CPT === nothing && CPT_arg !== nothing)
			CPT = CPT_arg
		end

		show = false;	fmt = nothing;	savefig = ""
		if ((val = find_in_dict(d, [:show])[1]) !== nothing)  show = true  end
		if ((val = find_in_dict(d, [:fmt])[1])  !== nothing)  fmt  = val   end
		if ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing)  savefig = val  end

		d[:C] = CPT;	d[:Q] = "s";	done = false#	d[:W] = "c"
		if ((C_int == 0) && (opt_A == "none" || opt_A == :none))  d[:W] = "c";  done = true  end	# Then no need grdcontour
		grdview(cmd0, arg1; first=first, d...)
		del_from_dict(d, [[:C :z], [:Q], [:W]])
		if (done)  return  end

		if (C_int > 0 || C_contours != "" || opt_A !== nothing)
			if     (C_int > 0)        d[:C] = string(C_int)
			elseif (C_contours != "") d[:C] = C_contours
			end
			if (opt_A !== nothing)    d[:A] = opt_A  end
		else
			d[:C] = CPT;
		end

		if (show)  d[:show] = true  end
		if (fmt !== nothing) d[:fmt] = fmt  end
		if (savefig != "")   d[:savefig] = savefig  end
		if (opt_G !== nothing)  d[:G] = opt_G  end
		if (opt_L !== nothing)  d[:L] = opt_L  end
		if (opt_Q !== nothing)  d[:Q] = opt_Q  end
		if (opt_T !== nothing)  d[:T] = opt_T  end
		if (opt_S !== nothing)  d[:S] = opt_S  end
		if (opt_W !== nothing)  d[:W] = opt_W  end
		grdcontour(cmd0, arg1; first=false, d...)
	else
		if (isa(CPT_arg, GMTcpt))
			d[:C] = CPT_arg;
		elseif (isa(CPT, GMTcpt))
			d[:C] = CPT;
		else
			D = gmtinfo(arg1, C=1)
			C_inc, min, max = gen_contour_vals(D[1].data[5:6])
			d[:C] = makecpt(T=(min, max, C_inc))
		end
		d[:I] = true
		contour("", arg1; first=first, d...)
	end

end

# ---------------------------------------------------------------------------------------------------
function gen_contour_vals(in)
	if (isa(in, GMTgrid))  low = in.range[5];	high = in.range[6]
	else                   low = in[1];		high = in[2]
	end
	range = high - low
	C_int = auto_contour_interval(range)
	min = floor(low / C_int) * C_int;
	if (min > low)  min -= C_int  end
	max = ceil(high / C_int) * C_int;
	if (max < high)  max += C_int  end
	return C_int, min, max
end

# ---------------------------------------------------------------------------------------------------
function auto_contour_interval(range)
	# Do the same as GMT C
	x = 10 ^ (floor(log10(range)) - 1.0)
	nx = div(range, x, RoundNearest)
	x *= (nx > 40) ? 5 : (nx > 20 ? 2 : 1)
	return x		# Contour intervals
end

# ---------------------------------------------------------------------------------------------------
contourf(arg1, arg2=nothing, cmd0::String=""; kw...) = contourf(cmd0, arg1, arg2; first=true, kw...)