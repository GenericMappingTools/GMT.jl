var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#GMT.jl-Documentation-1",
    "page": "Home",
    "title": "GMT.jl Documentation",
    "category": "section",
    "text": ""
},

{
    "location": "#Index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": ""
},

{
    "location": "#GMT.psxy",
    "page": "Home",
    "title": "GMT.psxy",
    "category": "Function",
    "text": "psxy(cmd0::String=\"\", arg1=[]; caller=[], data=[], fmt=\"\", K=false, O=false,\n     first=true, kwargs...)\n\nreads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines, polygons, or symbols at those locations on a map.\n\nFull option list at psxy\n\nParameters\n\nA : straight_lines : – Str –     By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use the -A flag.\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : – Str –   Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.   -C\nD : offset : – Str –  'dx/dy'   Offset the plot symbol or line locations by the given amounts dx/dy.\nE : error_bars : – Str –   '[x|y|X|Y][+a][+cl|f][+n][+wcap][+ppen]'   Draw symmetrical error bars.   -E\nF : conn : connection : – Str –   '[c|n|r][a|f|s|r|refpoint]'   Alter the way points are connected   -F\nG : fill : markerfacecolor : MarkerFaceColor : – Str –   Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the   color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use   'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow   -G\nI : intens : – Str or number –   Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.\nL : closed_polygon : – Str –    '[+b|d|D][+xl|r|x0][+yl|r|y0][+ppen]'   Force closed polygons.    -L\nN : no_clip : –- Str or [] –   '[c|r]'   Do NOT clip symbols that fall outside map border \nP : portrait : –- Bool or [] –   Tell GMT to NOT draw in portriat mode (that is, make a Landscape plot)\nS : symbol : marker : Marker : – Str –  '[symbol][size[u]]'   Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines).    -S   Alternatively select a sub-set of symbols using the aliases: marker or Marker and values:\n-, x_dash\n+, plus\na, *, star\nc, circle\nd, diamond\ng, octagon\nh, hexagon\ni, v, inverted_tri\nn, pentagon\np, ., point\nr, rectangle\ns, square\nt, ^, triangle\nx, cross\ny, y_dash\nW : line_attribs : markeredgecolor : MarkerEdgeColor : – Str –  '[pen][attr]'   Set pen attributes for lines or the outline of symbols   -W   WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.   If your plot has polygons and symbols, use W or line_attribs for the polygons and   markeredgecolor or MarkerEdgeColor for filling the symbols. Similar to S above.\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\na : aspatial : – Str –\nbi : binary_in : – Str –\ndi : nodata_in : – Str –\ne : patern : – Str –\nf : colinfo : – Str –\ng : gaps : – Str –\nh : headers : – Str –\ni : input_col : – Str –\np : view : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.pscoast",
    "page": "Home",
    "title": "GMT.pscoast",
    "category": "Function",
    "text": "pscoast(cmd0::String=\"\"; fmt=\"\", clip=[], K=false, O=false, first=true, kwargs...)\n\nPlot continents, shorelines, rivers, and borders on maps. Plots grayshaded, colored, or textured land-masses [or water-masses] on maps and [optionally] draws coastlines, rivers, and political boundaries. A map projection must be supplied.\n\nFull option list at pscoast\n\nParameters\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nA : area : – Str or Number –   Features with an area smaller than min_area in km^2 or of   hierarchical level that is lower than min_level or higher than   max_level will not be plotted.   -A\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : river_fill : – Str –   Set the shade, color, or pattern for lakes and river-lakes.   -C\nD : res : resolution : – Str –   Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, and (c)rude).   -D\nE : ECW : – Str –  Tuple(Str, Str); Tuple(\"code\", (pen)), ex: (\"PT\",(0.5,\"red\",\"–\")); Tuple((...),(...),...)   Select painting or dumping country polygons from the Digital Chart of the World   -E\nF : box : – Str –   Draws a rectangular border around the map scale or rose.   -F\nG : land : – Str –   Select filling or clipping of “dry” areas.   -G\nI : rivers : – Str –   Draw rivers. Specify the type of rivers and [optionally] append pen attributes.   -I\nL : map_scale : – Str –   Dtraw a map scale.\nM : dump : – Str –   Dumps a single multisegment ASCII output. No plotting occurs.   -M\nN : borders : – Str –   Draw political boundaries. Specify the type of boundary and [optionally] append pen attributes   -N\nP : portrait : –- Bool or [] –   Tell GMT to NOT draw in portriat mode (that is, make a Landscape plot)\nS : water : – Str –   Select filling or clipping of “wet” areas.   -S\nTd : rose` : – Str –   Draws a map directional rose on the map at the location defined by the reference and anchor points.   -Td\nTm : compass : – Str –   Draws a map magnetic rose on the map at the location defined by the reference and anchor points.   -Tm\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nW : shore : – Str –   Draw shorelines [Default is no shorelines]. Append pen attributes.   -W\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\nbo : binary_out : – Str –\np : view : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.psscale",
    "page": "Home",
    "title": "GMT.psscale",
    "category": "Function",
    "text": "psscale(cmd0::String=\"\", arg1=[]; fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nPlots gray scales or color scales on maps.\n\nFull option list at psscale\n\nD : position : – Str –   Defines the reference point on the map for the color scale using one of four coordinate systems.   -D\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : cmap : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nF : box : – Str –   Draws a rectangular border around the scale.   -F\nG : truncate : – Str –     Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.   -G\nI : shade : – Number or [] –     Add illumination effects.   -I\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nJz : z_axis : – Str –   Set z-axis scaling.    -Jz\nL : equal_size : – Str or [] –   Gives equal-sized color rectangles. Default scales rectangles according to the z-range in the CPT.   -L\nM : monochrome : – Bool or [] –   Force conversion to monochrome image using the (television) YIQ transformation.   -M\nN : dpi : – Str or number –   Controls how the color scale is represented by the PostScript language.   -N\nQ : log : – Str –   Selects a logarithmic interpolation scheme [Default is linear].   -Q\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nS : nolines : – Bool or [] –   Do not separate different color intervals with black grid lines.\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nW : zscale : – Number –   Multiply all z-values in the CPT by the provided scale.   -W\nZ : zfile : – Str –   File with colorbar-width per color entry.   -Z\n\n\n\n"
},

