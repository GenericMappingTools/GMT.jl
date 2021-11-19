"""
    theme(name; kwrgs...)

Offer themes support. NAME is the theme name. So far the three options are:

- `modern`: - This is the default theme (same as GMT modern theme but with thinner FRAME_PEN [0.75p])
- `classic`: - The GMT classic theme
- `dark`: - A modern theme variation with dark background.
- `A0|2[XY|XX|YY][atg][ag][g][H][V][NT|nt][ITit][Graph][Dark]` Make a composition of these to select a theme.
   The main condition is that it starts with an A (Annotate). Hence `A2` means annotate two axis
   and `A0` means no axes at all. `XY` means to plot only left and bottom axes, `YY` only left and right
   and `XX` bottom and top. `atg` (or `afg`) means annotate, tick and grid lines. `ag` does not tick.
   `H` and `V` means grid lines will only be horizontal or vertical. Note, these require `atg` or `ag`.
   `NT` stands for not ticks at all and `IT` plots the ticks inside the axes. `Graph` adds a vector and
   to the end of each axis (sets `XY`), and `Dark` put the background in dark mode.
   - Example: `A2YYg` -> plot left and right axes (only) and add grid lines.
   - Example: `A2Graph` -> plot left and right axes (only) and adds arrows at the end of them

On top of the modern mode variations (so far `dark` only) one can set the following `kwargs` options:

- `noticks` or `no_ticks`: Axes will have annotations but no tick marks
- `inner_ticks` or `innerticks`: - Ticks will be drawn inside the axes instead of outside.
- `gray_grid` or `graygrid`: - When drawing grid line use `gray` instead of `black`
- `save`: - Save the name in the directory printed in shell by ``gmt --show-userdir`` and make it permanent.
- `reset`: - Remove the saved theme name and return to the default `modern` theme.

Note: Except `save` and `reset`, the changes operated by the `kwargs` are temporary and operate only until
an image is `show`(n) or saved.

This function can be called alone, e.g. ``theme("dark")`` or as an option in the ``plot()`` module.
"""
function theme(name="modern"; kwargs...)
	# Provide the support for themes

	(GMTver < v"6.2.0") && return nothing
	(!isa(G_API[1], Ptr{Nothing}) || G_API[1] == C_NULL) && (G_API[1] = GMT_Create_Session("GMT", 2, GMT_SESSION_BITFLAGS))

	d = KW(kwargs)
	font = ((val = find_in_dict(d, [:font])[1]) !== nothing) ? string(val) : ""
	bg_color = ((val = find_in_dict(d, [:bg_color])[1]) !== nothing) ? string(val) : ""
	color = ((val = find_in_dict(d, [:fg_color])[1]) !== nothing) ? string(val) : ""
	
	# Some previous calls may have changed these and a new theme option may be caught with the pens down
	def_fig_axes[1]  = def_fig_axes_bak		# So that we always start with the defaults
	def_fig_axes3[1] = def_fig_axes3_bak

	_name = string(name)
	if (_name == "classic")
		theme_classic()
	else
		theme_modern()			# All other themes are variations over the GMT_MODERN theme
		if (_name == "dark" || contains(_name, "Dark"))
			helper_theme_fonts_colors(font, color, bg_color, true)
		elseif ((_name != "modern") || (font != "" || color != ""))	# bg_color alone wont trigger next call
			helper_theme_fonts_colors(font, color, bg_color, false)
		end
		parse_theme_names(_name)
	end

	(find_in_dict(d, [:noticks :no_ticks])[1] !== nothing) && helper_theme_noticks()		# No ticks
	(find_in_dict(d, [:inner_ticks :innerticks])[1] !== nothing) &&  helper_theme_inticks()	# Inner ticks
	if (find_in_dict(d, [:gray_grid :graygrid])[1] !== nothing)
		gmtlib_setparameter(G_API[1], "MAP_GRID_PEN_PRIMARY", "auto,gray")
		gmtlib_setparameter(G_API[1], "MAP_GRID_PEN_SECONDARY", "auto,gray")
	end

	isOn = true				# Means this theme will be reset to the default (modern) in showfig()
	if (haskey(d, :save))
		f = joinpath(readlines(`$(joinpath("$(GMT_bindir)", "gmt")) --show-userdir`)[1], "theme_jl.txt")
		(isfile(f)) && rm(f)
		(_name == "reset") ? theme_modern() : write(f, _name)
		isOn = false		# So we wont reset defaults in showfig()
	end
	ThemeIsOn[1] = isOn
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function parse_theme_names(name::String)
	# Basically only short forms for setting -B option: A2atg, A2afg, A2ag, A2agHnt, A2agV, A2XY..., A0...
	# A2 means annotate two axes (default to WSrt)
	# If the name contains XY plot only WS (no EN). Containing "YY" or "XX" plots only WE or SN, respectively.
	# "afg" and "ag" have the normal meaning of 'a'nnotate, 't'icks & 'g'rid lines. 'f' can be used instead of 't'
	# "H" in name plots only the horizontal grid lines and 'V' only the vertical (requires "afg" or "ag")
	# "nt" or "NT" anywhere after "A2" means no ticks
	# "it" or "IT" means inside ticks
	# "A0" means no axes, but it can have annotations, ticks and gridlines
	if (name[1] == 'A')			# Name should either start with A2 or A0
		t1 = "a"
		if (contains(name, "atg") || contains(name, "afg"))
			t1 = "afg"
			contains(name, "H") && (t1 = "xaf -Byafg")		# Only horizontal grid lines
			contains(name, "V") && (t1 = "xafg -Byaf")		# Only vertical grid lines
		elseif (contains(name, "ag") || contains(name, "g"))
			t1 = "ag"
			contains(name, "H") && (t1 = "xa -Byag")		# Only horizontal grid lines
			contains(name, "V") && (t1 = "xag -Bya")		# Only vertical grid lines
		end
		if contains(name, "Graph")							# Add a vector to the end of each axis
			gmtlib_setparameter(G_API[1], "MAP_FRAME_TYPE", "graph")
			name *= "XY"									# Must be if already there, no problems
		end
		t2 = contains(name, "XY") ? "WS" : (contains(name, "YY")) ? "WE" : (contains(name, "XX")) ? "SN" : "WSrt"
		t1, t2 = " -B" * t1, " -B" * t2

		if (name[2] == '0')
			if (length(name) == 2)  t1, t2 = " ", ""		# Really no axes no annotations/ticks
			else                    gmtlib_setparameter(G_API[1], "MAP_FRAME_PEN", "0.001,white@100") # No axes, but need this sad trick
			end
		end

		def_fig_axes[1] = t1 * t2
		if     (contains(name, "nt") || contains(name, "NT"))  helper_theme_noticks()	# No ticks
		elseif (contains(name, "it") || contains(name, "IT"))  helper_theme_inticks()	# Inside ticks
		end
		gmtlib_setparameter(G_API[1], "MAP_GRID_PEN_PRIMARY", "auto,gray")
		gmtlib_setparameter(G_API[1], "MAP_GRID_PEN_SECONDARY", "auto,gray")
		return true
	end
	return false
