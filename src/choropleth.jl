"""
    choropleth(D, ids, vals; attrib="CODE", cmap="turbo", outline=true, kw...)
    choropleth(D, att=""; attrib="", cmap="turbo", outline=true, kw...)
    choropleth(D, data::GMTdataset, att=""; attrib="", cmap="turbo", outline=true, kw...)
    choropleth(D, data::Dict; outline=true, kw...)
    choropleth(D, data::NamedTuple; outline=true, kw...)
    choropleth(D, vals::Vector{<:Real}; attrib="CODE", outline=true, kw...)

Create a choropleth map visualization from geographic data with color-coded regions.

### Arguments
- `D`: Geographic data - either a file path (String) or Vector{GMTdataset} containing polygons.
- `ids::Vector{<:AbstractString}`: Region identifiers to match with the attribute values.
- `vals::Vector{<:Real}`: Numeric values to map to colors for each region.
- `att`: Attribute column name (positional argument) for coloring when values are in the dataset.
- `data::GMTdataset`: Dataset containing attributes to join with geographic features (must have text column).
- `data::Dict`: Dictionary mapping region identifiers to values.
- `data::NamedTuple`: Named tuple with region identifiers as keys and values.

### Keywords
- `attrib`: Attribute name to match identifiers (default: "CODE"). Takes precedence over positional `att`.
- `cmap`: A colormap name (default: "turbo") or a GMTcpt colormap.
- `outline`: Draw polygon outlines. `true` (default), `false`, or a pen specification string.
- `kw...`: Additional arguments passed to the plotting function (e.g., `proj`, `region`, `title`).

### Returns
Nothing or a GMTps type (when saving to file).

### Methods
1. **With IDs and values**: `choropleth(D, ids, vals)` - Explicit region IDs and corresponding values.
2. **From attribute**: `choropleth(D, att)` - Extract values from a numeric attribute column in D.
3. **With GMTdataset**: `choropleth(D, data, att)` - Join D with data using text column for matching.
4. **With Dict**: `choropleth(D, Dict("PT"=>10, "ES"=>20))` - Map from region codes to values.
5. **With NamedTuple**: `choropleth(D, (PT=10, ES=20))` - Same as Dict but with named tuple syntax.
6. **Values only**: `choropleth(D, vals)` - Values in order of unique IDs extracted from D.

### Examples
```julia
# Using explicit IDs and values
D = getdcw("PT,ES,FR")
choropleth(D, ["PT","ES","FR"], [10.0, 20.0, 30.0])

# Using a Dict
choropleth(D, Dict("PT"=>10, "ES"=>20, "FR"=>30))

# From attribute in dataset (values stored in polygon attributes)
choropleth("countries.shp", "GDP_PER_CAPITA")

# With custom colormap and no outlines
choropleth(D, ["PT","ES","FR"], [1.0, 2.0, 3.0], cmap="bamako", outline=false)

# The example in "Tutorials"
D = getdcw("US", states=true, file=:ODS);
Df = filter(D, _region=(-125,-66,24,50), _unique=true);
pop = gmtread(TESTSDIR * "assets/uspop.csv");
choropleth(Df, pop, "NAME", show=true)
```
"""
choropleth(D::String, ids::Vector{<:AbstractString}, vals::Vector{<:Real}; attrib::StrSymb="CODE", cmap="turbo", outline=true, kw...) =
	choropleth(gmtread(D), ids, vals; attrib=attrib, cmap=cmap, outline=outline, kw...)
function choropleth(D, ids::Vector{<:AbstractString}, vals::Vector{<:Real}; attrib::StrSymb="CODE",
                    cmap="turbo", outline=true, kw...)

	helper_plot_choropleth(D, ids, Float64.(vals), string(attrib), cmap, outline; kw...)
end


# ------------------------------------------------------------------------------------------------------
choropleth(D::String, att::StrSymb=""; attrib::StrSymb="", cmap="turbo", outline=true, kw...) =
	choropleth(gmtread(D), att; attrib=attrib, cmap=cmap, outline=outline, kw...)
function choropleth(D::Vector{<:GMTdataset}, att::StrSymb=""; attrib::StrSymb="", cmap="turbo", outline=true, kw...)

	_att = (attrib !== "") ? attrib : att		# May use either positional or keyword argument. Later takes precedence
	ids, vals = extract_ids_vals(D, string(_att))
	helper_plot_choropleth(D, ids, vals, string(_att), cmap, outline; kw...)
