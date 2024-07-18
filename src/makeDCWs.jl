"""
    makeDCWs(fname; float=false, name_cdl="xxxx.cdl", name_nc="", compress=true,
             attrib="", fix_RU::Bool=false, deltmp=true)

Convert the contents of the OGR file `fname` into a NetCDF CDL or NC file with the structure of the GMT DCW format.
So far, only administrative level 0 polygons (the country borders) are supported.

### Parameters
- `fname`: The name of the file to be converted. It needs to be an OGR readable file with polygons
  and metadata containing codes in ISO 3166-1 Alpha-3 or Alpha-2. Note: if the file being converted
  is the "world-administrative-boundaries" from OpenDataSoft (see full link below), it lacks the
  Anctartica polygons. A trick to get it is to extract the Antractica polygons from a Natural Earth
  file. Specifically, if a file named "ne_10m_admin_0_countries.shp.zip" exists in the same directory
  as the one being converted, it will be used to extract the missing Antractica polygons.

### Keywords
- `attrib`: The name of the attribute field in the OGR file that contains the country codes.
  It has to be an attribute whose value has to be either a ISO 3166-1 Alpha-3 or Alpha-2 code.
  For convenience, we provide defaults for 'Natural Earth'
  https://www.naturalearthdata.com/downloads/10m-cultural-vectors/ files (`attrib="ADM0_A3"`),
  'World Administrative Boundaries' https://public.opendatasoft.com/explore/dataset/world-administrative-boundaries/export/
  (`attrib="iso3"`) and 'Open Street Maps' (`attrib="iso2"`). For other products, you will need to first
  load the file with `gmtread` and then check the attributes to find out the attribute name that holds the country codes.
  Something like: ``o = gmtread("the_file"); info(o[1].attrib)``

- `float`: If true, save the coordinates in float 32 bits. The default is to use a scheme that scales the
  coordinates to fit in a UInt16 variable. GMT knows how to read both UInt16 and Float32 files.

- `name_cdl`: The name of the CDL file (default: "xxxx.cdl"). This file gets deleted if `deltmp` = true.

- `name_nc`: Name of the final netCDF file. WARNING: for this operation to work it is MANDATORY that the
  executable `ncgen` is in the path.

- `compress`: If true, compress the nc file with level 9 (default: true). Only used if `name_nc` is not empty
  and needs that the executable `nccopy` is in the path.

- `fix_RU`: The Russia polygon is often split at the dateline. If we find this is be true and this option is `true`,
  then it try to merge the two parts of Siberia in a single big Russia polygon. The default is `false` because
  probability that this operation goes wrong is not that low.
  this attempt fails set it to `false` and live with the split polygons.

- `deltmp`: Delete temporary files (default: true). Only used if `name_nc` is not empty

### Example
```julia
# Create a xxxx.cdl file with data scaled to Uint16 from the ne_10m_admin_0_countries_iso.shp.zip file
makeDCWs("ne_10m_admin_0_countries_iso.shp.zip")

# After that, to create a netCDF file "NE10m.nc" run in the command line:
ncgen -b -k 3 -o NE10m.nc -x xxxx.cdl

# and to compress it with level 9
nccopy -k 3 -d 9 -s NE10m.nc NE10m_9.nc

# To create a compressed netCDF file "NE10m.nc" with data stored in single precision.
makeDCWs("ne_10m_admin_0_countries_iso.shp.zip", name_nc="NE10m_f32.nc", float=true)
```
"""
function makeDCWs(fname="ne_10m_admin_0_countries_iso.shp.zip"; float=false, name_cdl::String="xxxx.cdl",
	name_nc::String="", compress=true, attrib="", fix_RU::Bool=false, deltmp=true)

	!isfile(fname) && error("File $fname not found")
	(attrib == "" && contains(fname, "ne_") && contains(fname, "_admin_0_countries")) && (attrib = "ADM0_A3")
	(attrib == "" && contains(fname, "world-administrative-boundaries")) && (attrib = "iso3")
	(attrib == "" && contains(fname, "adm0_polygons.gpkg")) && (attrib = "iso2")
	(attrib == "") && error("The attribute name for the country codes has to be specified")

	float_ = (float == 1)							# To get a boolean var
	ct = gmtread(fname, ogr=true)
	o = unique(info(ct, att=string(attrib)))		# Get the unique country codes
	d_iso = countries_iso3to2()

	if (contains(fname, "world-administrative-boundaries"))	# opendatasoft poygons miss Antarctica. Cheat with the NE one.
		pato = fileparts(fname)[1]
		f2 = (pato != "") ? pato * "/ne_10m_admin_0_countries.shp.zip" : "ne_10m_admin_0_countries_iso.shp.zip"
		if (isfile(f2))		# If the NE 10m file exists in same directory, get Antarctica from there.
			NE = gmtread(f2, ogr=true)
			ATA = filter(NE, ADM0_A3="ATA");			# Fish Antarctica polygons
			ind_ant = sortperm(length.(ATA), rev=true)[1:50];	# Pick only the 50 largest polygons
			ATA = ATA[ind_ant]
			for k = 1:20
				ATA[k].attrib["iso3"] = "ATA"			# Add iso3 code so it can pretend is a ODS polygon
			end
			ct = vcat(ct, ATA)
			append!(o, ["ATA"])
		end
	end

	dat1, dat2, dat3 = UInt8[], UInt8[], UInt8[]	# Temp vars to hold parts of the CDL file
	append!(dat1, "netcdf DCW {    // DCW netCDF specification in CDL\n")
	append!(dat1, "dimensions:\n")

	append!(dat2, "variables:\n")
	append!(dat2, ":title = \"DCW-GMT - The Natural Earth 10m countries for the Generic Mapping Tools\";\n")
	append!(dat2, ":source = \"Data from $fname processed at $(today())\";\n")
	append!(dat2, ":version = \"2.0.0\";\n")
	append!(dat2, ":gmtversion = \"6.1.1\";\n")				# Minimum GMT version needed to ingest files produced here.
	(float_) && append!(dat2, ":datatype = \"float\";\n")	# Only floating points nc need to declare this.
	append!(dat3, "data:\n")

	for k = 1:numel(o)						# Loop over all countries
		dd = Dict(Symbol(attrib) => o[k])	# All this in order to able to set the keyword name programatically.
		Dk = filter(ct; dd...)
		code = (length(o[k]) == 2) ? o[k] : get(d_iso, o[k], "")	# From iso 3-char to 2-char
		(code == "") && continue

		if (fix_RU && code == "RU")			# Fix Russia that has part of Siberia split at dateline.
			ind_big = sortperm(length.(Dk), rev=true)[1]		# Get the bigest polygon
			for n = 1:numel(Dk)
				if (Dk[n].bbox[1] >= -180 && (0 > Dk[n].bbox[2] > -171))	# Find polygon that starts at the dateline
					Dk[n].data[:,1] .+= 359.9999
					Dk[ind_big].data = polyunion(Dk[ind_big].data, Dk[n].data)	# Join the two
					dx = diff(Dk[ind_big].data[:,1]);		dy = diff(Dk[ind_big].data[:,2])
					ind_x = findall(abs.(dx) .< 0.00001);	ind_y = findall(abs.(dy) .< 0.00001)
					ind = intersect(ind_x, ind_y)
					(!isempty(ind)) && (Dk[ind_big].data = delrows!(Dk[ind_big].data, ind))		# Delete repeated points
					deleteat!(Dk, n)		# Delete the one that was included in the big one
					set_dsBB!(Dk)
					break
				end
			end
		end
	
		append!(dat1, string("\t", code, "_length = ", sum(size.(Dk,1))+length(Dk), ";\n"))
		if (float_)
			append!(dat2, string("\tfloat ", code, "_lon(", code, "_length);\n"))
			append!(dat2, string("\t\t", code, "_lon:min = ", Dk[1].ds_bbox[1], ";\n"))
			append!(dat2, string("\t\t", code, "_lon:max = ", Dk[1].ds_bbox[2], ";\n"))
		else					# The uint16 case
			append!(dat2, string("\tushort ", code, "_lon(", code, "_length);\n"))
			append!(dat2, string("\t\t", code, "_lon:valid_range = 0, 65535;\n"))
			append!(dat2, string("\t\t", code, "_lon:units = \"0-65535\";\n"))
			append!(dat2, string("\t\t", code, "_lon:min = ", Dk[1].ds_bbox[1], ";\n"))
			append!(dat2, string("\t\t", code, "_lon:max = ", Dk[1].ds_bbox[2], ";\n"))
			append!(dat2, string("\t\t", code, "_lon:scale = ", 65535 / (Dk[1].ds_bbox[2] - Dk[1].ds_bbox[1]), ";\n"))
		end

		append!(dat3, string("\t", code, "_lon ="))
		(!float_) && (xscale = 65534 / (Dk[1].ds_bbox[2] - Dk[1].ds_bbox[1]))
		for n = 1:numel(Dk)
			lon = (float_) ? Dk[n].data[:,1] : round.(UInt16, (Dk[n].data[:,1] .- Dk[1].ds_bbox[1]) * xscale)
			append!(dat3, "\n\t65535, ")
			for j = 1:numel(lon)
				append!(dat3, @sprintf("%.9g, ", lon[j]))
				(j < length(lon) && rem(j, 10) == 0) && append!(dat3, "\n\t")
			end
		end
		dat3[length(dat3)-1], dat3[length(dat3)] = ';', '\n'

		# Now the LATs
		if (float_)
			append!(dat2, string("\tfloat ", code, "_lat(", code, "_length);\n"))
			append!(dat2, string("\t\t", code, "_lat:min = ", Dk[1].ds_bbox[3], ";\n"))
			append!(dat2, string("\t\t", code, "_lat:max = ", Dk[1].ds_bbox[4], ";\n"))
		else
			append!(dat2, string("\tushort ", code, "_lat(", code, "_length);\n"))
			append!(dat2, string("\t\t", code, "_lat:valid_range = 0, 65535;\n"))
			append!(dat2, string("\t\t", code, "_lat:units = \"0-65535\";\n"))
			append!(dat2, string("\t\t", code, "_lat:min = ", Dk[1].ds_bbox[3], ";\n"))
			append!(dat2, string("\t\t", code, "_lat:max = ", Dk[1].ds_bbox[4], ";\n"))
			append!(dat2, string("\t\t", code, "_lat:scale = ", 65535 / (Dk[1].ds_bbox[4] - Dk[1].ds_bbox[3]), ";\n"))
		end

		append!(dat3, string("\t", code, "_lat ="))
		(!float_) && (yscale = 65534 / (Dk[1].ds_bbox[4] - Dk[1].ds_bbox[3]))
		for n = 1:numel(Dk)
			lat = (float_) ? Dk[n].data[:,2] : round.(UInt16, (Dk[n].data[:,2] .- Dk[1].ds_bbox[3]) * yscale)
			ishole = contains(Dk[n].header, "-Ph") ? "1" : "0"
			append!(dat3, "\n\t$ishole, ")
			for j = 1:numel(lat)
				append!(dat3, @sprintf("%.8g, ", lat[j]))
				(j < length(lat) && rem(j, 10) == 0) && append!(dat3, "\n\t")
			end
		end
		dat3[length(dat3)-1], dat3[length(dat3)] = ';', '\n'
	end
	append!(dat3, "\n}")
	fid = open(name_cdl, "w")
	write(fid, dat1, dat2, dat3)
	close(fid)

	if (name_nc != "")
		_name_nc = (compress == 1) ? name_nc * ".tmp" : name_nc
		run(`ncgen -b -k 3 -o $_name_nc -x $name_cdl`)
		(compress == 1) && run(`nccopy -k 3 -d 9 -s $_name_nc $name_nc`)
		if (deltmp)
			rm(name_cdl)
			(compress == 1) && rm(_name_nc)
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    d = countries_iso3to2()

