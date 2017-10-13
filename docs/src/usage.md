# The multiple usages

Access to GMT from Julia is accomplished via a main function (also called gmt), which offers full
access to all of GMT’s ~140 modules as well as fundamental import, formatting, and export of GMT
data objects. Internally, the GMT5 C API defines six high-level data structures (GMT6 will define only five)
that handle input and output of data via GMT modules. These are data tables (representing one or more
sets of points, lines, or polygons), grids (2-D equidistant data matrices), raster images (with 1–4
color bands), raw PostScript code, text tables (free-form text/data mixed records) and color palette
tables (i.e., color maps). Correspondingly, we have defined five data structures that we use at the
interface between GMT and Julia via the gmt function. The GMT.jl wrapper is responsible for translating
between the GMT structures and native Julia structures, which are:

- **Grids**: Many tools consider equidistant grids a particular data type and numerous file formats
  exist for saving such data. Because GMT relies on GDAL we are able to read and write almost
  all such formats in addition to a native netCDF4 format that complies with both the COARDS
  and CF netCDF conventions. We have designed a native Julia grid structure [`GMTgrid`](@ref)
  that holds header information from the GMT grid as well as the data matrix representing the
  gridded values. These structures may be passed to GMT modules that expect grids and are
  returned from GMT modules that produce such grids. In addition, we supply a function to
  convert a matrix and some metadata into a grid structure.

- **Images**: The raster image shares many characteristics with the grid structure except the
  bytes representing each node reflect gray shade, color bands (1, 3, or 4 for indexed, RGB and
  RGBA, respectively), and possibly transparency values. We therefore represent images in another
  native structure [`GMTimage`](@ref) that among other items contains three components: The image
  matrix, a color map (present for indexed images only), and an alpha matrix (for images specifying
  transparency on a per-pixel level). As for grids, a wrapper function creating the correct structure
  is available.

- **Segments**: GMT considers point, line, and polygon data to be organized in one or more segments
  in a data table. Modules that return segments uses a native Julia segment structure [`GMTdataset`](@ref)
  that holds the segment data, which may be either numerical, text, or both; it also holds a segment
  header string which GMT uses to pass metadata. Thus, GMT modules returning segments will typically
  produce arrays of segments and you may pass these to any other module expecting points, lines, or
  polygons or use them directly in Julia. Since a matrix is one fundamental data type you can also
  pass a matrix directly to GMT modules as well. Consequently, it is very easy to pass data from
  Julia into GMT modules that process data tables as well as to receive data segments from GMT modules
  that process and produce data tables as output.

- **Color palettes**: GMT uses its flexible Color Palette Table (CPT) format to describe how the
  color (or pattern) of symbols, lines, polygons or grids should vary as a function of a state variable.
  In Julia, this information is provided in another structure [`GMTcpt`](@ref) that holds the color
  map as well as an optional alpha array for transparency values. Like grids, these structures may
  be passed to GMT modules that expect CPTs and will be returned from GMT modules that normally
  would produce CPT files.

- **PostScript**: While most users of the GMT.jl wrapper are unlikely to manipulate PostScript
  directly, it allows for the passing of PostScript via another data structure [`GMTps`](@ref).

Given this design the Julia wrapper is designed to work in two distinct ways. The first way
is the more feature reach and follows closely the GMT usage from shell(s) command line but still
provide all the facilities of the Julia language. In this mode all **GMT** options are put in
a single text string that is passed, plus the data itself when it applies, to the ``gmt()`` command.
This function is invoked with the syntax (where the brackets mean optional parameters):

    [output objects] = gmt("modulename optionstring" [, input objects]);

Let see an example to reproduce the CookBook example of an Hemisphere map using a Azimuthal projection.

    gmt("pscoast -Rg -JA280/30/3.5i -Bg -Dc -A1000 -Gnavy -P > GMT_lambert_az_hemi.ps")

but that is not particularly interesting as after all we could do the exact same thing on the a
shell command line. Things start to get interesting when we can send data *in* and *out* from
Julia to **GMT**. So, consider the following example


