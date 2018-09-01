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
    "location": "#Functions-1",
    "page": "Home",
    "title": "Functions",
    "category": "section",
    "text": "DocTestSetup = quote\n    using GMT\nendplot(arg1::Array; fmt=\"\", kwargs...)\n\nimshow(arg1; fmt=\"\", kwargs...)\n\nbasemap(cmd0::String=\"\"; fmt=\"\", kwargs...)\n\ncoast(cmd0::String=\"\"; fmt=\"\", clip=[], kwargs...)\n\nhistogram(cmd0::String=\"\", arg1=[]; fmt::String=\"\", kwargs...)\n\ncolorbar(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\ntext(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\nrose(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\nsolar(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\nxy(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\ngmtinfo(cmd0::String=\"\", arg1=[]; kwargs...)\n\ngrdcontour(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\ngrdimage(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[]; fmt=\"\", kwargs...)\n\ngrdinfo(cmd0::String=\"\", arg1=[]; kwargs...)\n\ngrdtrack(cmd0::String=\"\", arg1=[], arg2=[]; kwargs...)\n\ngrdview(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; \n        fmt=\"\", kwargs...)\n\nmakecpt(cmd0::String=\"\", arg1=[]; kwargs...)\n\nnearneighbor(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\npsconvert(cmd0::String=\"\", arg1=[]; kwargs...)\n\nsplitxyz(cmd0::String=\"\", arg1=[]; kwargs...)\n\nsurface(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\ntriangulate(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)\n\nwiggle(cmd0::String=\"\", arg1=[]; fmt=\"\", kwargs...)"
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
    "location": "examples/#Here\'s-the-\"Hello-World\"-1",
    "page": "Some examples",
    "title": "Here\'s the \"Hello World\"",
    "category": "section",
    "text": "using GMT\nplot(collect(1:10),rand(10), lw=1, lc=\"blue\", fmt=\"png\", marker=\"square\",\n     markeredgecolor=0, size=0.2, markerfacecolor=\"red\", title=\"Hello World\",\n     x_label=\"Spoons\", y_label=\"Forks\", show=true)<div style=\"width:300px; height=200px\"> (Image: \"Hello world\") </div>A few notes about this example. Because we didn\'t specify the figure size (with the figsize keyword) a default value of 12x8 cm (not counting labels and title) was used. The fmt=png selected the PNG format. The show=true is needed to show the image at the end.But now we want an image made up with two layers of data. And we are going to plot on the sphere (the Earth). For that we will need to use the coast program to plot the Earth and append some curvy lines."
},

{
    "location": "examples/#And-the-\"Hello-Round-World\"-1",
    "page": "Some examples",
    "title": "And the \"Hello Round World\"",
    "category": "section",
    "text": "x = range(0, stop=2pi, length=180);       seno = sin.(x/0.2)*45;\ncoast(region=[0 360 -90 90], proj=\"A300/30/6c\", frame=\"g\", resolution=\"c\", land=\"navy\")\n\nplot!(collect(x)*60, seno, lw=0.5, lc=\"red\", fmt=\"png\", marker=\"circle\",\n      markeredgecolor=0, size=0.05, markerfacecolor=\"cyan\", show=true)In this example region=[0 360 -90 90]  means the domain is the whole Earth, frame=\"g\" sets the grid on, resolution=\"c\" selects the crude coast lines resolution and the  land=\"navy\" paints the continents with a navy blue color. More complex is the proj=\"A300/30/6c\" argument that selects the map projection, which is a Lambert projection with projection center at 300 degrees East, 0 degrees North. The 6c sets the map width of 6 centimeters.(Image: \"Hello round world\")Note that now the first command, the coast, does not have the show keyword. It means we are here creating the first layer but we don\'t want to see it just yet. The second command uses the ! variation of the plot function, which means that we are appending to a previous plot, and uses the show=true because we are donne with this figure."
},

{
    "location": "examples/#Simple-contours-1",
    "page": "Some examples",
    "title": "Simple contours",
    "category": "section",
    "text": "Contours are created with grdcontour that takes a grid as input (or a GMTgrid data type). This example shows uses the peaks function to create a classical example. Note, however, that the memory consumption in this example, when creating the plot, is much lower than traditional likewise  examples because we will be using only one 2D array intead of 3 3D arrays (ref). In the example cont=1 and annot=2 means draw contours at evry 1 unit of the G grid and annotate at evry other contour line. frame=\"a\" means pick a default automatic annotation and labeling for the axis.x,y,z=GMT.peaks()\nG = gmt(\"surface -R-3/3/-3/3 -I0.1\", [x[:] y[:] z[:]]);  # Iterpolate into a regular grid\ngrdcontour(G, cont=1, annot=2, frame=\"a\", fmt=\"png\", show=1)(Image: \"Simple black&white contour\")Now with colored contours. To make it colored we need to generate a color map and use it. Notetice that we have to specify a pen attribute to get the colored contours because pen specifications are always set separately. Here we will create first a colormap with makecpt that will from -6 to 8 with steps of 1. These values are picked up after the z values of the G grid. cpt = makecpt(range=\"-6/8/1\");      # Create the color map\ngrdcontour(G, frame=\"a\", fmt=\"png\", color=cpt, pen=\"+c\", show=1)(Image: \"Simple color contour\")"
},

{
    "location": "examples/#Color-images-1",
    "page": "Some examples",
    "title": "Color images",
    "category": "section",
    "text": "Color images are made with grdimage which takes the usual common options and a color map. It operates over grids or images. The next example shows how to create a color appropriate for the grid\'s z range, plot the image and add a color scale. We use here the data keyword to tell the program to load the grid from a file. The  before the tut_relief.nc file name instructs GMT to download the file from its server on the first usage and save it in a cache dir. See the GMT tuturial for more details about what the arguments mean.topo = makecpt(color=\"rainbow\", range=\"1000/5000/500\", continuous=true);\ngrdimage(\"@tut_relief.nc\", shade=\"+ne0.8+a100\", proj=\"M12c\", frame=\"a\", fmt=\"jpg\",\n         color=topo)\ncolorbar!(position=\"jTC+w5i/0.25i+h+o0/-1i\", region=[-108 -103 35 40], color=topo,\n       proj=[], frame=\"y+lm\", fmt=\"jpg\", show=1)(Image: \"Hello shaded world\")"
},

{
    "location": "examples/#Perspective-view-1",
    "page": "Some examples",
    "title": "Perspective view",
    "category": "section",
    "text": "We will make a perspective, color-coded view of the US Rockies from the southeast.topo = makecpt(color=\"rainbow\", range=\"1000/5000/500\", continuous=true);\ngrdview(\"@tut_relief.nc\", proj=\"M12c\", JZ=\"1c\", shade=\"+ne0.8+a100\", view=\"135/30\",\n        frame=\"a\", fmt=\"jpg\", color=topo, Q=\"i100\", show=1)(Image: \"Hello 3D view world\")"
},

