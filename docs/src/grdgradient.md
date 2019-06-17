# grdgradient

	grdgradient(cmd0::String="", arg1=nothing; kwargs...)

Compute directional derivative or gradient from a grid

Description
-----------

Computes the directional derivative in a given direction (**azim**), or to find the direction (**slopegrid**) [and the magnitude (**find_dir**)] of the vector gradient of the data.

Estimated values in the first/last row/column of output depend on boundary conditions (see **interp**). 

Required Arguments
------------------

The 2-D gridded data set to be contoured.

Optional Arguments
------------------

- **A** or **azim** : -- *azim=azim* **|** *azim=(azim1, azim2)*\
    Azimuthal direction for a directional derivative; *azim* is the angle in the x,y plane measured in degrees positive clockwise from north (the +y direction) toward east (the +x direction). The negative of the directional derivative, *-[dz/dx sin(azim) + dz/dy cos(azim)]*, is found; negation yields positive values when the slope of z(x,y) is downhill in the *azim* direction, the correct sense for shading the illumination of an image (see [grdimage](@ref) and [grdview](@ref)) by a light source above the x,y plane shining from the *azim* direction. Optionally, supply two azimuths, **azim=(azim1, azim2)**, in which case the gradients in each of these directions are calculated and the one larger in magnitude is retained; this is useful for illuminating data with two directions of lineated structures, e.g., **azim=(0,270)** illuminates from the north (top) and west (left).  Finally, if *azim* is a file it must be a grid of the same domain, spacing and registration as *in\_grdfile* and we will update the azimuth at each output node when computing the directional derivatives.

- **G** or **outgrid** : -- *outgrid="gridname"*\
    Name of the output grid file for the directional derivative. Optional, use only when saving directly to a file.

- **D** or **find\_dir** : -- *find\_dir=true* **|** *find\_dir=:a* **|** *find\_dir=:c* **|** *find\_dir=:o* **|** *find\_dir=:n* **|** *find\_dir=acon*\
    Find the direction of the positive (up-slope) gradient of the data. To instead find the aspect (the down-slope direction), use **find\_dir=:a**. By default, directions are measured clockwise from north, as *azim* in **azim** above. Use **find\_dir=:c** to use conventional Cartesian angles measured counterclockwise from the positive x (east) direction. Use **find\_dir=:o** to report orientations (0-180) rather than directions (0-360). Use **find\_dir=:n** to add 90 degrees to all angles (e.g., to give local strikes of the surface). Note, you can combine two or more options by cating the single flgas in a word, (*e.g.* **find\_dir=:on**)

- **E** or **lambert** : -- *lambert=([simple=true, peucker=true, manip=true,] view=(azim,elev) [,ambient=val, difuse=val, specular=val, shine=val])*\
    Compute Lambertian radiance appropriate to use with [grdimage](@ref) and [grdview](@ref). The Lambertian Reflection assumes an ideal surface that reflects all the light that strikes it and the surface appears equally bright from all viewing directions. Here, *azim* and *elev* are the azimuth and elevation of the light vector. Optionally, supply *ambient* [0.55], *diffuse* [0.6], *specular* [0.4], or *shine* [10], which are parameters that control the reflectance properties of the surface. Default values are given in the brackets. Use **lambert=(simple=true, view=(azim,elev))** for a simpler Lambertian algorithm. Note that with this form you only have to provide azimuth and elevation. Alternatively, use **lambert=(peucker=true,)** for the Peucker piecewise linear approximation (simpler but faster algorithm; in this case the *azim* and *elev* are hardwired to 315 and 45 degrees. This means that even if you provide other values they will be ignored. The **lambert=(manip=true,)** uses another algorithm that gives results close to ESRI's hillshade but faster. In this case the azimuth and elevation are hardwired to 315 and 45 degrees.

- **N** or **norm** or **normalize** : -- *norm=([laplace=true, cauchy=true,] [amp=val,] [sigma=val, offset=val])*\
    Normalization. [Default is no normalization.] The actual gradients *g* are offset and scaled to produce normalized gradients *gn* with a maximum output magnitude of *amp*. If *amp* is not given, default *amp* = 1. If *offset* is not given, it is set to the average of *g*. **norm=true** yields *gn = amp ]* (g - offset)/max(abs(g - offset))*. **norm=(laplace=true,)** normalizes using a cumulative Laplace distribution yielding *gn* = *amp* \* (1.0 - exp(sqrt(2) \* (*g* - *offset*)/ *sigma*)), where *sigma* is estimated using the L1 norm of (*g* - *offset*) if it is not given. **norm=(cauchy=true,)** normalizes using a cumulative Cauchy distribution yielding *gn* = (2 \* *amp* / PI) \* atan( (*g* - *offset*)/ *sigma*) where *sigma* is estimated using the L2 norm of (*g* - *offset*) if it is not given. To use *offset* and/or *sigma* from a previous calculation, leave out the argument to the modifier(s) (*e.g.* set them to "") and see **save\_stats** for usage.