{
    "location": "#GMT.grdimage",
    "page": "Home",
    "title": "GMT.grdimage",
    "category": "Function",
    "text": "grdimage(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],\n		 fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nProduces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning them a gray-shade (or color) based on the z-value.\n\nFull option list at grdimage\n\nParameters\n\nA : img_out : image_out : – Str –     Save an image in a raster format instead of PostScript.   -A\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : cmap : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nD : img_in : image_in : – Str or [] –     Specifies that the grid supplied is an image file to be read via GDAL.   -D\nE : dpi : – Int or [] –     Sets the resolution of the projected grid that will be created.   -E\nG : – Str or Int –   -G\nI : shade : intensity : intensfile : – Str or GMTgrid –   Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,   or a grdgradient shading flags.   -I\nM : monochrome : – Bool or [] –   Force conversion to monochrome image using the (television) YIQ transformation.   -M\nN : noclip : – Bool or [] –   Do not clip the image at the map boundary.   -N\nQ : nan_t : nan_alphan : – Bool or [] –   Make grid nodes with z = NaN transparent, using the colormasking feature in PostScript Level 3.\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\nf : colinfo : – Str –\nn : interp : – Str –     -n\np : view : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.grdcontour",
    "page": "Home",
    "title": "GMT.grdcontour",
    "category": "Function",
    "text": "grdcontour(cmd0::String=\"\", arg1=[]; data=[], fmt=\"\", K=false, O=false,\n           first=true, kwargs...)\n\nReads a 2-D grid file or a GMTgrid type and produces a contour map by tracing each contour through the grid.\n\nFull option list at pscontour\n\nParameters\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nA : annot : – Str or Number –   Save an image in a raster format instead of PostScript.   -A\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : cont : contour : – Str or Number –   Contours to be drawn.   -C\nD : dump : – Str –   Dump contours as data line segments; no plotting takes place.   -D\nF : force : – Str or [] –   Force dumped contours to be oriented so that higher z-values are to the left (-Fl [Default]) or right.   -F\nG : labels : – Str –   Controls the placement of labels along the quoted lines.   -G\nJz : z_axis : – Str –   Set z-axis scaling.    -Jz\nL : range : – Str –   Limit range: Do not draw contours for data values below low or above high.   -L\nQ : cut : – Str or Number –   Do not draw contours with less than cut number of points.   -Q\nS : smooth : – Number –   Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval.   -S\nT : ticks : – Str –   Draw tick marks pointing in the downward direction every gap along the innermost closed contours.   -T\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nW : pen : – Str or Number –   Sets the attributes for the particular line.   -W\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\nZ : scale : – Str –   Use to subtract shift from the data and multiply the results by factor before contouring starts.   -Z\nbo : binary_out : – Str –\ndo : nodata_out : – Number –     Examine all output columns and if any item equals NAN substitute it with     the chosen missing data value     -do\ne : patern : – Str –\nf : colinfo : – Str –\nh : headers : – Str –\np : view : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.grdview",
    "page": "Home",
    "title": "GMT.grdview",
    "category": "Function",
    "text": "grdview(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],\n        fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nReads a 2-D grid file and produces a 3-D perspective plot by drawing a mesh, painting a colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons to a raster image.\n\nFull option list at grdview\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : cmap : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nG : drapefile : – Str or GMTgrid or a Tuple with 3 GMTgrid types –   Drape the image in drapefile on top of the relief provided by relief_file.   -G\nI : shade : intensity : intensfileintens : – Str or GMTgrid –   Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,   or a grdgradient shading flags.   -I\nJz : z_axis : – Str –   Set z-axis scaling.    -Jz\nN : plane : – Str or Int –   Draws a plane at this z-level.   -N\nQ : type : – Str or Int –   Specify m for mesh plot, s* for surface, **i for image.   -Q\nS : smooth : – Number –   Smooth the contours before plotting.   -S\nT : no_interp : – Str –   Plot image without any interpolation.   -T\nW : contour : mesh : facade : – Str –   Draw contour, mesh or facade. Append pen attributes.   -W\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\nf : colinfo : – Str –\nn : interp : – Str –     -n\np : view : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.makecpt",
    "page": "Home",
    "title": "GMT.makecpt",
    "category": "Function",
    "text": "makecpt(cmd0::String=\"\", arg1=[]; data=[], kwargs...)\n\nMake static color palette tables (CPTs).\n\nFull option list at makecpt\n\nA : alpha : transparency : – Str –   Sets a constant level of transparency (0-100) for all color slices.   -A\nC : color : cmap : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nD : – Str or [] –   Select the back- and foreground colors to match the colors for lowest and highest   z-values in the output CPT. -D\nE : data_levels : – Int or [] –   Implies reading data table(s) from file or arrays. We use the last data column to   determine the data range   -E\nF : force : – Str –   Force output CPT to written with r/g/b codes, gray-scale values or color name.   -F\nG : truncate : – Str –   Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.   -G\nI : inverse : reverse : – Str –   Reverse the sense of color progression in the master CPT.   -I\nN : – Bool or [] –   Do not write out the background, foreground, and NaN-color fields.\nQ : log : – Str –   Selects a logarithmic interpolation scheme [Default is linear].   -Q\nT : range : – Str –   Defines the range of the new CPT by giving the lowest and highest z-value and interval.   -T\nW : wrap : categorical : – Bool or [] –   Do not interpolate the input color table but pick the output colors starting at the   beginning of the color table, until colors for all intervals are assigned.   -W\nZ : continuous : – Bool or [] –   Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].   -Z\n\n\n\n"
},