{
    "location": "examples/#Warp-image-in-geographical-projection-1",
    "page": "Some examples",
    "title": "Warp image in geographical projection",
    "category": "section",
    "text": "In this example we will load a network image (GDAL will do that for us) and make a creative world map. First command, the imshow, needs to set show=false to no display the image before it is complete. We have to do this because imshow is a one command only shot and so, by default, it has the show keyword hardwire to true.imshow(\"http://larryfire.files.wordpress.com/2009/07/untooned_jessicarabbit.jpg\",\n      frame=\"g\", region=\"d\", proj=\"I15c\", image_in=\"r\", show=false)\ncoast!(shore=\"1,white\", resolution=\"c\", fmt=\"png\", show=true)(Image: SinuJessica)"
},

{
    "location": "rectangles/#",
    "page": "Draw rectangles examples",
    "title": "Draw rectangles examples",
    "category": "page",
    "text": ""
},

{
    "location": "rectangles/#Draw-rectangles-1",
    "page": "Draw rectangles examples",
    "title": "Draw rectangles",
    "category": "section",
    "text": ""
},

{
    "location": "rectangles/#Simple-filled-rectangle-1",
    "page": "Draw rectangles examples",
    "title": "Simple filled rectangle",
    "category": "section",
    "text": "using GMT\nrect = [2 2; 2 6; 6 6; 6 2; 2 2];\nplot(rect, region=[0 10 0 10], lw=1, fill=\"blue\", frame=\"a\", axis=\"equal\", fmt=\"png\", show=true)(Image: \"Blue rectangle\")"
},

{
    "location": "rectangles/#Rectangles-with-patterns-1",
    "page": "Draw rectangles examples",
    "title": "Rectangles with patterns",
    "category": "section",
    "text": "Now add some patterns. The full pattern syntax is explained in GMT patterns but basically we are using pattern number 20 at 200 dpi and a blue background for the left rectangle and pattern 89 also at 200 dpis for the right rectangle.using GMT\nrect = [1 1; 1 7; 4 7; 4 1; 1 1];\nplot(rect, region=[0 10 0 10], lw=1, fill=\"p20+bgreen+r200\", frame=\"a\", axis=\"equal\")\nplot!([4 0].+rect, lw=1, fill=\"p89+r200\", fmt=\"png\", show=true)(Image: \"Pattern Rectangles\")"
},

{
    "location": "rectangles/#Rectangles-with-transparency-1",
    "page": "Draw rectangles examples",
    "title": "Rectangles with transparency",
    "category": "section",
    "text": "This variation creates rectangles with 0, 30% and 70% transparency as well as different boundary lines.using GMT\nrect = [0.5 0.5; 0.5 7; 2.5 7; 2.5 0.5; 0.5 0.5];\nplot(rect, region=[0 10 0 10], lw=0.5, fill=\"blue\", frame=\"a\", axis=\"equal\")\nplot!([3 0].+rect, lw=1, ls=\"--\", fill=\"blue\", transparency=30)\nplot!([6 0].+rect, lw=2, lc=\"red\", fill=\"blue\", transparency=70, fmt=\"png\", show=true)(Image: \"Transparent Rectangles\")"
},

{
    "location": "frames/#",
    "page": "Draw frames examples",
    "title": "Draw frames examples",
    "category": "page",
    "text": ""
},

{
    "location": "frames/#Draw-Frames-1",
    "page": "Draw frames examples",
    "title": "Draw Frames",
    "category": "section",
    "text": ""
},

{
    "location": "frames/#Geographic-basemaps-1",
    "page": "Draw frames examples",
    "title": "Geographic basemaps",
    "category": "section",
    "text": "Geographic basemaps may differ from regular plot axis in that some projections support a “fancy” form of axis and is selected by the MAPFRAMETYPE setting. The annotations will be formatted according to the FORMATGEOMAP template and MAPDEGREESYMBOL setting. A simple example of part of a basemap is shown in Figure Geographic map border.using GMT\nbasemap(R=\"-1/2/0/0.4\", proj=\"M8\", frame=\"a1f15mg5m S\")\nt = [-1.0 0 0 1.0\n    0.25 0 0 0.25\n    1.25 0 0 0.08333332];\nGMT.xy!(t, symbol=\"v2p+b+e+a60\", lw=0.5, fill=\"black\", y_offset=\"-1.0\", no_clip=true)\nif (GMTver < 6)\n    T = [\"-0.5 0.05 annotation\", \"0.375 0.05 frame\", \"1.29166666 0.05 grid\"];\nelse\n    T = text_record([-0.5 0.05; 0.375 0.05; 1.29166666 0.05], [\"annotation\", \"frame\", \"grid\"]);\nend\ntext!(T, text_attrib=\"+f9p+jCB\", fmt=\"png\", show=true)(Image: \"B_geo_1\")The machinery for primary and secondary annotations axes can be utilized for geographic basemaps. This may be used to separate degree annotations from minutes- and seconds-annotations. For a more complicated basemap example using several sets of intervals, including different intervals and pen attributes for grid lines and grid crosses.using GMT\nbasemap(region=\"-2/1/0/0.35\", proj=\"M10\", frame=\"pa15mf5mg5m wSe s1f30mg15m\", MAP_FRAME_TYPE=\"fancy+\",\n	MAP_GRID_PEN_PRIMARY=\"thinnest,black,.\", MAP_GRID_CROSS_SIZE_SECONDARY=0.25, MAP_FRAME_WIDTH=0.2,\n	MAP_TICK_LENGTH_PRIMARY=0.25, FORMAT_GEO_MAP=\"ddd:mm:ssF\", FONT_ANNOT_PRIMARY=\"+8\", FONT_ANNOT_SECONDARY=12)\n# Draw Arrows and text\nt = [-1.875 0 0 0.33333\n    -0.45833 0 0 0.11111\n    0.541666 0 0 0.11111]\nGMT.xy!(t, symbol=\"v0.08+b+e+jc\", lw=0.5, fill=\"black\", y_offset=-1, no_clip=true)\nif (GMTver < 6)\n    T = [\"-2.1 0.025 10p RM P:\", \"-1.875 0.05 6p CB annotation\",\n         \"-0.45833 0.05 6p CB frame\", \"0.541666 0.05 6p CB grid\"]\nelse\n    T = text_record([-2.1 0.025; -1.875 0.05; -0.45833 0.05; 0.541666 0.05], [\"10p RM P:\", \"6p CB annotation\", \"6p CB frame\", \"6p CB grid\"])\nend\ntext!(T, text_attrib=\"+f+j\", no_clip=true)\nt = [-1.5 0 0 1.33333; -0.25 0 0 0.66666; 0.625 0 0 0.33333]\nGMT.xy!(t, symbol=\"v0.08+b+e+jc\", lw=0.5, fill=\"black\", y_offset=-0.6, no_clip=true)\n\nif (GMTver < 6)\n    T = [\"-2.1 0.025 10p RM S:\", \"-1.5  0.05 9p CB annotation\",\n         \"-0.25 0.05 9p CB frame\", \"0.625 0.05 9p CB grid\"]\nelse\n    T = text_record([-2.1 0.025; -1.5  0.05; -0.25 0.05; 0.625 0.05], [\"10p RM S:\", \"9p CB annotation\", \"9p CB frame\", \"9p CB grid\"])\nend\ntext!(T, text_attrib=\"+f+j\", no_clip=true, fmt=\"png\", show=1)(Image: \"B_geo_2\")"
},

