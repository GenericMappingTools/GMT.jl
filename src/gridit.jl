"""
    G = gridit(fname="", indata=nothing; method="surface", gdopts="", proj="", epsg=0, kw...)

Wrapper function to interpolate scattered data into a grid.
Interpolation methods may be those of GMT and GDAL (gdal_grid).

### Parameters
- `fname`: A file name containing the source dataset to be interpolated. It must contain at least 3 columns (x y z).
- `indata`: Alternative source dataset in the form of a GMTdataset, a Mx3 matrix or a GDAL dataset.
- `method`: The interpolation method name. One of (GMT): "surface" or "minimum curvature", "triangulate",
     "nearneighbor", "sphtriangulate", "greenspline". The arguments: "mean", "median", "mode", "std", "highest",
     "lowest" will compute those amounts inside each *rectangular* cell.

     - Or (GDAL): "invdist", "invdistnn", "average", "nearest", "linear", "minimum", "maximum", "range",
     "count", "average_distance", "average_distance_pts". See https://gdal.org/programs/gdal_grid.html#gdal-grid

     - Note that there is some overlap between the diverse methods. For example, the GMT's ``nearneighbor``
     and GDAL's ``invdist`` apply the same algorithm (the Inverse Distance Weight) but they difer on how
     to select the points to do the weighted average.
- `gdopts`: List of options, in the form of a single string, accepted by the gdal_grid utility. This option
     only applies to the GDAL methods.
- `proj`: An optional proj4 string describing the data's coordinate system. Note that this not imply any
     data projection. The input data may itself already carry this information, case in which this option
     is not necessary.
- `wkt`: An optional wkt string describing the data's coordinate system. Same comments as `proj`
- `epsg`: An optional epsg code describing the data's coordinate system. Same comments as `proj`

# Kwargs
* `kw...` keyword=value arguments. These are used to pass options that are specific to a particular GMT
     interpolation methods. The user must consult individual manual pages to learn about the available
     possibilities. Two very important (actually, mandatory) *options* are the `region=...` and the
     `inc=...` that select the grid limits and the grid resolution. However, if they are not provided
     (or only one of them is) we make a very crude estimate based on data limits and point density.
     But this should only be used for a very exploratory calculation.
- `preproc`: This option only applies to the `method=:surface` and means that the data is previously passed
     through one of ``block*`` modules to decimate the data in each cell as strongly advised by the ``surface``
     program. `preproc=true` will use ``blockmean``. To use any of the other two, pass its name as value.
     *e.g.* `preproc="blockmedian"`.

### Returns
A GMTgrid or nothing if file was writen on disk.

### Example
    G = gridit("@ship_15.txt", method=:surface, mask=0.3, preproc=true);
"""
function gridit(fname::String="", arg1::Union{Nothing, MatGDsGd}=nothing; method::StrSymb="surface",
                gdopts::String="", proj="", epsg=0, kw...)

	d = KW(kw)
	len_d = length(d)
	d = seek_auto_RI(d, fname, arg1)

	(proj == "") && (proj = isa(arg1, GDtype) ? getproj(arg1, proj4=true) : "")
	(proj == "" && epsg != 0) && (proj = epsg2proj(epsg))
	_mtd = string(method)
	fun::Function = (_mtd == "surface" || contains(_mtd, "curvature")) ? surface : startswith(_mtd, "tri") ? triangulate : startswith(_mtd, "nearne") ? nearneighbor : startswith(_mtd, "sph") ? sphtriangulate : startswith(_mtd, "green") ? greenspline : sin
	if (fun == sin)			# sin was just a fallback function to keep type stability
		(_mtd == "mean" || _mtd == "std" || _mtd == "highest" || _mtd == "lowest") && (fun = blockmean)
		(_mtd == "median") && (fun = blockmedian)
		(_mtd == "mode")   && (fun = blockmode)
		if (fun == blockmean || fun == blockmedian || fun == blockmode)
			d[:A] = _mtd
		elseif (startswith(_mtd, "nearest"))	# GDAL's nearest neighbor
			d[:N] = "n";	fun = nearneighbor
		elseif (startswith(_mtd, "linear") || startswith(_mtd, "average") || startswith(_mtd, "invdist") || startswith(_mtd, "invdistnn") || startswith(_mtd, "minimum") || startswith(_mtd, "maximum") || startswith(_mtd, "range") || startswith(_mtd, "count") || startswith(_mtd, "average_distance") || startswith(_mtd, "average_distance_pts"))
			fun = gdalgrid
		else
			error("Unknown interpolation method: $_mtd")
		end
	end
	if (fun == gdalgrid)
		if (occursin(' ', _mtd))	# Allow also a syntax with spaces, e.g.: method="average radius=0.3"
			s = split(_mtd)
			for k = 2:numel(s) s[k][1] != ':' && (s[k] = ':' * s[k])  end
			_mtd = join(s)						# Join back into a string with no spaces.
		end
		G = gdalgrid((fname != "") ? fname : arg1, gdopts, method=_mtd, R=d[:R], I=d[:I])
	else
		G = (length(d) == len_d) ? fun(fname, arg1; kw...) : fun(fname, arg1; d...)
	end
	(proj != "") && (G.proj4 = proj)
	G
