function get_de_libnames()
	# Use a function for this because I F. CAN'T MAKE ANY SENSE ABOUT GLOBAL-LOCAL SCOPES INSIDE TRY-CATCH
	errou = false
	GMT_bindir, libgmt, libgdal, libproj, ver, userdir = "", "", "", "", "", ""

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

	catch err1;		println(err1)		# If not, install GMT if Windows. Otherwise just see if we have one at sight
		try
			if Sys.iswindows()
				fn = download("http://fct-gmt.ualg.pt/gmt/data/wininstallers/gmt-win64.exe", "GMTinstaller.exe")
				run(`cmd /k GMTinstaller.exe /S`)
				rm(fn, force=true)
				libgmt  = "gmt_w64.dll"
				libgdal = "gdal_w64.dll"
				libproj = "proj_w64.dll"
			else
				println("No GMT system wide installation found")
				println(err3)
				errou = true
				return errou, ver, libgmt, libgdal, libproj, GMT_bindir, userdir
			end

			out = readlines(`gmt --version`)[1]
			ver = ((ind = findfirst('_', out)) === nothing) ? VersionNumber(out) : VersionNumber(out[1:ind-1])

		catch err2;		println(err2)
			errou = true
		end
		userdir    = readlines(`gmt --show-userdir`)[1]
		GMT_bindir = readlines(`gmt --show-bindir`)[1]
	end
	return errou, ver, libgmt, libgdal, libproj, GMT_bindir, userdir
end


if (!Sys.iswindows() && get(ENV, "SYSTEMWIDE_GMT", "") == "")
	ver = VersionNumber(split(readlines(`$(GMT_jll.gmt()) "--version"`)[1],'_')[1])
	userdir = [readlines(`$(GMT_jll.gmt()) "--show-userdir"`)[1]]
	GMT_bindir = ""
	errou = false
else
	errou, ver, libgmt, libgdal, libproj, GMT_bindir, userdir = get_de_libnames()
end


if (!errou)		# Save shared names in file so that GMT.jl can read them at pre-compile time
	depfile = joinpath(dirname(@__FILE__), "deps.jl")
	open(depfile, "w") do f
		println(f, "_libgmt  = \"", escape_string(joinpath(GMT_bindir, libgmt)), '"')
		println(f, "_libgdal = \"", escape_string(joinpath(GMT_bindir, libgdal)), '"')
		println(f, "_libproj = \"", escape_string(joinpath(GMT_bindir, libproj)), '"')
		println(f, "_GMTver = v\"" * string(ver) * "\"")
		println(f, "userdir = \"", escape_string(userdir), '"')
	end
end