{
    "location": "frames/#Cartesian-linear-axes-1",
    "page": "Draw frames examples",
    "title": "Cartesian linear axes",
    "category": "section",
    "text": "For non-geographic axes, the MAPFRAMETYPE setting is implicitly set to plain. Other than that, cartesian linear axes are very similar to geographic axes. The annotation format may be controlled with the FORMATFLOATOUT parameter. By default, it is set to “%g”, which is a C language format statement for floating point numbers, and with this setting the various axis routines will automatically determine how many decimal points should be used by inspecting the stride settings. If FORMATFLOATOUT is set to another format it will be used directly (.e.g, “%.2f” for a fixed, two decimals format). Note that for these axes you may use the unit setting to add a unit string to each annotation.using GMT\nbasemap(region=\"0/12/0/1\", proj=\"X12/1\", frame=\"-Ba4f2g1+lFrequency+u\\\" \\%\\\" S\")\nt = [0 0 0 1.57; 6.0 0 0 0.79; 9.0 0 0 0.39]\nGMT.xy!(t, symbol=\"v2p+b+e+a60\", lw=0.5, fill=\"black\", y_offset=0.25, no_clip=true, Vd=1)\nif (GMTver < 6)\n    T = [\"2 0.2 annotation\"; \"7 0.2 frame\"; \"9.5 0.2 grid\"]\nelse\n    T = text_record([2 0.2; 7 0.2; 9.5 0.2], [\"annotation\", \"frame\", \"grid\"])\nend\ntext!(T, text_attrib=\"+f9p+jCB\", clearance=\"0.025/0.025\", fill=\"white\", fmt=\"png\", show=1)(Image: \"B_linear\")"
},

{
    "location": "frames/#Cartesian-log10-axes-1",
    "page": "Draw frames examples",
    "title": "Cartesian log10 axes",
    "category": "section",
    "text": "Due to the logarithmic nature of annotation spacings, the stride parameter takes on specific meanings. The following concerns are specific to log axes (see Figure Logarithmic projection axis):stride must be 1, 2, 3, or a negative integer -n. Annotations/ticks will then occur at 1, 1-2-5, or 1,2,3,4,...,9, respectively, for each magnitude range. For -n the annotations will take place every n‘th magnitude.\nAppend l to stride. Then, log10 of the annotation is plotted at every integer log10 value (e.g., x = 100 will be annotated as “2”) [Default annotates x as is].\nAppend p to stride. Then, annotations appear as 10 raised to log10 of the value (e.g., 10-5).using GMT\ngmt(\"set MAP_GRID_PEN_PRIMARY thinnest,.\")\nbasemap(region=\"1/1000/0/1\", proj=\"X8l/0.7\", frame=\"1f2g3p+l\\\"Axis Label\\\" S\")\nbasemap!(frame=\"1f2g3l+l\\\"Axis Label\\\" S\", y_offset=2.2)\nbasemap!(frame=\"1f2g3+l\\\"Axis Label\\\" S\", y_offset=2.2, fmt=\"png\", show=true)(Image: \"B_log\")"
},

{
    "location": "frames/#Cartesian-exponential-axes-1",
    "page": "Draw frames examples",
    "title": "Cartesian exponential axes",
    "category": "section",
    "text": "Normally, stride will be used to create equidistant (in the user’s unit) annotations or ticks, but because of the exponential nature of the axis, such annotations may converge on each other at one end of the axis. To avoid this problem, you can append p to stride, and the annotation interval is expected to be in transformed units, yet the annotation itself will be plotted as un-transformed units. E.g., if stride = 1 and power = 0.5 (i.e., sqrt), then equidistant annotations labeled 1, 4, 9, ... will appear.using GMT\ngmt(\"set MAP_GRID_PEN_PRIMARY thinnest,.\")\nbasemap(region=\"0/100/0/0.9\", proj=\"X3ip0.5/0.25i\", frame=\"a3f2g1p+l\\\"Axis Label\\\" S\")\nbasemap!(frame=\"20f10g5+l\\\"Axis Label\\\" S\",  y_offset=2.2, fmt=\"png\", show=true)(Image: \"B_pow\")"
},

