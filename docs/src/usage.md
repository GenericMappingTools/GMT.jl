# The monolitic usage

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

where *modulename* is a string with the name of a GMT module (e.g., *surface*, *grdimage*,
*psmeca*, or even a custom extension), while the *optionstring* is a text string with the options
passed to this module. If the module requires data inputs from the Julia environment, then these
are provided as optional comma-separated arguments following the option string. Should the module
produce output(s) then these are captured by assigning the result of gmt to one or more comma-separated
variables. Some modules do not require an option string or input objects, or neither, and some modules
do not produce any output objects.

In addition, it can also use two i/o modules that are irrelevant on the command line:
the *read* and *write* modules. These modules allow the toolbox to import and export any of the GMT
data types to and from external files. For instance, to import a grid from the file *relief.nc* we run

    G = gmt("read -Tg relief.nc");

We use the **-T** option to specify grid (g), image (i), PostScript (p), color palette (c), dataset (d)
or textset (t). Results kept in Julia can be written out at any time via the write module,
e.g., to save the grid Z to a file we use

    gmt("write model_surface.nc", Z);

Because GMT data tables often contain headers followed by many segments, each with their individual
segment headers, it is best to read such data using the read module since native Julia import functions
risk to choke on such headers.

## How input and output are assigned

Each GMT module knows what its primary input and output objects should be. Some modules only produce
output (e.g., *psbasemap* makes a basemap plot with axes annotations) while other modules only expect
input and do not return any items back (e.g., the write module writes the data object it is given to
a file). Typically, (i.e., on the command line) users must carefully specify the input filenames and
sometimes give these via a module option. Because users of this wrapper will want to provide input
from data already in memory and likewise wish to assign results to variables, the syntax between the
command line and Julia commands necessarily must differ. For example, here is a basic GMT command
that reads the time-series *raw_data.txt* and filters it using a 15-unit full-width (6 sigma) median filter:

    gmt filter1d raw_data.txt –Fm15 > filtered_data.txt

Here, the input file is given on the command line but input could instead come via the shell’s
standard input stream via piping. Most GMT modules that write tables will write these to the
shell’s output stream and users will typically redirect these streams to a file (as in our example)
or pipe the output into another process. When using GMT.jl there are no shell redirections available.
Instead, we wish to pass data to and from the MATLAB environment. If we assume that the content in
*raw_data.txt* exists in a array named *raw_data* and we wish to receive the filtered result
as a segment array named filtered, we would run the toolbox command

    filtered = gmt("filter1d -Fm15", raw_data);

This illustrates the main difference between command line and toolbox usage: Instead of
redirecting output to a file we return it to an internal object (here, a segment array) using
standard Julia assignments of output.

For data types where piping and redirection of output streams are inappropriate (including most
grid file formats) the GMT modules use option flags to specify where grids should be written.
Consider a GMT command that reads (x, y, z) triplets from the file depths.txt and produces an
equidistant grid using a Green’s function-based spline-in-tension gridding routine:

    gmt greenspline depths.txt -R-50/300/200/600 -I5 -D1 -St0.3 -Gbathy.nc

Here, the result of gridding Cartesian data (-D1) within the specified region (an equidistant
lattice from x from -50 to 300 and y from 200 to 600, both with increments of 5) using moderately
tensioned cubic splines (-St0.3) is written to the netCDF file *bathy.nc*. When using GMT.jl
we do not want to write a file but wish to receive the resulting grid as a new Julia variable.
Again, assuming we already loaded in the input data, the equivalent toolbox command is

    bathy = gmt("greenspline -R-50/300/200/600 -I5 -D1 -St0.3", depths);

Note that -G is no longer specified among the options. In this case the toolbox uses the GMT API
to determine that the primary output of greenspline is a grid and that this is specified via the
-G option. If no such option is given (or given without specifying a filename), then we instead
return the grid via memory, provided a left-side assignment is specified. GMT only allows this
behavior when called via an external API such as this toolbox: Not specifying the -G option on
the command line would result in an error message. However, it is perfectly fine to specify the
option -Gbathy.nc in Juliax – it simply means you are saving the result to a file instead
of returning it to Julia.

