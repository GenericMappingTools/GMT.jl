# Addapted from the original https://github.com/JuliaGeo/GADM.jl (MIT Licensed)
# and stripped from all of it's dependencies (ArchGDAL repaced by the GMT GDAL functions).
# Expanded to also return all subregions of a particular a particular administrative entity.
# To (partially) replace the role of the Tables.jl interface an option exists to print the
# names of all subregions of a parent administrative unit.

"""
    gadm(country, subregions...; children=false, names=false, children_raw=false, reportlevels=false)

Returns a GMTdataset for the requested country, or country subregion(s)

1. `country`: ISO 3166 Alpha 3 country code  
2. subregions: Full official names in hierarchial order (provinces, districts, etc.)
   To know the names of all administrative children of parent, use the option `names`
3. `children`: When true, function returns all subregions of parent
4. `children_raw`: When true, function returns two variables -> parent, children, where children is a GDAL object
   E.g. when children is set to true and when querying just the country,
   second return parameter are the states/provinces. If `children` we return a Vector of GMTdataset with
   the polygons. If `children_raw` the second output is a GDAL object much like in GADM.jl (less the Tables.jl) 
5. `reportlevels`: just report the number of administrative levels (including the country) and exit.

## Examples  
  
```julia
# data of India's borders
data = gadm("IND")

# uttar -> the limits of the Uttar Pradesh state
uttar = gadm("IND", "Uttar Pradesh, children=true)

# uttar -> limits of all districts of the  Uttar Pradesh state
uttar = gadm("IND", "Uttar Pradesh", children=true)

# Names of all states of India
gadm("IND", names=true)
```
"""
function gadm(country, subregions...; children::Bool=false, names::Bool=false, children_raw::Bool=false, reportlevels::Bool=false)
	isvalidcode(country) || throw(ArgumentError("please provide standard ISO 3 country codes"))
	data_pato = country |> _download		# Downloads and extracts dataset of the given country code
	data = Gdal.read(data_pato)
	!isnothing(data) ? data : throw(ArgumentError("failed to read data from disk"))
	nlayers = Gdal.nlayer(data)
	reportlevels && return nlayers

	function _filterlayer(layer, level, value, all::Bool=false)
		filtered, key = Vector{GMT.Gdal.Feature}(undef,0), "NAME_$(level)"
		for row in layer
			field = Gdal.getfield(row, key)
			if all || occursin(lowercase(value), lowercase(field))
				push!(filtered, row)
			end
		end
		isempty(filtered) && throw(ArgumentError("could not find required region"))
		filtered
	end
	function _getnames(layer, level, parent)
		# Get the names of all direct descendents of 'parent'
		filtered, key, keyP = Vector{String}(undef,0), "NAME_$(level)", "NAME_$(level-1)"
		for row in layer
			field  = Gdal.getfield(row, key)
			if (parent == "")		# Easier, all descendents are what we are looking for
				push!(filtered, field)
			else					# Filter only the descendents of a specific parent
				fieldP = Gdal.getfield(row, keyP)
				contains(lowercase(fieldP), parent) && push!(filtered, field)
			end
		end
		filtered
	end

	function _getlayer(plevel)
		# Get layer of the desired `level` from the `data`.
		nlayers = Gdal.nlayer(data)
		for l = 0:nlayers - 1
			layer = Gdal.getlayer(data, l)
			lname = Gdal.getname(layer)
			llevel = last(split(lname, "_"))
			string(plevel) == llevel && return layer
		end
		error("Asked data for a level ($(plevel+1)) that is lower than lowest data level ($(nlayers))")
	end

	function _get_polygs(gdfeature)
		D = gd2gmt(getgeom(gdfeature[1], 0),"")
		((prj = getproj(Gdal.getlayer(data, 0))) != C_NULL) && (D[1].proj4 = toPROJ4(prj))
		for n = 2:length(gdfeature)
			_D = gd2gmt(getgeom(gdfeature[n], 0),"")
			append!(D, _D)
		end
		D
	end

	# p -> parent, is the requested region
	plevel = length(subregions)
	plevel >= nlayers && throw(ArgumentError("more subregions required than in data")) 
	pname = isempty(subregions) ? "" : last(subregions)
	player = _getlayer(plevel)

	if (!children && !children_raw && !names) || (!names && nlayers == plevel + 1)	# Last case is when we have no more levels
		p = _filterlayer(player, plevel, pname, iszero(plevel))
		return !children_raw ? _get_polygs(p) : (_get_polygs(p), nothing)
	end

	# c -> children, is the region 1 level lower than p
	clevel = plevel + 1
	clayer = _getlayer(names || children || children_raw ? clevel : plevel)

	(names) && return _getnames(clayer, clevel, (plevel == 0) ? "" : lowercase(subregions[end]))

	c = _filterlayer(clayer, plevel, pname, iszero(plevel))

	if (children_raw)		# This is close (aside from the GMTdatset vs GDAL features) to the output of the GADM.jl
		p = _filterlayer(player, plevel, pname, iszero(plevel))
		return _get_polygs(p), c
	else
		return _get_polygs(c)
	end
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