{
    "location": "frames/#Cartesian-time-axes-1",
    "page": "Draw frames examples",
    "title": "Cartesian time axes",
    "category": "section",
    "text": "What sets time axis apart from the other kinds of plot axes is the numerous ways in which we may want to tick and annotate the axis. Not only do we have both primary and secondary annotation items but we also have interval annotations versus tick-mark annotations, numerous time units, and several ways in which to modify the plot. We will demonstrate this flexibility with a series of examples. While all our examples will only show a single x-axis (south, selected via -BS), time-axis annotations are supported for all axes.Our first example shows a time period of almost two months in Spring 2000. We want to annotate the month intervals as well as the date at the start of each week. Note the leading hyphen in the FORMATDATEMAP removes leading zeros from calendar items (e.g., 03 becomes 3).using GMT\nbasemap(region=\"2000-4-1T/2000-5-25T/0/1\", proj=\"X12/0.5\", frame=\"pa7Rf1d sa1O S\",\n        FORMAT_DATE_MAP=\"-o\", FONT_ANNOT_PRIMARY=\"+9p\", fmt=\"png\", show=true)(Image: \"B_time1\")The next example shows two different ways to annotate an axis portraying 2 days in July 1969:using GMT\ngmt(\"set FORMAT_DATE_MAP \\\"o dd\\\" FORMAT_CLOCK_MAP hh:mm FONT_ANNOT_PRIMARY +9p\")\nbasemap(region=\"1969-7-21T/1969-7-23T/0/1\", proj=\"X12/0.5\", frame=\"pa6Hf1h sa1K S\")\nbasemap!(frame=\"pa6Hf1h sa1D S\", y_offset=1.7, fmt=\"png\", show=true)The lower example chooses to annotate the weekdays (by specifying a1K) while the upper example choses dates (by specifying a1D). Note how the clock format only selects hours and minutes (no seconds) and the date format selects a month name, followed by one space and a two-digit day-of-month number.(Image: \"B_time2\")The lower example chooses to annotate the weekdays (by specifying a1K) while the upper example choses dates (by specifying a1D). Note how the clock format only selects hours and minutes (no seconds) and the date format selects a month name, followed by one space and a two-digit day-of-month number.The third example presents two years, annotating both the years and every 3rd month.using GMT\nbasemap(region=\"1997T/1999T/0/1\", proj=\"X12/0.25\", frame=\"pa3Of1o sa1Y S\", FORMAT_DATE_MAP=\"o\",\n    FORMAT_TIME_PRIMARY_MAP=\"Character\", FONT_ANNOT_PRIMARY=\"+9p\", fmt=\"png\", show=true)Note that while the year annotation is centered on the 1-year interval, the month annotations must be centered on the corresponding month and not the 3-month interval. The FORMATDATEMAP selects month name only and FORMATTIMEPRIMARYMAP selects the 1-character, upper case abbreviation of month names using the current language (selected by GMTLANGUAGE).(Image: \"B_time3\")The fourth example only shows a few hours of a day, using relative time by specifying t in the region option while the TIME_UNIT is d (for days). We select both primary and secondary annotations, ask for a 12-hour clock, and let time go from right to left:using GMT\ngmt(\"set FORMAT_CLOCK_MAP=-hham FONT_ANNOT_PRIMARY +9p TIME_UNIT d\")\nbasemap(region=\"0.2t/0.35t/0/1\", proj=\"X-12/0.25\", frame=\"pa15mf5m sa1H S\",\n    FORMAT_CLOCK_MAP=\"-hham\", FONT_ANNOT_PRIMARY=\"+9p\", TIME_UNIT=\"d\", fmt=\"png\", show=true)(Image: \"B_time4\")The fifth example shows a few weeks of time (Figure Cartesian time axis, example 5). The lower axis shows ISO weeks with week numbers and abbreviated names of the weekdays. The upper uses Gregorian weeks (which start at the day chosen by TIMEWEEKSTART); they do not have numbers.using GMT\ngmt(\"set FORMAT_DATE_MAP u FORMAT_TIME_PRIMARY_MAP Character FORMAT_TIME_SECONDARY_MAP full\n     FONT_ANNOT_PRIMARY +9p\")\nbasemap(region=\"1969-7-21T/1969-8-9T/0/1\", proj=\"X12/0.25\", frame=\"pa1K sa1U S\")\ngmt(\"set FORMAT_DATE_MAP o TIME_WEEK_START Sunday FORMAT_TIME_SECONDARY_MAP Chararacter\")\nbasemap!(frame=\"pa3Kf1k sa1r S\", y_offset=1.7, fmt=\"png\", show=true)(Image: \"B_time5\")Our sixth example shows the first five months of 1996, and we have annotated each month with an abbreviated, upper case name and 2-digit year. Only the primary axes information is specified.using GMT\nbasemap(region=\"1996T/1996-6T/0/1\", proj=\"X12/0.25\", frame=\"a1Of1d S\",\n    FORMAT_DATE_MAP=\"\\\"o yy\\\"\", FORMAT_TIME_PRIMARY_MAP=\"Abbreviated\", fmt=\"png\", show=true)(Image: \"B_time6\")Our seventh and final example illustrates annotation of year-days. Unless we specify the formatting with a leading hyphen in FORMATDATEMAP we get 3-digit integer days. Note that in order to have the two years annotated we need to allow for the annotation of small fractional intervals; normally such truncated interval must be at least half of a full interval.using GMT\ngmt(\"set FORMAT_DATE_MAP jjj TIME_INTERVAL_FRACTION 0.05 FONT_ANNOT_PRIMARY +9p\")\nbasemap(region=\"2000-12-15T/2001-1-15T/0/1\", proj=\"X12/0.25\", frame=\"pa5Df1d sa1Y S\",\n    FORMAT_DATE_MAP=\"jjj\", TIME_INTERVAL_FRACTION=0.05, FONT_ANNOT_PRIMARY=\"+9p\", fmt=\"png\", show=true)(Image: \"B_time7\")"
},

{
    "location": "frames/#Custom-axes-1",
    "page": "Draw frames examples",
    "title": "Custom axes",
    "category": "section",
    "text": "if (GMTver < 6)     T1 = [\"416.0 ig Devonian\"; \"443.7 ig Silurian\"; \"488.3 ig Ordovician\"; \"542 ig Cambrian\"];     T2 = [\"0 a\"; \"1 a\"; \"2 f\"; \"2.71828 ag e\"; \"3 f\"; \"3.1415926 ag @~p@~\"; \"4 f\"; \"5 f\"; \"6 f\";           \"6.2831852 ag 2@~p@~\"]; else     T1 = textrecord([416.0 443.7 488.3 542], [\"ig Devonian\", \"ig Silurian\", \"ig Ordovician\", \"ig Cambrian\"]);     T2 = textrecord([0 1 2 2.71828 3 3.1415926 4 5 6 6.2831852],                      [\"a\", \"a\", \"f\", \"ag e\", \"f\", \"ag @~p@~\", \"f\", \"f\", \"f\", \"ag 2@~p@~\"]); end basemap(T2,  region=\"416/542/0/6.2831852\", proj=\"X-5i/2.5i\", frame=\"WS+glightblue px25f5g25+u\\\" Ma\\\" pyc\") basemap!(T1, frame=\"WS sxc\", MAPANNOTOFFSETSECONDARY=\"10p\", MAPGRIDPENSECONDARY=\"2p\", show=1, Vd=1)"
},

