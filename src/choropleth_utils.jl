"""
    C = cpt4dcw(codes::String, vals::Vector{<:Real}; kwargs...)

Create a categorical CPT to use with the output of `coast(dcw=...)` to make Choropleth maps.
  - `codes` is a comma separated string with two chars country codes (ex: "PT,ES,FR,IT")
  - `vals` a vector with same size as number of country codes, with the values used to colorize the countries
Optionally provide a CPT in the kwarg `cmap=CPT` with a range sufficient to tansform the `vals` in colors.
As an alternative to the above provide a `makecpt` type `range` numeric vector to create a CPT.
If none of these are provided a default `CPT = makecpt(range=(0,255,1))` will be used.
"""
cpt4dcw(codes::String, vals::Vector{<:Real}; kwargs...) = cpt4dcw(split(codes,","), vals; kwargs...)
function cpt4dcw(codes::Vector{<:AbstractString}, vals::Vector{<:Real}; kwargs...)
	d = KW(kwargs)

	if ((val = find_in_dict(d, CPTaliases)[1]) !== nothing && isa(val, GMTcpt))
		C = val
	elseif ((val = find_in_dict(d, [:range])[1]) !== nothing && isvector(val) && length(val) >= 2)
		inc = (length(val) == 2) ? 1 : val[3]
		C = gmt("makecpt -T" * arg2str((val[1], val[2], inc)))
	else
		C = gmt("makecpt -T0/255/1")
	end

	p = sortperm(vals)		# Need to have the 'vals' sorted otherwise if we plot the CPT we get a mess
	_codes, _vals = codes[p], vals[p]

	# And we must also rip off all values that are outside the C.minmax interval otherwise the CPT if plotted is wrong
	n_vals, k = length(_vals), 1
	c = ones(Bool, n_vals)
	while(_vals[k] < C.minmax[1] && k <= n_vals)  c[k] = false;  k += 1  end
	k = n_vals
	while(_vals[k] > C.minmax[2] && k > 0)        c[k] = false;  k -= 1  end
	_codes, _vals = _codes[c], _vals[c]

	P::Ptr{GMT.GMT_PALETTE} = palette_init(G_API[1], C)			# A pointer to a GMT CPT

	Ccat::GMTcpt = gmt("makecpt -T"*join(_codes, ","))
	rgb = [0.0, 0.0, 0.0];

	inc = (C.minmax[2] - C.minmax[1]) / size(Ccat.cpt, 1)
	for k = 1:size(Ccat.cpt, 1)
		gmt_get_rgb_from_z(G_API[1], P, _vals[k], rgb)
		[Ccat.colormap[k, n] = copy(rgb[n]) for n = 1:3]
		[Ccat.cpt[k, n+1] = copy(rgb[(n % 3) + 1]) for n = 0:5]		# cpt = [rgb rgb]
		Ccat.range[k,1] = C.minmax[1] + (k-1) * inc
		Ccat.range[k,2] = C.minmax[1] + k * inc
	end
	Ccat.minmax = C.minmax
	return Ccat
end

function cpt4dcw(continent::String, vals=missing; kwargs...)
	if (startswith(lowercase(continent), "eu"))
		codes = euro_codes()
		_vals = (vals === missing) ? rand(52) .* 255 : vals
		cpt4dcw(codes, _vals; kwargs...)
	else
		error("Unknown continent $(continent)")
	end
end

# --------------------------------------------------------------------------------------------------
function euro_codes()
	"AD,AL,AT,AX,BA,BE,BG,BY,CH,CY,CZ,DE,DK,EE,ES,FI,FO,FR,GB,GG,GI,GL,GR,HR,HU,IE,IM,IS,IT,JE,LI,LT,LU,LV,MC,MD,ME,MK,MT,NL,NO,PL,PT,RO,RS,SE,SI,SJ,SK,SM,VA,XK"
end