{
    "location": "#Functions-1",
    "page": "Home",
    "title": "Functions",
    "category": "section",
    "text": "DocTestSetup = quote\n    using GMT\nendpsxy(cmd0::String=\"\", arg1=[]; caller=[], data=[], fmt=\"\",\n     K=false, O=false, first=true, kwargs...)\n\npscoast(cmd0::String=\"\"; fmt=\"\", clip=[], K=false, O=false, first=true, kwargs...)\n\npsscale(cmd0::String=\"\", arg1=[]; fmt=\"\", K=false, O=false, first=true, kwargs...)\n\ngrdimage(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],\n         fmt=\"\", K=false, O=false, first=true, kwargs...)\n\ngrdcontour(cmd0::String=\"\", arg1=[]; data=[], fmt=\"\",\n           K=false, O=false, first=true, kwargs...)\n\ngrdview(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],\n        fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nmakecpt(cmd0::String=\"\", arg1=[]; data=[], kwargs...)"
},

{
    "location": "examples/#",
    "page": "Some examples",
    "title": "Some examples",
    "category": "page",
    "text": ""
},

{
    "location": "examples/#Examples-1",
    "page": "Some examples",
    "title": "Examples",
    "category": "section",
    "text": ""
},

{
    "location": "examples/#Here's-the-\"Hello-World\"-1",
    "page": "Some examples",
    "title": "Here's the \"Hello World\"",
    "category": "section",
    "text": "using GMT\nplot(collect(1:10),rand(10), lw=1, lc=\"blue\", fmt=\"png\", marker=\"square\",\n     markeredgecolor=0, size=0.2, markerfacecolor=\"red\", title=\"Hello World\",\n     x_label=\"Spoons\", y_label=\"Forks\", show=true)(Image: \"Hello world\")A few notes about this example. Because we didn't specify the figure size (with the figsize keyword) a default value of 12x8 cm (not counting labels and title) was used. The fmt=png selected the PNG format. The show=true is needed to show the image at the end.But now we want an image made up with two layers of data. And we are going to plot on the sphere (the Earth). For that we will need to use the pscoast program to plot the Earth and append some curvy lines."
},

{
    "location": "examples/#And-the-\"Hello-Round-World\"-1",
    "page": "Some examples",
    "title": "And the \"Hello Round World\"",
    "category": "section",
    "text": "x = linspace(0, 2pi,180); seno = sin.(x/0.2)*45;\npscoast(region=\"g\", proj=\"A300/30/6c\", frame=\"g\", resolution=\"c\", land=\"navy\",\n        fmt=\"png\")\n\nplot!(collect(x)*60, seno, lw=0.5, lc=\"red\", fmt=\"png\", marker=\"circle\",\n      markeredgecolor=0, size=0.05, markerfacecolor=\"cyan\", show=true)(Image: \"Hello round world\")Note that now the first command, the pscoast, does not have the show keyword. It means we are here creating the first layer but we don't want to see it just yet. The second command uses the ! variation of the plot function, which means that we are appending to a previous plot, and uses the show=true because we are donne with this figure."
},