{
    "location": "usage/#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "usage/#Introduction-1",
    "page": "Introduction",
    "title": "Introduction",
    "category": "section",
    "text": "Access to GMT from Julia is accomplished via a main function (also called gmt), which offers full access to all of GMT’s ~140 modules as well as fundamental import, formatting, and export of GMT data objects. Internally, the GMT5 C API defines six high-level data structures (GMT6 will define only five) that handle input and output of data via GMT modules. These are data tables (representing one or more sets of points, lines, or polygons), grids (2-D equidistant data matrices), raster images (with 1–4 color bands), raw PostScript code, text tables (free-form text/data mixed records) and color palette tables (i.e., color maps). Correspondingly, we have defined five data structures that we use at the interface between GMT and Julia via the gmt function. The GMT.jl wrapper is responsible for translating between the GMT structures and native Julia structures, which are:Grids: Many tools consider equidistant grids a particular data type and numerous file formats exist for saving such data. Because GMT relies on GDAL we are able to read and write almost all such formats in addition to a native netCDF4 format that complies with both the COARDS and CF netCDF conventions. We have designed a native Julia grid structure Grid type that holds header information from the GMT grid as well as the data matrix representing the gridded values. These structures may be passed to GMT modules that expect grids and are returned from GMT modules that produce such grids. In addition, we supply a function to convert a matrix and some metadata into a grid structure.\nImages: The raster image shares many characteristics with the grid structure except the bytes representing each node reflect gray shade, color bands (1, 3, or 4 for indexed, RGB and RGBA, respectively), and possibly transparency values. We therefore represent images in another native structure Image type that among other items contains three components: The image matrix, a color map (present for indexed images only), and an alpha matrix (for images specifying transparency on a per-pixel level). As for grids, a wrapper function creating the correct structure is available.\nSegments: GMT considers point, line, and polygon data to be organized in one or more segments in a data table. Modules that return segments uses a native Julia segment structure Dataset type that holds the segment data, which may be either numerical, text, or both; it also holds a segment header string which GMT uses to pass metadata. Thus, GMT modules returning segments will typically produce arrays of segments and you may pass these to any other module expecting points, lines, or polygons or use them directly in Julia. Since a matrix is one fundamental data type you can also pass a matrix directly to GMT modules as well. Consequently, it is very easy to pass data from Julia into GMT modules that process data tables as well as to receive data segments from GMT modules that process and produce data tables as output.\nColor palettes: GMT uses its flexible Color Palette Table (CPT) format to describe how the color (or pattern) of symbols, lines, polygons or grids should vary as a function of a state variable. In Julia, this information is provided in another structure CPT type that holds the color map as well as an optional alpha array for transparency values. Like grids, these structures may be passed to GMT modules that expect CPTs and will be returned from GMT modules that normally would produce CPT files.\nPostScript: While most users of the GMT.jl wrapper are unlikely to manipulate PostScript directly, it allows for the passing of PostScript via another data structure Postscript type.Given this design the Julia wrapper is designed to work in two distinct ways. The first way, referred as the monolitic, is the more feature reach and follows closely the GMT usage from shell(s) command line but still provide all the facilities of the Julia language. See the Monolithic for the Reference on how to use the Package.\nThe second way uses an upper level set of functions that abstract aspects that make the monolitic usage more complex. It provides an interface to some of the GMT modules using a option=val list type syntax. This makes it more appropriate for newcommers but it won\'t release you from understanding the monolitic way. See the By Modules"
},

{
    "location": "monolitic/#",
    "page": "Monolithic",
    "title": "Monolithic",
    "category": "page",
    "text": ""
},

{
    "location": "monolitic/#Monolithic-1",
    "page": "Monolithic",
    "title": "Monolithic",
    "category": "section",
    "text": "In this mode all GMT options are put in a single text string that is passed, plus the data itself when it applies, to the gmt() command. This function is invoked with the syntax (where the brackets mean optional parameters):[output objects] = gmt(\"modulename optionstring\" [, input objects]);where modulename is a string with the name of a GMT module (e.g., surface, grdimage, psmeca, or even a custom extension), while the optionstring is a text string with the options passed to this module. If the module requires data inputs from the Julia environment, then these are provided as optional comma-separated arguments following the option string. Should the module produce output(s) then these are captured by assigning the result of gmt to one or more comma-separated variables. Some modules do not require an option string or input objects, or neither, and some modules do not produce any output objects.In addition, it can also use two i/o modules that are irrelevant on the command line: the read and write modules. These modules allow to import and export any of the GMT data types to and from external files. For instance, to import a grid from the file relief.nc we runG = gmt(\"read -Tg relief.nc\");We use the -T option to specify grid (g), image (i), PostScript (p), color palette (c), dataset (d) or textset (t). Results kept in Julia can be written out at any time via the write module, e.g., to save the grid Z to a file we usegmt(\"write model_surface.nc\", Z);Because GMT data tables often contain headers followed by many segments, each with their individual segment headers, it is best to read such data using the read module since native Julia import functions risk to choke on such headers."
},

