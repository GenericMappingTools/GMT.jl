GMT.jl
======

Julia wrapper for the Generic Mapping Tools [GMT](http://gmt.soest.hawaii.edu)

| **Documentation**                       | **Build Status (Julia 1.1)**              |
|:---------------------------------------:|:-----------------------------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

[gitter-url]: https://gitter.im/genericmappingtools/users

[contrib-url]: https://genericmappingtools.github.io/GMT.jl/latest/man/contributing/

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://genericmappingtools.github.io/GMT.jl/latest

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://genericmappingtools.github.io/GMT.jl/stable

[travis-img]: https://travis-ci.org/GenericMappingTools/GMT.jl.svg?branch=master
[travis-url]: https://travis-ci.org/GenericMappingTools/GMT.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/usjewfb5v48m18kh/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/joa-quim/gmt-jl-suu4y/branch/master

[codecov-img]: http://codecov.io/github/GenericMappingTools/GMT.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/GenericMappingTools/GMT.jl?branch=master

[coveralls-img]: https://coveralls.io/repos/github/GenericMappingTools/GMT.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/GenericMappingTools/GMT.jl?branch=master

[pkg-0.6-img]: http://pkg.julialang.org/badges/GMT_0.6.svg
[pkg-0.6-url]: http://pkg.julialang.org/?pkg=GMT&ver=0.6
[pkg-0.7-img]: http://pkg.julialang.org/badges/GMT_0.7.svg
[pkg-0.7-url]: http://pkg.julialang.org/?pkg=GMT&ver=0.7

The Generic Mapping Tools, **GMT**, is an open source collection of tools for manipulating geographic
and Cartesian data sets (including filtering, trend fitting, gridding, projecting, etc.) and producing
PostScript illustrations ranging from simple x–y plots via contour maps to artificially illuminated
surfaces and 3D perspective views.

This wrapper works only with GMT5.3.1 and above

Install
=======

Use the new Pkg3 to install current version.

    ]add GMT

A word of warning about the installation. The *GMT.jl* Julia wrapper does **NOT** install the
[GMT](http://gmt.soest.hawaii.edu) program. It's the user responsability to do that.

  * Windows64
      1. It's better to install the [GMT6dev version](http://w3.ualg.pt/~jluis/mirone/downloads/gmt.html)
      2. But if you prefer the official GMT5 version (the [..._win64.exe](https://gmt.soest.hawaii.edu/projects/gmt/wiki/Download))

  * Windows32

      Download and install the official version at (the [..._win32.exe](https://gmt.soest.hawaii.edu/projects/gmt/wiki/Download))

  * Unix
  
      Follow instructions at https://gmt.soest.hawaii.edu/projects/gmt/wiki/BuildingGMT

  * In any case, since *GMT* produces PostScript you need a PS visualizer

      Install `Ghostscript` and `ghostview` at https://www.ghostscript.com/download/gsdnld.html

On OSX, with a manual GMT build and dependencies obtained with Homebrew (that are installed at
/user/local/lib), I had to help Julia finding MY *libgmt.dylib*, with (this line should than be
added to the ~/.julia/config/startup.jl file)

    push!(Libdl.DL_LOAD_PATH, "/Users/j/programs/gmt5/lib")

Using
=====

The *GMT* Julia wrapper was designed to work in a way the close as possible to the command line version
and yet to provide all the facilities of the Julia language. In this sense, all **GMT** options are put
in a single text string that is passed, plus the data itself when it applies, to the ``gmt()`` command.
However, we also acknowledge that not every one is comfortable with the *GMT* syntax. This syntax is
needed to accommodate the immense pool of options that let you control all details of a figure but that
also makes it harder to read/master.

To make life easier we provide also a new mechanism that use the **GMT** module name directly and where
the program's options are set via keyword arguments. While the monolotic way of using this package is
robust and keeps being updated to latestes **GMT** developments, this *By modules* alternative is a Work
In Progress (the **GMT supplements** were not ported yet) and some things may not work yet. So all help
is most than wellcome.

Documentation
=============

[Latest Docs](https://genericmappingtools.github.io/GMT.jl/latest)

Examples
========

[Some examples](https://genericmappingtools.github.io/GMT.jl/latest/examples)

License
=======

The GMT.jl is free software: you can redistribute it and/or modify it under the terms of the MIT "Expat"
License. A copy of this license is provided in ``LICENSE.txt``