# --------------------------------------------------------------------------------------------------
function iso3to2_eu()
Dict("AND"=>"AD", "ALB"=>"AL", "AUT"=>"AT", "ALA"=>"AX", "BIH"=>"BA", "BEL"=>"BE", "BGR"=>"BG", "BLR"=>"BY", "CHE"=>"CH",
	"CYP"=>"CY", "CZE"=>"CZ", "DEU"=>"DE", "DNK"=>"DK", "EST"=>"EE", "ESP"=>"ES", "FIN"=>"FI", "FRO"=>"FO", "FRA"=>"FR",
	"GBR"=>"GB", "GGY"=>"GG", "GIB"=>"GI", "GRL"=>"GL", "GRC"=>"GR", "HRV"=>"HR", "HUN"=>"HU", "IRL"=>"IE", "IMN"=>"IM",
	"ISL"=>"IS", "ITA"=>"IT", "JEY"=>"JE", "LIE"=>"LI", "LTU"=>"LT", "LUX"=>"LU", "LVA"=>"LV", "MCO"=>"MC", "MDA"=>"MD", "MNE"=>"ME", "MKD"=>"MK", "MLT"=>"MT", "NLD"=>"NL", "NOR"=>"NO", "POL"=>"PL", "PRT"=>"PT", "ROU"=>"RO", "SRB"=>"RS",
	"SWE"=>"SE", "SVN"=>"SI", "SJM"=>"SJ", "SVK"=>"SK", "SMR"=>"SM", "VAT"=>"VA", "KSV"=>"XK") 
end

# --------------------------------------------------------------------------------------------------
function iso3to2_af()
Dict("AGO"=>"AO", "BFA"=>"BF", "BDI"=>"BI", "BEN"=>"BJ", "BVT"=>"BV", "BWA"=>"BW", "COD"=>"CD", "CAF"=>"CF", "COG"=>"CG",
	 "CIV"=>"CI", "CMR"=>"CM", "CPV"=>"CV", "DJI"=>"DJ", "DZA"=>"DZ", "EGY"=>"EG", "ESH"=>"EH", "ERI"=>"ER", "ETH"=>"ET",
	 "GAB"=>"GA", "GHA"=>"GH", "GMB"=>"GM", "GIN"=>"GN", "GNQ"=>"GQ", "GNB"=>"GW", "KEN"=>"KE", "COM"=>"KM", "LBR"=>"LR",
	 "LSO"=>"LS", "LBY"=>"LY", "MAR"=>"MA", "MDG"=>"MG", "MLI"=>"ML", "MRT"=>"MR", "MUS"=>"MU", "MWI"=>"MW", "NAM"=>"NA",
	 "NER"=>"NE", "NGA"=>"NG", "REU"=>"RE", "RWA"=>"RW", "SYC"=>"SC", "SDN"=>"SD", "SHN"=>"SH", "SLE"=>"SL", "SEN"=>"SN",
	 "SOM"=>"SO", "SSD"=>"SS", "STP"=>"ST", "SWZ"=>"SZ", "TCD"=>"TD", "ATF"=>"TF", "TGO"=>"TG", "TUN"=>"TN", "TZA"=>"TZ",
	 "UGA"=>"UG", "MYT"=>"YT", "ZAF"=>"ZA", "ZMB"=>"ZM", "ZWE"=>"ZW")
end

# --------------------------------------------------------------------------------------------------
function iso3to2_na()
	Dict( "CAN"=>"CA", "MEX"=>"MX", "USA"=>"US")
end

