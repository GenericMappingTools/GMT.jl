# Put this code in a separate file to permit access from future GMT_base module
function get_marker_name(d::Dict, @nospecialize(arg1), symbs::Vector{Symbol}, is3D::Bool, del::Bool=true)
	marca::String = "";		N = 0
	for symb in symbs
		if (haskey(d, symb))
			t = d[symb]
			if (isa(t, Tuple))				# e.g. marker=(:r, [2 3])
				msg = "";	cst = false
				opt = ""	# Probably this default value is never used but avoids compiling helper_markers(opt,) with a non def var
				o::String = string(t[1])
				if     (startswith(o, "E"))  opt = "E";  N = 3; cst = true
				elseif (startswith(o, "e"))  opt = "e";  N = 3
				elseif (o == "J" || startswith(o, "Rot"))  opt = "J";  N = 3; cst = true
				elseif (o == "j" || startswith(o, "rot"))  opt = "j";  N = 3
				elseif (o == "M" || startswith(o, "Mat"))  opt = "M";  N = 3
				elseif (o == "m" || startswith(o, "mat"))  opt = "m";  N = 3
				elseif (o == "P" || startswith(o, "sph"))  opt = "P";  N = 1
				elseif (o == "R" || startswith(o, "Rec"))  opt = "R";  N = 3
				elseif (o == "r" || startswith(o, "rec"))  opt = "r";  N = 2
				elseif (o == "V" || startswith(o, "Vec"))  opt = "V";  N = 2
				elseif (o == "v" || startswith(o, "vec"))  opt = "v";  N = 2
				elseif (startswith(o, "geovec"))  opt = "=";  N = 2
				elseif (o == "w" || o == "pie" || o == "web" || o == "wedge")  opt = "w";  N = 2
				elseif (o == "W" || o == "Pie" || o == "Web" || o == "Wedge")  opt = "W";  N = 2
				end
				if (N > 0)  marca, arg1, msg = helper_markers(opt, t[2], arg1, N, cst)  end
				(marca == "P") && (marca = "P$(t[2])")
				(msg != "") && error(msg)
				if (length(t) == 3 && isa(t[3], NamedTuple))
					if (marca == "w" || marca == "W")	# Ex (spiderweb): marker=(:pie, [...], (inner=1,))
						marca *= add_opt(t[3], (inner="/", arc="+a", radial="+r", size=("", arg2str, 1), pen=("+p", add_opt_pen)) )
					elseif (marca == "m" || marca == "M" || marca == "=")
						marca *= vector_attrib(t[3])
					end
				end
			elseif (isa(t, NamedTuple))		# e.g. marker=(pie=true, inner=1, ...)
				key = keys(t)[1];	opt = ""
				if     (key == :w || key == :pie || key == :web || key == :wedge)  opt = "w"
				elseif (key == :W || key == :Pie || key == :Web || key == :Wedge)  opt = "W"
				elseif (key == :b || key == :bar)     opt = "b"
				elseif (key == :B || key == :HBar)    opt = "B"
				elseif (key == :l || key == :letter)  opt = "l"
				elseif (key == :K || key == :Custom)  opt = "K"
				elseif (key == :k || key == :custom)  opt = "k"
				elseif (key == :M || key == :Matang)  opt = "M"
				elseif (key == :P || key == :sphere)  opt = "P"
				elseif (key == :m || key == :matang)  opt = "m"
				elseif (key == :geovec)  opt = "="
				end
				if (opt == "w" || opt == "W")
					marca = opt * add_opt(t, (size=("", arg2str, 1), inner="/", arc="+a", radial="+r", pen=("+p", add_opt_pen)))
				elseif (opt == "b" || opt == "B")
					marca = opt * add_opt(t, (size=("", arg2str, 1), base="+b", Base="+B"))
				elseif (opt == "l")
					marca = opt * add_opt(t, (size=("", arg2str, 1), letter="+t", justify="+j", font=("+f", font)))
				elseif (opt == "m" || opt == "M" || opt == "=")
					marca = opt * add_opt(t, (size=("", arg2str, 1), arrow=("", vector_attrib)))
				elseif (opt == "k" || opt == "K")
					marca = opt * add_opt(t, (custom="", size="/"))
				elseif (opt == "P")
					marca = opt * add_opt(t, (sphere=("", arg2str, 1), size=("", arg2str, 2), azim="+a", elev="+e", flat="_+f", nofill="_+n", no_fill="_+n"))
					(marca == "P") && (marca = "P7p")					# Default size 7p if none given
					(marca[2] == '+') && (marca = "P7p" * marca[2:end])	# 	iden
				end
			else
				t1::String = string(t)
				(t1[1] != 'T') && (t1 = lowercase(t1))
				if     (t1 == "-" || t1 == "x-dash")    marca = "-"
				elseif (t1 == "+" || t1 == "plus")      marca = "+"
				elseif (t1 == "a" || t1 == "*" || t1 == "star")  marca = "a"
				elseif (t1 == "k" || t1 == "custom")    marca = "k"
				elseif (t1 == "x" || t1 == "cross")     marca = "x"
				elseif (is3D)
					(t1 == "P" || t1 == "sphere") && (marca = "P")
					(t1 == "u" || t1 == "cube") && (marca = "u")		# Must come before next line
				elseif (t1[1] == 'c')                   marca = "c"
				elseif (t1[1] == 'd')                   marca = "d"		# diamond
				elseif (t1 == "g" || t1 == "octagon")   marca = "g"
				elseif (t1[1] == 'h')                   marca = "h"		# hexagon
				elseif (t1 == "i" || t1 == "inverted_tri")  marca = "i"
				elseif (t1[1] == 'l')                   marca = "l"		# letter
				elseif (t1 == "n" || t1 == "pentagon")  marca = "n"
				elseif (t1 == "p" || t1 == "." || t1 == "point")  marca = "p"
				elseif (t1[1] == 's')                   marca = "s"		# square
				elseif (t1[1] == 't' || t1 == "^")      marca = "t"		# triangle
				elseif (t1[1] == 'T')                   marca = "T"		# Triangle
				elseif (t1[1] == 'y')                   marca = "y"		# y-dash
				elseif (t1[1] == 'f')                   marca = "f"		# for Faults in legend
				elseif (t1[1] == 'q')                   marca = "q"		# for Quoted in legend
				end
				t1 = string(t)		# Repeat conversion for the case it was lower-cased above
				# Still need to check the simpler forms of these
				if (marca == "")  marca = helper2_markers(t1, ["e", "ellipse"])   end
				if (marca == "")  marca = helper2_markers(t1, ["E", "Ellipse"])   end
				if (marca == "")  marca = helper2_markers(t1, ["j", "rotrect"])   end
				if (marca == "")  marca = helper2_markers(t1, ["J", "RotRect"])   end
				if (marca == "")  marca = helper2_markers(t1, ["m", "matangle"])  end
				if (marca == "")  marca = helper2_markers(t1, ["M", "Matangle"])  end
				if (marca == "")  marca = helper2_markers(t1, ["r", "rectangle"])   end
				if (marca == "")  marca = helper2_markers(t1, ["R", "RRectangle"])  end
				if (marca == "")  marca = helper2_markers(t1, ["v", "vector"])  end
				if (marca == "")  marca = helper2_markers(t1, ["V", "Vector"])  end
				if (marca == "")  marca = helper2_markers(t1, ["w", "pie", "web"])  end
				if (marca == "")  marca = helper2_markers(t1, ["W", "Pie", "Web"])  end
			end
			(del) && delete!(d, symb)
			break
		end
	end
	return marca, arg1, N > 0
