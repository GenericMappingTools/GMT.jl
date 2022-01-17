# How to learn using GMT in Julia

## Case 1. You are already a GMT user

So you already know GMT and how to consult the GMT manual pages. Then the easiest way to start is to
use the option letters and options arguments as strings. Since (nearly) all base modules received
a wrapper you would call *pscoast* (or its alias *coast*) like this:

```julia
    coast(R="-10/0/35/45", J="M15c", B="afg", W="0.5p", show=true)
```

but what if you need to make a map with some data, a grid for example. Simple, give it as a first argument as in:

```julia
    grdimage("@earth_relief_20m.grd", J="R15c", B="a", show=true)
```

This will compute a cpt under the hood and use it. But what if you want to use another cpt? Also simple,
just make one and use it in the above command. *i.e.*:

```julia
    CPT = makecpt(T="-10000/8000/1000");
    grdimage("@earth_relief_20m.grd", J="R15c", B="a", C=CPT, show=true)
```

The last command introduced a novelty in using the **C** option and that's where things start to be interesting.
Instead of using a previously existing cpt file, *e.g.* a file called ``color.cpt`` and used it as C="color.cpt",
we created a `GMTcpt` object that resides only in Julia memory space and passed it directly via the **C** option.
The same could have been done if we had the `earth_relief_20m.grd` grid in memory, which, for example sake, can
be achieved by previously reading the grid file.

```julia
    CPT = makecpt(T="-10000/8000/1000");
    G = gmtread("@earth_relief_20m.grd");
    grdimage(G, J="R15c", B="a", C=CPT, show=true)
```

Though not particularly useful nor memory more efficient to read the grid first this example illustrates
typical usage. That is, use GMT to process and map/plot data resident in Julia memory. GMT modules know
how to manipulate import/create data stored in [`GMTgrid`](@ref), [`GMTimage`](@ref),
[`GMTdataset`](@ref), [`GMTcpt`](@ref) and [`GMTps`](@ref) objects.
The helper functions [`mat2grid`](@ref), [`mat2img`](@ref) and [`mat2ds`](@ref) exist to allow creating those objects from 2D arrays
of floats, uint8, uint16 and MxN matrices respectively.

Example: create three grids with random data, compute their average and display it

```julia
    G1 = mat2grid(rand(128,128));
    G2 = mat2grid(rand(128,128));
    G3 = mat2grid(rand(128,128));
    Gavg = (G1 .+ G2 .+ G3) ./ 3;
    imshow(Gavg)
```

Here we introduced also the use of a module that does not exist in GMT, `imshow`, but one that is in fact a mockup
made with `grdimage` and `grdview` and with a set of defaults and guesswork that allows quick and easy display of
grids and images. It also opens the door for a more vast ensemble of tools that go beyond the use of pure
GMT syntax.

## Case 2. You are a new GMT user or one that wants to use long verbose options

The GMT terse syntax is extremely versatile but also more cryptical and less on the likes of current times
where *explicit is better*. So all of the one letter options in GMT modules were given an alias as well as
many of its arguments. But there are so many of them (options + sub-options) that this raises a problem of
documentation. Some modules have received an adapted version of the GMT official documentation but this is
such a huge task that many modules do not have one yet. Most modules have a on-line help (type `? prog_name`)
that maps the one letter option to its aliases (there often more than one alias). This still leaves, however,
the issue of how the sub-options have been expanded. This has been addressed for the modules that have so far
a Julia manual, but not for all the others. For those, the recommended way is to use the helper program
`gmthelp`. It lists the mapping between the options aliases (and, for some, the sub-options) and the
GMT syntax. Let's, see the example of the `plot` (`psxy`) module

