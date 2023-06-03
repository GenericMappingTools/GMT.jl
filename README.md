GMT.jl
======

Julia wrapper for the Generic Mapping Tools [GMT](https://github.com/GenericMappingTools/gmt)

| **Documentation**                       | **Build Status (Julia 1.8)**              | **Discourse Forum**   | **Collaboration** |
|:---------------------------------------:|:-----------------------------------------:|:---------------------:|:---------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] | [![][forum-img]][forum-url] | [![][colprac-img]][colprac-url] |

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://genericmappingtools.github.io/GMTjl_doc/

[travis-img]: https://travis-ci.com/GenericMappingTools/GMT.jl.svg?branch=master
[travis-url]: https://travis-ci.com/GenericMappingTools/GMT.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/usjewfb5v48m18kh/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/joa-quim/gmt-jl-suu4y/branch/master

[codecov-img]: http://codecov.io/github/GenericMappingTools/GMT.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/GenericMappingTools/GMT.jl?branch=master

[forum-img]: https://img.shields.io/discourse/status?label=forum&server=https%3A%2F%2Fforum.generic-mapping-tools.org%2F&style=flat-square
[forum-url]: https://forum.generic-mapping-tools.org

[colprac-img]: https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet%20alt=%22Collaborative%20Practices%20for%20Community%20Packages%22
[colprac-url]: https://github.com/SciML/ColPrac

The Generic Mapping Tools, **GMT**, is an open source collection of tools for manipulating geographic
and Cartesian data sets (including filtering, trend fitting, gridding, projecting, etc.) and producing
PostScript illustrations ranging from simple x–y plots via contour maps to artificially illuminated
surfaces and 3D perspective views.
[This link](https://www.google.com/search?q=%22generic+mapping+tools%22+site%3Awikimedia.org&tbm=isch#imgrc=_)
will take you to an impressive collection of figures made with **GMT**

<a href="https://www.google.com/search?q=%22generic+mapping+tools%22+site%3Awikimedia.org&tbm=isch#imgrc=_"><img src="docs/src/figures/GMT_wikimeia.jpg" width="800" class="center"/></a>

This wrapper works with GMT6.4.0 and above and it is intended not only to access to **GMT** from
within the Julia language but also to provide a more modern interface to the **GMT** modules.
For example, instead of using the **GMT** classic syntax to do a line plot:

    gmt psxy filename -R0/10/0/5 -JX12 -W1p -Ba -P > psfile.ps

one can simply do:

    plot("filename", show=true)

or, more verbose but easier to read

    coast(region=:global, proj=:Winkel, frame=:g, area=10000,
          land=:burlywood4, water=:wheat1, show=true)

instead of

    gmt coast -Rd -JR12 -Bg -Dc -A10000 -Gburlywood4 -Swheat1 -P > GMT_winkel.ps

to show

<img src="docs/src/figures/GMT_winkel.png" width="350" class="center"/>

Install
=======

    ] add GMT

A word about the installation. On Unix (Mac included) we now use a GMT_jll artifact to provide the GMT binary,
but for Windows we keep using a MSVC GMT binary. This means that on Windows the GMT (the C lib) is not updated
automatically (but GMT.jl is). Updates there are done manually by running ``upGMT()``. Also, for some reasons
it may be desirable to use a system wide GMT installation. To swap to a system wide GMT installation, do (in REPL):

- ENV["SYSTEMWIDE_GMT"] = 1;
- import Pkg; Pkg.build("GMT")
- restart Julia

Note the above will work up until some other reason triggers a Julia recompile, where the JLL artifacts 
will be used again. To make the ENV["SYSTEMWIDE_GMT"] = 1 solution permanent, declare a "SYSTEMWIDE_GMT"
environment variable permanently in your .bashrc (or whatever).

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
in Progress (several of the **GMT supplements** were not ported yet) and some things may not work yet.
So all help is most than wellcome.

[Documentation and Examples](https://genericmappingtools.github.io/GMTjl_doc)
================================================================


Credits
=======

A lot of the GDAL interface functions rely on code from [GDAL.jl](https://github.com/JuliaGeo/GDAL.jl) by Martijn Visser
and [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl) by Yeesian Ng, released under the MIT license.

License
=======

The GMT.jl is free software: you can redistribute it and/or modify it under the terms of the MIT "Expat"
License. A copy of this license is provided in ``LICENSE.txt``