end

function helper_markers(opt::String, ext, arg1::GMTdataset, N::Int, cst::Bool)
	# Helper function to deal with the cases where one sends marker's extra columns via command
	# Example that will land and be processed here:  marker=(:Ellipse, [30 10 15])
	# N is the number of extra columns
	marca::String = "";	 msg = ""
	if (size(ext,2) == N)	# Here ARG1 is supposed to be a matrix that will be extended.
		S = Symbol(opt)
		t = arg1.data	# Because we need to passa matrix to this method of add_opt()
		marca, t = add_opt(add_opt, (Dict{Symbol,Any}(S => (par=ext,)), opt, "", [S]), (par="|",), true, t)
		arg1.data = t;		add2ds!(arg1)
	elseif (cst && length(ext) == 1)
		marca = opt * "-" * string(ext)::String
	else
		msg = string("Wrong number of extra columns for marker (", opt, "). Got ", size(ext,2), " but expected ", N)
	end
	return marca, arg1, msg
end

function helper2_markers(opt::String, alias::Vector{String})::String
	marca = ""
	if (opt == alias[1])			# User used only the one letter syntax
		marca = alias[1]
	else
		for k = 2:length(alias)		# Loop because of cases like ["w" "pie" "web"]
			o2 = alias[k][1:min(2,length(alias[k]))]	# check the first 2 chars and Ro, Rotrect or RotRec are all good
			#if (startswith(opt, o2))  marca = alias[1]; break  end		# Good when, for example, marker=:Pie
			if (startswith(opt, o2))	# Good when, for example, marker=:Pie
				marca = alias[1];
				(opt[end] == '-') && (marca *= '-')
				break 
			end
		end
	end

	# If we still have found nothing, assume that OPT is a full GMT opt string (e.g. W/5+a30+r45+p2,red)
	(marca == "" && opt[1] == alias[1][1]) && (marca = opt)
	return marca
end

# ---------------------------------------------------------------------------------------------------
function seek_custom_symb(marca::AbstractString, with_k::Bool=false)::String
	# If 'marca' is a custom symbol, seek it first in GMT.jl share/custom dir.
	# Return the full name of the marker plus extension
	# The WITH_K arg is to allow calling this fun with a sym name already prefaced with 'k', or not
	(with_k && marca[1] != 'k') && return marca		# Not a custom symbol, return what we got.

	function find_this_file(pato, symbname)
		for (root, dirs, files) in walkdir(pato)
			ind = findfirst(startswith.(files, symbname))
			if (ind !== nothing)  return joinpath(root, files[ind])  end
		end
		return ""
	end

	s = split(marca, '/')
	ind_s = with_k ? 2 : 1
	symbname = s[1][ind_s:end]
	cus_path = joinpath(dirname(pathof(GMTmodule[]))[1:end-4], "share", "custom")

	fullname = find_this_file(cus_path, symbname)
	if (fullname == "")
		cus_path2 = joinpath(GMTuserdir[1], "cache_csymb")
		cus_path2 = replace(cus_path2, "/" => "\\")	# Otherwise it will produce currupted PS
		fullname  = find_this_file(cus_path2, symbname)
	end

	(fullname == "") && return marca		# Assume it's a custom symbol from the official GMT collection.

	_siz  = split(marca, '/')[2]			# The custom symbol size
	_marca = (with_k ? "k" : "")  * fullname * "/" * _siz
	(GMTver <= v"6.4" && (length(_marca) - length(_siz) -2) > 62) && warn("Due to a GMT <= 6.4 limitation the length of full (name+path) custom symbol name cannot be longer than 62 bytes.")
	return _marca
end
