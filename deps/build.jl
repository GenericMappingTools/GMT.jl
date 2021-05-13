import Conda

depfile = joinpath(dirname(@__FILE__), "deps.jl")

if Sys.iswindows()
	if !isfile("C:\\programs\\gmt6\\bin\\gmt.exe")		# If we have none, download and install from installer
		fn = download("http://fct-gmt.ualg.pt/tmp/gmt-6.2.0_RC1-win64.exe", "GMTinstaller.exe")
		run(`cmd /k GMTinstaller.exe /S`)
		rm(fn, force=true)
	end
	GMT_home = "C:\\programs\\gmt6\\bin"
else
	Conda.add_channel("conda-forge")
	Conda.add("gmt")
	#GMT_home = Conda.LIBDIR
	GMT_home = joinpath(Conda.ROOTENV, "bin")
end

libgmt = string(chop(read(`$(joinpath("$(GMT_home)", "gmt")) --show-library`, String)))

@static Sys.iswindows() ? libgdal = "gdal_w64.dll" : (
		Sys.isapple() ? (libgdal = string(split(readlines(pipeline(`otool -L $(libgmt)`, `grep libgdal`))[1])[1])) : (
			Sys.isunix() ? (libgdal = string(split(readlines(pipeline(`ldd $(libgmt)`, `grep libgdal`))[1])[3])) :
			error("Don't know how to install this package in this OS.")
		)
	)

@static Sys.iswindows() ? libproj = "proj_w64.dll" : (
		Sys.isapple() ? (libproj = string(split(readlines(pipeline(`otool -L $(libgdal)`, `grep libproj`))[1])[1])) : (
			Sys.isunix() ? (libproj = string(split(readlines(pipeline(`ldd $(libgdal)`, `grep libproj`))[1])[3])) :
			error("Don't know how to use PROJ4 in this OS.")
		)
	)

# Save shared names in file so that GMT.jl can read them at pre-compile time
open(depfile, "w") do f
	println(f, "GMT_home = \"", escape_string(GMT_home), '"')
	println(f, "_libgmt  = \"", escape_string(libgmt), '"')
	println(f, "_libgdal = \"", escape_string(joinpath(GMT_home, libgdal)), '"')
	println(f, "_libproj = \"", escape_string(joinpath(GMT_home, libproj)), '"')
end
