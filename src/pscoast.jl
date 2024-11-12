"""
    coast(cmd0::String=""; kwargs...)

Plot continents, shorelines, rivers, and borders on maps.
Plots grayshaded, colored, or textured land-masses [or water-masses] on
maps and [optionally] draws coastlines, rivers, and political
boundaries. A map projection must be supplied.

See full GMT (not the `GMT.jl` one) docs at [`coast`]($(GMTdoc)coast.html)

Parameters
----------

- $(_opt_J)
- $(_opt_R)
- **A** | **area** :: [Type => Str or Number]

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
- $(_opt_B)
- **C** | **river_fill** :: [Type => Str]

    Set the shade, color, or pattern for lakes and river-lakes.
- **D** | **res** | **resolution** :: [Type => Str]		``Arg = c|l|i|h|f|a``

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, (c)rude), or (a)uto).
- **E** | **DCW** :: [Type => Str]

    Select painting or dumping country polygons from the Digital Chart of the World.
    + Tuple("code", Str); Tuple(code, number); Tuple("code" [,"fill"], (pen)); Tuple((...),(...),...)
    + ex: ("PT",(0.5,"red","--")); (("PT","gblue",(0.5,"red"),("ES",(0.5,"yellow")))
    +     DCW=:PT; DCW=(:PT, 1); DCW=("PT", :red)

- **getR** | **getregion** | **get_region** :: [Type => Str]

    Return the region corresponding to the code/list-of-codes passed in as argument.
- **F** | **box** :: [Type => Str]

    Draws a rectangular border around the map scale or rose.
- **G** | **land** :: [Type => Str]

    Select filling or clipping of “dry” areas.
- **I** | **rivers** :: [Type => Str]

    Draw rivers. Specify the type of rivers and [optionally] append pen attributes.
- **L** | **map_scale** :: [Type => Str]

    Draw a map scale.
- **M** | **dump** :: [Type => Str]

    Dumps a single multisegment ASCII output. No plotting occurs.
- **N** | **borders** :: [Type => Str]

    Draw political boundaries. Specify the type of boundary and [optionally] append pen attributes
- $(opt_P)
- **clip** :: [Type => Str]		``Arg = land|water|end``

    To clip land do *clip=:land*, *clip=:water* clips water. Use *end* to mark end of existing clip path.
    No projection information is needed.
- **S** | **water** | **ocean** :: [Type => Str]

    Select filling or clipping of “wet” areas.
- **Td** | **rose`** :: [Type => Str]

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
- **Tm** | **compass** :: [Type => Str]

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
- $(opt_U)
- $(opt_V)
- **W** | **shore** | **shorelines** | **coast** | **coastlines** :: [Type => Str]
    Draw shorelines [Default is no shorelines]. Append pen attributes.
- $(opt_X)
- $(opt_Y)
- $(opt_bo)
- $(_opt_p)
- $(_opt_t)
- $(opt_savefig)

To see the full documentation type: ``@? coast``
"""
function coast(cmd0::String=""; clip=nothing, first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "coast "  : "pscoast "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	if ((val = find_in_dict(d, [:getR :getregion :get_region], false)[1]) !== nothing)
		t::String = string(gmt_proggy, " -E", val)
		((Vd = find_in_dict(d, [:Vd], false)[1]) !== nothing) && (Vd_::Int = Vd; Vd_ == 1 ? println(t) : Vd_ > 1 ? (return t) : nothing)
		t = parse_V(d::Dict, t)
		return gmt(t).text[1]::String
	end

	cmd = add_opt(d, "", "M", [:M :dump])
	have_opt_M = (cmd != "")
	cmd = parse_E_coast(d, [:E, :DCW], cmd)		# Process first to avoid warning about "guess"
	if (cmd != "")								# Check for a minimum of points that segments must have
		if ((val = find_in_dict(d, [:minpts])[1]) !== nothing)  POSTMAN[1]["minpts"] = string(val)::String
		elseif (get(POSTMAN[1], "minpts", "") != "")            delete!(POSTMAN[1], "minpts")
		end
	end

	# Explain
	toTrack::Union{String, GMTgrid} = ""
	if (have_opt_M)
		O = true
		POSTMAN[1]["DCWnames"] = "s"		# When dumping, we want to add the country name as attribute
		if ((val = find_in_dict(d, [:Z])[1]) !== nothing)
			toTrack = (isa(val, GMTgrid) || (isa(val, String) && length(val) > 4)) ? val : ""
			toTrack == "" && (POSTMAN[1]["plusZzero"] = "y")# If toTrack the extra column is added by the grdtrack call below
		end
	end
	
	if (!occursin("-E+l", cmd) && !occursin("-E+L", cmd))	# I.e., no listings only
		cmd, = parse_R(d, cmd, O, true, false, have_opt_M)	# If have_opt_M we don't set the -R limits in globals
		if (!have_opt_M)									# If Dump no -R & -B
			cmd = parse_J(d, cmd, "guess", true, O)[1]
			cmd = parse_B(d, cmd, (O ? "" : (IamModern[1]) ? "" : DEF_FIG_AXES[1]))[1]
		end
	end
	common = have_opt_M ? [:UVXY :bo :params] : [:F :JZ :UVXY :bo :c :p :t :params :margin]
	cmd, = parse_common_opts(d, cmd, common; first=first)	# If -M don't touch -p
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:C :river_fill], [:D :res :resolution]])
	cmd  = parse_Td(d, cmd)
	cmd  = parse_Tm(d, cmd)
	cmd  = parse_L(d, cmd)
	cmd  = add_opt_fill(cmd, d, [:G :land], 'G')
	cmd  = add_opt_fill(cmd, d, [:S :water :ocean], 'S')

	if (clip !== nothing)
		_clip::String = string(clip)
		if     (_clip == "land")    cmd *= " -Gc"
		elseif (_clip == "water" || _clip == "ocean") cmd *= " -Sc"
		elseif (_clip == "end")     cmd = " -Q";	O = true		# clip = end can never be a first command
		else
			@warn("The 'clip' argument can only be a string with 'land', 'water' or 'end'. Ignoring it.")
		end
	end

	# Parse these three options that can be made to respond to same code
	cmd = parse_INW_coast(d, [[:I :rivers], [:N :borders], [:W :shore :shorelines :coast :coastlines]], cmd, "INW")
	(SHOW_KWARGS[1]) && print_kwarg_opts([:I :rivers],  "NamedTuple | Tuple | Dict | String")
	(SHOW_KWARGS[1]) && print_kwarg_opts([:N :borders], "NamedTuple | Tuple | Dict | String")
	(SHOW_KWARGS[1]) && print_kwarg_opts([:W :shore :shorelines :coast],   "NamedTuple | Tuple | Dict | String")

	if (!occursin(" -C",cmd) && !occursin(" -E",cmd) && !occursin(" -G",cmd) && !occursin(" -I",cmd) &&
		!occursin(" -M",cmd) && !occursin(" -N",cmd) && !occursin(" -Q",cmd) && !occursin(" -S",cmd) && !occursin(" -W",cmd))
		cmd *= " -W0.5p"
	end
	(!occursin("-D",cmd) && !contains(cmd, " -Q")) && (cmd *= " -Da")		# Then pick automatic
	finish = !occursin(" -M",cmd) && !occursin("-E+l", cmd) && !occursin("-E+L", cmd) ? true : false	# Otherwise the dump would be redirected to GMT_user.ps

	# Just let D = coast(R=:PT, dump=true) work without any furthers shits (plain GMT doesn't let it)
	(occursin(" -M",cmd) && !occursin("-E", cmd) && !occursin("-I", cmd) && !occursin("-N", cmd) && !occursin("-W", cmd) && !occursin("-A", cmd)) &&
		(cmd *= " -W -A0/1/1")

	get_largest = (!finish && occursin(" -E", cmd) && (find_in_dict(d, [:biggest :largest])[1] !== nothing))
	_cmd = (finish) ? finish_PS_nested(d, [gmt_proggy * cmd]) : [gmt_proggy * cmd]

	# This bit is for insets that call coast and this one further down calls another module (e.g. plot)
	if (IamModern[1] && length(_cmd) > 1 && contains(_cmd[1], "? "))
		spli = split(_cmd[2], " -J")
		if (length(spli) > 1)
			_cmd[2] = replace(_cmd[2], " -J" * split(spli[2])[1] => "")
		end
	end

	R = finish_PS_module(d, _cmd, "", K, O, finish)
	CTRL.pocket_d[1] = d					# Store d that may be not empty with members to use in other modules
	!isa(R, GDtype) && return R				# If R is not a GMTdataset we are done.

	if (get_largest)
		ind = argmax(size.(R))
		R = [R[ind]]						# Keep it a vector to be consistent with the other Dump cases
		R[1].proj4, R[1].geom = prj4WGS84, wkbPolygon
	end

	if (toTrack != "")						# Mean, get a Z column by interpolating the coastlines over a grid.
		_R::GDtype = grdtrack(toTrack, R, f="g", s="+a")
		!isempty(_R) && (R = _R)
	end

	geom = occursin(" -M", cmd) ? (occursin(" -E", cmd) ? wkbPolygon : wkbLineString) : wkbUnknown
	n_cols = isa(R, Vector{<:GMTdataset}) ? size(R[1].data, 2) : size(R.data, 2)
	cnames = (n_cols == 2) ? ["Lon", "Lat"] : ["Lon", "Lat", "Z"]
	isa(R, Vector{<:GMTdataset}) && (for k = 1:numel(R)  R[k].colnames = cnames; R[k].geom = geom  end; R[1].proj4 = prj4WGS84)
	isa(R, GMTdataset) && (R.colnames = cnames; R.geom = geom; R.proj4 = prj4WGS84)
	R
