"""
    iGMTinstall(; update::Bool=false, reinstall::Bool=false, remove::Bool=false)

Install the InteractiveGMT package by `dev`-ing it straight from its GitHub repository. This is the
equivalent of running `] dev https://github.com/GenericMappingTools/InteractiveGMT` at the Pkg REPL.
Once installed, the package is loaded into the current session (equivalent to `using InteractiveGMT`).

Binaries are published for Windows (x86_64), Linux (x86_64) and macOS on BOTH architectures --
Apple Silicon (arm64) and Intel (x86_64). The right one is picked from `Sys.ARCH` by the package's
own `deps/build.jl`, which downloads it from the InteractiveGMT GitHub releases (the macOS archives
are produced by its CI). Nothing has to be said about the machine.

If `update=true`, don't reinstall/rebuild -- just run `Pkg.build("InteractiveGMT")`, which re-runs
InteractiveGMT's own `deps/build.jl` (fetches the latest viewer library -- `gmtvtk.dll`,
`libgmtvtk.dylib` or `libgmtvtk.so` -- from its rolling "dll-latest" GitHub release, and on Windows
displaces a locked DLL safely). `Pkg.build` runs in a separate
Julia process, so this works standalone even when the InteractiveGMT GUI isn't running yet.

If `reinstall=true`, wipe the installation first and put it back from scratch: the package is
removed from the environment, its `dev` sources and the downloaded VTK+Qt runtime are deleted, then
it is `dev`-ed again and built. Use it when an installation is broken beyond what `update=true` can
repair.

If `remove=true`, uninstall and stop: the package is dropped from the environment and BOTH its
`dev` sources and the VTK+Qt binary runtime (`~/.julia/gmtvtk_runtime`, a few hundred MB) are
deleted, along with the Desktop shortcut.

A WORKING REPOSITORY IS NEVER DELETED. If the `dev` checkout has uncommitted changes, untracked
files or commits its upstream does not have -- or if that cannot be determined at all -- the sources
are kept and reported, and only the binary runtime is removed. There is no flag to override this: a
developer's tree is not the uninstaller's to throw away. A pristine `Pkg.develop` clone is clean and
in sync, so a genuine installation is still removed in full.

Files still in use (a `gmtvtk.dll` mapped by a running iGMT window) cannot be unlinked; those are
reported and left for you to delete.
"""
function iGMTinstall(up::Bool=false; update::Bool=false, reinstall::Bool=false, remove::Bool=false)
	# The platforms whose binaries are published. This mirrors the SAME test at the bottom of
	# InteractiveGMT's own deps/build.jl -- the build script is what actually fetches them, and which
	# architecture's archive it takes is its business (Sys.ARCH -> "arm64"/"x86_64" for macOS, where
	# both are real: Julia runs native on Apple Silicon and on Intel, and Qt/VTK are not universal
	# binaries). Refusing here only avoids a `dev` clone that could never be built.
	_ok = Sys.iswindows() || (Sys.islinux() && Sys.ARCH === :x86_64) ||
	      (Sys.isapple() && Sys.ARCH in (:aarch64, :x86_64))
	!_ok && (@warn("iGMT binaries are not published for this platform."); return nothing)
	_Pkg = Base.require(Base.PkgId(Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"), "Pkg"))
	(remove || reinstall) && _iGMTuninstall(_Pkg)
	remove && return nothing
	if (!reinstall && (update || up))
		_Pkg.build("InteractiveGMT")
		return nothing
	end
	_Pkg.develop(url="https://github.com/GenericMappingTools/InteractiveGMT")
	reinstall && _Pkg.build("InteractiveGMT")	# nothing was left to fetch the binaries otherwise
	Base.eval(Main, :(using InteractiveGMT))
	return nothing
end

# ---------------------------------------------------------------------------------------------------
# Delete a directory tree, reporting what went (and why it couldn't, e.g. a DLL still loaded by a
# running iGMT window -- Windows will not unlink a mapped image). Never throws: an uninstall must
# get as far as it can rather than abort half-way.
function _iGMTrmtree(path::String, what::String)
	!isdir(path) && return false
	try
		rm(path; recursive=true, force=true)
		println("  removed $what: $path")
		return true
	catch err
		@warn "could not remove $what -- delete it by hand once nothing is using it." path exception=(err,)
		return false
	end
end

# The Desktop shortcut InteractiveGMT creates for itself. Resolved through WScript.Shell's
# SpecialFolders, the SAME way it is created -- never a hard-coded path, since a OneDrive-redirected
# Desktop is not %USERPROFILE%\Desktop.
function _iGMTrmshortcut()
	!Sys.iswindows() && return nothing
	try
		desk = strip(read(`powershell -NoProfile -Command "(New-Object -ComObject WScript.Shell).SpecialFolders('Desktop')"`, String))
		lnk  = joinpath(desk, "iGMT.lnk")
		isfile(lnk) && (rm(lnk; force=true); println("  removed shortcut: $lnk"))
	catch
	end
	return nothing
end

# Is this checkout somebody's WORKING repository rather than a plain `Pkg.develop` clone? Uninstall
# must never destroy work, so the question is answered conservatively: anything uncommitted, anything
# untracked, any commit the upstream branch doesn't have -- and ALSO any case we cannot decide (no
# git on PATH, no upstream configured, git errors out). Undecidable means precious. Only a checkout
# that is provably clean AND provably in sync with its upstream can be deleted; that is exactly what
# a fresh `Pkg.develop(url=...)` leaves behind.
function _iGMTisworkrepo(path::AbstractString)
	!isdir(path) && return false
	!isdir(joinpath(path, ".git")) && return false		# not a clone at all -> nothing to lose
	try
		!isempty(strip(read(Cmd(`git status --porcelain`; dir=path), String))) && return true
		# Built from a vector, not a backtick literal: `@{upstream}` has braces, which the command
		# literal parser reserves -- as a literal it is a syntax error at macro-expansion time.
		ahead = Cmd(Cmd(["git", "rev-list", "--count", "@{upstream}..HEAD"]); dir=path)
		return strip(read(ahead, String)) != "0"
	catch
		return true										# cannot tell -> treat it as work, keep it
	end
end

# Uninstall InteractiveGMT: drop it from the active environment, delete its `dev` sources and the
# depot-wide VTK+Qt binary runtime it downloaded. Shared by `remove=true` and `reinstall=true`, so
# both take exactly the same things away -- except a working repository, which is never deleted by
# either, with no flag to override that.
function _iGMTuninstall(_Pkg)
	println("Uninstalling InteractiveGMT...")
	try
		_Pkg.rm("InteractiveGMT")
	catch
		println("  (not present in the active environment)")
	end
	src = joinpath(_Pkg.devdir(), "InteractiveGMT")
	if _iGMTisworkrepo(src)
		println("  KEPT sources: $src")
		println("  (a working repository -- uncommitted, untracked or unpushed work. Delete it yourself if you really mean to.)")
	else
		_iGMTrmtree(src, "sources")
	end
	_iGMTrmtree(joinpath(first(DEPOT_PATH), "gmtvtk_runtime"), "VTK/Qt runtime")
	_iGMTrmshortcut()
	return nothing
end