{
    "location": "examples/#Color-images-1",
    "page": "Some examples",
    "title": "Color images",
    "category": "section",
    "text": "Color images are made with grdimage which takes the usual common options and a color map. It operates over grids or images. The next example shows how to create a color appropriate for the grid's z range, plot the image and add a color scale. We use here the data keyword to tell the program to load the grid from a file. The  before the tut_relief.nc file name instructs GMT to download the file from its server on the first usage and save it in a cache dir. See the GMT tuturial for more details about what the arguments mean.topo = makecpt(color=\"rainbow\", range=\"1000/5000/500\", continuous=true);\ngrdimage(\"@tut_relief.nc\", shade=\"+ne0.8+a100\", proj=\"M12c\", frame=\"a\", fmt=\"jpg\",\n         color=topo)\npsscale!(position=\"jTC+w5i/0.25i+h+o0/-1i\", region=\"@tut_relief.nc\", color=topo,\n         frame=\"y+lm\", fmt=\"jpg\", show=1)(Image: \"Hello shaded world\")"
},

{
    "location": "examples/#Perspective-view-1",
    "page": "Some examples",
    "title": "Perspective view",
    "category": "section",
    "text": "We will make a perspective, color-coded view of the US Rockies from the southeast.grdview(\"@tut_relief.nc\", proj=\"M12c\", JZ=\"1c\", shade=\"+ne0.8+a100\", view=\"135/30\",\n        frame=\"a\", fmt=\"jpg\", color=\"topo\", Q=\"i100\", show=1)(Image: \"Hello 3D view world\")"
},

{
    "location": "usage/#",
    "page": "The manual",
    "title": "The manual",
    "category": "page",
    "text": ""
},

{
    "location": "usage/#The-monolitic-usage-1",
    "page": "The manual",
    "title": "The monolitic usage",
    "category": "section",
    "text": "Access to GMT from Julia is accomplished via a main function (also called gmt), which offers full access to all of GMT’s ~140 modules as well as fundamental import, formatting, and export of GMT data objects. Internally, the GMT5 C API defines six high-level data structures (GMT6 will define only five) that handle input and output of data via GMT modules. These are data tables (representing one or more sets of points, lines, or polygons), grids (2-D equidistant data matrices), raster images (with 1–4 color bands), raw PostScript code, text tables (free-form text/data mixed records) and color palette tables (i.e., color maps). Correspondingly, we have defined five data structures that we use at the interface between GMT and Julia via the gmt function. The GMT.jl wrapper is responsible for translating between the GMT structures and native Julia structures, which are:Grids: Many tools consider equidistant grids a particular data type and numerous file formats exist for saving such data. Because GMT relies on GDAL we are able to read and write almost all such formats in addition to a native netCDF4 format that complies with both the COARDS and CF netCDF conventions. We have designed a native Julia grid structure GMTgrid that holds header information from the GMT grid as well as the data matrix representing the gridded values. These structures may be passed to GMT modules that expect grids and are returned from GMT modules that produce such grids. In addition, we supply a function to convert a matrix and some metadata into a grid structure.\nImages: The raster image shares many characteristics with the grid structure except the bytes representing each node reflect gray shade, color bands (1, 3, or 4 for indexed, RGB and RGBA, respectively), and possibly transparency values. We therefore represent images in another native structure GMTimage that among other items contains three components: The image matrix, a color map (present for indexed images only), and an alpha matrix (for images specifying transparency on a per-pixel level). As for grids, a wrapper function creating the correct structure is available.\nSegments: GMT considers point, line, and polygon data to be organized in one or more segments in a data table. Modules that return segments uses a native Julia segment structure GMTdataset that holds the segment data, which may be either numerical, text, or both; it also holds a segment header string which GMT uses to pass metadata. Thus, GMT modules returning segments will typically produce arrays of segments and you may pass these to any other module expecting points, lines, or polygons or use them directly in Julia. Since a matrix is one fundamental data type you can also pass a matrix directly to GMT modules as well. Consequently, it is very easy to pass data from Julia into GMT modules that process data tables as well as to receive data segments from GMT modules that process and produce data tables as output.\nColor palettes: GMT uses its flexible Color Palette Table (CPT) format to describe how the color (or pattern) of symbols, lines, polygons or grids should vary as a function of a state variable. In Julia, this information is provided in another structure GMTcpt that holds the color map as well as an optional alpha array for transparency values. Like grids, these structures may be passed to GMT modules that expect CPTs and will be returned from GMT modules that normally would produce CPT files.\nPostScript: While most users of the GMT.jl wrapper are unlikely to manipulate PostScript directly, it allows for the passing of PostScript via another data structure GMTps.Given this design the Julia wrapper is designed to work in two distinct ways. The first way, referred as the monolitic, is the more feature reach and follows closely the GMT usage from shell(s) command line but still provide all the facilities of the Julia language. See the Monolitic for the Reference on how to use the Package.\nThe second way uses an upper level set of functions that abstract aspects that make the monolitic usage more complex. It provides an interface to some of the GMT modules using a option=val list type syntax. This makes it more appropriate for newcommers but it won't release you from understanding the monolitic way. See the By Modules"
},

{
    "location": "man/monolitic/#",
    "page": "Monolitic",
    "title": "Monolitic",
    "category": "page",
    "text": ""
},

