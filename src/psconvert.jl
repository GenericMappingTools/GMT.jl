"""
    psconvert(cmd0::String="", arg1=[]; kwargs...)

Place images or EPS files on maps.

Full option list at [`psconvert`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html)

Parameters
----------

- **A** : **adjust** : -- Str or Number --  
    Adjust the BoundingBox and HiResBoundingBox to the minimum required by the image content.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#a)
- **C** : **gs_option** : -- Str or Array os strings --
    Specify a single, or an araay of, custom option that will be passed on to GhostScript as is.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#c)
- **D** : **out_dir*** : *output_dir** : -- Str --
    Sets an alternative output directory (which must exist) [Default is the same directory
    as the PS files].
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#d)
- **E** : **dpi** : -- Number --
    Set raster resolution in dpi [default = 720 for PDF, 300 for others].
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#e)
- **F** : **:out_name** : **output_name** : -- Str --
    Force the output file name.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#f)
- **G** : **ghost_path** : -- Bool or [] --
    Full path to your GhostScript executable.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#g)
- **I** : -- Bool or [] --
    Enforce gray-shades by using ICC profiles.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#i)
- **in_memory** : -- Bool or [] --
	Process a in memory PS file. No other input file should be provided.
	Currently works on Windows only.
- **L** : **list_file** : -- Str --
    The listfile is an ASCII file with the names of the PostScript files to be converted.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#l)
- **Q** : **anti_aliasing** : -- Str --
    Set the anti-aliasing options for graphics or text. Append the size of the subsample box (1, 2, or 4) [4].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#q)
- **S** : **gs_command** : -- Bool or [] --
    Print to standard error the GhostScript command after it has been executed.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#s)
- **T** : **format** : -- Str --
    b|e|E|f|F|j|g|G|m|s|t Sets the output format, where b = BMP, e = EPS, E = EPS with PageSize command,
    f = PDF, F = multi-page PDF, j = JPEG, g = PNG, G = transparent PNG (untouched regions are
    transparent), m = PPM,  and t = TIFF [default is JPEG].
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#t)
- **W** : **world_file** : -- Str --
    Write a ESRI type world file suitable to make (e.g) .tif files be recognized as geotiff by
    software that know how to do it. 
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#w)
- **kml** -- Str or [] --
    Create a minimalist KML file that allows loading the image in GoogleEarth.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#w)
- **Z** : **del_input_ps** : -- Bool or [] --
    Remove the input PostScript file(s) after the conversion.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/psconvert.html#z)
- $(GMT.opt_V)
"""
# ---------------------------------------------------------------------------------------------------
function psconvert(cmd0::String="", arg1=[]; data=[], fmt::String="", kwargs...)

	length(kwargs) == 0 && isempty_(data) && return monolitic("psconvert", cmd0, arg1)	# Speedy mode

	if (!isempty_(data) && !isa(data, String))
		error("When using 'data', it MUST contain a String data type (the file name")
	end

	d = KW(kwargs)
	cmd = parse_V("", d)

	cmd = add_opt(cmd, 'A', d, [:A :adjust])
	cmd = add_opt(cmd, 'D', d, [:D :out_dir :output_dir])
	cmd = add_opt(cmd, 'E', d, [:E :dpi])
	cmd = add_opt(cmd, 'F', d, [:F :out_name :output_name])
	cmd = add_opt(cmd, 'G', d, [:G :ghost_path])
	cmd = add_opt(cmd, 'I', d, [:I])
	cmd = add_opt(cmd, 'L', d, [:L :list_file])
	cmd = add_opt(cmd, 'Q', d, [:Q :anti_aliasing])
	cmd = add_opt(cmd, 'S', d, [:S :gs_command])
	cmd = add_opt(cmd, 'T', d, [:T :format])
	cmd = add_opt(cmd, 'Z', d, [:Z :del_input_ps])

	for sym in [:C :gs_option]
		if (haskey(d, sym))
			if (isa(d[sym], String))
				cmd = cmd * " -C" * d[sym]
			elseif (isa(d[sym], Array{Any})) 
				for k = 1:length(d[sym])
					cmd = cmd * " -C" * d[sym][k]
				end
			end
			break
		end
	end

	cmd = add_opt(cmd, 'W', d, [:W :world_file])
	if (haskey(d, :kml))
		cmd = cmd * " -W+k" * d[:kml]
	end

	got_output = false
	if (haskey(d, :in_memory))
		cmd = cmd * " ="
		if (!isempty_(arg1))
			warn("The IN_MEMORY option is imcompatible with passing an input file name.
			      Dropping this one.")
			arg1 = []
		end
		got_output = true
	end

	# In case DATA holds a file name, copy it into cmd.
	cmd, arg1, = read_data(data, cmd, arg1)

	(haskey(d, :Vd)) && println(@sprintf("\tpsconvert %s", cmd))

	if (got_output)
		if (!isempty_(arg1))  return gmt("psconvert " * cmd, arg1)
		else                  return gmt("psconvert " * cmd)
		end
	else
		if (!isempty_(arg1))  gmt("psconvert " * cmd, arg1)
		else                  gmt("psconvert " * cmd)
		end
	end
end