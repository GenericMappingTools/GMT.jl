"""
    movie(main::String; pre="", post="", kwargs...)

Create animation sequences and movies.

Full option list at [`movie`]($(GMTdoc)movie.html)


Parameters
----------

- **main** :: [Type => Str]

    Name of a stand-alone GMT.jl script that makes the frame-dependent plot.``
- **C** | **canvas** :: [Type => Str]

    Specify the canvas size used when composing the movie frames.
    ($(GMTdoc)movie.html#c)
- **N** | **name** :: [Type => Str]

    Determines the name of a sub-directory with frame images as well as the final movie file.
    ($(GMTdoc)movie.html#n)
- **T** | **frames** :: [Type => Int | Str]

    Either specify how many image frames to make or supply a file with a set of parameters, one record per frame (i.e., row). 
    ($(GMTdoc)movie.html#t)
- **pre** :: [Type => Str]

	The optional *backgroundscript* file (a GMT.jl script) can be used one or two purposes: (1) It may create files
	(such as timefile) that will be needed by mainscript to make the movie, and (2) It may make a static background
	plot that should form the background for all frames.
    ($(GMTdoc)movie.html#s)
- **post** :: [Type => Str]

    The optional *foregroundscript* file (a GMT.jl script) can be used to make a static foreground plot that should be overlain on all frames. 
    ($(GMTdoc)movie.html#s)
- **A** | **gif** :: [Type => Str]		``Args = [+l[n]][+sstride]``

    Build an animated GIF file. You may specify if the movie should play more than once and if so append how many times to repeat.
    ($(GMTdoc)movie.html#a)
- **D** | **frame_rate** :: [Type => Int]

    Set the display frame rate in frames per seconds for the final animation [24].
    ($(GMTdoc)movie.html#d)
- **F** | **format** :: [Type => Str]	``Arg = format[+ooptions]``

    Set the format of the final video product. Choose either mp4 (MPEG-4 movie) or webm (WebM movie).
    ($(GMTdoc)movie.html#f)
- **G** | **fill** :: [Type => Str | Int | Touple]

    Set the canvas color or fill before plotting commences [none].
    ($(GMTdoc)movie.html#g)
- **H** | **scale** :: [Type => Number]

    Temporarily increases the effective dots-per-unit by factor, rasterizes the frame, then downsamples the image by the same factor at the end.
    ($(GMTdoc)movie.html#h)
- **I** | **includefile** :: [Type => Str]

    Insert the contents of includefile into the movie_init script that is accessed by all movie scripts.
    ($(GMTdoc)movie.html#i)
- **L** | **label** :: [Type => Str]

    Automatic labeling of individual frames.
    ($(GMTdoc)movie.html#l)
- **M** | **cover_page** :: [Type => number]	``Arg = frame[,format]``

    Select a single frame for a cover page. This frame will be written to the current directory.
    ($(GMTdoc)movie.html#m)
- **Q** | **debug** :: [Type => Bool | Str]		``Arg = [s]``

    Debugging: Leave all files and directories we create behind for inspection.
    ($(GMTdoc)movie.html#q)
- **W** | **work_dir** :: [Type => Str]

	By default, all temporary files and frame PNG file are built in the subdirectory prefix set via **name**.
	You can override that by giving another workdir as a relative or full directory path.
    ($(GMTdoc)movie.html#w)
- **Z** | **clean** :: [Type => Bool]

    Erase the entire **name** directory after assembling the final movie [Default leaves directory with all images.
    ($(GMTdoc)movie.html#z)
- $(GMT.opt_V)
- $(GMT.opt_x)
"""
function movie(cmd0::String=""; pre="", post="", kwargs...)

	d = KW(kwargs)

	if (cmd0 == "")  error("A main script is mandatory")  end
	if ((mainName = jl_sc_2_shell_sc(cmd0, "main_script")) === nothing)  error("Main script has nothing useful")  end

	cmd = parse_common_opts(d, "", [:V_params :x])
	cmd = parse_these_opts(cmd, d, [[:C :canvas], [:N :name], [:T :frames]])
	cmd = parse_these_opts(cmd, d, [[:A :gif], [:D :frame_rate], [:F :format], [:G :fill],
				[:H :scale], [:I :includefile], [:L :label], [:M :cover_page], [:Q :debug], [:W :work_dir], [:Z :clean]])

	if (pre  != "" && ((preName = jl_sc_2_shell_sc(pre,  "pre_script"))  !== nothing))  cmd *= " -Sb" * preName  end
	if (post != "" && ((posName = jl_sc_2_shell_sc(post, "post_script")) !== nothing))  cmd *= " -Sf" * posName  end

	global cmds_history
	IamModern[1] = false; FirstModern[1] = false; convert_syntax[1] = false; cmds_history = [""]

	cmd = "movie " * mainName * cmd				# In any case we need this
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt(cmd)
end

# --------------------------------------------------------------------------------------------------
function jl_sc_2_shell_sc(name::String, name2::String)
	global cmds_history
	IamModern[1] = true; FirstModern[1] = true; convert_syntax[1] = true; cmds_history = [""]
	include(name)	# This include plus the convert_syntax = true will put all cmds in 'name' into cmds_history
	fname = write_script(name2)
end

# -----------------------------------------------------------------------------------------------
function write_script(fname)
	if (cmds_history[1] != "")
		if (Sys.iswindows())  fname *= ".bat";	b = "%";	e = "%"
		else                  fname *= ".sh";	b = "\\\${";	e = "}"
		end
		par_list = ["MOVIE_DPU", "MOVIE_HEIGHT", "MOVIE_RATE", "MOVIE_NFRAMES", "MOVIE_FRAME", "MOVIE_TAG", "MOVIE_NAME", "MOVIE_WIDTH", "MOVIE_COL0", "MOVIE_COL1", "MOVIE_COL2", "MOVIE_COL4", "MOVIE_TEXT", "MOVIE_WORD0", "MOVIE_WORD1", "MOVIE_WORD2", "MOVIE_WORD3"]
		fid = open(fname, "w")
		println(fid, "gmt begin")
		for cmd in cmds_history
			for par in par_list
				if (occursin(par, cmd))  cmd = replace(cmd, par => b * par * e)  end
			end
			println(fid, "\t gmt ",cmd)
		end
		println(fid, "gmt end")
		close(fid)
		return fname
	end
end