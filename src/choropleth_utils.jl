"""
C = cpt4dcw(codes::String, vals::Vector{<:Number}; kwargs...)

	Create a categorical CPT to use with the output of `coast(dcw=...)` to make Choropleth maps.
	`codes` is a comma separated string with two chars country codes (ex: "PT,ES,FR,IT")
	`vals` a vector with same size as number of country codes, with the values used to colorize the countries
	Optionally provide a CPT in the kwarg `cmap=CPT` with a range sufficient to tansform the `vals` in colors.
	As an alternative to the above provide a `makecpt` type `range` numeric vector to create a CPT.
	If none of these are provided a default `CPT = makecpt(range=(0,255,1))` will be used.
"""
function cpt4dcw(codes::String, vals::Vector{<:Number}; kwargs...)
	#
	d = KW(kwargs)

	if ((val = find_in_dict(d, [:C :color :cmap])[1]) !== nothing && isa(val, GMTcpt))
		C = val
	elseif ((val = find_in_dict(d, [:range])[1]) !== nothing && isvector(val) && length(val) >= 2)
		inc = (length(val) == 2) ? 1 : val[3]
		C::GMTcpt = makecpt(T=(val[1], val[2], inc))
	else
		C = makecpt(T=(0,255,1))
	end

	Ccat::GMTcpt = makecpt(T=codes);
	rgb = [0.0, 0.0, 0.0];

	P::Ptr{GMT.GMT_PALETTE} = palette_init(API, C);		# A pointer to a GMT CPT
	for k = 1:size(Ccat.cpt, 1)
		gmt_get_rgb_from_z(API, P, vals[k], rgb)
		[Ccat.colormap[k, n] = rgb[n] for n = 1:3]
		[Ccat.cpt[k, n+1] = rgb[(n % 3) .+ 1] for n = 0:5]		# cpt = [rgb rgb]
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

#= --------------------------------------------------------------------------------------------------
function euro_dict()
Dict(
	"AD"=>0., "AL"=>0., "AT"=>0., "AX"=>0., "BA"=>0., "BE"=>0., "BG"=>0., "BY"=>0., "CH"=>0., "CY"=>0., "CZ"=>0., 
	"DE"=>0., "DK"=>0., "EE"=>0., "ES"=>0., "FI"=>0., "FO"=>0., "FR"=>0., "GB"=>0., "GG"=>0., "GI"=>0., "GL"=>0., 
	"GR"=>0., "HR"=>0., "HU"=>0., "IE"=>0., "IM"=>0., "IS"=>0., "IT"=>0., "JE"=>0., "LI"=>0., "LT"=>0., "LU"=>0., 
	"LV"=>0., "MC"=>0., "MD"=>0., "ME"=>0., "MK"=>0., "MT"=>0., "NL"=>0., "NO"=>0., "PL"=>0., "PT"=>0., "RO"=>0., 
	"RS"=>0., "SE"=>0., "SI"=>0., "SJ"=>0., "SK"=>0., "SM"=>0., "VA"=>0., "XK"=>0.) 
end
=#