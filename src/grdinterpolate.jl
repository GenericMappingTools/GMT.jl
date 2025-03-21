"""
	grdinterpolate(cmd0="", arg1=nothing, arg2=nothing; kwargs...)

Interpolate a 3-D cube, 2-D grids or 1-D series from a 3-D data cube or stack of 2-D grids.

See full GMT (not the `GMT.jl` one) docs at [`grdinterpolate`]($(GMTdoc)/grdinterpolate.html)

Parameters
----------

- **D** | **meta** | **metadata** :: [Type => Str | NamedTuple]  

    Give one or more combinations for values xname, yname, zname (3rd dimension in cube), and dname
    (data value name) and give the names of those variables and in square bracket their units
- **E** | **crossection** :: [Type => Str | GMTdtaset | NamedTuple]

    Specify a crossectinonal profile via a file or from specified line coordinates and modifiers. If a file,
    it must contain a single segment with either lon lat or lon lat dist records. These must be equidistant. 
- **F** | **interp_type** | **interpolator** :: [Type => Str]   ``Arg = l|a|c|n[+1|+2]``

    Choose from l (Linear), a (Akima spline), c (natural cubic spline), and n (no interpolation:
    nearest point) [Default is Akima].
- **G** | **outfile** | **outgrid** :: [Type => Str]

    Output file name. If `range` only selects a single layer then the data cube collapses to a regular 2-D grid file
- $(_opt_R)
- **S** | **pt** | **track** :: [Type => Str | Tuple | Dataset]	`Arg = x/y|pointfile[+hheader]`

    Rather than compute gridded output, create tile/spatial series through the stacked grids at the given point (x/y)
    or the list of points in pointfile. 
- **T** | **range** :: [Type => Str]			`Arg = [min/max/]inc[+i|n] |-Tfile|list`

    Make evenly spaced time-steps from min to max by inc [Default uses input times].
- **Z** | **levels** :: [Type => range]			`Arg = [levels]`

    The `levels` may be specified the same way as in `range`. If not given then we default to an integer
    levels array starting at 0.
- $(opt_V)
- $(_opt_bi)
- $(opt_bo)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_n)
- $(opt_o)
- $(opt_q)
- $(opt_s)
- $(opt_swap_xy)

When using two numeric inputs and no `outfile` option, the order of the x,y and grid is not important.
That is, both of this will work: ``D = grdinterpolate([0 0], G);``  or  ``D = grdinterpolate(G, [0 0]);``

When using the `pt` or `crossection` options the default is to NOT ouput the redundant horizontal x,y coordinates
(contrary to the GMT default). If you want to have them, use option `colinfo`, *e.g.* `colinfo="0-3"`,
or use `allcols=true`.

To see the full documentation type: ``@? grdinterpolate``
"""
grdinterpolate(cmd0::String; kwargs...) = grdinterp_helper(cmd0, nothing; kwargs...)
grdinterpolate(arg1; kwargs...)         = grdinterp_helper("", arg1; kwargs...)

