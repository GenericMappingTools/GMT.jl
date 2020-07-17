"""
    movie(main; pre=nothing, post=nothing, kwargs...)

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
- **E** | **titlepage** :: [Type => Str | tuple]

    Give a titlepage script that creates a static title page for the movie [no title]. 
    ($(GMTdoc)movie.html#e)
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
- **K** | **fading** :: [Type => Number | Str | Tuple]	``Arg = [+f[i|o]fade[s]][+gfill][+p] ]``

    Add fading in and out for the main animation sequence [no fading].
    ($(GMTdoc)movie.html#k)
- **L** | **label** :: [Type => Str]

    Automatic labeling of individual frames.
    ($(GMTdoc)movie.html#l)
- **M** | **cover_page** :: [Type => number]	``Arg = frame[,format]``

    Select a single frame for a cover page. This frame will be written to the current directory.
    ($(GMTdoc)movie.html#m)
- **P** | **progress** :: [Type => Str | Tuple]

    Automatic placement of progress indicator(s).
    ($(GMTdoc)movie.html#p)
- **Q** | **debug** :: [Type => Bool | Str]		``Arg = [s]``

    Debugging: Leave all files and directories we create behind for inspection.
    ($(GMTdoc)movie.html#q)
- **Sb** | **background** :: [Type => Str | Function]

    Optional background script or bg PS file [GMT6.1 only]
    ($(GMTdoc)movie.html#s)
- **Sf** | **foreground** :: [Type => Str | Function]

    Optional foreground script or fg PS file [GMT6.1 only]
    ($(GMTdoc)movie.html#s)
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
function movie(main; pre=nothing, post=nothing, kwargs...)

	d = KW(kwargs)

	if (isa(main, Function) || isa(main, String))
		if ((mainName = jl_sc_2_shell_sc(main, "main_script")) === nothing)  error("Main script has nothing useful")  end
	else
		error("A main script is mandatory")
	end

	cmd, = parse_common_opts(d, "", [:V_params :x])
	cmd = parse_these_opts(cmd, d, [[:C :canvas], [:N :name]])
	cmd = parse_these_opts(cmd, d, [[:D :frame_rate], [:H :scale], [:I :includefile], [:L :label], [:M :cover_page],
	                                [:Q :debug], [:W :work_dir], [:Z :clean]])
	cmd = add_opt(cmd, "A", d, [:A :gif], (loop="+l", stride="+s"))
	cmd = add_opt(cmd, "E", d, [:E :titlepage], (title=("",arg2str,1), duration="+d", fade="+f", fill=("+g", add_opt_fill)))
	cmd = add_opt(cmd, "F", d, [:F :format], (format=("",arg2str,1), transparent="_+t", options="+o"))
	cmd = add_opt(cmd, "G", d, [:G :fill], (fill=("",add_opt_fill,1), pen=("+p", add_opt_pen)))
	cmd = add_opt(cmd, "K", d, [:K :fading], (fade="+f", fill=("+g", add_opt_fill), preserve="_+p"))
	cmd = add_opt(cmd, "P", d, [:P :progress],
				  (indicator=("1", nothing, 1), annot="+a", font=("+f", font), justify="+j", offset=("+o", arg2str), width="+w", fill=("+g", add_opt_fill), Fill=("+G", add_opt_fill), pen=("+p", add_opt_pen), Pen=("+P", add_opt_pen)))
	cmd = add_opt(cmd, "T", d, [:T :frames],
				  (range=("", arg2str, 1), n_frames="_+n", nframes="_+n", first="+s", tag_width="+p", split_words="+w"))

	if ((val = find_in_dict(d, [:Sb :background])[1]) !== nothing)
		cmd = helper_fgbg(cmd, val, "bg_script", " -Sb")
	end
	if ((val = find_in_dict(d, [:Sf :foreground])[1]) !== nothing)
		cmd = helper_fgbg(cmd, val, "fg_script", " -Sf")
	end

	if (pre !== nothing && isa(pre, Function) || isa(pre, String))
		if ((preName = jl_sc_2_shell_sc(pre,  "pre_script"))  !== nothing)  cmd *= " -Sb" * preName  end
	end
	if (post !== nothing && isa(post, Function) || isa(post, String))
		if ((posName = jl_sc_2_shell_sc(post,  "pre_script"))  !== nothing)  cmd *= " -Sf" * posName  end
	end

	global cmds_history
	IamModern[1] = false; FirstModern[1] = false; convert_syntax[1] = false; cmds_history = [""]

	cmd = "movie " * mainName * cmd				# In any case we need this
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt(cmd)
end

# --------------------------------------------------------------------------------------------------
function helper_fgbg(cmd::String, val, sc_name::String, opt::String)
	# VAL is the contents of either -Sf or -Sb options
	# OPT = " -Sb" or " -Sf"
	if (isa(val, Function) || (isa(val, String) && endswith(val, ".jl")))
		if ((bg_sc = jl_sc_2_shell_sc(val, sc_name)) === nothing)  error("$sc_name script has nothing useful")  end
		cmd *= opt * bg_sc
	elseif (isa(val, String) && val != "")
		cmd *= opt * val
	end
	return cmd
end

# --------------------------------------------------------------------------------------------------
function jl_sc_2_shell_sc(name, name2::String)
	global cmds_history
	IamModern[1] = true; FirstModern[1] = true; convert_syntax[1] = true; cmds_history = [""]
	if (isa(name, String))
		include(name)	# This include plus the convert_syntax = true will put all cmds in 'name' into cmds_history
	else
		name()			# Run the function, which must be defined ...
	end
	fname = write_script(name2)
end

# -----------------------------------------------------------------------------------------------
function write_script(fname)
	if (cmds_history[1] != "")
		if (Sys.iswindows())  fname *= ".bat";	b = "%";	e = "%"
		else                  fname *= ".sh";	b = "\${";	e = "}"
		end
		par_list = ["MOVIE_DPU", "MOVIE_HEIGHT", "MOVIE_RATE", "MOVIE_NFRAMES", "MOVIE_FRAME", "MOVIE_TAG", "MOVIE_NAME", "MOVIE_WIDTH", "MOVIE_COL0", "MOVIE_COL1", "MOVIE_COL2", "MOVIE_COL4", "MOVIE_TEXT", "MOVIE_WORD0", "MOVIE_WORD1", "MOVIE_WORD2", "MOVIE_WORD3"]
		got_begin = false
		for cmd in cmds_history			# Check if we have a gmtbegin.
			if (occursin("gmtbegin", cmd))  got_begin = true;  break  end
		end
		fid = open(fname, "w")
		if (!got_begin) println(fid, "gmt begin")  end
		for cmd in cmds_history
			for par in par_list
				if (occursin(par, cmd))  cmd = replace(cmd, par => b * par * e)  end
			end
			println(fid, "\t gmt ",cmd)
		end
		if (!got_begin) println(fid, "gmt end")  end
		close(fid)
		return fname
	end
end