{
    "location": "man/monolitic/#Monolitic-1",
    "page": "Monolitic",
    "title": "Monolitic",
    "category": "section",
    "text": "In this mode all GMT options are put in a single text string that is passed, plus the data itself when it applies, to the gmt() command. This function is invoked with the syntax (where the brackets mean optional parameters):[output objects] = gmt(\"modulename optionstring\" [, input objects]);where modulename is a string with the name of a GMT module (e.g., surface, grdimage, psmeca, or even a custom extension), while the optionstring is a text string with the options passed to this module. If the module requires data inputs from the Julia environment, then these are provided as optional comma-separated arguments following the option string. Should the module produce output(s) then these are captured by assigning the result of gmt to one or more comma-separated variables. Some modules do not require an option string or input objects, or neither, and some modules do not produce any output objects.In addition, it can also use two i/o modules that are irrelevant on the command line: the read and write modules. These modules allow to import and export any of the GMT data types to and from external files. For instance, to import a grid from the file relief.nc we runG = gmt(\"read -Tg relief.nc\");We use the -T option to specify grid (g), image (i), PostScript (p), color palette (c), dataset (d) or textset (t). Results kept in Julia can be written out at any time via the write module, e.g., to save the grid Z to a file we usegmt(\"write model_surface.nc\", Z);Because GMT data tables often contain headers followed by many segments, each with their individual segment headers, it is best to read such data using the read module since native Julia import functions risk to choke on such headers."
},

{
    "location": "man/monolitic/#How-input-and-output-are-assigned-1",
    "page": "Monolitic",
    "title": "How input and output are assigned",
    "category": "section",
    "text": "Each GMT module knows what its primary input and output objects should be. Some modules only produce output (e.g., psbasemap makes a basemap plot with axes annotations) while other modules only expect input and do not return any items back (e.g., the write module writes the data object it is given to a file). Typically, (i.e., on the command line) users must carefully specify the input filenames and sometimes give these via a module option. Because users of this wrapper will want to provide input from data already in memory and likewise wish to assign results to variables, the syntax between the command line and Julia commands necessarily must differ. For example, here is a basic GMT command that reads the time-series raw_data.txt and filters it using a 15-unit full-width (6 sigma) median filter:gmt filter1d raw_data.txt –Fm15 > filtered_data.txtHere, the input file is given on the command line but input could instead come via the shell’s standard input stream via piping. Most GMT modules that write tables will write these to the shell’s output stream and users will typically redirect these streams to a file (as in our example) or pipe the output into another process. When using GMT.jl there are no shell redirections available. Instead, we wish to pass data to and from the MATLAB environment. If we assume that the content in raw_data.txt exists in a array named raw_data and we wish to receive the filtered result as a segment array named filtered, we would run the commandfiltered = gmt(\"filter1d -Fm15\", raw_data);This illustrates the main difference between command line and Julia usage: Instead of redirecting output to a file we return it to an internal object (here, a segment array) using standard Julia assignments of output.For data types where piping and redirection of output streams are inappropriate (including most grid file formats) the GMT modules use option flags to specify where grids should be written. Consider a GMT command that reads (x, y, z) triplets from the file depths.txt and produces an equidistant grid using a Green’s function-based spline-in-tension gridding routine:gmt greenspline depths.txt -R-50/300/200/600 -I5 -D1 -St0.3 -Gbathy.ncHere, the result of gridding Cartesian data (-D1) within the specified region (an equidistant lattice from x from -50 to 300 and y from 200 to 600, both with increments of 5) using moderately tensioned cubic splines (-St0.3) is written to the netCDF file bathy.nc. When using GMT.jl we do not want to write a file but wish to receive the resulting grid as a new Julia variable. Again, assuming we already loaded in the input data, the equivalent command isbathy = gmt(\"greenspline -R-50/300/200/600 -I5 -D1 -St0.3\", depths);Note that -G is no longer specified among the options. In this case the wrapper uses the GMT API to determine that the primary output of greenspline is a grid and that this is specified via the -G option. If no such option is given (or given without specifying a filename), then we instead return the grid via memory, provided a left-side assignment is specified. GMT only allows this behavior when called via an external API such as this wrapper: Not specifying the -G option on the command line would result in an error message. However, it is perfectly fine to specify the option -Gbathy.nc in Julia – it simply means you are saving the result to a file instead of returning it to Julia.Some GMT modules can produce more than one output (here called a secondary outputs) or can read more than one input type (i.e., secondary inputs). Secondary inputs or outputs are always specified by explicit module options on the command line, e.g., -Fpolygon.txt. In these cases, the gmt() enforces the following rules: When a secondary input is passed as an object then we must specify the corresponding option flag but provide no file argument (e.g., just -F in the above case). Likewise, for secondary output we supply the option flag and add additional objects to the left-hand side of the assignment. All secondary items, whether input or output, must appear after all primary items, and if more than one secondary item is given then their order must match the order of the corresponding options in optionstring.Here are two examples contrasting the GMT command line versus gmt() usage. In the first example we wish to determine all the data points in the file all_points.txt that happen to be located inside the polygon specified in the file polygon.txt. On the command line this would be achieved bygmt select points.txt -Fpolygon.txt > points_inside.txtwhile in Julia (assuming the points and polygon already reside in memory) we would runinside = gmt(\"gmtselect -F\", points, polygon);Here, the points object must be listed first since it is the primary data expected.Our second example considers the joining of line segments into closed polygons. We wish to create one file with all closed polygons and another file with any remaining disjointed lines. Not expecting perfection, we allow segment end-points closer than 0.1 units to be connected. On the command line we would rungmt connect all_segments.txt -Cclosed.txt -T0.1 > rest.txtwhere all_segments.txt are the input lines, closed.txt is the file that will hold closed polygons made from the relevant lines, while any remaining lines (i.e., open polygons) are written to standard output and redirected to the file rest.txt. Equivalent Julia usage would beall = gmt(\"read -Td all_segments.txt\");\nrest, closed = gmt(\"gmtconnect -T0.1 -C\", all);Note the primary output (here rest) must be listed before any secondary outputs (here closed) in the left-hand side of the assignment.So far, the gmt() function has been able to understand where inputs and outputs objects should be inserted, provided we follow the rules introduced above. However, there are two situations where more information must be provided. The first situation involves two GMT modules that allow complete freedom in how arguments are passed. These are gmtmath and grdmath, our reverse polish notation calculators for tables and grids, respectively. While the command-line versions require placement of arguments in the right order among the desired operators, the gmt() necessarily expects all inputs at the end of the function call. Hence we must assist the command by placing markers where the input arguments should be used; the marker we chose is the question mark (?). We will demonstrate this need using an example of grdmath. Imagine that we have created two separate grids: kei.nc contains an evaluation of the radial z = bei(r) Kelvin-Bessel function while cos.nc contains a cylindrical undulation in the x-direction. We create these two grids on the command line bygmt grdmath -R-4/4/-4/4 -I256+ X Y HYPOT KEI = kei.nc\ngmt grdmath -R -I256+ X COS = cos.ncLater, we decide we need pi plus the product of these two grids, so we computegmt grdmath kei.nc cos.nc MUL PI ADD = answer.ncIn Julia the first two commands are straightforward:kei = gmt(\"grdmath -R-4/4/-4/4 -I256+ X Y HYPOT KEI\");\nC   = gmt(\"grdmath -R -I256+ X COS\");but when time comes to perform the final calculation we cannot simply doanswer = gmt(\"grdmath MUL PI ADD\", kei, C);since grdmath would not know where kei and C should be put in the context of the operators MUL and ADD. We could probably teach grdmath to discover the only possible solution since the MUL operator requires two operands but none are listed on the command line. The logical choice then is to take kei and C as operands. However, in the general case it may not be possible to determine a unique layout, but more importantly it is simply too confusing to separate all operators from their operands (other than constants) as we would lose track of the mathematical operation we are performing. For this reason, we will assist the module by inserting question marks where we wish the module to use the next unused input object in the list. Hence, the valid command actually becomesanswer = gmt(\"grdmath ? ? MUL PI ADD\", kei, C);Of course, all these calculations could have been done at once with no input objects but often we reuse results in different contexts and then the markers are required. The second situation arises if you wish to use a grid as argument to the -R option (i.e., to set the current region to that of the grid). On the command line this may look likegmt pscoast -Reurope.nc -JM5i –P -Baf -Gred > map.psHowever, in Julia we cannot simply supply -R with no argument since that is already an established shorthand for selecting the previously specified region. The solution is to supply –R?. Assuming our grid is called europe then the Julia command would becomemap = gmt(\"pscoast -R? -JM5i -P -Baf -Gred\", europe);"
},