function grdinterp_helper(cmd0::String, arg1; allcols::Bool=false, gdal=false, kwargs...)

	arg2 = nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_common_opts(d, "", [:R :V_params :bi :bo :di :e :f :g :h :i :n :o :q :s :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:G :outfile :outgrid], [:Z :levels]])

	cmd = add_opt(d, cmd, "D", [:D :meta :metadata],
          (xname="+x", yname="+y", zname="+z", dname="+d", scale="+s", offset="+o", nodata="+n", title="+t", remark="+r", varname="+v"))
	cmd = add_opt(d, cmd, "F", [:F :interpolator :interp_type],
          (linear="_l", akima="_a", cubic="_c", nearest="_n", first_derivative="+1", second_derivative="+2"))

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)

	cmd, args, n1, = add_opt(d, cmd, "E", [:E :crossection], :line, Vector{Any}([arg1, arg2]), (azim="+a", great_circ="_+g", parallel="_+p", inc="+i", length="+l", npoints="+n", middpoint="+o", radius="+r", loxodrome="_+x"))
	(n1 == 1) && (arg1 = args[1])
	(n1 == 2) && (arg2 = args[2])

	if ((val = find_in_dict(d, [:S :track :pt])[1]) !== nothing)
		if (isa(val, String))
			_fn::String = string(val)			# Damn Any's
			if (isnumeric(_fn[1]) && contains(_fn, '/') && (pts_num = tryparse.(Float64, split(_fn, '/'))) === nothing)
				pts = mat2ds([pts_num[1] pts_num[2]])
			else
				!isfile(_fn) && error("File not found: $_fn")
				pts = gmtread(_fn, data=true)
			end
		elseif ((isa(val, Vector) || isa(val, Tuple)) && length(val) >= 2)
			pts = mat2ds(Float64.([val[1] val[2]]))
			#cmd *= " -S" * arg2str(val)
		elseif (isa(val, Matrix{<:Real}))
			pts = mat2ds(Float64.(val))
		elseif (isGMTdataset(val))
			pts = val
			#(arg1 === nothing) ? arg1 = val : ((arg2 === nothing) ? arg2 = val : arg3 = val)
			#cmd *= " -S"
		else  error("Bad data type for option `track` $(typeof(val))")
		end

		no_coords = (haskey(d, :no_coords) || haskey(d, :nocoords))		# Output or not the x,y coordinates
		if (gdal == 0 && (cmd0 != "" || contains(cmd, " -Z")))		# Passed in a cube file name or a grid's collection. Job for GMT grdinterpolate
			arg1 = pts
			cmd *= " -S"
		else					# GMT can't handle cubes in memory, so we have to do it here
			(gdal == 1 && cmd0 != "") && return grdinterp_local_opt_S(cmd0, pts, no_coords)		# Passed in a cube file name
			return grdinterp_local_opt_S(arg1, pts, no_coords, gdal=gdal)	# EXIT here
		end
	end

	cmd = parse_opt_range(d, cmd, "T")[1]

	out_two_cols = !allcols && occursin(" -S", cmd) && !occursin(" -o", cmd)
	out_two_cols && (cmd *= " -o2,3")		# The default is NOT ouput the first two columns (redundant)

	if (isa(arg1, Tuple))
		cmd *= repeat(" ?", length(arg1))	# Need as many '?' as numel(arg1)
		common_grd(d, "grdinterpolate " * cmd, arg1..., arg2)
	else
		if (cmd0 != "" && !contains(cmd, " -R") && val !== nothing)		# Since GMT will read layer-by-layer, better to limit to the region framing the points
			D = grdinfo(cmd0, C=true)
			x_min = max(D[1], pts.ds_bbox[1]-D[9]*3);	x_max = min(D[2], pts.ds_bbox[2]+D[9]*3)
			y_min = max(D[3], pts.ds_bbox[3]-D[10]*3);	y_max = min(D[4], pts.ds_bbox[4]+D[10]*3)
			cmd *= " -R$x_min/$x_max/$y_min/$y_max"
		end
		common_grd(d, "grdinterpolate " * cmd, arg1, arg2)
	end
end

# ---------------------------------------------------------------------------------------------------
# Minimalist method that uses GDAL. Needs to be expanded to handle, at least, a -R option.
function grdinterp_local_opt_S(fname::AbstractString, pts::GMTdataset, no_coords::Bool)
	r = Gdal.gdalrasterinterpolate(fname, pts; method=Gdal.GRIORA_Cubic)
	D = mat2ds([collect(1:length(r)) r])
	!isempty(pts.attrib) && (D.attrib = pts.attrib)		# Pass on the points attributes as well. But no colnames from bands.
	D.colnames = ["Layer", "Value"]
	return D
end