{
    "location": "monolitic/#How-input-and-output-are-assigned-1",
    "page": "Monolithic",
    "title": "How input and output are assigned",
    "category": "section",
    "text": "Each GMT module knows what its primary input and output objects should be. Some modules only produce output (e.g., psbasemap makes a basemap plot with axes annotations) while other modules only expect input and do not return any items back (e.g., the write module writes the data object it is given to a file). Typically, (i.e., on the command line) users must carefully specify the input filenames and sometimes give these via a module option. Because users of this wrapper will want to provide input from data already in memory and likewise wish to assign results to variables, the syntax between the command line and Julia commands necessarily must differ. For example, here is a basic GMT command that reads the time-series raw_data.txt and filters it using a 15-unit full-width (6 sigma) median filter:gmt filter1d raw_data.txt –Fm15 > filtered_data.txtHere, the input file is given on the command line but input could instead come via the shell’s standard input stream via piping. Most GMT modules that write tables will write these to the shell’s output stream and users will typically redirect these streams to a file (as in our example) or pipe the output into another process. When using GMT.jl there are no shell redirections available. Instead, we wish to pass data to and from the Julia environment. If we assume that the content in raw_data.txt exists in a array named raw_data and we wish to receive the filtered result as a segment array named filtered, we would run the commandfiltered = gmt(\"filter1d -Fm15\", raw_data);This illustrates the main difference between command line and Julia usage: Instead of redirecting output to a file we return it to an internal object (here, a segment array) using standard Julia assignments of output.For data types where piping and redirection of output streams are inappropriate (including most grid file formats) the GMT modules use option flags to specify where grids should be written. Consider a GMT command that reads (x, y, z) triplets from the file depths.txt and produces an equidistant grid using a Green’s function-based spline-in-tension gridding routine:gmt greenspline depths.txt -R-50/300/200/600 -I5 -D1 -St0.3 -Gbathy.ncHere, the result of gridding Cartesian data (-D1) within the specified region (an equidistant lattice from x from -50 to 300 and y from 200 to 600, both with increments of 5) using moderately tensioned cubic splines (-St0.3) is written to the netCDF file bathy.nc. When using GMT.jl we do not want to write a file but wish to receive the resulting grid as a new Julia variable. Again, assuming we already loaded in the input data, the equivalent command isbathy = gmt(\"greenspline -R-50/300/200/600 -I5 -D1 -St0.3\", depths);Note that -G is no longer specified among the options. In this case the wrapper uses the GMT API to determine that the primary output of greenspline is a grid and that this is specified via the -G option. If no such option is given (or given without specifying a filename), then we instead return the grid via memory, provided a left-side assignment is specified. GMT only allows this behavior when called via an external API such as this wrapper: Not specifying the -G option on the command line would result in an error message. However, it is perfectly fine to specify the option -Gbathy.nc in Julia – it simply means you are saving the result to a file instead of returning it to Julia.Some GMT modules can produce more than one output (here called a secondary outputs) or can read more than one input type (i.e., secondary inputs). Secondary inputs or outputs are always specified by explicit module options on the command line, e.g., -Fpolygon.txt. In these cases, the gmt() enforces the following rules: When a secondary input is passed as an object then we must specify the corresponding option flag but provide no file argument (e.g., just -F in the above case). Likewise, for secondary output we supply the option flag and add additional objects to the left-hand side of the assignment. All secondary items, whether input or output, must appear after all primary items, and if more than one secondary item is given then their order must match the order of the corresponding options in optionstring.Here are two examples contrasting the GMT command line versus gmt() usage. In the first example we wish to determine all the data points in the file all_points.txt that happen to be located inside the polygon specified in the file polygon.txt. On the command line this would be achieved bygmt select points.txt -Fpolygon.txt > points_inside.txtwhile in Julia (assuming the points and polygon already reside in memory) we would runinside = gmt(\"gmtselect -F\", points, polygon);Here, the points object must be listed first since it is the primary data expected.Our second example considers the joining of line segments into closed polygons. We wish to create one file with all closed polygons and another file with any remaining disjointed lines. Not expecting perfection, we allow segment end-points closer than 0.1 units to be connected. On the command line we would rungmt connect all_segments.txt -Cclosed.txt -T0.1 > rest.txtwhere all_segments.txt are the input lines, closed.txt is the file that will hold closed polygons made from the relevant lines, while any remaining lines (i.e., open polygons) are written to standard output and redirected to the file rest.txt. Equivalent Julia usage would beall = gmt(\"read -Td all_segments.txt\");\nrest, closed = gmt(\"gmtconnect -T0.1 -C\", all);Note the primary output (here rest) must be listed before any secondary outputs (here closed) in the left-hand side of the assignment.So far, the gmt() function has been able to understand where inputs and outputs objects should be inserted, provided we follow the rules introduced above. However, there are two situations where more information must be provided. The first situation involves two GMT modules that allow complete freedom in how arguments are passed. These are gmtmath and grdmath, our reverse polish notation calculators for tables and grids, respectively. While the command-line versions require placement of arguments in the right order among the desired operators, the gmt() necessarily expects all inputs at the end of the function call. Hence we must assist the command by placing markers where the input arguments should be used; the marker we chose is the question mark (?). We will demonstrate this need using an example of grdmath. Imagine that we have created two separate grids: kei.nc contains an evaluation of the radial z = bei(r) Kelvin-Bessel function while cos.nc contains a cylindrical undulation in the x-direction. We create these two grids on the command line bygmt grdmath -R-4/4/-4/4 -I256+ X Y HYPOT KEI = kei.nc\ngmt grdmath -R -I256+ X COS = cos.ncLater, we decide we need pi plus the product of these two grids, so we computegmt grdmath kei.nc cos.nc MUL PI ADD = answer.ncIn Julia the first two commands are straightforward:kei = gmt(\"grdmath -R-4/4/-4/4 -I256+ X Y HYPOT KEI\");\nC   = gmt(\"grdmath -R -I256+ X COS\");but when time comes to perform the final calculation we cannot simply doanswer = gmt(\"grdmath MUL PI ADD\", kei, C);since grdmath would not know where kei and C should be put in the context of the operators MUL and ADD. We could probably teach grdmath to discover the only possible solution since the MUL operator requires two operands but none are listed on the command line. The logical choice then is to take kei and C as operands. However, in the general case it may not be possible to determine a unique layout, but more importantly it is simply too confusing to separate all operators from their operands (other than constants) as we would lose track of the mathematical operation we are performing. For this reason, we will assist the module by inserting question marks where we wish the module to use the next unused input object in the list. Hence, the valid command actually becomesanswer = gmt(\"grdmath ? ? MUL PI ADD\", kei, C);Of course, all these calculations could have been done at once with no input objects but often we reuse results in different contexts and then the markers are required. The second situation arises if you wish to use a grid as argument to the -R option (i.e., to set the current region to that of the grid). On the command line this may look likegmt pscoast -Reurope.nc -JM5i –P -Baf -Gred > map.psHowever, in Julia we cannot simply supply -R with no argument since that is already an established shorthand for selecting the previously specified region. The solution is to supply –R?. Assuming our grid is called europe then the Julia command would becomemap = gmt(\"pscoast -R? -JM5i -P -Baf -Gred\", europe);"
},

{
    "location": "modules/#",
    "page": "By Modules",
    "title": "By Modules",
    "category": "page",
    "text": ""
},