end

# ---------------------------------------------------------------------------------------------------
function parse_INW_coast(d::Dict, symbs::Vector{Matrix{Symbol}}, cmd::String, flags::String)
	# This function is also used by pshistogram (opt -N). Must be length(flags) == length(symbs)
	(length(symbs) != length(flags)) && error("Length of symbs must be equal to number of chars in FLAGS")
	for k = 1:length(symbs)
		if ((val = find_in_dict(d, symbs[k], false)[1]) !== nothing)
			if (isa(val, NamedTuple) || isa(val, AbstractDict) || (isa(val, Tuple) && isa(val[1], NamedTuple)))  
				cmd::String = add_opt(d, cmd, string(flags[k]), symbs[k], (type="/#", level="/#", mode="+p#", pen=("", add_opt_pen)))
			elseif (isa(val, Tuple))
				if (flags[k] == 'W')	# The shore case is ambiguous, this shore=(1,:red) could mean -W1/red or -W1,red 
					cmd *= " -W" * parse_pen(val)	# We take it to mean pen only. Levels must use the NT form
				else
					cmd *= " -" * flags[k] * string(val[1]) * "/" * parse_pen(val[2])
				end
			else    cmd *= " -" * flags[k] * arg2str(val)	# Includes Str, Number or Symb
			end
			delete!(d, symbs[k])			# Now we can delete the kwarg
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_E_coast(d::Dict, symbs::Vector{Symbol}, cmd::String)
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | Dict | String")
	if ((val = find_in_dict(d, symbs, false)[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))	# Simple case, ex E="PT,+gblue" or E=:PT
			t::String = string(" -E", val)
			startswith(t, " -EWD") && (t = " -E=" * t[4:end])		# Let E="WD" work
			(t == " -E") && (delete!(d, [:E, :DCW]); return cmd)	# This lets use E="" like earthregions may do
			(!contains(cmd, " -M") && is_in_dict(d, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag]) === nothing) &&
				(d[:R] = t[4:end])					# Must also see what to do for the other elseif branches
			!contains(t, "+") && (t *= "+p0.5")		# If only code(s), append pen
			cmd *= t
		elseif (isa(val, NamedTuple) || isa(val, AbstractDict))
			cmd = add_opt(d, cmd, "E", [:DCW :E], (country="", name="", continent="=", pen=("+p", add_opt_pen),
			                                       fill=("+g", add_opt_fill), file=("+f"), inside=("_+c"), outside=("_+C"), adjust_r=("+r", arg2str), adjust_R=("+R", arg2str), adjust_e=("+e", arg2str), headers=("_+z")))
		elseif (isa(val, Tuple))
			cmd = parse_dcw(cmd, val)
		end
		cmd *= " -Vq"				# Suppress annoying warnings regarding filling syntax with +r<dpi>
		delete!(d, symbs)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_dcw(cmd::String, val::Tuple)::String
	# First test if (code, pen) or (code, fill) are passed in.
	if (isa(val, Tuple) && length(val) == 2)
		(isa(val[2], Real)) && return string(cmd, " -E", val[1], "+p", val[2])
		(isa(val[2], String) || isa(val[2], Symbol)) && return string(cmd, " -E", val[1], "+g", string(val[2]))
	end

	for k = 1:numel(val)
		if (isa(val[k], NamedTuple) || isa(val[k], Dict))
			isa(val[k], AbstractDict) && (val[k] = Base.invokelatest(dict2nt, val[k]))
			cmd *= add_opt(Dict(:DCW => val[k]), "", "E", [:DCW], (country="", name="", continent="=", pen=("+p", add_opt_pen),
			                                                       fill=("+g", add_opt_fill), file=("+f"), inside=("_+c"), outside=("_+C"), adjust_r=("+r", arg2str), adjust_R=("+R", arg2str), adjust_e=("+e", arg2str), headers=("_+z")))
		elseif (isa(val[k], Tuple))
			cmd *= parse_dcw(val[k])
		else
			cmd *= parse_dcw(val)
			break
		end
	end
	return cmd
