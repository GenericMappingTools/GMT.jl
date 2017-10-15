# By Modules

In this mode we access the individual **GMT** modules directly by their name, and options are
set using keyword arguments. The general syntax is (where the brackets mean optional parameters):

    [output objects] = modulename([cmd::String="",] [argi=[];] opt1=val1, opt2=val2, kwargs...);

where *modulename* is the program name (*e.g. pscoast*), *cmd* is used to transmit a file name for
modules that will read data from files and *argi* is one, and for certain modules, or more data
arrays or *GMT.jl* data types. *opti* named arguments common to many modules used for example to
set the output format. Finally *kwargs* are keyword parameters used to set the individual module
options. But contrary to the [`Monolitic`](@ref) usage, the one letter *GMT* option syntax may be
replaced by more verbose aliases. To make it clear let us look at couple of examples.

    pscoast(region="g", proj="A300/30/6c", frame="g", resolution="c", land="navy", fmt="ps")

This command creates a map in PotScript file (set by the *fmt="ps"*) called *GMTjl_tmp.ps* and save
in your system's *tmp* directory. For comparison, the same command could have been written, using
the classical one letter option syntax, as:

    pscoast(R="g", J="A300/30/6c", B="g", D="c", G="navy", fmt="ps")

So, each module defines a set of aliases to the one letter options that are reported in each module
man page.

The above example, however, does not use any input data (*pscoast* knows how to find its own data). One
way of providing it to modules that work on them is to send in a file name with the data to operate on.
This example

    grdimage("@tut_relief.nc", shade="+ne0.8+a100", proj="M12c", frame="a", fmt="ps", show=true)

reads a the netCDF grid *tut_relief.nc* and displays it as an Mercator projected image. The '@' prefix
is used bu *GMT* to know that the grid file should be downloaded from a server and cached locally. This
example introduces also the *show=true* keyword. It means that we want to see right way the image that
just been created. While it might seam obvious that one want to see the result, the result might not be
ready with only one *GMT* module call. And that because the *GMT* phylosophy uses a *layer cake*  model
to construct potentially highly complex figures. Next example illustrates a slightly more evolved
example

    topo = makecpt(color="rainbow", range="1000/5000/500", Z=[]);
    grdimage("@tut_relief.nc", shade="+ne0.8+a100", proj="M12c", frame="a", color=topo, fmt="jpg")
    psscale!(position="jTC+w5i/0.25i+h+o0/-1i", region="@tut_relief.nc", color=topo, frame="y+lm",
             fmt="jpg", show=true)

Here we used the *makecpt* command to compute a colormap object, used it as the value of the *color*
keyword of both *grdimage* and *psscale* modules. The final image is made up of two layers, the first
one is the part created by *grdimage*, which is complemented by the color scale plot performed by
*psscale*. But since this was an appending operation we **HAD** to use the **!** form. This form tells
*GMT* tho append to a previous initiated image. The image layer cake is finalized by the *show=true*
keyword. If our example had more layers, we would have used the sample rule: second on layers use the
**!** construct and the last is signaled by *show=true*.