{
    "location": "modules/#By-Modules-1",
    "page": "By Modules",
    "title": "By Modules",
    "category": "section",
    "text": "In this mode we access the individual GMT modules directly by their name, and options are set using keyword arguments. The general syntax is (where the brackets mean optional parameters):[output objects] = modulename([cmd::String=\"\",] [argi=[],] opt1=val1, opt2=val2, kwargs...);where modulename is the program name (e.g. coast), cmd is used to transmit a file name for modules that will read data from files and argi is one or, and for certain modules, more data arrays or GMT.jl data types. opti named arguments common to many modules used for example to set the output format. Finally kwargs are keyword parameters used to set the individual module options. But contrary to the Monolithic usage, the one letter GMT option syntax may be replaced by more verbose aliases. To make it clear let us look at couple of examples.coast(region=\"g\", proj=\"A300/30/6c\", frame=\"g\", resolution=\"c\", land=\"navy\")This command creates a map in PotScript file called GMTjl_tmp.ps and save it in your system\'s tmp directory. For comparison, the same command could have been written, using the classical one letter option syntax, as:coast(R=\"g\", J=\"A300/30/6c\", B=\"g\", D=\"c\", G=\"navy\")So, each module defines a set of aliases to the one letter options that are reported in each module man page.Before diving more in the way options may be transmitted into the module, we have to understand what happens with the output image file. By not directly specifying any format we are using the default output image format which is PostScript (actually, with the exception of grdimage -A, the only format that GMT can write). But we can select other formats by using the fmt keyword, for example fmt=\"jpg\", or fmt=:png or fmt=:pdf. In such cases, the ghostscript program (you need to have it installed) will take care of converting the ps file into the selected format. Note that we used either strings (\"\") or symbols (:) to represent the format. Here the rule is we can use symbols for any string argument that can be safely written as a symbol. Example, this is valid =:abc, but this is not =:+a (apparently parser will try to add to a). The use of symbols may be prefered for a question of lazzyness (less typing).The above example, however, does not use any input data (coast knows how to find its own data). One way of providing it to modules that work on them is to send in a file name with the data to operate on. This examplegrdimage(\"@tut_relief.nc\", shade=\"+ne0.8+a100\", proj=:M12c, frame=:a, show=true)reads a the netCDF grid tut_relief.nc and displays it as an Mercator projected image. The \'@\' prefix is used by GMT to know that the grid file should be downloaded from a server and cached locally. This example introduces also the show=true keyword. It means that we want to see right way the image that has just been created. While it might seam obvious that one want to see the result, the result might not be ready with only one GMT module call. And that\'s why the GMT philosophy uses a layer cake  model to construct potentially highly complex figures. Next example illustrates a slightly more evolved exampletopo = makecpt(color=:rainbow, range=\"1000/5000/500\", Z=[]);\ngrdimage(\"@tut_relief.nc\", shade=\"+ne0.8+a100\", proj=:M12c, frame=:a, color=topo,\n         fmt=:jpg)\ncolorbar!(position=\"jTC+w5i/0.25i+h+o0/-1i\", region=\"@tut_relief.nc\", color=topo,\n       frame=\"y+lm\", fmt=:jpg, show=true)Here we use the makecpt command to compute a colormap object and used it as the value of the color keyword of both grdimage and colorbar modules. The final image is made up of two layers, the first one is the part created by grdimage, which is complemented by the color scale plot performed by colorbar. But since this was an appending operation we HAD to use the ! form. This form tells GMT to append to a previous initiated image. The image layer cake is finalized by the show=true keyword. If our example had more layers, we would have used the same rule: second and on layers use the ! construct and the last is signaled by show=true.The examples above show also that we didn\'t completely get rid of the compact GMT syntax. For example the shade=\"+ne0.8+a100\" in grdimage means that we are computing the shade using a normalized a cumulative Laplace distribution and setting the Sun direction from the 100 azimuth direction. For as much we would like to simplify that, it\'s just not possible for the time being. To access the (very) high degree of control that GMT provides one need to use its full syntax. As such, readers are redirected to the main GMT documentation to learn about the fine details of those options.Setting line and symbol attributes has received, however, a set of aliases. So, instead of declaring the pen line attributes like -W0.5,blue,–, one can use the aliases lw=0.5, lc=\"blue\", ls=\"–\". An example would be:plot(collect(1:10),rand(10), lw=0.5, lc=:blue, ls=\"--\", fmt=:png, marker=:circle,\n     markeredgecolor=0, size=0.2, markerfacecolor=:red, title=\"Bla Bla\",\n     x_label=:Spoons, y_label=:Forks, show=true)This example introduces also keywords to plot symbols and set their attributes. Also shown are the parameters used to set the image\'s title and labels.But setting pen attributes like illustrated above may be complicated if one has more that one set of graphical objects (lines and polygons) that need to receive different settings. A good example of this is again provide by a coast command. Imagine that we want to plot coast lines as well as country borders with different line colors and thickness. Here we cannot simple state lw=1 because the program wouldn\'t know which of the shore line or borders this attribute applies to. The solution for this is to use tuples as values of corresponding keyword options.coast(limits=[-10 0 35 45], proj=:M12c, shore=(0.5,\"red\"), frame=:a,\n        show=1, borders=(1,(1,\"green\")))Here we used tuples to set the pen attributes, where the tuple may have 1 to 3 elements in the form (width[c|i|p]], [color], [style[c|i|p|]). The borders=(1,(1,\"green\")) option is actually a tuple-in-a-tuple because here we need also to specify the political boundary level to plot (1 = National Boundaries)."
},

{
    "location": "modules/#Specifying-the-pen-attributes-1",
    "page": "By Modules",
    "title": "Specifying the pen attributes",
    "category": "section",
    "text": "So, in summary, a pen attribute may be set in three different ways:With a text string that follows the width, color, style specs as explained in Specifying pen attributes\nBy using the lw or linewidth keyword where its value is either a number, meaning the line thickness in points, or a string like the width above; the color is set with the lc or linecolor and the value is either a number between [0 255] (meaning a gray shade) or a color name (for example \"red\"); and a ls or linestyle with the value specified as a string (example: \"- -\" plot a dashed line).\nA tuple with one to three elements: ([width], [color], [style]) where each of the elements follows the same syntax as explained in the case (2) above."
},

{
    "location": "modules/#Specifying-the-axes-1",
    "page": "By Modules",
    "title": "Specifying the axes",
    "category": "section",
    "text": "The axes are controlled by the B or frame or axes keywords. The easiest form it can have is the axes=:a, which means do an automatic annotation of the 4 map boundaries – left, bottom, right and top – axes. To annotate only the left and bottom boundaries, one would do axes=\"a WSne\" (note the space between a and WSne). For a higher level of control the user must really consult the original -B documentation.Other than setting titles and labels with a axes string we can also do it by using the keywords title, x_label and y_label.The figure limits is set with the R, region or limits  keywords. Again, the full docs for this option are explained in -R documentation. But other than the string version, the numeric form region=[xmin xmax ymin ymax] is also permitted. And when dealing with grids, even the region=mygrid.grd is a valid operation. Where mygrid.grd is a GMTgrid type. The plot() function allows a no limits setting, in which case it will default to the data\'s bounding box."
},

{
    "location": "modules/#Axes-(and-other)-configuration-1",
    "page": "By Modules",
    "title": "Axes (and other) configuration",
    "category": "section",
    "text": "There are almost 150 parameters which can be adjusted individually to modify the appearance of plots or affect the manipulation of data. When a program is run, it initializes all parameters to the GMTdefaults (see more at GMT defaults).  At times it may be desirable to temporarilly override some of those defaults. We can do that easily by using any of the keywords conf, par or params, which are recognized by all modules. Its usage follows closely the syntax described at gmt.conf but using Named Tuples. The parameter names are always given in UPPER CASE. The parameter values are case-insensitive unless otherwise noted and can be given as strings or numeric. Provide as many parameters as you want in the named tuple. Examplebasemap(...., conf=(MAP_TICK_LENGTH_PRIMARY=0.25, FORMAT_GEO_MAP=\"ddd:mm:ssF\"))"
},

{
    "location": "modules/#Specifying-the-figure-size-1",
    "page": "By Modules",
    "title": "Specifying the figure size",
    "category": "section",
    "text": "Figure sizes are automatically set to 12x8 cm for basic case of Cartesian xy plots done with the plot() function but otherwise in general they need to be user specified using the J or proj or projection keywords. See the full doc at -J documentation.  For Cartesian plots one can also use the figsize=width  or figsize=[width height] keyword, where the dimensions are in centimiters. The array form allows also set height or width to 0 to have it recomputed based on the implied scale of the other axis. Use negative sizes to reverse the direction of an axis (e.g., to have y be positive down). If neither of these forms is used, the figure width defaults to 14 cm."
},

