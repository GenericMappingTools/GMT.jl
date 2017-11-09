using BinDeps

@BinDeps.setup

libgmt = library_dependency("libgmt")

# package managers
provides(Pacman, "gmt", libgmt)

if is_apple()
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "gmt", libgmt)
end

@BinDeps.install Dict(:libgmt => :libgmt)
