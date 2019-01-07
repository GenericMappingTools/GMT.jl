# By Modules

In this mode we access the individual **GMT** modules directly by their name, and options are
set using keyword arguments. The general syntax is (where the brackets mean optional parameters):

    [output objects] = modulename([cmd::String="",] [argi=[],] opt1=val1, opt2=val2, kwargs...);

where *modulename* is the program name (*e.g. coast*), *cmd* is used to transmit a file name for
modules that will read data from files and *argi* is one or, and for certain modules, more data
arrays or *GMT.jl* data types. *opti* named arguments common to many modules used for example to
set the output format. Finally *kwargs* are keyword parameters used to set the individual module
options. But contrary to the [Monolithic](@ref) usage, the one letter *GMT* option syntax may be
replaced by more verbose aliases. To make it clear let us look at couple of examples.

    coast(region="g", proj="A300/30/6c", axis="g", resolution="c", land="navy")

This command creates a map in PotScript file called *GMTjl_tmp.ps* and save it in your system's
*tmp* directory. For comparison, the same command could have been written, using the classical
one letter option syntax, as:

    coast(R="g", J="A300/30/6c", B="g", D="c", G="navy")

So, each module defines a set of aliases to the one letter options that are reported in each module
man page.

Before diving more in the way options may be transmitted into the module, we have to understand what
happens with the output image file. By not directly specifying any format we are using the default
output image format which is PostScript (actually, except for *grdimage -A*, the only
format that *GMT* can write). But we can select other formats by using the *fmt* keyword, for example
*fmt="jpg"*, or *fmt=:png* or *fmt=:pdf*. In such cases, the *ghostscript* program (you need to have
it installed) will take care of converting the *ps* file into the selected format. Note that we used
either strings ("") or symbols (:) to represent the format. Here the rule is we can use symbols for
any string argument that can be safely written as a symbol. Example, this is valid =:abc, but this
is not =:+a (apparently parser will try to add to *a*). The use of symbols may be preferred for a
question of laziness (less typing).

The above example, however, does not use any input data (*coast* knows how to find its own data). One
way of providing it to modules that work on them is to send in a file name with the data to operate on.
This example

    grdimage("@tut_relief.nc", shade="+ne0.8+a100", proj=:M12c, axis=:a, show=true)

reads a the netCDF grid *tut_relief.nc* and displays it as a Mercator projected image. The '@' prefix
is used by *GMT* to know that the grid file should be downloaded from a server and cached locally. This
example introduces also the *show=true* keyword. It means that we want to see right way the image that
has just been created. While it might seem obvious that one wants to see the result, the result might not be
ready with only one *GMT* module call. And that's why the *GMT* philosophy uses a *layer cake* model
to construct potentially highly complex figures. Next example illustrates a slightly more evolved
example

    topo = makecpt(color=:rainbow, range="1000/5000/500", Z=[]);
    grdimage("@tut_relief.nc", shade="+ne0.8+a100", proj=:M12c, axis=:a, color=topo,
             fmt=:jpg)
    colorbar!(position="jTC+w5i/0.25i+h+o0/-1i", region="@tut_relief.nc", color=topo,
           axis="y+lm", fmt=:jpg, show=true)

Here we use the *makecpt* command to compute a colormap object and used it as the value of the *color*
keyword of both *grdimage* and *colorbar* modules. The final image is made up of two layers, the first
one is the part created by *grdimage*, which is complemented by the color scale plot performed by
*colorbar*. But since this was an appending operation we **HAD** to use the **!** form. This form tells
*GMT* to append to a previous initiated image. The image layer cake is finalized by the *show=true*
keyword. If our example had more layers, we would have used the same rule: second and on layers use the
**!** construct and the last is signaled by *show=true*.

By defaultn the image files are written into *tmp* system directory under the name *GMTjl_tmp.ps* (remember
*PostScript* is the default format) and *GMTjl_tmp.xxx* when user specifies a different format with the
*fmt* keyword. It's one of this files that shows up when *show=true* is used. But we may want to save the
image file permanently under a different name and location. For that use the keyword *savefig=name*, where
*name* is relative or full file name.