{
    "location": "modules/#The-output-format-1",
    "page": "By Modules",
    "title": "The output format",
    "category": "section",
    "text": "It was referred above that the fmt determines the output format and that the default is PostScript. Actually the default format is choosen by the contents of the global FMT variable set at the top of the GMT.jl file. Eventually this will evolve to using an evironment variable but for the moment users will have to edit that file to set a different default format.A very interesting alternative is to set FMT=\"\", that is to not specify any image format. This will result in NOT saving any file on disk but to keep the PS figure internally stored in the program\'s memory.  In other words the figure is built and kept in memory only. This allows converting to another format directly without the use of an intermediary disk file. The conversion is performed by the psconvert GMT module that would be used like this (to convert to PDF):psconvert(in_memory=true, adjust=true, format=:f, out_name=\"myfig.pdf\")The issue with this solution, that could be implemented internally without user intervention, is that it currently only works on Windows.Another interesting alternative to a file format is the option to create RGB images with psconvert and return it to Julia as a Image type type.I = psconvert(in_memory=true, adjust=true)but again, so far on Windows only. A cool thing to develop would be the possibility to display this I image with the Images.jl package."
},

{
    "location": "modules/#Saving-data-to-disk-1",
    "page": "By Modules",
    "title": "Saving data to disk",
    "category": "section",
    "text": "As referred in the Monolithic section, we have two programs to do read and writing. Their module names are gmtread and gmtwrite. These modules allow to import and export any of the GMT data types to and from external files. For instance, to save the grid G stored into a GMTgrid type into the file relief.nc we run gmtwrite(\"relief.nc\", G)Here there is no need to inform about the type of data that we are dealing with because that can be inferred from the type of the numeric argument. There are cases, however, where we may want to save the result of a computation directly on disk instead of assigning it to a Julia variable and latter save it with gmtwrite. For computations that deal with grids that is easy. Just provide ask for an output name using the outgrid keyword, likegrdcut(G, limits=[3 9 2 8], outgrid=\"lixo.grd\");but for table data the GMT programs normally output their results to stdout so if we want to save data directly to disk (as would do the corresponding GMT shell command) we use the write or |> keywords. We can also use this mechanism to append to an existing file, but then we use the write_append keyword. The following converts the grid G to x,y,z triplets and save the result in a disk file.grd2xyz(G, write=\"lixo.xyz\")"
},

{
    "location": "modules/#How-inputs-are-transmitted-to-modules-1",
    "page": "By Modules",
    "title": "How inputs are transmitted to modules",
    "category": "section",
    "text": "Different modules take different number of inputs (for example grdblend accepts a variable number of grids) and some modules accept primary input and optionally a secondary input (for example the weights  option in grdtrend). The primary input(s) can be sent as text strings with the names of files to be read or as Julia variables holding the appropriate data type, and that as the first argument to the module call. Alternatively, the numeric input can be sent via the data keyword whose value can be a tuple when the expected input is composed by more than one variable. The same applies when an option is expected to receive more than one arguments (for example the three R,G,B in grdview). Examples:grdimage(G, intens=I, J=:M6i, color=C, B=\"1 WSne\", X=:c, Y=0.5, show=1)\n\ngrdimage(data=G, intens=I, J=:M6i, color=C, B=\"1 WSne\", X=:c, Y=0.5, show=1)\n\ngrdview(G, intens=:+, J=:M4i, JZ=\"2i\", p=\"145/35\", G=(Gr,Gg,Gb), B=\"af WSne\", Q=:i, show=1,)"
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
    "location": "types/#Grid-type-1",
    "page": "The GMT types",
    "title": "Grid type",
    "category": "section",
    "text": "type GMTgrid                  # The type holding a local header and data of a GMT grid\n   proj4::String              # Projection string in PROJ4 syntax (Optional)\n   wkt::String                # Projection string in WKT syntax (Optional)\n   range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]\n   inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]\n   registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration\n   nodata::Float64            # The value of nodata\n   title::String              # Title (Optional)\n   comment::String            # Remark (Optional)\n   command::String            # Command used to create the grid (Optional)\n   datatype::String           # \'float\' or \'double\'\n   x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates\n   y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates\n   z::Array{Float32,2}        # [n_rows x n_columns] grid array\n   x_units::String            # Units of XX axis (Optional)\n   y_units::String            # Units of YY axis (Optional)\n   z_units::String            # Units of ZZ axis (Optional)\n   layout::String             # A three character string describing the grid memory layout\nend"
},

{
    "location": "types/#Image-type-1",
    "page": "The GMT types",
    "title": "Image type",
    "category": "section",
    "text": "type GMTimage                 # The type holding a local header and data of a GMT image\n   proj4::String              # Projection string in PROJ4 syntax (Optional)\n   wkt::String                # Projection string in WKT syntax (Optional)\n   range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]\n   inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]\n   registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration\n   nodata::Float64            # The value of nodata\n   title::String              # Title (Optional)\n   comment::String            # Remark (Optional)\n   command::String            # Command used to create the image (Optional)\n   datatype::String           # \'uint8\' or \'int8\' (needs checking)\n   x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates\n   y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates\n   image::Array{UInt8,3}      # [n_rows x n_columns x n_bands] image array\n   x_units::String            # Units of XX axis (Optional)\n   y_units::String            # Units of YY axis (Optional)\n   z_units::String            # Units of ZZ axis (Optional) ==> MAKES NO SENSE\n   colormap::Array{Clong,1}   # \n   alpha::Array{UInt8,2}      # A [n_rows x n_columns] alpha array\n   layout::String             # A four character string describing the image memory layout\nend"
},

{
    "location": "types/#Dataset-type-1",
    "page": "The GMT types",
    "title": "Dataset type",
    "category": "section",
    "text": "type GMTdataset\n    data::Array{Float64,2}     # Mx2 Matrix with segment data\n    text::Array{Any,1}         # Array with text after data coordinates (mandatory only when plotting Text)\n    header::String             # String with segment header (Optional but sometimes very useful)\n    comment::Array{Any,1}      # Array with any dataset comments [empty after first segment]\n    proj4::String              # Projection string in PROJ4 syntax (Optional)\n    wkt::String                # Projection string in WKT syntax (Optional)\nend"
},

{
    "location": "types/#CPT-type-1",
    "page": "The GMT types",
    "title": "CPT type",
    "category": "section",
    "text": "type GMTcpt\n    colormap::Array{Float64,2}\n    alpha::Array{Float64,1}\n    range::Array{Float64,2}\n    minmax::Array{Float64,1}\n    bfn::Array{Float64,2}\n    depth::Cint\n    hinge::Cdouble\n    cpt::Array{Float64,2}\n    model::String\n    comment::Array{Any,1}   # Cell array with any comments\nend"
},

{
    "location": "types/#Postscript-type-1",
    "page": "The GMT types",
    "title": "Postscript type",
    "category": "section",
    "text": "type GMTps\n    postscript::String      # Actual PS plot (text string)\n    length::Int             # Byte length of postscript\n    mode::Int               # 1 = Has header, 2 = Has trailer, 3 = Has both\n    comment::Array{Any,1}   # Cell array with any comments\nend"
},

]}