end

function parse_dcw(val::Tuple)::String
    t::String = string("", " -E", val[1])
	if (length(val) > 1)
		if (isa(val[2], Tuple))  t *= "+p" * parse_pen(val[2])
		else                     t *= string(val[2])
		end
		if (length(val) > 2)
			if (isa(val[3], Tuple))  t *= add_opt_fill("+g", Dict(fill => val[3]), [:fill])
			else                     t *= string(val[3])
			end
		end
	end
	return t
end

# ---------------------------------------------------------------------------------------------------
coast!(cmd0::String=""; clip=nothing, kw...) = coast(cmd0; clip=clip, first=false, kw...)

const pscoast  = coast			# Alias
const pscoast! = coast!
 

# ---------------------------------------------------------------------------------------------------
"""
    [GI = ] earthregions(name=""; proj="guess", country=false, dataset="", grid=false,
                         res="", registration="", round=0, exact=false)

`earthregions` plots or automatically extracts grid/image over a named geographic region. A large number of
predefined regions is provided via _collections_, which are lists of names, their rectangular geographic
boundaries and a code to access them. Users pick a region by its code(s) and choose between making a map
of that region or download topo/bathymetric data (a grid or image) of that area.

### Parameters
- `name`: It can be either the name of one collection or the code of one geographic region. If it is a
    collection name (one of: ``"DCW", "NatEarth", "UN", "Mainlands", "IHO", "Wiki", "Lakes"``) the regions
    of that collection are printed, displaying the region's boundaries, code and name. If, instead, a code
    is passed (codes are unique) then depending on the values of `grid` or `dataset` we either produce a
    map of that region (the default) or extract grid/image over it.
- `proj`: In case a map is requested, pass the desired projection in form of a proj4 string or use the GMT
    projection syntax for that map. By default, we guess a good projection based on the map limits.
- `country`: The particular case of the ``DCW`` collection let us also plot the country(ies) border lines.
    Set `country=true` to do that. Note that the ``DCW`` regions can be specified by a comma separated list
    of country codes, _e.g._ `earthregions("PT,ES", country=true)`.
- `dataset`: This option is used to select data download instead of map plotting. The available datasets are
    those explained in https://www.generic-mapping-tools.org/remote-datasets/, which shortly are: ``"earth_relief",
    "earth_synbath", "earth_gebco", "earth_mask", "earth_day", "earth_night", "earth_geoid", "earth_faa",
    "earth_mask", "eart_dist", "earth_mss", "earth_vgg", "earth_wdmam", "earth_age", "mars_relief", "moon_relief",
    "mercury_relief", "venus_relief", "pluto_relief"``.

    Note that ``"earth_day", "earth_night"`` are images that are not stored as tilles in the server, so the
    entire file is downloaded (only once and stored in your local ~.gmt/server directory). So, this may take
    a while for the first-time usage.
- `grid`: A shorthand boolean option equivalent to `dataset="earth_relief"` 
- `res`: The dataset resolution. Possible resolutions are: ``"01d", "30m", "20m", "15m", "10m", "06m", "05m",
    "04m", "03m", "02m", "01m", "30s", "15s", "03s", "01s"``. However, they are not all available to all
    datasets. For example, only ``"earth_relief", "earth_synbath", "earth_gebco"`` exist for all those
    resolutions. In case a `dataset` is specified but no resolution, we make estimate of that resolution
    based on map extents and what would be good to create a map with 15 cm width.
- `registration`: The dataset registration. Either `grid` or `pixel`. If not provided we choose one.
- `exact`: The region boundaries in the collections were rounded to more friendly numbers (few decimals).
    This means that they differ slightly from the pure ``GMT`` (`coast`) numbers. Setting `exact=true` will
    force using the strict ``GMT`` limits.
- `round=inc`: Adjust the region boundaries by rounding to multiples of the steps indicated by inc, (xinc,yinc), or
    (winc,einc,sinc,ninc). Aditionally, `round` can be a string but in that case it must strictly follow the
    hard core GMT syntax explained at https://docs.generic-mapping-tools.org/dev/coast.html#r

See also: `coast`, `mosaic`

### Returns
A ``GMTgrid`` or a ``GMTimage`` if `dataset` is used or ``nothing`` otherwise.

## Examples
```jldoctest
   earthregions("IHO")                      # List the ocean regions as named by the IHO

   earthregions("PT,ES,FR", country=true)   # Make a map of Portugal, Spain and France regions.

   G = earthregions("IHO31", grid=true);    # Get a grid of the "Sea of Azov"

   viz(G, shade=true, coast=true)           # and make a nice map.
```

To see the plots produced by these examples type: ``@? earthregions``
"""
function earthregions(name::String=""; proj="guess", grid::Bool=false, dataset="", res="", exact::Bool=false,
                      registration="", country::Bool=false, round=0, Vd::Int=0)

	(name == "") && (println("Available collections:\n\t" * join(["DCW", "NatEarth", "UN", "Mainlands", "IHO", "Wiki", "Lakes"], ", ")); return)

	(registration != "" && res == "") && error("ERROR: Cannot specify a registration and NOT specify a resolution.")
	(grid && dataset == "") && (dataset = "earth_relief")

	datasets = ["earth_relief", "earth_synbath", "earth_gebco", "earth_mask", "earth_day", "earth_night", "earth_geoid", "earth_faa", "earth_mask", "eart_dist", "earth_mss", "earth_vgg", "earth_wdmam", "earth_age", "mars_relief", "moon_relief", "mercury_relief", "venus_relief", "pluto_relief"]
	(dataset != "") && (dataset::String = string(dataset))		# To let use symbols too.
	(dataset != "" && !any(startswith.(dataset, datasets))) && error("ERROR: unknown grid/image dataset name: '$dataset'. Must be one of:\n$datasets")
	type = (dataset != "" || grid) ? "raster" : "map"

	# Check that dataset name and resolutions exists.
	all_res = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "03s", "01s"]
	if (res != "")
		ind = findfirst(res .== all_res)
		(ind === nothing) && error("ERROR: unknown resolution '$res'. Must one of:\n$all_res")
		(ind > 11 && any(dataset .== ["earth_faa", "earth_vgg", "earth_geoid", "earth_age"])) && error("ERROR: maximum vailable resolution for this '$dataset' dataset is 01m")
		(ind > 12 && any(dataset .== ["earth_day", "earth_night"])) && error("ERROR: maximum vailable resolution for this '$dataset' dataset is 30s")
		(ind > 13 && dataset == "earth_mask") && error("ERROR: maximum available resolution for this '$dataset' dataset is 15s")
		(ind > 9 && dataset == "earth_wdmam") && error("ERROR: maximum available resolution for this '$dataset' dataset is 03m")
	end

	isImg = any(contains.(dataset, ["earth_day", "earth_night"]))
	(isImg && res == "" && !any(contains.(dataset, all_res))) && error("When using 'earth_day' or 'earth_night' is mandatory to specify a resolution.")

	d = Dict("NatEarth" => ["SAM", "AFR", "ASI", "EUR", "NAM", "MLNS", "MCNS", "PLNS", "MLYA", "GDRG", "ALP", "TIAN", "URAL", "CCSM", "HMLY", "ANDM", "RCKM", "NCNP", "KZST", "NEUP", "GRPL", "CONB", "AMZB", "IDCP", "ARAP", "GOBD", "SHRD", "WEPL", "IBRP", "TBTP", "CEAM", "SBRP", "EANT", "WANT", "ANTP", "GRSI", "ARTA"], 
	"UN" => ["UN002", "UN015", "UN202", "UN014", "UN017", "UN018", "UN011", "UN019", "UN419", "UN029", "UN013", "UN005", "UN021", "UN010", "UN142", "UN143", "UN030", "UN035", "UN034", "UN145", "UN151", "UN154", "UN039", "UN155", "UN009", "UN053", "UN054", "UN057", "UN061"],
	"Mainlands" => ["CRC", "ECC", "PTC", "ESC"],
	"Lakes" => ["CSPS", "GRLK", "LSUP", "LVIC", "LHUR", "LMIC", "LTAN", "LBAI", "GRBL", "LMAL", "GRSL", "LERI", "LWIN", "LONT", "LLAD", "NGNI", "BRNI", "BFFI", "SMTI", "HNSI", "VCTI", "GBRI", "ELLI", "SLWI", "SNZI", "JAVI", "NNZI", "LZNI", "NWFI", "MNDI", "IRLI", "HKKI", "SKHI", "BNKI", "DVNI", "ALXI", "TDFI", "SVRI", "BRKI", "AXHI", "MLVI", "SMPI", "MRJI", "SPTI", "KYSI", "NWBI", "PRWI", "YZHI", "VNCI", "TMRI", "SCLI", "EASI", "AZRI", "CNRI", "GLPI", "MDRI", "BLRI"],
	"IHO" => ["IHO1", "IHO1A", "IHO1B", "IHO1C", "IHO2", "IHO3", "IHO4", "IHO5", "IHO6", "IHO7", "IHO8", "IHO9", "IHO10", "IHO11", "IHO12", "IHO13", "IHO14", "IHO14A", "IHO15", "IHO15A", "IHO16", "IHO16A", "IHO17", "IHO17A", "IHO18", "IHO19", "IHO20", "IHO21", "IHO21A", "IHO22", "IHO23", "IHO24", "IHO25", "IHO26", "IHO27", "IHO28", "IHO28-1", "IHO28A", "IHO28B", "IHO28C", "IHO28D", "IHO28-2", "IHO28E", "IHO28F", "IHO28G", "IHO28H", "IHO29", "IHO30", "IHO31", "IHO32", "IHO33", "IHO34", "IHO35", "IHO36", "IHO37", "IHO38", "IHO39", "IHO40", "IHO41", "IHO42", "IHO43", "IHO44", "IHO45", "IHO45A", "IHO46A", "IHO46B", "IHO47", "IHO48", "IHO48A", "IHO48B", "IHO48C", "IHO48D", "IHO48E", "IHO48F", "IHO48G", "IHO48H", "IHO48I", "IHO48J", "IHO48K", "IHO48L", "IHO48M", "IHO48N", "IHO48O", "IHO49", "IHO50", "IHO51", "IHO52", "IHO53", "IHO54", "IHO55", "IHO56", "IHO57", "IHO58", "IHO59", "IHO60", "IHO61", "IHO62", "IHO62A", "IHO63", "IHO64", "IHO65", "IHO66", "SOCE", "SRGS"],
	"Wiki" => ["STHC", "GUIA", "BLVR", "MANT", "LANT", "LCYA", "BLCS", "SCND", "BLTC", "NRDC", "BNLX", "LVNT", "MSHR", "HOAF", "MGHR", "ARBC"])
	collections = ["NatEarth", "UN", "Mainlands", "IHO", "Wiki", "Lakes"]
	collect_dcw = ["DCW", "NatEarth", "UN", "Mainlands", "IHO", "Wiki", "Lakes"]

	pato::String = joinpath(dirname(pathof(GMT))[1:end-4], "share", "named_regions", "")

	coll_name = any(name .== collect_dcw) ? name : ""	# Check if 'name' is a collection name
	code = (coll_name == "") ? name : ""				# If not, than it must be a code

	if (coll_name != "")		# Just show the collection
		return show(gmtread(pato * coll_name * "_collection.txt"), allrows=true)
	else						# Need to find region
		opt_E = ""
		(contains(code,",") || contains(code, '.')) && (exact = true)	# For composite codes don't bother to make a union of rounded -R's
		if (!exact)
			ind, col = 0, 0
			for k = 1:numel(collections)
				((ind = findfirst(code .== d[collections[k]])) !== nothing) && (col = k; break)
			end
			if (col == 0)		# We treat the DCW collection differently because it's too big to have pre-loaded.
				D::GMTdataset = gmtread(pato * "DCW_collection.txt")::GMTdataset
				extra_guys, code_continent = ["01", "02", "03", "04", "05", "06", "07"], ""
				if (((ind = findfirst(code .== extra_guys)) !== nothing) ||
					((ind = findfirst(code .== ["Africa", "Antarctica", "Asia", "Europe", "Noth America", "Oceania", "South America"])) !== nothing))
					code_continent = ["=AF", "=AN", "=AS", "=EU", "=NA", "=OC", "=SA"][ind]
					code = extra_guys[ind]		# This one is for next findfirst be able to find ind for coordinates.
				end
				ind = findfirst(startswith.(D.text, code * ","))	# Trailing comma because we want to find sep code/name
				(ind === nothing) && error("Could not find the code '$code' in any of the collections:\n$collect_dcw")
				(code_continent != "") && (code = code_continent)
				country && (opt_E = code * "+p0.5")
			else
				D = gmtread(pato * collections[col] * "_collection.txt")::GMTdataset
			end

			(col != 0 && col != 2 && country) &&	# Using numbers (0 & 2) is dangerours. If collection lists change ...
				(@warn("This collection knows nothing about DCW country polygons."); country = false)
			reg::Vector{Float64} = D.data[ind,:]
			lim::String = @sprintf("%.6g/%.6g/%.6g/%.6g", reg[:]...)
		else					# Use the limits provided by GMT directly and no check if 'code' is valid
			lim = code
			(country && ((length(code) == 2 || contains(code,",") || contains(code,".")))) && (opt_E = code * "+p0.5")
		end
	end

	# Let user expand the bounding box to the nearest multiples of round
	(isa(round, String) && !any(startswith.(round, ["+r", "+R", "+e"]))) && error("When given as a string the 'round' option must start with one of +r, +R or +e. See GMT -R pscoast docs.")
	lim = isa(round, String) ? lim * round	: (round != 0) ? string(lim, "+r", arg2str(round)) : lim

	_type = string(type)
	if (_type == "map")
		coast(R=lim, G="tomato", S="lightblue", proj=proj, E=opt_E, Vd=Vd, show=true)
	else
		regist = (registration != "") ? "_" * registration[1] : ""	# If user want to screw (no p or g), let it do.
		(res != "" && regist == "") && (regist = isImg ? "_p" : "_g") 
		opt_J = (res == "") ? " -JX15" : ""
		(res != "") && (res = "_" * res)
		fname = "@" * dataset * res * regist
		if (isImg)
			# Here the problem is that gmt("grdcut ...) is not able to cut images, so we have to resort to GDAL
			# But GDAL knows nothing about the '@file' mechanism, so we must download the image first with GMT
			D2 = gmtwhich(fname, V=:q)	# See if image is already in the cache dir
			isempty(D2) && (gmtwhich(fname, G=:a); D2 = gmtwhich(fname, V=:q))	# If not, download it
			return grdcut(D2.text[1]::String, R=lim)::GMTimage			# This grdcut call will lower to use gdaltranslate
		end 
		gmt("grdcut @"*dataset * res * regist * opt_J * " -R" * lim * " -Vq")::GMTgrid
	end
end