function grdinterp_local_opt_S(arg1::GItype, pts::GMTdataset, no_coords::Bool; rowlayers=false, gdal=false)
	# GMT grdinterpolate can't handle cubes in memory, so we have to do the interpolations here.
	# If 'rowlayers' is true the output rows will have first 2 columns with the cordinates (or not if 'no_coords=true')
	# followed by the interpolated values at each layer. If 'rowlayers' is false, first column holds the
	# layer number and the rest in the output each column contains the vertical profile for each point.
	# In this case the point coordinates are not output.
	# This whole thing needs further documentation and testing.
	# Up. Don't understand anymore this 'rowlayers' thing and it doesn't seem to be ever used nor to work well.
	n_pts, n_layers = size(pts,1), size(arg1,3)
	DT = no_coords ? eltype(arg1) : eltype(pts)			# When we have coordinates, their type dominates.
	if (rowlayers)
		D = no_coords ? mat2ds(Matrix{DT}(undef, n_pts, n_layers)) : mat2ds([pts.data zeros(DT, n_pts, n_layers)])
	else
		D = mat2ds(Matrix{DT}(undef, n_layers, n_pts+1))
		layer_vals = isa(arg1.v, Vector{<:Real}) ? arg1.v : collect(1:n_layers)
	end
	startcol = no_coords ? 0 : 2				# This is used only in the 'rowlayers' case
	if (gdal)
		reg = arg1.registration
		pl = [((pts[:,1] .- arg1.range[1]) / arg1.inc[1] .- reg) ((size(arg1,1)-1) .- (pts[:,2] .- arg1.range[3]) / arg1.inc[2] .- reg)]
		(reg == 0) && (pl .+= [0.5 0.5])		# Because on the GDAL side registration is always pixel
		r = Gdal.gdalrasterinterpolate(gmt2gd(arg1), pl; method=Gdal.GRIORA_Cubic)
		D.data[:,2:end] .= r
		D.data[:,1] .= layer_vals
	else
		for k = 1:n_layers
			t = grdtrack(slicecube(arg1, k), pts, o=2)		# Want only the third column
			if (rowlayers)  D[:, k+startcol] .= convert.(DT, t.data)
			else
				for i = 1:n_pts  D.data[k,i+1] = t.data[i]  end
				D.data[k,1] = layer_vals[k]
			end
		end
	end
	set_dsBB!(D)	
	!isempty(pts.attrib) && (D.attrib = pts.attrib)		# Pass on the points attributes as well.

	grdinterp_opt_S_colnames!(arg1, D, pts, n_layers, startcol)		# Add colnames from band names in D if possible
	return D
end

# ---------------------------------------------------------------------------------------------------
function grdinterp_local_opt_S(arg1::GItype, pts::Vector{<:GMTdataset}, no_coords::Bool)
	# More complicated case of a multi-segment file
	# This method has no 'rowlayers' option because it is meant to be used for image classifications that
	# pass in multi-segment files (groups for training).
	# This whole thing needs further documentation and testing.
	n_layers = size(arg1,3)
	startcol = no_coords ? 0 : 2
	D = Vector{GMTdataset{Float64,2}}(undef, length(pts))
	DT = no_coords ? eltype(arg1) : eltype(pts[1])		# When we have coordinates, their type dominates.
	(DT <: Integer) && (DT = eltype(pts[1]))			# We don't want conversions to integers that are a pain. Specially if UInt8.
	for n = 1:length(pts)					# Loop over number of segments and initialize the output dataset vector
		n_pts = size(pts[n],1)
		D[n] = no_coords ? mat2ds(Matrix{DT}(undef, n_pts, n_layers)) : mat2ds([pts[n].data zeros(DT, n_pts, n_layers)])
		!isempty(pts[n].attrib) && (D[n].attrib = pts[n].attrib) 
	end
	for k = 1:n_layers
		t = grdtrack(slicecube(arg1, k), pts, o=2)		# Want only the third column
		for n = 1:length(pts)				# Loop again over number of segments and add this_layer column
			D[n][:, k+startcol] .= convert.(DT, t[n].data)
		end
	end
	set_dsBB!(D)

	grdinterp_opt_S_colnames!(arg1, D, pts, n_layers, startcol)		# Add colnames from band names in D if possible
	return D
end

# ---------------------------------------------------------------------------------------------------
function grdinterp_opt_S_colnames!(arg1, D, pts, n_layers, startcol)
	# Use band names in output column names. A little more convoluted because must deal with vector-scalar DS case
	all(isempty.(arg1.names)) && return nothing		# Quick, nothing usefull to do here.

	colnames = Vector{String}(undef, n_layers + startcol)
	for k = 1:n_layers
		colnames[k+startcol] = string(split(arg1.names[k], " [")[1])	# "Band2 - Blue [0.45-0.51]" is too long.
	end
	if (startcol == 2)
		isgeog(arg1) ? (colnames[1] = "Lon"; colnames[2] = "Lat") : (colnames[1] = "X"; colnames[2] = "Y")
	end
	if isa(D, Vector)
		for n = 1:numel(D)  D[n].colnames = colnames  end
	else
		D.colnames = colnames
	end
	return nothing
end
