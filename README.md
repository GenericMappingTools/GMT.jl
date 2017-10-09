GMT.jl
======

Julia wrapper for the Generic Mapping Tools [GMT](http://gmt.soest.hawaii.edu)

| **Documentation**                       | **PackageEvaluator**            | **Build Status**                          |
|:---------------------------------------:|:-------------------------------:|:-----------------------------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][pkg-0.6-img]][pkg-0.6-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

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

[issues-url]: https://github.com/JuliaDocs/GMT.jl/issues

[pkg-0.6-img]: http://pkg.julialang.org/badges/GMT_0.6.svg
[pkg-0.6-url]: http://pkg.julialang.org/?pkg=GMT&ver=0.6
[pkg-0.7-img]: http://pkg.julialang.org/badges/GMT_0.7.svg
[pkg-0.7-url]: http://pkg.julialang.org/?pkg=GMT&ver=0.7

This wrapper works only with GMT5.3.1 and above

Install
=======

    Pkg.add("GMT")

On OSX, with a manual GMT build and dependencies obtained with Homebrew (that are installed at /user/local/lib), I had to help
Julia finding MY *libgmt.dylib*, with (this line should than be added to the ~/.juliarc.jl file)

    push!(Libdl.DL_LOAD_PATH, "/Users/j/programs/gmt5/lib")

Using
=====

The Julia wrapper was designed to work in a way the closest as possible to the command line version and yet to provide all the facilities of the Julia language. In this sense, all **GMT** options are put in a single text string that is passed, plus the data itself when it applies, to the ``gmt()`` command. For example to reproduce the CookBook example of an Hemisphere map using a Azimuthal projection

    gmt("pscoast -Rg -JA280/30/3.5i -Bg -Dc -A1000 -Gnavy -P > GMT_lambert_az_hemi.ps")

but that is not particularly interesting as after all we could do the exact same thing on the a shell command line. Things start to get interesting when we can send data *in* and *out* from Julia to
**GMT**. So, consider the following example

    t = rand(100,3) * 150;
    G = gmt("surface -R0/150/0/150 -I1", t);

Here we just created a random data *100x3* matrix and told **GMT** to grid it using it's program *surface*. Note how the syntax follows closely the standard usage but we sent the data to be interpolated (the *t* matrix) as the second argument to the ``gmt()`` function. And on return we got the *G* variable that is a type holding the grid and it's metadata. See the :ref:`grid struct <grid-struct>` for the details of its members.

Imagining that we want to plot that random data art, we can do it with a call to *grdimage*, like

    gmt("grdimage -JX8c -Ba -P -Cblue,red > crap_img.ps", G)

Note that we now sent the *G grid* as argument instead of the **-G** *gridname* that we would have used in the command line. But for readability we could well had left the **-G** option in command string. E.g:

    gmt("grdimage -JX8c -Ba -P -Cblue,red -G > crap_img.ps", G)

While for this particular case it makes no difference to use or not the **-G**, because there is **only** one input, the same does not hold true when we have more than one. For example, we can run the same example but compute the color palette separately.

    cpt = gmt("grd2cpt -Cblue,red", G);
    gmt("grdimage -JX8c -Ba -P -C -G > crap_img.ps", G, cpt)

Now we had to explicitly write the **-C** & **-G** (well, actually we could have omitted the **-G** because
it's a mandatory input but that would make the things more confusing). Note also the order of the input data variables.
It is crucial that any *required* (primary) input data objects (for grdimage that is the grid) are given before
any *optional* (secondary) input data objects (here, that is the CPT object).  The same is true for modules that
return more than one item: List the required output object first followed by optional ones.

To illustrate another aspect on the importance of the order of input data let us see how to plot a sinus curve made of colored filled circles.

    x = linspace(-pi, pi)';            # The xx var
    seno = sin(x);                     # yy
    xyz  = [x seno seno];              # Duplicate yy so that it can be colored
    cpt  = gmt("makecpt -T-1/1/0.1");  # Create a color palette
    gmt("psxy -R-3.2/3.2/-1.1/1.1 -JX12c -Sc0.1c -C -P -Ba > seno.ps", xyz, cpt)

The point here is that we had to give *xyz, cpt* and not *cpt, xyz* (which would error) because optional input data
associated with an option letter **always comes after the required input**.

To plot text strings we send in the input data wrapped in a cell array. Example:

    lines = Any["5 6 Some label", "6 7 Another label"];
    gmt("pstext -R0/10/0/10 -JM6i -Bafg -F+f18p -P > text.ps", lines)

and we get back text info in cell arrays as well. Using the *G* grid computed above we can run *gmtinfo* on it

    info = gmt("gmtinfo", G)

But since GMT is build with GDAL support we can make good use of if to read and plot images that don't even need to be stored
locally. In the following example we will load a network image (GDAL will do that for us) and make a *creative* world map.
Last command is used to convert the PostScript file into a transparent PNG.

    gmt("grdimage -Rd -JI15c -Dr http://larryfire.files.wordpress.com/2009/07/untooned_jessicarabbit.jpg -P -Xc -Bg -K > jessy.ps")
    gmt("pscoast -R -J -W1,white -Dc -O >> jessy.ps")
    gmt("psconvert jessy.ps -TG -A")

![Screenshot](http://w3.ualg.pt/~jluis/jessy.png)

At the end of an **GMT** session work we call the internal functions that will do the house keeping of freeing no longer needed memory. We do that with this command:

    gmt("destroy")

So that's basically how it works. When numeric data has to be sent *in* to **GMT** we use Julia variables holding the data in matrices or structures or cell arrays depending on the case. On return we get the computed result stored in variables that we gave as output arguments. Things only complicate a little more for the cases where we can have more than one *input* or *output* arguments. The file *gallery.jl*, that reproduces the examples in the Gallery section of the GMT documentation, has many (not so trivial) examples on usage of the **GMT** wrapper.

----------

The Grid type
-------------

    type GMTJL_GRID 	            # The type holding a local header and data of a GMT grid
       proj4::String              # Projection string in PROJ4 syntax (Optional)
       wkt::String                # Projection string in WKT syntax (Optional)
       range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]
       inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]
       registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration
       nodata::Float64            # The value of nodata
       title::String              # Title (Optional)
       comment::String            # Remark (Optional)
       command::String            # Command used to create the grid (Optional)
       datatype::String           # 'float' or 'double'
       x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates
       y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates
       z::Array{Float32,2}        # [n_rows x n_columns] grid array
       x_units::String            # Units of XX axis (Optional)
       y_units::String            # Units of YY axis (Optional)
       z_units::String            # Units of ZZ axis (Optional)
       layout::String             # A three character string describing the grid memory layout
    end

The Image type
--------------

    type GMTimage                 # The type holding a local header and data of a GMT image
       proj4::String              # Projection string in PROJ4 syntax (Optional)
       wkt::String                # Projection string in WKT syntax (Optional)
       range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]
       inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]
       registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration
       nodata::Float64            # The value of nodata
       title::String              # Title (Optional)
       comment::String            # Remark (Optional)
       command::String            # Command used to create the image (Optional)
       datatype::String           # 'uint8' or 'int8' (needs checking)
       x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates
       y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates
       image::Array{UInt8,3}      # [n_rows x n_columns x n_bands] image array
       x_units::String            # Units of XX axis (Optional)
       y_units::String            # Units of YY axis (Optional)
       z_units::String            # Units of ZZ axis (Optional) ==> MAKES NO SENSE
       colormap::Array{Clong,1}   # 
       alpha::Array{UInt8,2}      # A [n_rows x n_columns] alpha array
       layout::String             # A four character string describing the image memory layout
    end

The DATASET type
----------------

    type GMTdataset
        header::String
        data::Array{Float64,2}
        text::Array{Any,1}
        comment::Array{Any,1}
        proj4::String
        wkt::String
    end

The CPT type
------------

    type GMTcpt
        colormap::Array{Float64,2}
        alpha::Array{Float64,1}
        range::Array{Float64,2}
        minmax::Array{Float64,1}
        bfn::Array{Float64,2}
        depth::Cint
        hinge::Cdouble
        cpt::Array{Float64,2}
        model::String
        comment::Array{Any,1}   # Cell array with any comments
    end

The Postscript type
-------------------

    type GMTps
        postscript::String      # Actual PS plot (text string)
        length::Int             # Byte length of postscript
        mode::Int               # 1 = Has header, 2 = Has trailer, 3 = Has both
        comment::Array{Any,1}   # Cell array with any comments
    end
