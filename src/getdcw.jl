export getdcw

"""
    getdcw(codes; states=false, file::StrSymb="") -> Vector{GMTdataset}

Get country/region polygons from the DCW (Digital Chart of the World) database.

### Arguments
- `codes`: Country codes as string (comma-separated for multiple) or vector of strings.
           Use 2-letter ISO 3166-1 codes (e.g., "PT", "ES", "FR") or continent codes
           (e.g., "=AF" for Africa, "=EU" for Europe OR the continent names themselves).
           Special commands: `:list`, `:states`, `:continents`

### Keywords
- `states`: If true, get state/province level polygons instead of country level.
            Only available for: AR, AU, BR, CA, CN, GB, IN, NO, RU, US. Default: false
- `file`: indicate that we want to use another netCDF file than the default DCW file. 
   `file`, without extension, can be either just the absolute file name, case in which the file.nc
   is expected to be found in the shared folder that also contains the dcw-gmt.nc file,
   or the full file name, case in which the file can be located anywhere. For example:
   `getdcw=(:CH, file=:ODS)` extracts the Swiss polygon from (small) ODS.nc file. 

### Returns
- `Vector{GMTdataset}`: Polygons with attributes including "CODE" and "NAME".

### Example
```julia
# Get single country
pt = getdcw("PT")

# Get multiple countries
iberia = getdcw("PT,ES")

# Get European countries (continent code)
europe = getdcw("=EU")

# Get Brazilian states
br_states = getdcw("BR", states=true)

# Use with fourcolors
polys = getdcw("PT,ES,FR,DE,IT,CH,AT,BE,NL")
fourcolors(polys, groupby="CODE")

# List available codes
getdcw(:list)        # all countries
```

### Available continent codes
- `=AF` : Africa
- `=AN` : Antarctica
- `=AS` : Asia
- `=EU` : Europe
- `=NA` : North America
- `=OC` : Oceania
- `=SA` : South America
- `=WD` : World

### Countries with state/province data
AR (Argentina), AU (Australia), BR (Brazil), CA (Canada), CN (China),
GB (United Kingdom), IN (India), NO (Norway), RU (Russia), US (United States)
"""
function getdcw(codes::Union{String,Symbol}; states::Bool=false, file::StrSymb="")
	_codes = string(codes)

	# Handle special commands
	if _codes == "list"
		D = gmt("pscoast -E+L")
		println("Available DCW codes:")
		for line in D.text  println("  ", line)  end
		return D
	end
	_codes = startswith(_codes, "Afr") ? "=AF" : startswith(_codes, "Ant") ? "=AN" : startswith(_codes, "Asi") ? "=AS" : startswith(_codes, "Eur") ? "=EU" : startswith(_codes, "Nort") ? "=NA" : startswith(_codes, "Oce") ? "=OC" : startswith(_codes, "South") ? "=SA" : startswith(_codes, "Wor") ? "=WD" : _codes

	# Handle states request
	if states
		valid_states = ("AR", "AU", "BR", "CA", "CN", "GB", "IN", "NO", "RU", "US")
		country = uppercase(replace(_codes, "," => ""))
		if length(country) == 2 && !(country in valid_states)
			error("State-level data only available for: $(join(valid_states, ", ")). Got: $country")
		end
		_codes = "+" * _codes
	end

	# Call coast with dump option
	file !== "" && (_codes *= "+f$file")
	kw = Dict{Symbol,Any}(:DCW => _codes * "+z", :dump => true)
	D = coast(; kw...)

	return D
end

# Vector version
function getdcw(codes::Vector{<:AbstractString}; kwargs...)
	getdcw(join(codes, ","); kwargs...)
end
