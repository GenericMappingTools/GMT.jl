"""
    psconvert(cmd0::String="", arg1=nothing; kwargs...)

Place images or EPS files on maps.

Full option list at [`psconvert`]($(GMTdoc)psconvert.html)

Parameters
----------

- **A** | **adjust** | **crop** :: [Type => Str or Number]  

    Adjust the BoundingBox and HiResBoundingBox to the minimum required by the image content.
    ($(GMTdoc)psconvert.html#a)
- **C** | **gs_option** :: [Type => Str or Array os strings]

    Specify a single, or an araay of, custom option that will be passed on to GhostScript as is.
    ($(GMTdoc)psconvert.html#c)
- **D** | **out_dir** | **output_dir** :: [Type => Str]

    Sets an alternative output directory (which must exist) [Default is the same directory
    as the PS files].
    ($(GMTdoc)psconvert.html#d)
- **E** | **dpi** :: [Type => Number]

    Set raster resolution in dpi [default = 720 for PDF, 300 for others].
    ($(GMTdoc)psconvert.html#e)
- **F** | **:out_name** | **output_name** :: [Type => Str]

    Force the output file name.
    ($(GMTdoc)psconvert.html#f)
- **G** | **ghost_path** :: [Type => Bool]

    Full path to your GhostScript executable.
    ($(GMTdoc)psconvert.html#g)
- **I** | **icc_gray** :: [Type => Bool]

    Enforce gray-shades by using ICC profiles.
    ($(GMTdoc)psconvert.html#i)
- **in_memory** :: [Type => Bool]

    Process a in memory PS file. No other input file should be provided.
    Currently works on Windows only.
- **L** | **list_file** :: [Type => Str]

    The listfile is an ASCII file with the names of the PostScript files to be converted.
    ($(GMTdoc)psconvert.html#l)
- **Q** | **anti_aliasing** :: [Type => Str]

    Set the anti-aliasing options for graphics or text. Append the size of the subsample box
    (1, 2, or 4) [4]. This option is set by default.
    ($(GMTdoc)psconvert.html#q)
- **S** | **gs_command** :: [Type => Bool]

    Print to standard error the GhostScript command after it has been executed.
    ($(GMTdoc)psconvert.html#s)
- **T** | **format** :: [Type => Str]

    b|e|E|f|F|j|g|G|m|s|t Sets the output format, where b = BMP, e = EPS, E = EPS with PageSize command,
    f = PDF, F = multi-page PDF, j = JPEG, g = PNG, G = transparent PNG (untouched regions are
    transparent), m = PPM,  and t = TIFF [default is JPEG].
    Alternatively, the format may be set with the *fmt* keyword, e.g. *fmt=:png*.
    ($(GMTdoc)psconvert.html#t)
- **W** | **world_file** :: [Type => Str]

    Write a ESRI type world file suitable to make (e.g) .tif files be recognized as geotiff by
    software that know how to do it. 
    ($(GMTdoc)psconvert.html#w)
- **kml** :: [Type => Str | []]

    Create a minimalist KML file that allows loading the image in GoogleEarth.
    ($(GMTdoc)psconvert.html#w)
- **Z** | **del_input_ps** :: [Type => Bool]

    Remove the input PostScript file(s) after the conversion.
    ($(GMTdoc)psconvert.html#z)
- $(GMT.opt_V)
"""
function psconvert(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("psconvert", cmd0, arg1)

	if (!isempty(cmd0)) && (arg1 === nothing)  arg1 = cmd0  end

	d = KW(kwargs)
	cmd = add_opt("", 'A', d, [:A :adjust :crop])
	if (cmd == " -A")  cmd = cmd * "1p"  end		# If just -A default to -A1p
	cmd = parse_these_opts(cmd, d, [[:D :out_dir :output_dir], [:E :dpi], [:F :out_name :output_name],
	                                [:G :ghost_path], [:I :icc_gray], [:L :list_file], [:P :portrait], [:Q :anti_aliasing], [:S :gs_command], [:Z :del_input_ps]])
	cmd = parse_V_params(cmd, d)

	if ((val = find_in_dict(d, [:fmt])[1]) !== nothing)
		fmt = isa(val, Symbol) ? string(val) : val
		if     (fmt == "pdf")  cmd *= " -Tf"
		elseif (fmt == "eps")  cmd *= " -Te"
		elseif (fmt == "png")  cmd *= " -Tg"
		elseif (fmt == "jpg")  cmd *= " -Tj"
		elseif (fmt == "tif")  cmd *= " -Tt"
		end
	else
		cmd = add_opt(cmd, 'T', d, [:T :format])
	end

	if ((val = find_in_dict(d, [:C :gs_option])[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))
			cmd = string(cmd, " -C", val)
		elseif (isa(val, Array{String})) 
			for k = 1:length(val)
				cmd *= " -C" * val[k]
			end
		end
	end

	cmd = add_opt(cmd, 'W', d, [:W :world_file])
	if (haskey(d, :kml))  cmd *= " -W+k" * d[:kml]  end

	if (haskey(d, :in_memory))
		(arg1 === nothing) ? cmd *= " =" : arg1 = nothing	# in_memory and input file are incompat. File wins
		delete!(d, :in_memory)
	end

	# In case DATA holds a file name, copy it into cmd.
	if (cmd0 != "" || arg1 !== nothing)						# Data was passed as file name
		cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
	end

	if (isempty(cmd))          cmd = "-A1p -Tj -Qg4 -Qt4"  end 	# Means no options were used. Allowed case
	if (!occursin("-Q", cmd))  cmd = cmd * " -Qt4 -Qg4"    end	# We promised to have these as default

	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt("psconvert " * cmd, arg1)
end

# ---------------------------------------------------------------------------------------------------
psconvert(arg1::GMTps; kw...) = psconvert("", arg1; kw...)