{
    "location": "man/modules/#",
    "page": "By Modules",
    "title": "By Modules",
    "category": "page",
    "text": ""
},

{
    "location": "man/modules/#By-Modules-1",
    "page": "By Modules",
    "title": "By Modules",
    "category": "section",
    "text": "In this mode we access the individual GMT modules directly by their name, and options are set using keyword arguments. The general syntax is (where the brackets mean optional parameters):[output objects] = modulename([cmd::String=\"\",] [argi=[];] opt1=val1, opt2=val2, kwargs...);where modulename is the program name (e.g. pscoast), cmd is used to transmit a file name for modules that will read data from files and argi is one, and for certain modules, or more data arrays or GMT.jl data types. opti named arguments common to many modules used for example to set the output format. Finally kwargs are keyword parameters used to set the individual module options. But contrary to the Monolitic usage, the one letter GMT option syntax may be replaced by more verbose aliases. To make it clear let us look at couple of examples.pscoast(region=\"g\", proj=\"A300/30/6c\", frame=\"g\", resolution=\"c\", land=\"navy\", fmt=\"ps\")This command creates a map in PotScript file (set by the fmt=\"ps\") called GMTjl_tmp.ps and save it in your system's tmp directory. For comparison, the same command could have been written, using the classical one letter option syntax, as:pscoast(R=\"g\", J=\"A300/30/6c\", B=\"g\", D=\"c\", G=\"navy\", fmt=\"ps\")So, each module defines a set of aliases to the one letter options that are reported in each module man page.Before diving more in the way options may be transmitted in the model we have to understand what happens with the output image file. The fmt=\"ps\" states that the output image format is in PostScript (actually, with the exception of grdimage -A, the only format that GMT can write). But we can also say fmt=\"jpg\", orfmt=\"png\" or fmt=\"pdf\". In such cases, the ghostscript program (you need to have it installed) will take care of converting the ps file into the selected format.The above example, however, does not use any input data (pscoast knows how to find its own data). One way of providing it to modules that work on them is to send in a file name with the data to operate on. This examplegrdimage(\"@tut_relief.nc\", shade=\"+ne0.8+a100\", proj=\"M12c\", frame=\"a\",\n         fmt=\"ps\", show=true)reads a the netCDF grid tut_relief.nc and displays it as an Mercator projected image. The '@' prefix is used by GMT to know that the grid file should be downloaded from a server and cached locally. This example introduces also the show=true keyword. It means that we want to see right way the image that just been created. While it might seam obvious that one want to see the result, the result might not be ready with only one GMT module call. And that because the GMT philosophy uses a layer cake  model to construct potentially highly complex figures. Next example illustrates a slightly more evolved exampletopo = makecpt(color=\"rainbow\", range=\"1000/5000/500\", Z=[]);\ngrdimage(\"@tut_relief.nc\", shade=\"+ne0.8+a100\", proj=\"M12c\", frame=\"a\", color=topo,\n         fmt=\"jpg\")\npsscale!(position=\"jTC+w5i/0.25i+h+o0/-1i\", region=\"@tut_relief.nc\", color=topo,\n         frame=\"y+lm\", fmt=\"jpg\", show=true)Here we used the makecpt command to compute a colormap object, used it as the value of the color keyword of both grdimage and psscale modules. The final image is made up of two layers, the first one is the part created by grdimage, which is complemented by the color scale plot performed by psscale. But since this was an appending operation we HAD to use the ! form. This form tells GMT tho append to a previous initiated image. The image layer cake is finalized by the show=true keyword. If our example had more layers, we would have used the same rule: second on layers use the ! construct and the last is signaled by show=true.The examples above show also that we didn't completely get rid of the compact GMT syntax. For example the shade=\"+ne0.8+a100\" in grdimage means that we are computing the shade using a normalized a cumulative Laplace distribution and setting the Sun direction from the 100 azimuth direction. For as much we would like to simplify that, it's just not possible. To access the high degree of control that GMT provides one need to use its full syntax. As such, readers are redirected to the main GMT documentation to learn about the fine details of those options.Setting line and symbol attributes has received, however, a set of aliases. So, instead of declaring the pen line attributes like -W0.5,blue,–, one can use the aliases lw=0.5, lc=\"blue\", ls=\"–\". An example would beplot(collect(1:10),rand(10), lw=0.5, lc=\"blue\", ls=\"--\", fmt=\"png\", marker=\"circle\",\n     markeredgecolor=0, size=0.2, markerfacecolor=\"red\", title=\"Bla Bla\",\n     x_label=\"Spoons\", y_label=\"Forks\", show=true)This example introduces also keywords to plot symbols and set their attributes. Also shown are the parameters used to set the image's title and labels.But setting pen attributes like illustrated above may be complicated if one has more that one set of graphical objects (lines and polygons) that need to receive different settings. A good example of this again provide by a pscoast command. Imagine one want to plot coast lines ans well as country borders with different line colors and thickness. Here we cannot simple state lw=1 because the program wouldn't know which of the shore line or borders this attribute applies to. The solution for this is to use tuples as values of corresponding keyword options.pscoast(limits=\"-10/0/35/45\", proj=\"M12c\", shore=(0.5,\"red\"), fmt=\"ps\", frame=\"a\",\n        show=1, borders=(1,(1,\"green\")))Here we used tuples to set the pen attributes, where the tuple may have 1 to 3 elements in the form (width[c|i|p]], [color], [style[c|i|p|]). The borders=(1,(1,\"green\")) option is actually a tuple-in-a-tuple because here we need also to specify the political boundary level to plot (1 = National Boundaries)."
},

