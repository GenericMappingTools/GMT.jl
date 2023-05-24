"""
Wraper function to interpolate swcattered data into a grid
"""
function gridit(fname::String="", arg1::Union{Nothing, MatGDsGd}=nothing; method::StrSymb="surface", proj="", epsg=0, kw...)

	d = KW(kw)
	len_d = length(d)
	d = seek_auto_RI(d, fname, arg1)

	(proj == "") && (proj = isa(arg1, GDtype) ? getproj(arg1, proj4=true) : "")
	(proj == "" && epsg != 0) && (proj = epsg2proj(epsg))
	_mtd = string(method)
	fun::Function = (_mtd == "surface" || startswith(_mtd, "curvature")) ? surface : startswith(_mtd, "tri") ? triangulate : startswith(_mtd, "nearne") ? nearneighbor : startswith(_mtd, "sph") ? sphtriangulate : startswith(_mtd, "green") ? greenspline : sin
	if (fun == sin)			# sin was just a fallback function to keep type stability
		(_mtd == "mean" || _mtd == "std" || _mtd == "highest" || _mtd == "lowest") && (fun = blockmean)
		(_mtd == "median") && (fun = blockmedian)
		(_mtd == "mode")   && (fun = blockmode)
		if (fun == blockmean || fun == blockmedian || fun == blockmode)
			d[:A] = _mtd
		elseif (startswith(_mtd, "nearest"))	# GDAL's nearest neighbor
			d[:N] = "n";	fun = nearneighbor
		elseif (_mtd == "linear" || _mtd == "average" || _mtd == "invdist" || _mtd == "invdistnn")
			fun = gdalgrid
		else
			error("Unknown interpolation method: $_mtd")
		end
	end
	G = (length(d) == len_d) ? fun(fname, arg1; kw...) : fun(fname, arg1; d...)
	(proj != "") && (G.proj4 = proj)
	G
end

gridit(arg1::MatGDsGd; method::StrSymb="surface", proj="", epsg=0, kw...) =
	gridit("", arg1; method=method, proj=proj, epsg=epsg, kw...)

# ---------------------------------------------------------------------------------------------------
function seek_auto_RI(d::Dict{Symbol,Any}, fname::String, arg1::Union{Nothing, MatGDsGd})
	# Check if -R -I was provided and if not make a wild guess of them. 
	have_R = (is_in_dict(d, [:R :region :limits]) !== nothing)
	have_I = (is_in_dict(d, [:I :inc :increment :spacing]) !== nothing)
	(have_R && !have_I) && error("When using 'region|limits' must also use 'inc|sapcing'")
	(!have_R && have_I) && error("When using 'inc|spacing' must also use 'region|limits'")
	if (!have_R && !have_I)
		d[:R], d[:I] = estimate_RI(fname != "" ? fname : arg1)
	end
	return d
end

# ---------------------------------------------------------------------------------------------------
function estimate_RI(indata)
	# Make a wild guess of -R -I
	if (isa(indata, AbstractString))
		s = split(gmt("gmtinfo " * indata).text[1], '\t')	# Must follow the parse path because we want
		W,E = parse.(Float64, split(s[2][2:end-1],'/'))		# also the number of points.
		S,N = parse.(Float64, split(s[3][2:end-1],'/'))
		np = parse(Int,split(s[1])[end])
	else
		D::GDtype = isa(indata, Gdal.AbstractDataset) ? gd2gmt(indata) : indata
		W,E,S,N = isa(D, GMTdataset) ? D.bbox[1:4] : D[1].ds_bbox[1:4]
		np = sum(length.(D))
	end
	inc = round(sqrt(((E-W)*(N-S)) / np) * 4, digits=4)
	nx = round(Int, (E-W) / inc) + 1
	ny = round(Int, (N-S) / inc) + 1
	opt_I = @sprintf("%.10g", inc)
	opt_R = @sprintf("%.12g/%.12g/%.12g/%.12g", W, W+(nx-1)*inc, S, S+(ny-1)*inc)
	return opt_R, opt_I
end