# --------------------------------------------------------------------------------------------------
"""
d = iso3to2_world()

	Creates a Dictionary that maps WORLD country code names from ISO3166A3 (3 chars) to ISO3166A2 (2 chars)
	It has 250 contry names.
"""
function iso3to2_world()
Dict("AFG"=>"AF", "ALA"=>"AX", "ALB"=>"AL", "DZA"=>"DZ", "ASM"=>"AS", "AND"=>"AD", "AGO"=>"AO", "AIA"=>"AI", "ATA"=>"AQ",
	"ATG"=>"AG", "ARG"=>"AR", "ARM"=>"AM", "ABW"=>"AW", "AUS"=>"AU", "AUT"=>"AT", "AZE"=>"AZ", "BHS"=>"BS", "BHR"=>"BH",
	"BGD"=>"BD", "BRB"=>"BB", "BLR"=>"BY", "BEL"=>"BE", "BLZ"=>"BZ", "BEN"=>"BJ", "BMU"=>"BM", "BTN"=>"BT", "BOL"=>"BO",
	"BES"=>"BQ", "BIH"=>"BA", "BWA"=>"BW", "BVT"=>"BV", "BRA"=>"BR", "IOT"=>"IO", "BRN"=>"BN", "BGR"=>"BG", "BFA"=>"BF",
	"BDI"=>"BI", "KHM"=>"KH", "CMR"=>"CM", "CAN"=>"CA", "CPV"=>"CV", "CYM"=>"KY", "CAF"=>"CF", "TCD"=>"TD", "CHL"=>"CL",
	"CHN"=>"CN", "CXR"=>"CX", "CCK"=>"CC", "COL"=>"CO", "COM"=>"KM", "COG"=>"CG", "COD"=>"CD", "COK"=>"CK", "CRI"=>"CR",
	"CIV"=>"CI", "HRV"=>"HR", "CUB"=>"CU", "CUW"=>"CW", "CYP"=>"CY", "CZE"=>"CZ", "DNK"=>"DK", "DJI"=>"DJ", "DMA"=>"DM",
	"DOM"=>"DO", "ECU"=>"EC", "EGY"=>"EG", "SLV"=>"SV", "GNQ"=>"GQ", "ERI"=>"ER", "EST"=>"EE", "ETH"=>"ET", "FLK"=>"FK",
	"FRO"=>"FO", "FJI"=>"FJ", "FIN"=>"FI", "FRA"=>"FR", "GUF"=>"GF", "PYF"=>"PF", "ATF"=>"TF", "GAB"=>"GA", "GMB"=>"GM",
	"GEO"=>"GE", "DEU"=>"DE", "GHA"=>"GH", "GIB"=>"GI", "GRC"=>"GR", "GRL"=>"GL", "GRD"=>"GD", "GLP"=>"GP", "GUM"=>"GU",
	"GTM"=>"GT", "GGY"=>"GG", "GIN"=>"GN", "GNB"=>"GW", "GUY"=>"GY", "HTI"=>"HT", "HMD"=>"HM", "VAT"=>"VA", "HND"=>"HN",
	"HKG"=>"HK", "HUN"=>"HU", "ISL"=>"IS", "IND"=>"IN", "IDN"=>"ID", "IRN"=>"IR", "IRQ"=>"IQ", "IRL"=>"IE", "IMN"=>"IM",
	"ISR"=>"IL", "ITA"=>"IT", "JAM"=>"JM", "JPN"=>"JP", "JEY"=>"JE", "JOR"=>"JO", "KAZ"=>"KZ", "KEN"=>"KE", "KIR"=>"KI",
	"PRK"=>"KP", "KOR"=>"KR", "KWT"=>"KW", "KGZ"=>"KG", "LAO"=>"LA", "LVA"=>"LV", "LBN"=>"LB", "LSO"=>"LS", "LBR"=>"LR",
	"LBY"=>"LY", "LIE"=>"LI", "LTU"=>"LT", "LUX"=>"LU", "MAC"=>"MO", "MKD"=>"MK", "MDG"=>"MG", "MWI"=>"MW", "MYS"=>"MY",
	"MDV"=>"MV", "MLI"=>"ML", "MLT"=>"MT", "MHL"=>"MH", "MTQ"=>"MQ", "MRT"=>"MR", "MUS"=>"MU", "MYT"=>"YT", "MEX"=>"MX",
	"FSM"=>"FM", "MDA"=>"MD", "MCO"=>"MC", "MNG"=>"MN", "MNE"=>"ME", "MSR"=>"MS", "MAR"=>"MA", "MOZ"=>"MZ", "MMR"=>"MM",
	"NAM"=>"NA", "NRU"=>"NR", "NPL"=>"NP", "NLD"=>"NL", "NCL"=>"NC", "NZL"=>"NZ", "NIC"=>"NI", "NER"=>"NE", "NGA"=>"NG",
	"NIU"=>"NU", "NFK"=>"NF", "MNP"=>"MP", "NOR"=>"NO", "PSE"=>"PS", "OMN"=>"OM", "PAK"=>"PK", "PLW"=>"PW", "PAN"=>"PA",
	"PNG"=>"PG", "PRY"=>"PY", "PER"=>"PE", "PHL"=>"PH", "PCN"=>"PN", "POL"=>"PL", "PRT"=>"PT", "PRI"=>"PR", "QAT"=>"QA",
	"REU"=>"RE", "ROU"=>"RO", "RUS"=>"RU", "RWA"=>"RW", "BLM"=>"BL", "SHN"=>"SH", "KNA"=>"KN", "LCA"=>"LC", "MAF"=>"MF",
	"SPM"=>"PM", "VCT"=>"VC", "WSM"=>"WS", "SMR"=>"SM", "STP"=>"ST", "SAU"=>"SA", "SEN"=>"SN", "SRB"=>"RS", "SYC"=>"SC",
	"SLE"=>"SL", "SGP"=>"SG", "SXM"=>"SX", "SVK"=>"SK", "SVN"=>"SI", "SLB"=>"SB", "SOM"=>"SO", "ZAF"=>"ZA", "SGS"=>"GS",
	"SSD"=>"SS", "ESP"=>"ES", "LKA"=>"LK", "SDN"=>"SD", "SUR"=>"SR", "SJM"=>"SJ", "SWZ"=>"SZ", "SWE"=>"SE", "CHE"=>"CH",
	"SYR"=>"SY", "TWN"=>"TW", "TJK"=>"TJ", "TZA"=>"TZ", "THA"=>"TH", "TLS"=>"TL", "TGO"=>"TG", "TKL"=>"TK", "TON"=>"TO",
	"TTO"=>"TT", "TUN"=>"TN", "TUR"=>"TR", "TKM"=>"TM", "TCA"=>"TC", "TUV"=>"TV", "UGA"=>"UG", "UKR"=>"UA", "ARE"=>"AE",
	"GBR"=>"GB", "USA"=>"US", "UMI"=>"UM", "URY"=>"UY", "UZB"=>"UZ", "VUT"=>"VU", "VEN"=>"VE", "VNM"=>"VN", "VGB"=>"VG",
	"VIR"=>"VI", "WLF"=>"WF", "ESH"=>"EH", "YEM"=>"YE", "ZMB"=>"ZM", "ZWE"=>"ZW", "KSV"=>"XK")
