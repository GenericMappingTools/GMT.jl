import Conda

const depfile = joinpath(dirname(@__FILE__), "deps.jl")

Conda.add_channel("gmt")
Conda.add("gmt")

GMT_Conda_home = Conda.LIBDIR

@info "Using GMT from $GMT_Conda_home"
open(depfile, "w") do f
	println(f, "const GMT_Conda_home = \"", escape_string(GMT_Conda_home), '"')
	println(f, "const libgmt = \"", escape_string(libgmt), '"')
end
