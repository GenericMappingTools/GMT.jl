# By Modules

In this mode we access the individual **GMT** modules directly by their name, and options are
set using keyword arguments. The general syntax is (where the brackets mean optional parameters):

    [output objects] = modulename([cmd::String="",] [argi=[];] opt1=val1, opt2=val2, kwargs...);

where *modulename* is the program name (*e.g. coast*), *cmd* is used to transmit a file name for
modules that will read data from files and *argi* is one, and for certain modules, or more data
arrays or *GMT.jl* data types. *opti* named arguments common to many modules used for example to
set the output format. Finally *kwargs* are keyword parameters used to set the individual module
options. But contrary to the [Monolitic](@ref) usage, the one letter *GMT* option syntax may be
replaced by more verbose aliases. To make it clear let us look at couple of examples.

    coast(region="g", proj="A300/30/6c", frame="g", resolution="c", land="navy")

This command creates a map in PotScript file called *GMTjl_tmp.ps* and save it in your system's
*tmp* directory. For comparison, the same command could have been written, using the classical
one letter option syntax, as:

    coast(R="g", J="A300/30/6c", B="g", D="c", G="navy")

So, each module defines a set of aliases to the one letter options that are reported in each module
man page.

Before diving more in the way options may be transmitted into the module, we have to understand what
happens with the output image file. By not directly specifying any format we are using the default
output image format which is PostScript (actually, with the exception of *grdimage -A*, the only
format that *GMT* can write). But we can select other formats by using the *fmt* keyword, for example
*fmt="jpg"*, or *fmt="png"* or *fmt="pdf"*. In such cases, the *ghostscript* program (you need to have
it installed) will take care of converting the *ps* file into the selected format.

The above example, however, does not use any input data (*coast* knows how to find its own data). One
way of providing it to modules that work on them is to send in a file name with the data to operate on.
This example

    grdimage("@tut_relief.nc", shade="+ne0.8+a100", proj="M12c", frame="a", show=true)

reads a the netCDF grid *tut_relief.nc* and displays it as an Mercator projected image. The '@' prefix
is used by *GMT* to know that the grid file should be downloaded from a server and cached locally. This
example introduces also the *show=true* keyword. It means that we want to see right way the image that
just been created. While it might seam obvious that one want to see the result, the result might not be
ready with only one *GMT* module call. And that's because the *GMT* philosophy uses a *layer cake*  model
to construct potentially highly complex figures. Next example illustrates a slightly more evolved
example

    topo = makecpt(color="rainbow", range="1000/5000/500", Z=[]);
    grdimage("@tut_relief.nc", shade="+ne0.8+a100", proj="M12c", frame="a", color=topo,
             fmt="jpg")
    scale!(position="jTC+w5i/0.25i+h+o0/-1i", region="@tut_relief.nc", color=topo,
           frame="y+lm", fmt="jpg", show=true)

Here we used the *makecpt* command to compute a colormap object, used it as the value of the *color*
keyword of both *grdimage* and *psscale* modules. The final image is made up of two layers, the first
one is the part created by *grdimage*, which is complemented by the color scale plot performed by
*psscale*. But since this was an appending operation we **HAD** to use the **!** form. This form tells
*GMT* to append to a previous initiated image. The image layer cake is finalized by the *show=true*
keyword. If our example had more layers, we would have used the same rule: second on layers use the
**!** construct and the last is signaled by *show=true*.

The examples above show also that we didn't completely get rid of the compact *GMT* syntax. For example
the *shade="+ne0.8+a100"* in *grdimage* means that we are computing the shade using a normalized a
cumulative Laplace distribution and setting the Sun direction from the 100 azimuth direction. For as much
we would like to simplify that, it's just not possible. To access the high degree of control that *GMT*
provides one need to use its full syntax. As such, readers are redirected to the main *GMT* documentation
to learn about the fine details of those options.

Setting line and symbol attributes has received, however, a set of aliases. So, instead of declaring the
pen line attributes like *-W0.5,blue,--*, one can use the aliases *lw=0.5, lc="blue", ls="--"*. An
example would be

    plot(collect(1:10),rand(10), lw=0.5, lc="blue", ls="--", fmt="png", marker="circle",
         markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla",
         x_label="Spoons", y_label="Forks", show=true)

This example introduces also keywords to plot symbols and set their attributes. Also shown are the
parameters used to set the image's title and labels.

But setting pen attributes like illustrated above may be complicated if one has more that one set of
graphical objects (lines and polygons) that need to receive different settings. A good example of
this again provide by a *coast* command. Imagine one want to plot coast lines ans well as country
borders with different line colors and thickness. Here we cannot simple state *lw=1* because the
program wouldn't know which of the shore line or borders this attribute applies to. The solution for
this is to use tuples as values of corresponding keyword options.

    coast(limits="-10/0/35/45", proj="M12c", shore=(0.5,"red"), frame="a",
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
   elements follows the same syntax as explained in the case (2) above.

## Specifying the axes

The axes are controlled by the **B** or **frame** or **axes** keywords. The easiest for it can have
is the *axes="a"*, which means do an automatic annotation of the 4 map boundaries
-- left, bottom, right and top -- axes. To annotate only the left and bottom boundaries, one
would do *axes="a WSne"*. For a higher level of control the user must really consult the original
[`-B documentation`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#b-full).

Axes titles and labels may be also set. That is, other than setting them with a **axes** string, using
the keywords **title**, **x_label** and **y_label**.

The figure limits is set with the **R**, **region** or **limits**  keywords. Again, the full docs for this
option are explained in [`-R documentation`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#r-full)
but besides the string version, the numeric form *region=[x_min x_max y_min y_max]* is also permitted.
The ``plot()`` function allows that a no limits setting, in which case it will default to the
data's bounding box.

## Specifying the figure size

Figure sizes are automatically set to 12x8 cm for basic case of Cartesian *xy* plots done with the *plot()*
function but otherwise in general they need to be user specified using the **J** or **proj** or **projection**
keywords. See the full doc at [`-J documentation`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#j-full). 
For Cartesian plots one can also use the *figsize=width*  or *figsize=[width height]* keyword, where the
dimensions are in centimiters. The array form allows also set *height* or *width* to 0 to have it recomputed
based on the implied scale of the other axis. Use negative sizes to reverse the direction of an axis
(e.g., to have y be positive down). If neither of these forms is used, the figure width defaults to 14 cm.

## The output format

It was referred above that the **fmt** determines the output format and that the default is PostScript.
Actually the default format is choosen by the contents of the global **FMT** variable set at the top of
the *GMT.jl* file. Eventually this will evolve to using an evironment variable but for the moment users
will have to edit that file to set a different default format.

A very interesting alternative is to set **FMT=""**, that is to not specify any image format. This will
result in *NOT* saving any file on disk but to keep the PS figure internally stored in the program's memory. 
In other words the figure is built and kept in memory only. This allows converting to another format
directly without the use of an intermediary disk file. The conversion is performed by the *psconvert* *GMT*
module that would be used like this (to convert to PDF):

    psconvert(in_memory=true, adjust=true, format="f", out_name="myfig.pdf")

The issue with this solution, that could be implemented internally without user intervention, is that it
currently only works on Windows.

A very interesting alternative to a file format is the option to create RGB images with *psconvert* and
return it to Julia in a [Image type](@ref) type.

    I = psconvert(in_memory=true, adjust=true)

but again, so far on Windows only. A cool thing to develop would be the possibility to display this *I*
image with the [`Images.jl`](https://github.com/JuliaImages/Images.jl) package.
 