- **Q** or **save\_stats** : -- *save\_stats=:save* **|** *save\_stats=:read* **|** *save\_stats=:Read*\
    Controls how normalization via **norm** is carried out.  When multiple grids should be normalized the same way (i.e., with the same *offset* and/or *sigma*), we must pass these values via **norm**.  However, this is inconvenient if we compute these values from a grid. Use **save\_stats=:save** to save the results of *offset* and *sigma* to a statistics file; if grid output is not needed for this run then specify **outgrid=:none**. For subsequent runs, just use **save\_stats=:read** to read these values. Using **save\_stats=:Read** will read then delete the statistics file. See TILES for more information. (Warning: this option is available on GMT6 only)

- **R** or **region** or **limits** : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)* **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more\ 
    will select a subsection of working grid. If this subsection exceeds the boundaries of the grid, only the common region will be extracted. More at [limits](@ref)

- **S** or **slopegrid** :\
    Name of output grid file with scalar magnitudes of gradient vectors. Requires **find\_dir** but makes **outgrid** optional. 

- **V** or *verbose* : -- *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

Grid Distance Units
-------------------

If the grid does not have meter as the horizontal unit, append **+u**\ *unit* to the input file name to convert from the specified unit to meter. If your grid is geographic, convert distances to meters by supplying **colinfo=:g** instead.

Hints
-----

If you don't know what **norm** options to use to make an intensity file for [grdimage](@ref) and [grdview](@ref), a good first try is **norm=e0.6**.

Usually 255 shades are more than enough for visualization purposes. You can save 75% disk space by appending =nb/a to the output filename *outgrid*.

If you want to make several illuminated maps of subregions of a large data set, and you need the illumination effects to be consistent across all the maps, use the **norm** option and supply the same value of *sigma* and *offset* to **grdgradient** for each map. A good guess is *offset* = 0 and *sigma* found by `grdinfo` **-L2** or **-L1** applied to an unnormalized gradient grd.

If you simply need the *x*- or *y*-derivatives of the grid, use `grdmath`.

Tiles
-----

For very large datasets (or very large plots) you may need to break the job into multiple tiles. It is then important that the normalization of the intensities are handled the same way for each tile. By default, *offset* and *sigma* are recalculated for each tile. Hence, different tiles of the same large grid will compute different *offset* and *sigma* values. Thus, the intensity for the same directional slope will be different across the final map. This inconsistency can lead to visible changes in image appearance across tile seams. The way to ensure compatible results is to specify the same *offset* and *sigma* via the modifiers to **norm**. However, if these need to be estimated from the large grid then the **save\_stats** option can help: Run **grdgradient** on the full grid (or as large portion of the grid that your computer can handle) and specify **save\_stats=:save** to create a statistics file with the resulting *offset* and *sigma*. Then, for each of your grid tile calculations, give **norm=(offset="",)** and/or **norm=(sigma="",)** without arguments to **norm** and specify **save\_stats=:read**. This option will read the values from the hidden statistics file and use them in the normalization. If you use **save\_stats=:Read** for the final tile then the statistics file is removed after use.

Examples
--------

To make a file for illuminating the data in geoid.nc using exp- normalized gradients in the range [-0.6,0.6] imitating light sources in the north and west directions:

```julia
    G = grdgradient("geoid.nc", azim=(0,270), norm=(laplace=true, amp=0.6), Verbose=true)
```

To find the azimuth orientations of seafloor fabric in the file topo.nc:

```julia
    G = grdgradient("topo.nc", find_dir=:no);
```

To determine the offset and sigma suitable for normalizing the intensities from topo.nc, do

```julia
    grdgradient("topo.nc", azim=30, norm=:t0.6, save_stats=:save);
```

To use the previously determined offset and sigma to normalize the intensities in tile\_3.nc, do

```julia
    Gtile_3_int = grdgradient("tile_3.nc", azim=30, norm=(cauchy=true,offset="",sigma=""),save_stats=:read)
```

References
----------

Horn, B.K.P., Hill-Shading and the Reflectance Map, Proceedings of the
IEEE, Vol. 69, No. 1, January 1981, pp. 14-47.
(http://people.csail.mit.edu/bkph/papers/Hill-Shading.pdf)