end

# --------------------------------------------------------------------------------------------------
"""
    code, vals = mk_codes_values(codes::Vector{String}, vals; region::StrSymb="world")

Take a list of country `codes`` in the ISO alpha-3 country code names, a vector of numeric `vals`
that will be used in a choropleth and select only those that belong to the region `region`.
Possible values for region are: "world", "eu", "af" or "na".

Returns `code` in the ISO alpha-2 country code names and corresponding `vals`. This output is then
usable in cpt2dcw() to create a colormap to use in `plot()` and make a country choropleth map.
"""
function mk_codes_values(codes::Vector{String}, vals; region::StrSymb="world")
	isempty(codes) && error("The country codes 'codes' input argument is empty.")
	code_len = length(codes[1])
	(length(codes[1]) != 3) && error("The country codes in this function must follow the 3 char ISO codes. This does not.")

	_reg = lowercase(string(region))
	!any(_reg .== ["world", "eu", "af", "na"]) && error("The region $(region) is invalid or has not been implemented yet.")
	d = (_reg == "eu") ? iso3to2_eu() : (_reg == "af") ? iso3to2_af() : (_reg == "na") ? iso3to2_na() : iso3to2_world()

	ky, vl = String[], Float64[]
	for k = 1:length(codes)
		r = get(d, codes[k], "")
		if (r != "" && vals[k] !== missing)
			append!(ky, [r])
			append!(vl, vals[k])
		end
	end
	return ky, vl
end

#= --------------------------------------------------------------------------------------------------
function choropleth(polygs::Vector{<:GMTdataset}, colorval::Vector{<:Real}; kwargs...)
	d = KW(kwargs)
	data_ids, ind = get_segment_ids(polygs)
	zvals = make_zvals_vec(polygs, data_ids, colorval)
	C::GMTcpt = makecpt(T=(1,6,1))		# <==================================================== ERRADO
	((val = find_in_dict(d, [:fmt])[1]) !== nothing) && (fmt = arg2str(val))
	fmt::String = ((val = find_in_dict(d, [:fmt])[1]) !== nothing) ? arg2str(val) : "ps"   
	see = (find_in_dict(d, [:show])[1] !== nothing) ? true : false
	val, symb = find_in_dict(d, [:savefig :name])
	if (val === nothing)
		plot(polygs, Z=zvals, L=true, G="+z", fmt=fmt, show=see, colorbar=true)
	else
		plot(polygs, Z=zvals, L=true, G="+z", name=string(d[symb]), fmt=fmt, show=see, colorbar=true)
	end
end
=#