The examples above show also that we didn't completely get rid of the compact *GMT* syntax. For example
the *shade="+ne0.8+a100"* in *grdimage* means that we are computing the shade using a normalized a
cumulative Laplace distribution and setting the Sun direction from the 100 azimuth direction. For as much
we would like to simplify that, it's just not possible for the time being. To access the (very) high degree
of control that *GMT* provides one need to use its full syntax. As such, readers are redirected to the main
*GMT* documentation to learn about the fine details of those options.

Setting line and symbol attributes has received, however, a set of aliases. So, instead of declaring the
pen line attributes like *-W0.5,blue,--*, one can use the aliases *lw=0.5, lc="blue", ls="--"*. An
example would be:

    plot(collect(1:10),rand(10), lw=0.5, lc=:blue, ls="--", fmt=:png, marker=:circle,
         markeredgecolor=0, size=0.2, markerfacecolor=:red, title="Bla Bla",
         x_label=:Spoons, y_label=:Forks, show=true)

This example introduces also keywords to plot symbols and set their attributes. Also shown are the
parameters used to set the image's title and labels.

But setting pen attributes like illustrated above may be complicated if one has more that one set of
graphical objects (lines and polygons) that need to receive different settings. A good example of
this is again provided by a *coast* command. Imagine that we want to plot coast lines as well as country
borders with different line colors and thickness. Here we cannot simple state *lw=1* because the
program wouldn't know which of the shore line or borders this attribute applies to. The solution for
this is to use tuples as values of corresponding keyword options.

    coast(limits=[-10 0 35 45], proj=:M12c, shore=(0.5,"red"), axis=:a,
            show=1, borders=(1,(1,"green")))

Here we used tuples to set the pen attributes, where the tuple may have 1 to 3 elements in the form
(width[c|i|p]], [color], [style[c|i|p|]). The *borders=(1,(1,"green"))* option is actually a
tuple-in-a-tuple because here we need also to specify the political boundary level to plot
(1 = National Boundaries).

## Specifying the pen attributes

So, in summary, a *pen* attribute may be set in three different ways:

1. With a text string that follows the *width*, *color*, *style* specs as explained in
   [`Specifying pen attributes`] (http://gmt.soest.hawaii.edu/doc/latest/GMT_Docs.html#specifying-pen-attributes)

2. By using the **lw** or **linewidth** keyword where its value is either a number, meaning the
   line thickness in points, or a string like the *width* above; the color is set with the
   **lc** or **linecolor** and the value is either a number between *[0 255]* (meaning a gray shade)
   or a color name (for example "red"); and a **ls** or **linestyle** with the value specified as
   a string (example: "- -" plot a dashed line).

3. A tuple with one to three elements: ([*width*], [*color*], [*style*]) where each of the
   elements follow the same syntax as explained in the case (2) above.

## Specifying the axes

The axes are controlled by the **B** or **frame** or **axis** keywords. The easiest form it can have
is the *axes=:a*, which means do an automatic annotation of the 4 map boundaries
-- left, bottom, right and top -- axes. To annotate only the left and bottom boundaries, one
would do *axes="a WSne"* (note the space between *a* and *WSne*). For a higher level of control the
user must really consult the original
[`-B documentation`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#b-full).

Other than setting titles and labels with a **axes** string we can also do it by using the keywords
**title**, **x_label** and **y_label**.

The figure limits is set with the **R**, **region** or **limits**  keywords. Again, the full docs for this
option are explained in [`-R documentation`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#r-full).
But other than the string version, the numeric form *region=[x_min x_max y_min y_max]* is also permitted.
And when dealing with grids, even the *region=mygrid.grd* is a valid operation. Where *mygrid.grd* is a
*GMTgrid* type. The ``plot()`` function allows a no limits setting, in which case it will default to the
data's bounding box.

## Axes (and other) configuration

There are almost 150 parameters which can be adjusted individually to modify the appearance of plots or
affect the manipulation of data. When a program is run, it initializes all parameters to the GMTdefaults
(see more at [`GMT defaults`](https://gmt.soest.hawaii.edu/doc/latest/GMT_Docs.html#gmt-defaults)). 
At times it may be desirable to temporarily override some of those defaults. We can do that easily
by using any of the keywords *conf*, *par* or *params*, which are recognized by all modules. Its usage
follows closely the syntax described at [`gmt.conf`](https://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html)
but using Named Tuples. The parameter names are always given in UPPER CASE. The parameter values are
case-insensitive unless otherwise noted and can be given as strings or numeric. Provide as many
parameters as you want in the named tuple. Example

    basemap(...., conf=(MAP_TICK_LENGTH_PRIMARY=0.25, FORMAT_GEO_MAP="ddd:mm:ssF"))


## Specifying the figure size

Figure sizes are automatically set to 12x8 cm for basic case of Cartesian *xy* plots done with the *plot()*
function but otherwise in general they need to be user specified using the **J** or **proj** or **projection**
keywords. See the full doc at [`-J documentation`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#j-full). 
For Cartesian plots one can also use the *figsize=width*  or *figsize=[width height]* keyword, where the
dimensions are in centimeters. The array form allows also set *height* or *width* to 0 to have it recomputed
based on the implied scale of the other axis. Use negative sizes to reverse the direction of an axis
(e.g., to have y be positive down). If neither of these forms is used, the figure width defaults to 14 cm.

## The output format

It was referred above that the **fmt** determines the output format and that the default is *PostScript*.
Actually, the default format is chosen by the contents of the global **FMT** variable set at the top of
the *GMT.jl* file. Eventually this will evolve to using an environment variable but for the moment users
will have to edit that file to set a different default format.

A very interesting alternative is to set **FMT=""**, that is to not specify any image format. This will
result in *NOT* saving any file on disk but to keep the PS figure internally stored in the program's memory. 
In other words, the figure is built and kept in memory only. This allows converting to another format
directly without the use of an intermediary disk file. The conversion is performed by the *psconvert* *GMT*
module that would be used like this (to convert to PDF):

    psconvert(in_memory=true, adjust=true, format=:f, out_name="myfig.pdf")

The issue with this solution, that could be implemented internally without user intervention, is that it
currently only works on Windows.

Another interesting alternative to a file format is the option to create RGB images with *psconvert* and
return it to Julia as a [Image type](@ref) type.

    I = psconvert(in_memory=true, adjust=true)

but again, so far on Windows only. A cool thing to develop would be the possibility to display this *I*
image with the [`Images.jl`](https://github.com/JuliaImages/Images.jl) package.

## Saving data to disk

As referred in the [Monolithic](@ref) section, we have two programs to do read and writing. Their
module names are *gmtread* and *gmtwrite*. These modules allow to import and export any of the GMT
data types to and from external files. For instance, to save the grid *G* stored into a GMTgrid type
into the file *relief.nc* we run 

    gmtwrite("relief.nc", G)

Here there is no need to inform about the type of data that we are dealing with because that can be
inferred from the type of the numeric argument. There are cases, however, where we may want to save
the result of a computation directly on disk instead of assigning it to a Julia variable and latter
save it with *gmtwrite*. For computations that deal with grids that is easy. Just provide ask for an
output name using the *outgrid* keyword, like

    grdcut(G, limits=[3 9 2 8], outgrid="lixo.grd");

but for table data the **GMT** programs normally output their results to *stdout* so if we want to save
data directly to disk (as would do the corresponding GMT shell command) we use the *write* or *|>*
keywords. We can also use this mechanism to append to an existing file, but then we use the *append*
keyword. Use together with the **bo** option to save as a binary file. The following converts the grid
*G* to *x,y,z* triplets and save the result in an ASCII disk file.

    grd2xyz(G, write="lixo.xyz")

## How inputs are transmitted to modules

Different modules take different number of inputs (for example *grdblend* accepts a variable number of
grids) and some modules accept primary input and optionally a secondary input (for example the *weights* 
option in *grdtrend*). The primary input(s) can be sent as text strings with the names of files to be read
or as Julia variables holding the appropriate data type, and that as the first argument to the module call.
Alternatively, the numeric input can be sent via the *data* keyword whose value can be a tuple when the
expected input is composed by more than one variable. The same applies when an option is expected to
receive more than one arguments (for example the three *R,G,B* in *grdview*). Examples:

    grdimage(G, intens=I, J=:M6i, color=C, B="1 WSne", X=:c, Y=0.5, show=1)

    grdimage(data=G, intens=I, J=:M6i, color=C, B="1 WSne", X=:c, Y=0.5, show=1)

    grdview(G, intens=:+, J=:M4i, JZ="2i", p="145/35", G=(Gr,Gg,Gb), B="af WSne", Q=:i, show=1,)