```julia
    gmthelp(plot)
    Option: R, or region, or limits => GMTgrid | NamedTuple |Tuple | Array | String
    Option: J, or proj, or projection => NamedTuple | String
    Option: B, or frame, or axes, or xaxis, or yaxis, or zaxis, or axis2, or xaxis2, or yaxis2 => NamedTuple | String
    Option: a, or e, or f, or g, or l, or p, or t, or params => (Common options)
    Option: D, or shift, or offset => Tuple | String | Number | Bool [Possibly not yet expanded]
    Option: I, or intens => Tuple | String | Number | Bool [Possibly not yet expanded]
    Option: N, or no_clip, or noclip => Tuple | String | Number | Bool [Possibly not yet expanded]
    Option: A, or steps, or straight_lines => (x=?(x), y=?(y), meridian=?(m), parallel=?(p), )
    Option: F, or conn, or connection => (continuous=?(c), net=?(n), network=?(n), refpoint=?(r), ignore_hdr=Any(a), single_group=Any(f), segments=Any(s), segments_reset=Any(r), anchor=?(), )
    Option: C, or color, or cmap => GMTcpt | Tuple | Array | String | Number
    Option: G, or fill => NamedTuple | Tuple | Array | String | Number
    Option: G, or markerfacecolor, or MarkerFaceColor, or mc => NamedTuple | Tuple | Array | String | Number
    Option: L, or close, or polygon => (left=Any(+xl), right=Any(+xr), x0=?(+x), bot=Any(+yb), top=Any(+yt), y0=?(+y), sym=Any(+d), asym=Any(+D), envelope=Any(+b), pen=?(+p), )
    Option: W, or pen => NamedTuple | Tuple | String | Number
    Option: S, or symbol => (symb=?(1), size=?(), unit=?(1), )
```

Let's look for example at option **C** that is called `color` or `cmap` in the expanded form. It can take as argument
a `GMTcpt` argument (the example above), or a Tuple with the three (R,G,B) color elements with values between 0 and 255,
or in a Array form [R, G, B], or a String (*e.g.* color="color.cpt", or color="red"), or as a Number (color=200).

Let's also look at the **L** or `close` or `polygon` option. It says that this option can be expanded in form a
named tuple with keys like *bot*, *top*, *x0*, etc... (they describe how to connect first and last point). The *Any*
in sub-options like `bot=Any(+yb)` informs that *Any*thing will do and the `(+yb)` is the GMT terse syntax modifier.
This info is useful when one needs to consult the pure GMT documentation. On the other hand when we see `pen=?(+p)`
the `?` means that one have to give the required info. So, for example `polygon=(bot=true, pen=(1, :red))` means
"close the poly-line trough *ymin* and outline it with a red pen with 1 point thickness"

Other options end with `(Common options)`. This means they are options common to all GMT programs and that, for the
ones that are currently implemented, one can do

```julia
    gmthelp(:b)
    Option: b, or binary => (ncols=?(), type=?(), swapp_bytes=Any(w), little_endian=Any(+l), big_endian=?(+b), )
```

but for many we still get

```julia
    gmthelp(:i)
    Option: i, or incol => (Common option not yet expanded)
```

meaning we must use the terse syntax arguments in form of strings. *e.g.* `incol="0,2"` to read only first and
third column of input data.

Still other options end with `[Possibly not yet expanded]`. It means that sub-options have not yet received
aliases so you must use either arguments in string form or in Tuple form in case the input is numeric and GMT
expects numbers separated by slashes. For example (invented option) *shift=(1,2)* will translate to *s1/2*

The `plot` command is hugely vast, so a series of *avatars* have been derived from it. Namely, `lines`,
specialized in plotting lines only; `scater` & `scater3` for scatter plots; `bar` & `bar3`, for bar plots, 
`arrows` for drawing arrows; `plot3`, `ternary`, `plotyy`. They all share the same argument syntax that mimics
in many cases the matplotlib syntax with also many Matlab synonyms.

Examples

```julia
    # A Scatter plot
    scatter(rand(100),rand(100), markersize=rand(100), marker=:c, color=:ocean, zcolor=rand(100), figsize=15, alpha=50, Y=4, title="Scatter", show=true)
```

```julia
    # Colored bar plot
    bar(rand(15), color=:rainbow, figsize=(14,8), title="Colored bars", Y=3, show=true)
```

```julia
    # Arrow
    arrows([0.5 0.5 0 8], limits=(-0.1,3,0,2.5), figsize=(16,5), arrow=(len=2,stop=1,shape=0.5), pen=6, B="a WSrt", title="Arrow", show=true)
```


```julia
    # Peaks 3D bars
    G = GMT.peaks();    cmap = grd2cpt(G);      # Compute a colormap with the grid's data range
    bar3(G, lw=:thinnest, color=cmap, figsize=14, Y=5, show=true)
```

```julia
    # Contours
    G = GMT.peaks();
    grdcontour(G, color=makecpt(range=(-6,8,1)), pen="+c", figsize=16, region=(-3,3,-3,3), title="Contours", show=true)
```