end

# ------------------------------------------------------------------------------------------------------
choropleth(D::String, data::GMTdataset, att::StrSymb=""; attrib::StrSymb="", cmap="turbo", outline=true, kw...) =
	choropleth(gmtread(D), data, att; attrib=attrib, cmap=cmap, outline=outline, kw...)
function choropleth(D::Vector{<:GMTdataset}, data::GMTdataset, att::StrSymb=""; attrib::StrSymb="", cmap="turbo", outline=true, kw...)
	isempty(data.text) && error("The 'data' GMTdataset has no text column to guid the joining operation.")
	_att = (attrib !== "") ? attrib : att		# May use either positional or keyword argument. Later takes precedence
	(get(D[1].attrib, _att, "") === "") && error("The 'D' GMTdatasets has no attribute $(_att).")
	zvals = polygonlevels(D, data, att=_att)
	helper_plot_choropleth(D, String[], view(data, :,1), string(_att), cmap, outline, zvals; kw...)
end

# ------------------------------------------------------------------------------------------------------
choropleth(D::String, data::Dict; outline=true, kw...) = choropleth(gmtread(D), data; outline=outline, kw...)
function choropleth(D::Vector{<:GMTdataset}, data::Dict; outline=true, kw...)
	ids = collect(keys(data))
	vals = [data[k] for k in ids]
	choropleth(D, string.(ids), Float64.(vals); outline=outline, kw...)
end

# ------------------------------------------------------------------------------------------------------
choropleth(D::String, data::NamedTuple; outline=true, kw...) = choropleth(gmtread(D), data; outline=outline, kw...)
choropleth(D::Vector{<:GMTdataset}, data::NamedTuple; outline=true, kw...) = choropleth(D, Dict(pairs(data)); outline=outline, kw...)

# ------------------------------------------------------------------------------------------------------
choropleth(D::String, vals::Vector{<:Real}; attrib::StrSymb="CODE", outline=true, kw...) =
	choropleth(gmtread(D), vals; attrib=attrib, outline=outline, kw...)
function choropleth(D::Vector{<:GMTdataset}, vals::Vector{<:Real}; attrib::StrSymb="CODE", outline=true, kw...)
	# Extract unique IDs in order of first appearance
	att = string(attrib)
	ids = String[]
	last_id = ""
	for d in D
		id = get(d.attrib, att, "")
		(id == last_id) && continue			# skip obvious duplicates
		!(id in ids) && push!(ids, id)
		last_id = id
	end

	length(vals) != length(ids) && error("Values length ($(length(vals))) != unique IDs ($(length(ids))): $(join(ids, ", "))")
	choropleth(D, ids, vals; attrib=att, outline=outline, kw...)
end

# ------------------------------------------------------------------------------------------------------
function extract_ids_vals(D, attrib::String)
	ids, vals = String[], String[]
	last_id = ""
	for d in D
		id = get(d.attrib, attrib, "")
		(id == last_id) && continue			# skip obvious duplicates
		!(id in ids) && (push!(ids, id); push!(vals, d.attrib[attrib]))
		last_id = id
	end
	ind = findall(x -> x === "", vals)		# Shit, can't use tryparse() because it f. returns Nothing's instaed of NaN's for ""
	if (!isempty(ind))
		vals = deleteat!(vals, ind)
		ids = deleteat!(ids, ind)
	end
	ids, (tryparse(Float64, vals[1]) === nothing) ? collect(1.0:length(vals)) : parse.(Float64, vals)
end

# ------------------------------------------------------------------------------------------------------
function helper_plot_choropleth(D, ids, vals, attrib::String, cmap, outline, _zvals=Float64[]; kw...)
	zvals = (isempty(_zvals)) ? polygonlevels(D, ids, vals, att=attrib) : _zvals
	pen_ouline = isa(outline, Bool) ? "0" : outline
	C = isa(cmap, GMTcpt) ? cmap : makecpt(T=(minimum(vals), maximum(vals)), C=string(cmap))
	return (outline != false) ? plot(D; level=zvals, cmap=C, plot=(data=D, pen=pen_ouline), kw...) :
	                            plot(D; level=zvals, cmap=C, kw...)
end

# ------------------------------------------------------------------------------------------------------
choropleth!(args...; kw...) = choropleth(args...; first=false, kw...)