end

gridit(arg1::MatGDsGd; method::StrSymb="surface", proj="", epsg=0, kw...) =
	gridit("", arg1; method=method, proj=proj, epsg=epsg, kw...)

# ---------------------------------------------------------------------------------------------------
function seek_auto_RI(d::Dict{Symbol,Any}, fname::String, arg1::Union{Nothing, MatGDsGd})
	# Check if -R -I was provided and if not make a wild guess of them. 
	opt_RI, opt_R = parse_RIr(d, "", false, false)
	opt_I = (opt_RI != opt_R) ? split(opt_RI)[1] : ""	# opt_RI has -I first than -R
	have_R, have_I = (opt_R != ""), (opt_RI != opt_R)

	if (!have_R && !have_I)
		d[:R], d[:I] = estimate_RI(fname != "" ? fname : arg1)
	elseif (!have_R && have_I)
		opt_r = parse_r(d, "", false)[1]
		if (fname != "")
			d[:R] = gmt("gmtinfo " * fname * " " * opt_I * opt_r).text[1][3:end]
		else
			D::GDtype = isa(arg1, Gdal.AbstractDataset) ? gd2gmt(arg1) : isa(arg1, Matrix{<:Real}) ? mat2ds(arg1) : arg1
			d[:R] = gmt("gmtinfo " * opt_I * opt_r, D).text[1][3:end]
		end
	elseif (have_R && !have_I)
		np = (fname != "") ? get_limits_np(fname)[5] : get_limits_np(arg1)[5]
		W, E, S, N = parse.(Float64, split(opt_R[4:end], '/'))
		inc = sqrt(((E-W)*(N-S)) / np) * 4
		inc_x = (E-W) / (round(Int, (E-W) / inc))
		inc_y = (N-S) / (round(Int, (N-S) / inc))
		d[:I] = @sprintf("%.12g/%.12g", inc_x, inc_y)
	end
	return d
end

# ---------------------------------------------------------------------------------------------------
function estimate_RI(indata)
	# Make a wild guess of -R -I
	W, E, S, N, np = get_limits_np(indata)
	inc = round(sqrt(((E-W)*(N-S)) / np) * 4, digits=6)
	nx = round(Int, (E-W) / inc) + 1
	ny = round(Int, (N-S) / inc) + 1
	opt_I = @sprintf("%.12g", inc)
	opt_R = @sprintf("%.12g/%.12g/%.12g/%.12g", W, W+(nx-1)*inc, S, S+(ny-1)*inc)
	return opt_R, opt_I
end

# ---------------------------------------------------------------------------------------------------
function get_limits_np(indata)
	# Get the data limits and nunmber of points. 'indata' can be a file name, a Matrix, a D or a Gdal obj.
	if (isa(indata, AbstractString))
		s = split(gmt("gmtinfo " * indata).text[1], '\t')	# Must follow the parse path because we want
		W,E = parse.(Float64, split(s[2][2:end-1],'/'))		# also the number of points.
		S,N = parse.(Float64, split(s[3][2:end-1],'/'))
		np = parse(Int,split(s[1])[end])
	else
		D::GDtype = isa(indata, Gdal.AbstractDataset) ? gd2gmt(indata) : isa(indata, Matrix{<:Real}) ? mat2ds(indata) : indata
		W,E,S,N = isa(D, GMTdataset) ? D.bbox[1:4] : D[1].ds_bbox[1:4]
		np = isa(D, GMTdataset) ? size(D,1) : sum(size.(D,1))
	end
	return W, E, S, N, np
end