Return a dictionary with ISO 3166-1 Alpha-3 country codes as keys and ISO 3166-1 Alpha-2 country codes as values.

### Example
```julia
    d = countries_iso3to2();
	d["AFG"]
	"AF"
```
"""
function countries_iso3to2()
	Dict(
		"AFG" => "AF", "ALA" => "AX", "ALB" => "AL", "DZA" => "DZ", "ASM" => "AS", "AND" => "AD", "AGO" => "AO", "AIA" => "AI",
		"ATA" => "AQ", "ATG" => "AG", "ARG" => "AR", "ARM" => "AM", "ABW" => "AW", "AUS" => "AU", "AUT" => "AT", "AZE" => "AZ",
		"BHS" => "BS", "BHR" => "BH", "BGD" => "BD", "BRB" => "BB", "BLR" => "BY", "BEL" => "BE", "BLZ" => "BZ", "BEN" => "BJ",
		"BMU" => "BM", "BTN" => "BT", "BOL" => "BO", "BES" => "BQ", "BIH" => "BA", "BWA" => "BW", "BVT" => "BV", "BRA" => "BR",
		"VGB" => "VG", "IOT" => "IO", "BRN" => "BN", "BGR" => "BG", "BFA" => "BF", "BDI" => "BI", "KHM" => "KH", "CMR" => "CM",
		"CAN" => "CA", "CPV" => "CV", "CYM" => "KY", "CAF" => "CF", "TCD" => "TD", "CHL" => "CL", "CHN" => "CN", "HKG" => "HK",
		"MAC" => "MO", "CXR" => "CX", "CCK" => "CC", "COL" => "CO", "COM" => "KM", "COG" => "CG", "COD" => "CD", "COK" => "CK",
		"CRI" => "CR", "CIV" => "CI", "HRV" => "HR", "CUB" => "CU", "CUW" => "CW", "CYP" => "CY", "CZE" => "CZ", "DNK" => "DK",
		"DJI" => "DJ", "DMA" => "DM", "DOM" => "DO", "ECU" => "EC", "EGY" => "EG", "SLV" => "SV", "GNQ" => "GQ", "ERI" => "ER",
		"EST" => "EE", "ETH" => "ET", "FLK" => "FK", "FRO" => "FO", "FJI" => "FJ", "FIN" => "FI", "FRA" => "FR", "GUF" => "GF",
		"PYF" => "PF", "ATF" => "TF", "GAB" => "GA", "GMB" => "GM", "GEO" => "GE", "DEU" => "DE", "GHA" => "GH", "GIB" => "GI",
		"GRC" => "GR", "GRL" => "GL", "GRD" => "GD", "GLP" => "GP", "GUM" => "GU", "GTM" => "GT", "GGY" => "GG", "GIN" => "GN",
		"GNB" => "GW", "GUY" => "GY", "HTI" => "HT", "HMD" => "HM", "VAT" => "VA", "HND" => "HN", "HUN" => "HU", "ISL" => "IS",
		"IND" => "IN", "IDN" => "ID", "IRN" => "IR", "IRQ" => "IQ", "IRL" => "IE", "IMN" => "IM", "ISR" => "IL", "ITA" => "IT",
		"JAM" => "JM", "JPN" => "JP", "JEY" => "JE", "JOR" => "JO", "KAZ" => "KZ", "KEN" => "KE", "KIR" => "KI", "PRK" => "KP",
		"KOR" => "KR", "KWT" => "KW", "KGZ" => "KG", "LAO" => "LA", "LVA" => "LV", "LBN" => "LB", "LSO" => "LS", "LBR" => "LR",
		"LBY" => "LY", "LIE" => "LI", "LTU" => "LT", "LUX" => "LU", "MKD" => "MK", "MDG" => "MG", "MWI" => "MW", "MYS" => "MY",
		"MDV" => "MV", "MLI" => "ML", "MLT" => "MT", "MHL" => "MH", "MTQ" => "MQ", "MRT" => "MR", "MUS" => "MU", "MYT" => "YT",
		"MEX" => "MX", "FSM" => "FM", "MDA" => "MD", "MCO" => "MC", "MNG" => "MN", "MNE" => "ME", "MSR" => "MS", "MAR" => "MA",
		"MOZ" => "MZ", "MMR" => "MM", "NAM" => "NA", "NRU" => "NR", "NPL" => "NP", "NLD" => "NL", "ANT" => "AN", "NCL" => "NC",
		"NZL" => "NZ", "NIC" => "NI", "NER" => "NE", "NGA" => "NG", "NIU" => "NU", "NFK" => "NF", "MNP" => "MP", "NOR" => "NO",
		"OMN" => "OM", "PAK" => "PK", "PLW" => "PW", "PSE" => "PS", "PAN" => "PA", "PNG" => "PG", "PRY" => "PY", "PER" => "PE",
		"PHL" => "PH", "PCN" => "PN", "POL" => "PL", "PRT" => "PT", "PRI" => "PR", "QAT" => "QA", "REU" => "RE", "ROU" => "RO",
		"RUS" => "RU", "RWA" => "RW", "BLM" => "BL", "SHN" => "SH", "KNA" => "KN", "LCA" => "LC", "MAF" => "MF", "SPM" => "PM",
		"VCT" => "VC", "WSM" => "WS", "SMR" => "SM", "STP" => "ST", "SAU" => "SA", "SEN" => "SN", "SRB" => "RS", "SYC" => "SC",
		"SLE" => "SL", "SGP" => "SG", "SXM" => "SX", "SVK" => "SK", "SVN" => "SI", "SLB" => "SB", "SOM" => "SO", "ZAF" => "ZA",
		"SGS" => "GS", "SSD" => "SS", "ESP" => "ES", "LKA" => "LK", "SDN" => "SD", "SUR" => "SR", "SJM" => "SJ", "SWZ" => "SZ",
		"SWE" => "SE", "CHE" => "CH", "SYR" => "SY", "TWN" => "TW", "TJK" => "TJ", "TZA" => "TZ", "THA" => "TH", "TLS" => "TL",
		"TGO" => "TG", "TKL" => "TK", "TON" => "TO", "TTO" => "TT", "TUN" => "TN", "TUR" => "TR", "TKM" => "TM", "TCA" => "TC",
		"TUV" => "TV", "UGA" => "UG", "UKR" => "UA", "ARE" => "AE", "GBR" => "GB", "USA" => "US", "UMI" => "UM", "URY" => "UY",
		"UZB" => "UZ", "VUT" => "VU", "VEN" => "VE", "VNM" => "VN", "VIR" => "VI", "WLF" => "WF", "ESH" => "EH", "YEM" => "YE",
		"ZMB" => "ZM", "ZWE" => "ZW", "XKX" => "XK")	
end