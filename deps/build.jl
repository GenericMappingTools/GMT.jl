using BinDeps

@BinDeps.setup

libgmt = library_dependency("libgmt")

# package managers
provides(AptGet, "gmt", libgmt)
provides(Pacman, "gmt", libgmt)

@BinDeps.install Dict(:libgmt => :libgmt)
