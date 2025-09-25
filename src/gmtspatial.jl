"""
	gmtspatial(cmd0::String="", arg1=nothing, kwargs...)

Geospatial operations on points, lines and polygons.

Parameters
----------

- **A** | **nn** | **nearest_neighbor** :: [Type => Str]     `Arg = [amin_dist][unit]`

    Perform spatial nearest neighbor (NN) analysis: Determine the nearest neighbor of each point
    and report the NN distances and the point IDs involved in each pair.
- **C** | **clip** :: [Type => Bool]

    Clips polygons to the map region, including map boundary to the polygon as needed. The result is a closed polygon.
- **D** | **duplicates** :: [Type => Str]   `Arg = [+ffile][+aamax][+ddmax][+c|Ccmax][+sfact]`

    Check for duplicates among the input lines or polygons, or, if file is given via +f, check if the
    input features already exist among the features in file.
- **E** | **handedness** :: [Type => Str]  `Arg = +|-`

    Reset the handedness of all polygons to match the given + (counter-clockwise) or - (clockwise). Implies Q+
- **F** | **force_polygons** :: [Type => Str | []]   `Arg = [l]`

    Force input data to become polygons on output, i.e., close them explicitly if not already closed.
    Optionally, append l to force line geometry.
- **I** | **intersections** :: [Type => Str | []]   `Arg = [e|i]`

    Determine the intersection locations between all pairs of polygons.
- **N** | **in_polygons** | **in_polyg** :: [Type => Str]     `Arg = pfile[+a][+pstart][+r][+z]`

    Determine if one (or all, with +a) points of each feature in the input data are inside any of
    the polygons given in the pfile.
- **Q** | **centroid** or **area** or **length** :: [Type => Str]      `Arg = [[unit][+cmin[/max]][+h][+l][+p][+s[a|d]]`

    Measure the area of all polygons or length of line segments.
- $(_opt_R)
- **S** | **polygons** :: [Type => Str]     `Arg = h|i|j|s|u`

    Spatial processing of polygons.
- **T** | **truncate** :: [Type => Str | []]     `Arg = [clippolygon]`

    Truncate polygons against the specified polygon given, possibly resulting in open polygons.
- $(opt_V)
- **W** | **extend** :: [Type => Str | Tuple]     `Arg = <dist>[<unit>][+f|l]`

    Extend all segments with extra first and last points that are <dist> units away from the original
    end points in the directions implied by the line ends.

"""
gmtspatial(cmd0::String, arg1=nothing; kw...) = gmtspatial_helper(cmd0, arg1, nothing; kw...)
gmtspatial(arg1; kw...) = gmtspatial_helper("", arg1, nothing; kw...)
gmtspatial(arg1, arg2; kw...) = gmtspatial_helper("", arg1, arg2; kw...)

# ---------------------------------------------------------------------------------------------------
function gmtspatial_helper(cmd0::String, arg1, arg2; kw...)
	(cmd0 == "" && arg1 === nothing && arg2 === nothing && length(kwargs) == 0) && return gmt("gmtspatial")
	d = init_module(false, kw...)[1]			# Also checks if the user wants ONLY the HELP mode
	isa(arg1, Matrix) && (arg1 = mat2ds(arg1))
	invokelatest(_gmtspatial_helper, cmd0, arg1, arg2, d)
end

function _gmtspatial_helper(cmd0::String, arg1, arg2, d::Dict)::Union{GMTdataset{Float64,2}, Vector{<:GMTdataset{Float64,2}}}

	arg3 = nothing;     arg4 = nothing

	cmd, = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :nn :nearest_neighbor], [:C :clip], [:E :handedness], [:F :force_polygons],
	                                 [:I :intersections], [:Q :centroid :area :length], [:W :extend]])
	cmd = add_opt(d, cmd, "S", [:S :polygons :polyg_process], (buffer="b", holes="_h", intersection ="_i", dateline="_s", union="_u"))

	cmd, args, n, = add_opt(d, cmd, "D", [:D :duplicates], :data, [arg1, arg2], (amax="+a", dmax="+d", cmax="+c", Cmax="+c", fact="+s", ortho="_+p"))
	if (n > 0)
		arg1, arg2 = args[:];   cmd *= "+f"
	end
 
	cmd, args, n, = add_opt(d, cmd, "N", [:N :in_polyg :in_polygons], :data, Array{Any,1}([arg1, arg2, arg3]), (all="_+a", start="+p", has_feature="_+r", add_IDs="_+z", individual="_+i"))
	if (n > 0)  arg1, arg2, arg3 = args[:]  end

	cmd, args, n, = add_opt(d, cmd, "T", [:T :truncate], :data, Array{Any,1}([arg1, arg2, arg3, arg4]), (x="",))
	if (n > 0)  arg1, arg2, arg3, arg4 = args[:]  end

	do_sort = (find_in_dict(d, [:sort])[1] !== nothing)
	if (isa(arg1,Tuple))
		D = common_grd(d, cmd0, cmd, "gmtspatial ", arg1..., arg2, arg3, arg4)		# Finish build cmd and run it
		arg = arg1[end]
	else
		isa(arg1, GDtype) && isgeog(arg1) && !contains(cmd, " -f") && (cmd *= " -fg")
		D = common_grd(d, cmd0, cmd, "gmtspatial ", arg1, arg2, arg3, arg4)
		arg = arg2
	end
	hasID = (isa(arg, GMTdataset) && (contains(arg.header, "-Z") || contains(arg.header, "-L"))) ||	# To know if add +1 to start at 1
	        (isa(arg, Vector{<:GMTdataset}) && (contains(arg[1].header, "-Z") || contains(arg[1].header, "-L")))
	if (do_sort && !isempty(D))
		ind = sortperm(view(D, :, 3))
		D.data = D.data[ind, :]
		!isempty(D.text) && (D.text = D.text[ind])
	end

	if contains(cmd, "-N+i")
		D.colnames = ["x","y","polID"]
		sz = hasID ? 0 : size(D,1)
		for k = 1:sz  D[k,3] += 1  end
	elseif contains(cmd, " -Q")		# -Q -> centroids
		setgeom!(D, wkbPoint)		# -Q+l is probably a different geom
		D.colnames = getsize(D)[2] == 2 ? ["centroid_x","centroid_y"] : ["centroid_x","centroid_y","area"];
		if isa(D, GMTdataset)
			ind = findall(.!isfinite.(D.data[:,1]))
			#!isempty(ind) && (D.data = delrows!(D.data, ind))		# Can't do this because it changes the number of output rows
		end
	end
	set_dsBB!(D)
	D
end

# ---------------------------------------------------------------------------------------------------
#gmtspatial(arg1, arg2=nothing; kw...) = gmtspatial("", arg1, arg2; kw...)