{
    "location": "man/modules/#Specifying-the-pen-attributes-1",
    "page": "By Modules",
    "title": "Specifying the pen attributes",
    "category": "section",
    "text": "So, in summary, a pen attribute may be set in three different ways:With a text string that follows the width, color, style specs as explained in Specifying pen attributes\nBy using the lw or linewidth keyword where its value is either a number, meaning the line thickness in points, or a string like the width above; the color is set with the lc or linecolor and the value is either a number between 0 255 or a color name (for example \"red\"); and a ls or linestyle with the value specified as a string (example: \"–\" plot a dashed line).\nA tuple with one to three elements: ([width], [color], [style]) where each of the elements follows the same syntax as explained in the case (2) above."
},

{
    "location": "man/modules/#Specifying-the-axes-1",
    "page": "By Modules",
    "title": "Specifying the axes",
    "category": "section",
    "text": "The axes are controlled by the B or frame or axes keywords. The easiest for it can have is the axes=\"a\", which means do an automatic annotation of the 4 map boundaries – left, bottom, right and top – axes. To annotate only the left and bottom boundaries, one would do axes=\"a WSne\". For a higher level of control the user must really consult the original -B documentation.Axes titles and labels may be also set, taht is other than setting them with a axes string, using the keywords title, x_label and y_label.The figure limits is set with the R, region, or limits  keywords. Again, the full docs for this option are explained in -R documentation but besides the string version, the numeric form region=[x_min x_max y_min y_max] is also permitted. The plot() function allows that a no limits setting, in which case it will default to the data's bounding box."
},

