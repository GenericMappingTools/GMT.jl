function theme(name; kwargs...)
	d = KW(kwargs)
	font = ((val = find_in_dict(d, [:font])[1]) !== nothing) ? string(val) : ""
	bg_color = ((val = find_in_dict(d, [:bg_color])[1]) !== nothing) ? string(val) : ""
	color = ((val = find_in_dict(d, [:fg_color])[1]) !== nothing) ? string(val) : ""
	if (name == :dark || name == "dark")
		reset_defaults(API)
		fonts  = (font == "")  ? ["AvantGarde-Book", "AvantGarde-Demi", "Helvetica"] : [font, font, font]
		colors = (color == "") ? ["gray92", "gray86"] : [color, color]
		(bg_color == "") && (bg_color = "5/5/35")

		gmtlib_setparameter(API, "FONT_ANNOT_PRIMARY", "12p,$(fonts[1]),$(colors[1])")
		gmtlib_setparameter(API, "FONT_ANNOT_SECONDARY", "14p,$(fonts[1]),$(colors[1])")
		gmtlib_setparameter(API, "FONT_HEADING", "32p,$(fonts[2]),$(colors[1])")
		gmtlib_setparameter(API, "FONT_LABEL", "16p,$(fonts[1]),black")
		gmtlib_setparameter(API, "FONT_LOGO", "8p,$(fonts[3]),$(colors[1])")
		gmtlib_setparameter(API, "FONT_TAG", "20p,$(fonts[1]),$(colors[1])")
		gmtlib_setparameter(API, "FONT_TITLE", "24p,$(fonts[2]),$(colors[1])")

		gmtlib_setparameter(API, "MAP_DEFAULT_PEN", "default,$(colors[1])")
		gmtlib_setparameter(API, "MAP_FRAME_PEN", "thicker,$(colors[1])")
		gmtlib_setparameter(API, "MAP_GRID_PEN_PRIMARY", "default,$(colors[1])")
		gmtlib_setparameter(API, "MAP_GRID_PEN_SECONDARY", "thinner,$(colors[2])")
		gmtlib_setparameter(API, "MAP_TICK_PEN_PRIMARY", "thinner,$(colors[1])")
		gmtlib_setparameter(API, "MAP_TICK_PEN_SECONDARY", "thinner,$(colors[2])")
		gmtlib_setparameter(API, "PS_PAGE_COLOR", "$bg_color")
		ThemeIsOn[1] = true
#=
	elseif (name == :modern || name == "modern")
		reset_defaults(API)
		if (font == "")  fonts = ["AvantGarde-Book", "AvantGarde-Demi", "Helvetica"]	# The GMT settings
		else             fonts = [font, font, font]
		end
		(color == "") && (color = "black")
		(bg_color == "") && (bg_color = "white")

		gmtlib_setparameter(API, "FONT_ANNOT_PRIMARY", "auto,$(fonts[1]),$color")
		gmtlib_setparameter(API, "FONT_ANNOT_SECONDARY", "14p,$(fonts[1]),$color")
		gmtlib_setparameter(API, "FONT_HEADING", "auto,$(fonts[2]),$color")
		gmtlib_setparameter(API, "FONT_LABEL", "auto,$(fonts[1]),$color")
		gmtlib_setparameter(API, "FONT_LOGO", "auto,$(fonts[3]),$color")
		gmtlib_setparameter(API, "FONT_TAG", "auto,$(fonts[1]),$color")
		gmtlib_setparameter(API, "FONT_TITLE", "auto,$(fonts[2]),$color")
		gmtlib_setparameter(API, "FORMAT_GEO_MAP", "ddd:mm:ssF")
		gmtlib_setparameter(API, "MAP_FRAME_AXES", "WrStZ")
		gmtlib_setparameter(API, "MAP_ANNOT_MIN_SPACING", "auto")
		gmtlib_setparameter(API, "MAP_ANNOT_OFFSET_PRIMARY", "auto")
		gmtlib_setparameter(API, "MAP_ANNOT_OFFSET_SECONDARY", "auto")
		gmtlib_setparameter(API, "MAP_FRAME_TYPE", "plain")
		gmtlib_setparameter(API, "MAP_FRAME_WIDTH", "auto")
		gmtlib_setparameter(API, "MAP_HEADING_OFFSET", "auto")
		gmtlib_setparameter(API, "MAP_LABEL_OFFSET", "auto")
		gmtlib_setparameter(API, "MAP_TICK_LENGTH_PRIMARY", "auto")
		gmtlib_setparameter(API, "MAP_TICK_LENGTH_SECONDARY", "auto")
		gmtlib_setparameter(API, "MAP_TITLE_OFFSET", "auto")
		gmtlib_setparameter(API, "MAP_VECTOR_SHAPE", "auto")
		gmtlib_setparameter(API, "PS_PAGE_COLOR", "$bg_color")
=#
	end
	isOn = true				# Means this theme will reset to defaults in showfig()
	if (haskey(d, :save) || haskey(d, "save"))
		f = joinpath(readlines(`gmt --show-userdir`)[1], "theme_jl.txt")
		(isfile(f)) && rm(f)
		(name == :none || name == "none") ? reset_defaults(API) : write(f, string(name))
		isOn = false		# So we wont reset defaults in showfig()
	end
	ThemeIsOn[1] = isOn
	return nothing
end