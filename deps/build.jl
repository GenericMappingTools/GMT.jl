function get_de_libnames()
	# Use a function for this because I F. CAN'T MAKE ANY SENSE ABOUT GLOBAL-LOCAL SCOPES INSIDE TRY-CATCH
	errou = false
	GMT_bindir, libgmt, libgdal, libproj, ver, userdir, devdate = "", "", "", "", "", "", "0001-01-01"

	try						# First try to find an existing GMT installation (RECOMENDED WAY)
		(Sys.iswindows() && get(ENV, "FORCE_INSTALL_GMT", "") != "") && error("Forcing an automatic GMT install")
		out = readlines(`gmt --version`)[1]		# If it errors here, jump to the catch branch
		ver = ((ind = findfirst('_', out)) === nothing) ? VersionNumber(out) : VersionNumber(out[1:ind-1])
		(ver < v"6.1") && error("Need at least GMT6.1. The one you have ($ver) is not supported.")	# GOTO DOWNLOAD

		libgmt = haskey(ENV, "GMT_LIBRARY") ? ENV["GMT_LIBRARY"] : string(chop(read(`gmt --show-library`, String)))

		@static Sys.iswindows() ? libgdal = "gdal_w64.dll" : (
			Sys.isapple() ? (libgdal = string(split(readlines(pipeline(`otool -L $(libgmt)`, `grep libgdal`))[1])[1])[8:end]) : (
					Sys.isunix() ? (libgdal = string(split(readlines(pipeline(`ldd $(libgmt)`, `grep libgdal`))[1])[3])) :
					error("Don't know how to use GDAL this package in this OS.")
				)
			)
		@static Sys.iswindows() ? libproj = "proj_w64.dll" : (
			Sys.isapple() ? (libproj = string(split(readlines(pipeline(`otool -L $(libgdal)`, `grep libproj`))[1])[1])[8:end]) : (
					Sys.isunix() ? (libproj = string(split(readlines(pipeline(`ldd $(libgdal)`, `grep libproj`))[1])[3])) :
					error("Don't know how to use PROJ4 in this OS.")
				)
			)

		GMT_bindir = string(chop(read(`gmt --show-bindir`, String)))

	catch err1;		println(err1)		# If not, install GMT if Windows. Otherwise just see if we have one at sight
		try
			if Sys.iswindows()
				println("\nDowloading and installing from the Windows installer\n")
				fn = download("http://fct-gmt.ualg.pt/gmt/data/wininstallers/gmt-win64.exe", "GMTinstaller.exe")
				run(`cmd /k GMTinstaller.exe /S`)
				rm(fn, force=true)
				libgmt  = "gmt_w64.dll"
				libgdal = "gdal_w64.dll"
				libproj = "proj_w64.dll"
				GMT_bindir = "C:\\programs\\gmt6\\bin"
			else
				println("\n\nNo GMT system wide installation found\n\n")
				return true, ver, libgmt, libgdal, libproj, GMT_bindir, userdir, devdate
			end

			try
				if Sys.iswindows()
					out = readlines(`gmt --version`)[1]
					ver = ((ind = findfirst('_', out)) === nothing) ? VersionNumber(out) : VersionNumber(out[1:ind-1])
				end
			catch
				return false, v"6.5", libgmt, libgdal, libproj, GMT_bindir, "c:/j/.gmt", devdate
			end

		catch err2;		println(err2)
			return true, ver, libgmt, libgdal, libproj, GMT_bindir, userdir, devdate
		end
	end
	userdir    = readlines(`gmt --show-userdir`)[1]
	out = readlines(`gmt --version`)[1]
	devdate = ((ind = findlast('_', out)) !== nothing) && out[ind+1:end]
	Sys.iswindows() && (GMT_bindir = readlines(`gmt --show-bindir`)[1])		# Only on Win is that all dlls are in same bin dir
	return errou, ver, libgmt, libgdal, libproj, GMT_bindir, userdir, devdate
end

force_winjll = (get(ENV, "FORCE_WINJLL", "") != "")		# Use this env var to also force use of the JLL on Windows
if (force_winjll || (!Sys.iswindows() && get(ENV, "SYSTEMWIDE_GMT", "") == ""))		# That is: the JLL case
	# Just to have something. They won't be used in main. There, wee only need that a "deps.jl" exists
	libgmt, libgdal, libproj, ver, userdir, devdate = "nikles", "nikles", "nikles", "0.0", "nikles", "0001-01-01"
	GMT_bindir = ""
	is_jll = 1
	errou = false
else
	errou, ver, libgmt, libgdal, libproj, GMT_bindir, userdir, devdate = get_de_libnames()
	is_jll = 0
end


if (!errou)		# Save shared names in file so that GMT.jl can read them at pre-compile time
	depfile = joinpath(dirname(@__FILE__), "deps.jl")
	open(depfile, "w") do f
		println(f, "_libgmt  = \"", escape_string(joinpath(GMT_bindir, libgmt)), '"')
		println(f, "_libgdal = \"", escape_string(joinpath(GMT_bindir, libgdal)), '"')
		println(f, "_libproj = \"", escape_string(joinpath(GMT_bindir, libproj)), '"')
		println(f, "_GMTver = v\"" * string(ver) * "\"")
		println(f, "devdate = ", '"', devdate, '"')
		println(f, "userdir = \"", escape_string(userdir), '"')
		println(f, "have_jll = ", is_jll)
	end
end
