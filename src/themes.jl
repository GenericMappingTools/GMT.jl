function theme(name::String=""; kwargs...)
	d = KW(kwargs)
	font = ((val = find_in_dict(d, [:font])[1]) !== nothing) ? string(val) : ""
	bg_color = ((val = find_in_dict(d, [:bg_color])[1]) !== nothing) ? string(val) : ""
	color = ((val = find_in_dict(d, [:fg_color])[1]) !== nothing) ? string(val) : ""
	pure_modern()			# All themes are variations over the GMT_MODERN theme

	if (name == :dark || name == "dark")
		helper_theme_fonts_colors(font, color, bg_color, true)
	elseif (font != "" || color != "")		# We wont consider bg_color important enough to trigger next call
		helper_theme_fonts_colors(font, color, bg_color, false)
	end

	if (find_in_dict(d, [:noticks :no_ticks])[1] !== nothing)
		gmtlib_setparameter(API, "MAP_TICK_LENGTH_PRIMARY", "0/0")
		gmtlib_setparameter(API, "MAP_TICK_LENGTH_SECONDARY", "0/0")
	end
	if (find_in_dict(d, [:inner_ticks :innerticks])[1] !== nothing)		# Modern theme provides no way of setting this
		gmtlib_setparameter(API, "MAP_TICK_LENGTH_PRIMARY", "-4p")
		gmtlib_setparameter(API, "MAP_TICK_LENGTH_SECONDARY", "-12p")
	end
	if (find_in_dict(d, [:gray_grid :graygrid])[1] !== nothing)
		gmtlib_setparameter(API, "MAP_GRID_PEN_PRIMARY", "auto,gray")
		gmtlib_setparameter(API, "MAP_GRID_PEN_SECONDARY", "auto,gray")
	end

	isOn = true				# Means this theme will be reset to the default (modern) in showfig()
	#=
	if (haskey(d, :save) || haskey(d, "save"))
		f = joinpath(readlines(`$(joinpath("$(GMT_bindir)", "gmt")) --show-userdir`)[1], "theme_jl.txt")
		(isfile(f)) && rm(f)
		#(name == :none || name == "none") ? reset_defaults(API) : write(f, string(name))
		isOn = false		# So we wont reset defaults in showfig()
	end
	=#
	ThemeIsOn[1] = isOn
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function helper_theme_fonts_colors(font, color, bg_color, dark::Bool)
	fonts  = (font == "")  ? ["AvantGarde-Book", "AvantGarde-Demi", "Helvetica"] : [font, font, font]
	colors = (color == "") ? (dark ? ["gray92", "gray86"] : ["black", "black"]) : [color, color]
	(bg_color == "") && (bg_color = (dark) ? "5/5/35" : "white")
	fonts_colors_settings(fonts, colors, bg_color)
end

# ---------------------------------------------------------------------------------------------------
function fonts_colors_settings(fonts, colors, bg_color)
	# This function serves mainly the dark theme but can be used by any other theme that
	# wants to change font and/or colors.
	gmtlib_setparameter(API, "FONT_ANNOT_PRIMARY", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(API, "FONT_ANNOT_SECONDARY", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(API, "FONT_HEADING", "auto,$(fonts[2]),$(colors[1])")
	gmtlib_setparameter(API, "FONT_LABEL", "auto,$(fonts[1]),black")
	gmtlib_setparameter(API, "FONT_LOGO", "auto,$(fonts[3]),$(colors[1])")
	gmtlib_setparameter(API, "FONT_TAG", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(API, "FONT_TITLE", "auto,$(fonts[2]),$(colors[1])")
	gmtlib_setparameter(API, "MAP_DEFAULT_PEN", "0.25p,$(colors[1])")
	gmtlib_setparameter(API, "MAP_FRAME_PEN", "0.5p,$(colors[1])")
	gmtlib_setparameter(API, "MAP_GRID_PEN_PRIMARY", "auto,$(colors[1])")
	gmtlib_setparameter(API, "MAP_GRID_PEN_SECONDARY", "auto,$(colors[2])")
	gmtlib_setparameter(API, "MAP_TICK_PEN_PRIMARY", "auto,$(colors[1])")
	gmtlib_setparameter(API, "MAP_TICK_PEN_SECONDARY", "auto,$(colors[2])")
	gmtlib_setparameter(API, "PS_PAGE_COLOR", "$bg_color")
end

# ---------------------------------------------------------------------------------------------------
function pure_modern()
	# Set the MODERN mode settings
	IamModern[1] && return nothing		# Already modern so nothing to do
	swapmode(classic=false)				# Set GMT->current.setting.run_mode = GMT_MODERN
	reset_defaults(API)					# Set the modern mode settings
	gmtlib_setparameter(API, "MAP_FRAME_PEN", "0.5p")
	swapmode(classic=true)				# Reset GMT->current.setting.run_mode = GMT_CLASSIC
end

# ---------------------------------------------------------------------------------------------------
function swapmode(; classic::Bool=true)
	# GMT6.2 shot out the access the gmtinit_conf_classic() and gmtinit_conf_modern() functions
	# (declared them GMT_LOCAL) and direct access to members of the API mega-structure is,
	# for the time being, impractical so we must resort to tricks. This function changes the state
	# of GMT->current.setting.run_mode to MODERN or CLASSIC, which in turn calls the wished conf function.
	if (classic == false)
		GMT_Create_Options(API, 0, "-pdf lix")			# Cheat to make GMT go into MODERN mode
	else
		gmtlib_setparameter(API, "GMT_VERBOSE", "q")	# Shut up messages about session dir not found
		gmt_manage_workflow(API, GMT_END_WORKFLOW, NULL)		# Force reset to CLASSIC
		gmtlib_setparameter(API, "GMT_VERBOSE", "w")
	end
	return nothing
end