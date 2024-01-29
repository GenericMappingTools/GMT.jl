"""
    psconvert(cmd0::String="", arg1=nothing; kwargs...)

Place images or EPS files on maps.

See full GMT (not the `GMT.jl` one) docs at [`psconvert`]($(GMTdoc)psconvert.html)

Parameters
----------

- **A** | **adjust** | **crop** :: [Type => Str or Number]  

    Adjust the BoundingBox and HiResBoundingBox to the minimum required by the image content.
- **C** | **gs_option** :: [Type => Str or Array os strings]

    Specify a single, or an araay of, custom option that will be passed on to GhostScript as is.
- **D** | **out_dir** | **output_dir** :: [Type => Str]

    Sets an alternative output directory (which must exist) [Default is the same directory
    as the PS files].
- **E** | **dpi** :: [Type => Number]

    Set raster resolution in dpi [default = 720 for PDF, 300 for others].
- **F** | **:out_name** | **output_name** :: [Type => Str]

    Force the output file name.
- **G** | **ghost_path** :: [Type => Bool]

    Full path to your GhostScript executable.
- **I** | **resize** :: [Type => Bool]

    Adjust the BoundingBox and HiResBoundingBox by scaling and/or adding margins.
- **in_memory** :: [Type => Bool]

    Process a in memory PS file. No other input file should be provided.
    Currently works on Windows only.
- **L** | **list_file** :: [Type => Str]

    The listfile is an ASCII file with the names of the PostScript files to be converted.
- **M** | **embed**

    Sandwich the current psfile between an optional background (-Mb) and optional foreground (-Mf) Postscript plots.
- **N** | **bgcolor**

    Set optional BoundingBox background fill color, fading, or draw the outline of the BoundingBox.
- **Q** | **anti_aliasing** :: [Type => Str]

    Set the anti-aliasing options for graphics or text. Append the size of the subsample box
    (1, 2, or 4) [4]. This option is set by default.
- **S** | **gs_command** :: [Type => Bool]

    Print to standard error the GhostScript command after it has been executed.
- **T** | **format** :: [Type => Str]

    b|e|E|f|F|j|g|G|m|s|t Sets the output format, where b = BMP, e = EPS, E = EPS with PageSize command,
    f = PDF, F = multi-page PDF, j = JPEG, g = PNG, G = transparent PNG (untouched regions are
    transparent), m = PPM,  and t = TIFF [default is JPEG].
    Alternatively, the format may be set with the *fmt* keyword, e.g. *fmt=:png*.
- **W** | **world_file** :: [Type => Str]

    Write a ESRI type world file suitable to make (e.g) .tif files be recognized as geotiff by
    software that know how to do it. 
- **kml** :: [Type => Str | []]

    Create a minimalist KML file that allows loading the image in GoogleEarth.
- **Z** | **del_input_ps** :: [Type => Bool]

    Remove the input PostScript file(s) after the conversion.
- $(GMT.opt_V)

To see the full documentation type: ``@? psconvert``
"""
function psconvert(cmd0::String="", arg1=nothing; kwargs...)

	if (!isempty(cmd0)) && (arg1 === nothing)  arg1 = cmd0  end

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd = add_opt(d, "", "A", [:A :adjust :crop])
	(cmd == " -A") && (cmd = cmd * "1p")			# If just -A default to -A1p
	cmd = parse_these_opts(cmd, d, [[:D :out_dir :output_dir], [:E :dpi], [:F :out_name :output_name],
	                                [:G :ghost_path], [:I :resize], [:L :list_file], [:M :embed], [:N :bgcolor], [:P :portrait], [:Q :anti_aliasing], [:S :gs_command], [:Z :del_input_ps]])
	cmd = parse_V_params(d, cmd)

	if ((val = find_in_dict(d, [:fmt])[1]) !== nothing)
		fmt = isa(val, Symbol) ? string(val) : val
		if     (fmt == "pdf")  cmd *= " -Tf"
		elseif (fmt == "eps")  cmd *= " -Te"
		elseif (fmt == "png")  cmd *= " -Tg"
		elseif (fmt == "jpg")  cmd *= " -Tj"
		elseif (fmt == "tif")  cmd *= " -Tt"
		end
	else
		cmd = add_opt(d, cmd, "T", [:T :format])
	end

	if ((val = find_in_dict(d, [:C :gs_option])[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))
			cmd = string(cmd, " -C", val)
		elseif (isa(val, Array{String})) 
			for k = 1:numel(val)
				cmd *= " -C" * val[k]
			end
		end
	end

	cmd = add_opt(d, cmd, "W", [:W :world_file])
	(haskey(d, :kml)) && (cmd *= " -W+k" * d[:kml])

	if (haskey(d, :in_memory))
		(arg1 === nothing) ? cmd *= " =" : arg1 = nothing	# in_memory and input file are incompat. File wins
		delete!(d, :in_memory)
	end

	# In case DATA holds a file name, copy it into cmd.
	if (cmd0 != "" || arg1 !== nothing)						# Data was passed as file name
		cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
	end

	(isempty(cmd)) && (cmd = "-A1p -Tj -Qg4 -Qt4")   	# Means no options were used. Allowed case
	(!occursin("-Q", cmd)) && (cmd *= " -Qt4 -Qg4")		# We promised to have these as default

	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt("psconvert " * cmd, arg1)
end

# ---------------------------------------------------------------------------------------------------
psconvert(arg1::GMTps; kw...) = psconvert("", arg1; kw...)
