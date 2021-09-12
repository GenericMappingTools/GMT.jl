# Addapted from the original https://github.com/JuliaGeo/GADM.jl (MIT Licensed)
# and stripped from all of it's dependencies (ArchGDAL repaced by the GMT GDAL functions).
# Loosing the Tables.jl, however, is a limitation since the `children` output is now
# difficult to interpret. Must do something about this one of these days.

"""
    GADM(country, subregions...; children=false)

Returns a GMTdataset for the requested country, or country subregion

1. country: ISO 3166 Alpha 3 country code  
2. subregions: Full official names in hierarchial order (provinces, districts, etc.)  
3. children: When true, function returns two variables -> parent, children.  
Eg. when children is set true when querying just the country,
second return parameter are the states/provinces. WARNING, since the Tables.jl dependency
was dropped (from the original GADM.jl) this second output is, for now, difficult to interpret

## Examples  
  
```julia
# data of India's borders
data = GADM("IND")
# parent -> state data, children -> all districts inside Uttar Pradesh
parent, children = GADM("IND", "Uttar Pradesh"; children=true)
```
"""
function GADM(country, subregions...; children=false)
	isvalidcode(country) || throw(ArgumentError("please provide standard ISO 3 country codes"))
	data_pato = country |> _download		# Downloads and extracts dataset of the given country code
	data = Gdal.read(data_pato)
	!isnothing(data) ? data : throw(ArgumentError("failed to read data from disk"))
	nlayers = Gdal.nlayer(data)

	function _filterlayer(layer, key, value, all=false)
		filtered = []
		for row in layer
			index = Gdal.findfieldindex(row, Symbol(key))
			field = Gdal.getfield(row, index)
			if all || occursin(lowercase(value), lowercase(field))
				push!(filtered, row)
			end
		end
		filtered
	end

	function _getlayer()
		# Get layer of the desired `level` from the `data`.
		nlayers = Gdal.nlayer(data)
		for l = 0:nlayers - 1
			layer = Gdal.getlayer(data, l)
			lname = Gdal.getname(layer)
			llevel = last(split(lname, "_"))
			string(plevel) == llevel && return layer
		end
		throw(ArgumentError("asked for level $(plevel), valid levels are 0-$(nlayers - 1)"))
	end

	# p -> parent, is the requested region
	plevel = length(subregions)
	plevel >= nlayers && throw(ArgumentError("more subregions provided than actual")) 
	pname = isempty(subregions) ? "" : last(subregions)
	player = _getlayer()
	p = _filterlayer(player, "NAME_$(plevel)", pname, iszero(plevel))
	isempty(p) && throw(ArgumentError("could not find required region"))
	D = gd2gmt(getgeom(p[1], 0),"")
	((prj = getproj(Gdal.getlayer(data, 0))) != C_NULL) && (D[1].proj4 = toPROJ4(prj))

	!children && return D

	# c -> children, is the region 1 level lower than p
	clevel = plevel + 1
	clevel == nlayers && return (D, nothing)
	clayer = _getlayer()
	c = _filterlayer(clayer, "NAME_$(plevel)", pname, iszero(plevel))

	return D, c
end

# ------------------------------------------------------------------------------------------------------
# Tells whether or not `str` is a valid ISO 3166 Alpha 3 country code. Valid code examples are "IND", "USA", "BRA".
isvalidcode(str) = match(r"\b[A-Z]{3}\b", str) !== nothing

# ------------------------------------------------------------------------------------------------------
function _download(country)
	# Downloads data (for the first call) for `country` and returns its full name.
	ID, name_zip = "gadm36_$(country).gpkg", "gadm36_$(country)_gpkg.zip"
	cache = joinpath(readlines(`gmt --show-userdir`)[1], "cache")
	if !isdir(cache)
		((pato = mkdir(cache)) == "") && error("Failed to create the 'cache' dir where download file would be stored")
	end
	fname = joinpath(cache, ID)
	isfile(fname) && return fname

	println("Downloading geographic data for country $country provided by the https://gadm.org project. It may take a while.")
	println("The file $ID (after uncompressing) will be stored in $cache")
	dlfile = download("https://biogeo.ucdavis.edu/data/gadm3.6/gpkg/$(name_zip)", joinpath(cache, name_zip))
	curr_pato = pwd();	cd(cache)
	@static Sys.iswindows() ? run(`tar -xf $dlfile`) : run(`unzip $dlfile`)
	rm(dlfile)
	cd(curr_pato)
	return fname
end