Some GMT modules can produce more than one output (here called a secondary outputs) or can read
more than one input type (i.e., secondary inputs). Secondary inputs or outputs are always
specified by explicit module options on the command line, e.g., *-Fpolygon.txt*. In these cases,
the ``gmt()`` enforces the following rules: When a secondary input is passed as an object then we
must specify the corresponding option flag but provide no file argument (e.g., just *-F* in the
above case). Likewise, for secondary output we supply the option flag and add additional objects
to the left-hand side of the assignment. All secondary items, whether input or output, must appear
after all primary items, and if more than one secondary item is given then their order must match
the order of the corresponding options in optionstring.

Here are two examples contrasting the GMT command line versus ``gmt()`` usage. In the first example
we wish to determine all the data points in the file *all_points.txt* that happen to be located inside
the polygon specified in the file *polygon.txt*. On the command line this would be achieved by

    gmt select points.txt -Fpolygon.txt > points_inside.txt

while in Julia (assuming the points and polygon already reside in memory) we would run

    inside = gmt("gmtselect -F", points, polygon);

Here, the points object must be listed first since it is the primary data expected.

Our second example considers the joining of line segments into closed polygons. We wish to create
one file with all closed polygons and another file with any remaining disjointed lines. Not expecting
perfection, we allow segment end-points closer than 0.1 units to be connected. On the command line
we would run

    gmt connect all_segments.txt -Cclosed.txt -T0.1 > rest.txt

where *all_segments.txt* are the input lines, closed.txt is the file that will hold closed polygons
made from the relevant lines, while any remaining lines (i.e., open polygons) are written to standard
output and redirected to the file rest.txt. Equivalent toolbox usage would be

    all = gmt("read -Td all_segments.txt");
    rest, closed = gmt("gmtconnect -T0.1 -C", all);

Note the primary output (here rest) must be listed before any secondary outputs (here closed)
in the left-hand side of the assignment.

So far, the toolbox has been able to understand where inputs and outputs objects should be inserted,
provided we follow the rules introduced above. However, there are two situations where more
information must be provided. The first situation involves two GMT modules that allow complete
freedom in how arguments are passed. These are gmtmath and grdmath, our reverse polish notation
calculators for tables and grids, respectively. While the command-line versions require placement
of arguments in the right order among the desired operators, the toolbox necessarily expects all
inputs at the end of the function call. Hence we must assist the toolbox command by placing markers
where the input arguments should be used; the marker we chose is the question mark (?). We will
demonstrate this need using an example of grdmath. Imagine that we have created two separate grids:
*kei.nc* contains an evaluation of the radial *z = bei(r)* Kelvin-Bessel function while *cos.nc*
contains a cylindrical undulation in the x-direction. We create these two grids on the command line by

    gmt grdmath -R-4/4/-4/4 -I256+ X Y HYPOT KEI = kei.nc
    gmt grdmath -R -I256+ X COS = cos.nc

Later, we decide we need pi plus the product of these two grids, so we compute

    gmt grdmath kei.nc cos.nc MUL PI ADD = answer.nc

In Julia the first two commands are straightforward:

    kei = gmt("grdmath -R-4/4/-4/4 -I256+ X Y HYPOT KEI");
    C   = gmt("grdmath -R -I256+ X COS");

but when time comes to perform the final calculation we cannot simply do

    answer = gmt("grdmath MUL PI ADD", kei, C);

since grdmath would not know where kei and C should be put in the context of the operators MUL and ADD.
We could probably teach grdmath to discover the only possible solution since the MUL operator requires
two operands but none are listed on the command line. The logical choice then is to take kei and C as
operands. However, in the general case it may not be possible to determine a unique layout, but more
importantly it is simply too confusing to separate all operators from their operands (other than
constants) as we would lose track of the mathematical operation we are performing. For this reason,
we will assist the module by inserting question marks where we wish the module to use the next unused
input object in the list. Hence, the valid toolbox command actually becomes

    answer = gmt("grdmath ? ? MUL PI ADD", kei, C);

Of course, all these calculations could have been done at once with no input objects but often we
reuse results in different contexts and then the markers are required. The second situation arises
if you wish to use a grid as argument to the -R option (i.e., to set the current region to that of
the grid). On the command line this may look like

    gmt pscoast -Reurope.nc -JM5i –P -Baf -Gred > map.ps

However, in the toolbox we cannot simply supply -R with no argument since that is already an established
shorthand for selecting the previously specified region. The solution is to supply –R?. Assuming our
grid is called europe then the toolbox command would become

    map = gmt("pscoast -R? -JM5i -P -Baf -Gred", europe);

