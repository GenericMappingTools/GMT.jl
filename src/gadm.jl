# Addapted from the original https://github.com/JuliaGeo/GADM.jl (MIT Licensed)
# and stripped from all of it's dependencies (ArchGDAL repaced by the GMT GDAL functions).
# Expanded to also return all subregions of a particular administrative entity.
# To (partially) replace the role of the Tables.jl interface an option exists to print the
# names of all subregions of a parent administrative unit.

"""
    gadm(country, subregions...; children=false, names=false, children_raw=false, reportlevels=false)

Return a GMTdataset for the requested country, or country subregion(s)

- `country`: ISO 3166 Alpha 3 country code  .
- `subregions`: Full official names in hierarchial order (provinces, districts, etc...).
   To know the names of all administrative children of parent, use the option `names`.
- `children`: When true, function returns all subregions of parent.
- `children_raw`: When true, function returns two variables -> parent, children, where children is a GDAL object
   E.g. when children is set to true and when querying just the country,
   second return parameter are the states/provinces. If `children` we return a Vector of GMTdataset with
   the polygons. If `children_raw` the second output is a GDAL object much like in GADM.jl (less the Tables.jl)
- `names`: Return a string vector with all `children` names. 
- `reportlevels`: just report the number of administrative levels (including the country) and exit.

## Examples  
  
```julia
# data of India's borders
data = gadm("IND")

# uttar -> the limits of the Uttar Pradesh state
uttar = gadm("IND", "Uttar Pradesh")

# uttar -> limits of all districts of the  Uttar Pradesh state
uttar = gadm("IND", "Uttar Pradesh", children=true)

# Names of all states of India
gadm("IND", names=true)
```
"""
function gadm(country, subregions...; children::Bool=false, names::Bool=false, children_raw::Bool=false, reportlevels::Bool=false)
	isvalidcode(country) || throw(ArgumentError("please provide standard ISO 3 country codes"))
	data_pato = country |> _download		# Downloads and extracts dataset of the given country code
	ressurectGDAL()			# Some previous GMT modules (or other shits) may have called GDALDestroyDriverManager() 
	data = Gdal.read(data_pato)
	ressurectGDAL()			# Again !!!!!?
	!isnothing(data) ? data : throw(ArgumentError("failed to read data from disk"))
	nlayers = Gdal.nlayer(data)
	reportlevels && return nlayers

	function _filterlayer(layer, layer_name, level, value, all::Bool=false)
		filtered = Vector{GMT.Gdal.Feature}(undef,0)
		# They Fck changed this between version 3.6 and 4.5. Before, it was always NAME_0, Name_1, ...
		key = "NAME_$(level)"
		if (level == 0)
			key = contains(layer_name, "gadm36") ? "NAME_0" : "COUNTRY"
		end
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
			string(plevel) == llevel && return layer, lname
		end
		error("Asked data for a level ($(plevel+1)) that is lower than lowest data level ($(nlayers))")
	end

	function _get_attrib(feature)
		n = Gdal.nfield(feature)
		attrib = DictSvS()
		[attrib[Gdal.getname(Gdal.getfielddefn(feature, i))] = string(Gdal.getfield(feature, i)) for i = 0:n-1]
		attrib
	end

	function _get_polygs(gdfeature)
		D = gd2gmt(getgeom(gdfeature[1], 0),"")
		isa(D, GMTdataset) && (D = [D])		# Hopefully not too wasteful but it simplifies a lot the whole algo
		att = _get_attrib(gdfeature[1])
		for k = 1:numel(D)  D[k].attrib = att;  D[k].colnames = ["Lon", "Lat"]  end
		D[1].attrib = _get_attrib(gdfeature[1])
		((prj = getproj(Gdal.getlayer(data, 0))) != C_NULL) && (D[1].proj4 = toPROJ4(prj))
		for n = 2:numel(gdfeature)
			_D = gd2gmt(getgeom(gdfeature[n], 0),"")
			isa(_D, GMTdataset) && (_D = [_D])
			att = _get_attrib(gdfeature[n])
			for k = 1:numel(_D)  _D[k].attrib = att;  _D[k].colnames = ["Lon", "Lat"]  end
			append!(D, _D)
		end
		set_dsBB!(D, false)		# Compute only the global BB. The other were computed aready
		return (length(D) == 1) ? D[1] : D
	end

	# p -> parent, is the requested region
	plevel = length(subregions)
	plevel >= nlayers && throw(ArgumentError("more subregions required than in data")) 
	pname = isempty(subregions) ? "" : last(subregions)
	player, layer_name = _getlayer(plevel)

	if (!children && !children_raw && !names) || (!names && nlayers == plevel + 1)	# Last case is when we have no more levels
		p = _filterlayer(player, layer_name, plevel, pname, iszero(plevel))
		return !children_raw ? _get_polygs(p) : (_get_polygs(p), nothing)
	end

	# c -> children, is the region 1 level lower than p
	clevel = plevel + 1
	clayer, layer_name = _getlayer(names || children || children_raw ? clevel : plevel)

	(names) && return _getnames(clayer, clevel, (plevel == 0) ? "" : lowercase(subregions[end]))

	c = _filterlayer(clayer, layer_name, plevel, pname, iszero(plevel))

	if (children_raw)		# This is close (aside from the GMTdatset vs GDAL features) to the output of the GADM.jl
		p = _filterlayer(player, layer_name, plevel, pname, iszero(plevel))
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
	ID = "gadm41_$(country).gpkg"
	#https://biogeo.ucdavis.edu/data/gadm3.6/gpkg/gadm36_PRT_gpkg.zip
	cache = joinpath(GMTuserdir[1], "cache")
	if !isdir(cache)
		((pato = mkdir(cache)) == "") && error("Failed to create the 'cache' dir where download file would be stored")
	end
	fname = joinpath(cache, ID)
	isfile(fname) && return fname

	println("Downloading geographic data for country $country provided by the https://gadm.org project. It may take a while.")
	println("The file $ID will be stored in $cache")
	Downloads.download("https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/$(ID)", joinpath(cache, ID))
	#curr_pato = pwd();	cd(cache)
	#@static Sys.iswindows() ? run(`tar -xf $dlfile`) : run(`unzip $dlfile`)
	#rm(dlfile)
	#cd(curr_pato)
	old_fname = joinpath(cache, "gadm36_$(country).gpkg")	# If an old 3.6 exists, remove it.
	isfile(old_fname) && rm(old_fname)
	return fname
end
