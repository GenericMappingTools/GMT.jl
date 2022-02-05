GMT.jl
======

Julia wrapper for the Generic Mapping Tools [GMT](https://github.com/GenericMappingTools/gmt)

| **Documentation**                       | **Build Status (Julia 1.5)**              | **Discourse Forum**   | **Collaboration** |
|:---------------------------------------:|:-----------------------------------------:|:---------------------:|:---------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] | [![][forum-img]][forum-url] | [![][colprac-img]][colprac-url] |

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://genericmappingtools.github.io/GMT.jl/dev

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

This wrapper works with GMT6.1.0 and above and it is intended not only to access to **GMT** from
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

<img src="docs/src/figures/mapproj/GMT_winkel.png" width="350" class="center"/>

Install
=======

    ] add GMT

A word of warning about the installation. It is recommended that you install the [GMT](https://github.com/GenericMappingTools/gmt)
program in your system as explained bellow. If you do this then the *GMT.jl* wrapper will be able to find it. However, if you don't
care about disk space usage and some extra >4 GB are no worries for you then on Unix (Mac and Linux) if the wrapper doesn't find GMT,
it will install one automatically via Conda. On Windows the installation is done with the Windows installer and no such huge waste
takes place. One may also force the automatic installation by setting the environment variable ``FORCE_INSTALL_GMT``


  * Windows64
      Install the [GMT6 version](http://fct-gmt.ualg.pt/gmt/data/wininstallers/gmt-6.3-dev-win64.exe)

  * Windows32
      [..._win32.exe](https://github.com/GenericMappingTools/gmt/releases/download/6.2.0/GMT-6.2.0-win32.exe)

  * Unix
  
      Follow instructions at <https://github.com/GenericMappingTools/gmt/blob/master/INSTALL.md>

  * Since *GMT* produces PostScript you need a PS interpreter. Windows installer comes with ghostcript but on Mac/Linux you need to:

      Install `Ghostscript` and `ghostview` at <https://ghostscript.com/releases/gsdnld.html>

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

[Quick Learn](https://genericmappingtools.github.io/GMT.jl/dev/quick_learn)

[GMT.jl docs](https://genericmappingtools.github.io/GMT.jl/dev)

[GMT Docs](https://www.generic-mapping-tools.org/gmt/latest/)

Examples
========

[Some examples](https://genericmappingtools.github.io/GMT.jl/dev/examples)

Credits
=======

A lot of the GDAL interface functions rely on code from [GDAL.jl](https://github.com/JuliaGeo/GDAL.jl) by Martijn Visser
and [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl) by Yeesian Ng, released under the MIT license.

License
=======

The GMT.jl is free software: you can redistribute it and/or modify it under the terms of the MIT "Expat"
License. A copy of this license is provided in ``LICENSE.txt``