end

# ---------------------------------------------------------------------------------------------------
function helper_theme_inticks()
	# Inside ticks. Fixed length because GMT has no way to set it auto
	gmtlib_setparameter(G_API[1], "MAP_TICK_LENGTH_PRIMARY", "-4p")
	gmtlib_setparameter(G_API[1], "MAP_TICK_LENGTH_SECONDARY", "-12p")
end

# ---------------------------------------------------------------------------------------------------
function helper_theme_noticks()
	gmtlib_setparameter(G_API[1], "MAP_TICK_LENGTH_PRIMARY", "0/0")
	gmtlib_setparameter(G_API[1], "MAP_TICK_LENGTH_SECONDARY", "0/0")
end

# ---------------------------------------------------------------------------------------------------
function helper_theme_fonts_colors(font, color, bg_color, dark::Bool)
	fonts  = (font == "")  ? ["Helvetica", "Helvetica", "Helvetica"] : [font, font, font]
	colors = (color == "") ? (dark ? ["gray92", "gray86"] : ["black", "black"]) : [color, color]
	(bg_color == "") && (bg_color = (dark) ? "5/5/35" : "white")
	fonts_colors_settings(fonts, colors, bg_color)
end

# ---------------------------------------------------------------------------------------------------
function fonts_colors_settings(fonts, colors, bg_color)
	# This function serves mainly the dark theme but can be used by any other theme that
	# wants to change font and/or colors.
	gmtlib_setparameter(G_API[1], "FONT_ANNOT_PRIMARY", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "FONT_ANNOT_SECONDARY", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "FONT_HEADING", "auto,$(fonts[2]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "FONT_LABEL", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "FONT_LOGO", "auto,$(fonts[3]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "FONT_TAG", "auto,$(fonts[1]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "FONT_TITLE", "auto,$(fonts[2]),$(colors[1])")
	gmtlib_setparameter(G_API[1], "MAP_DEFAULT_PEN", "0.25p,$(colors[1])")
	gmtlib_setparameter(G_API[1], "MAP_FRAME_PEN", "0.75,$(colors[1])")
	gmtlib_setparameter(G_API[1], "MAP_GRID_PEN_PRIMARY", "auto,$(colors[1])")
	gmtlib_setparameter(G_API[1], "MAP_GRID_PEN_SECONDARY", "auto,$(colors[2])")
	gmtlib_setparameter(G_API[1], "MAP_TICK_PEN_PRIMARY", "auto,$(colors[1])")
	gmtlib_setparameter(G_API[1], "MAP_TICK_PEN_SECONDARY", "auto,$(colors[2])")
	gmtlib_setparameter(G_API[1], "PS_PAGE_COLOR", "$bg_color")
end

# ---------------------------------------------------------------------------------------------------
function theme_modern()
	# Set the MODERN mode settings
	(GMTver < v"6.2.0") && return nothing
	swapmode(G_API[1], classic=false)		# Set GMT->current.setting.run_mode = GMT_MODERN
	reset_defaults(G_API[1])					# Set the modern mode settings
	gmtlib_setparameter(G_API[1], "MAP_FRAME_PEN", "0.75")
	!IamModern[1] && swapmode(G_API[1], classic=true)	# Reset GMT->current.setting.run_mode = GMT_CLASSIC
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function theme_classic()
	(GMTver < v"6.2.0") && return nothing
	swapmode(G_API[1], classic=true)			# Set GMT->current.setting.run_mode = GMT_CLASSIC
	reset_defaults(G_API[1])					# Set the classic mode settings
end

# ---------------------------------------------------------------------------------------------------
function swapmode(API; classic::Bool=true)
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