{
    "location": "man/modules/#Specifying-the-figure-size-1",
    "page": "By Modules",
    "title": "Specifying the figure size",
    "category": "section",
    "text": "Figure sizes are automatically set to 12x8 cm for basic case of Cartesian xy plots done with the plot() function but otherwise in general they need to be user specified using the J or proj or projection keywords. See the full doc at -J documentation.  For Cartesian plots one can also use the figsize=width  or figsize=[width height] keyword, where the dimensions are in centimiters. The array form allows also set height or width to 0 to have it recomputed based on the implied scale of the other axis. Use negative sizes to reverse the direction of an axis (e.g., to have y be positive down). If neither of these forms is used, the figure width defaults to 14 cm."
},

{
    "location": "types/#",
    "page": "The GMT types",
    "title": "The GMT types",
    "category": "page",
    "text": ""
},

{
    "location": "types/#The-GMT.jl-types-1",
    "page": "The GMT types",
    "title": "The GMT.jl types",
    "category": "section",
    "text": ""
},

{
    "location": "types/#The-Grid-type-1",
    "page": "The GMT types",
    "title": "The Grid type",
    "category": "section",
    "text": "type GMTgrid                  # The type holding a local header and data of a GMT grid\n   proj4::String              # Projection string in PROJ4 syntax (Optional)\n   wkt::String                # Projection string in WKT syntax (Optional)\n   range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]\n   inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]\n   registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration\n   nodata::Float64            # The value of nodata\n   title::String              # Title (Optional)\n   comment::String            # Remark (Optional)\n   command::String            # Command used to create the grid (Optional)\n   datatype::String           # 'float' or 'double'\n   x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates\n   y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates\n   z::Array{Float32,2}        # [n_rows x n_columns] grid array\n   x_units::String            # Units of XX axis (Optional)\n   y_units::String            # Units of YY axis (Optional)\n   z_units::String            # Units of ZZ axis (Optional)\n   layout::String             # A three character string describing the grid memory layout\nend"
},

{
    "location": "types/#The-Image-type-1",
    "page": "The GMT types",
    "title": "The Image type",
    "category": "section",
    "text": "type GMTimage                 # The type holding a local header and data of a GMT image\n   proj4::String              # Projection string in PROJ4 syntax (Optional)\n   wkt::String                # Projection string in WKT syntax (Optional)\n   range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]\n   inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]\n   registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration\n   nodata::Float64            # The value of nodata\n   title::String              # Title (Optional)\n   comment::String            # Remark (Optional)\n   command::String            # Command used to create the image (Optional)\n   datatype::String           # 'uint8' or 'int8' (needs checking)\n   x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates\n   y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates\n   image::Array{UInt8,3}      # [n_rows x n_columns x n_bands] image array\n   x_units::String            # Units of XX axis (Optional)\n   y_units::String            # Units of YY axis (Optional)\n   z_units::String            # Units of ZZ axis (Optional) ==> MAKES NO SENSE\n   colormap::Array{Clong,1}   # \n   alpha::Array{UInt8,2}      # A [n_rows x n_columns] alpha array\n   layout::String             # A four character string describing the image memory layout\nend"
},

{
    "location": "types/#The-DATASET-type-1",
    "page": "The GMT types",
    "title": "The DATASET type",
    "category": "section",
    "text": "type GMTdataset\n    header::String\n    data::Array{Float64,2}\n    text::Array{Any,1}\n    comment::Array{Any,1}\n    proj4::String\n    wkt::String\nend"
},

{
    "location": "types/#The-CPT-type-1",
    "page": "The GMT types",
    "title": "The CPT type",
    "category": "section",
    "text": "type GMTcpt\n    colormap::Array{Float64,2}\n    alpha::Array{Float64,1}\n    range::Array{Float64,2}\n    minmax::Array{Float64,1}\n    bfn::Array{Float64,2}\n    depth::Cint\n    hinge::Cdouble\n    cpt::Array{Float64,2}\n    model::String\n    comment::Array{Any,1}   # Cell array with any comments\nend"
},

{
    "location": "types/#The-Postscript-type-1",
    "page": "The GMT types",
    "title": "The Postscript type",
    "category": "section",
    "text": "type GMTps\n    postscript::String      # Actual PS plot (text string)\n    length::Int             # Byte length of postscript\n    mode::Int               # 1 = Has header, 2 = Has trailer, 3 = Has both\n    comment::Array{Any,1}   # Cell array with any comments\nend"
},

]}
