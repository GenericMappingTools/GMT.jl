function run_tests(what::ASCIIString)
	if (what == "all_examples")
		for (k = 1:45)
			(k < 10) ? ex = @sprintf("ex0%d", k) : ex = @sprintf("ex%d", k)
			gmtest(ex)
		end
	else
	end
end

# ----------------------------------------------------------------------------------------
function gmtest(test)
# Run an example or test and print its tested status, i.e. if it PASS or FAIL
	include("C:/progs_cygw/GMTdev/GMT.jl/src/gallery.jl")
	GRAPHICSMAGICK = "C:/programs/GraphicsMagick/gm.exe"

	ps, t_path = gallery(test)
	if (isempty(ps))
		println("    Test -> " * test * " <- does not exist or some other error occurred")
		return
	end
	pato, fname = fileparts(ps)
	png_name = pato * fname * ".png"
	ps_orig  = t_path * fname * ".ps"

	# Compare the ps file with its original.
	cm = `$GRAPHICSMAGICK compare -density 200 -maximum-error 0.001 -highlight-color magenta -highlight-style
		 assign -metric rmse -file $png_name $ps_orig $ps`

	run(pipeline(ignorestatus(cm), stdout=DevNull, stderr="errs.txt"))
	t = readall("errs.txt");
	rm("errs.txt")
	if (isempty(t))
		println("    Test " * test * " PASS")
		rm(png_name)
	else
		ind = searchindex(t, "image")
		println("    Test " * test * " FAIL with: " * t[ind:end-1])
	end
end


function fileparts(file)
	path = dirname(file)
	f = basename(file)
	fname, ext = splitext(f)
	return path, fname, ext
end