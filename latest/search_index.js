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
    "text": "psxy(cmd0::String=\"\", arg1=[]; caller=[], data=[], fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nreads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines, polygons, or symbols at those locations on a map. If a symbol is selected and no symbol size given, then psxy will interpret the third column of the input data as symbol size. Symbols whose size is <= 0 are skipped. If no symbols are specified then the symbol code must be present as last column in the input. If -S is not used, a line connecting the data points will be drawn instead. To explicitly close polygons, use -L. Select a fill with -G. If -G is set, -W will control whether the polygon outline is drawn or not. If a symbol is selected, -G and -W determines the fill and outline/no outline, respectively.\n\nFull option list at psxy\n\nParameters\n\nA : straight_lines : – Str –     By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use the -A flag.\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : – Str –   Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.   -C\nD : offset : – Str –  'dx/dy'   Offset the plot symbol or line locations by the given amounts dx/dy.\nE : error_bars : – Str –   '[x|y|X|Y][+a][+cl|f][+n][+wcap][+ppen]'   Draw symmetrical error bars.   -E\nF : conn : connection : – Str –   '[c|n|r][a|f|s|r|refpoint]'   Alter the way points are connected   -F\nG : fill : markerfacecolor : MarkerFaceColor : – Str –   Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the   color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use   'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow   -G\nI : intens : – Str or number –   Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.\nL : closed_polygon : – Str –    '[+b|d|D][+xl|r|x0][+yl|r|y0][+ppen]'   Force closed polygons.    -L\nN : no_clip : –- Str or [] –   '[c|r]'   Do NOT clip symbols that fall outside map border \nP : portrait : –- Bool or [] –   Tell GMT to NOT draw in portriat mode (that is, make a Landscape plot)\nS : symbol : marker : Marker : – Str –  '[symbol][size[u]]'   Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines).    -S   Alternatively select a sub-set of symbols using the aliases: marker or Marker and values:\n-, x_dash\n+, plus\na, *, star\nc, circle\nd, diamond\ng, octagon\nh, hexagon\ni, v, inverted_tri\nn, pentagon\np, ., point\nr, rectangle\ns, square\nt, ^, triangle\nx, cross\ny, y_dash\nW : line_attribs : markeredgecolor : MarkerEdgeColor : – Str –  '[pen][attr]'   Set pen attributes for lines or the outline of symbols   -W   WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.   If your plot has polygons and symbols, use W or line_attribs for the polygons and   markeredgecolor or MarkerEdgeColor for filling the symbols. Similar to S above.\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\na : aspatial : – Str –\nbi : binary_in : – Str –\ndi : nodata_in : – Str –\ne : patern : – Str –\nf : colinfo : – Str –\ng : gaps : – Str –\nh : headers : – Str –\ni : input_col : – Str –\np : perspective : – Str –\nt : alpha : transparency : – Str –\n\n\n\n"
},

{
    "location": "#GMT.pscoast",
    "page": "Home",
    "title": "GMT.pscoast",
    "category": "Function",
    "text": "pscoast(cmd0::String=\"\"; fmt=\"\", clip=[], K=false, O=false, first=true, kwargs...)\n\nPlot continents, shorelines, rivers, and borders on maps. Plots grayshaded, colored, or textured land-masses [or water-masses] on maps and [optionally] draws coastlines, rivers, and political boundaries. A map projection must be supplied.\n\nFull option list at http://gmt.soest.hawaii.edu/doc/latest/pscoast.html\n\n- F = box\n- M = dump\n- Td = rose\n- Tm = compass\n\nParameters\n----------\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nA : area : – Str or number –       'min_area[/min_level/max_level][+ag|i|s|S][+r|l][+ppercent]'       Features with an area smaller than min_area in km^2 or of       hierarchical level that is lower than min_level or higher than       max_level will not be plotted.\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : river_fill : – Str –       Set the shade, color, or pattern for lakes and river-lakes.\nD : res : resolution : – Str –       Selects the resolution of the data set to use ((f)ull, (h)igh,       (i)ntermediate, (l)ow, and (c)rude).\nE : ECW : – Str –  Tuple(Str, Str); Tuple(\"code\", (pen)), ex: (\"PT\",(0.5,\"red\",\"–\")); Tuple((...),(...),...)       'code1,code2,...[+l|L][+gfill][+ppen]'		       Select painting or dumping country polygons from the Digital Chart of the World\nG : land : – Str –       Select filling or clipping of “dry” areas.\nI : rivers : – Str –       'river[/pen]'       Draw rivers. Specify the type of rivers and [optionally] append pen       attributes.\nL : map_scale : – Str –       Dtraw a map scale.\nN : borders : – Str –       'border[/pen]'       Draw political boundaries. Specify the type of boundary and       [optionally] append pen attributes\nP : portrait : –- Bool or [] –   Tell GMT to NOT draw in portriat mode (that is, make a Landscape plot)\nS : water : – Str –       Select filling or clipping of “wet” areas.\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nW : shore : – Str –       '[level/]pen'       Draw shorelines [Default is no shorelines]. Append pen attributes.\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\nbo : binary_out : – Str –\np : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.psscale",
    "page": "Home",
    "title": "GMT.psscale",
    "category": "Function",
    "text": "psscale(cmd0::String=\"\", arg1=[]; fmt=\"\", K=false, O=false, first=true, kwargs...)\n\n\n\n"
},

{
    "location": "#GMT.grdimage",
    "page": "Home",
    "title": "GMT.grdimage",
    "category": "Function",
    "text": "grdimage(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],\n		 fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nProduces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning them a gray-shade (or color) based on the z-value.\n\nFull option list at grdimage\n\nParameters\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\n\n\n\n"
},

{
    "location": "#GMT.grdcontour",
    "page": "Home",
    "title": "GMT.grdcontour",
    "category": "Function",
    "text": "grdcontour(cmd0::String=\"\", arg1=[]; data=[], fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nParameters\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\n\n\n\n"
},

{
    "location": "#GMT.grdview",
    "page": "Home",
    "title": "GMT.grdview",
    "category": "Function",
    "text": "grdview(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],\n        fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nReads a 2-D grid file and produces a 3-D perspective plot by drawing a mesh, painting a colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons to a raster image.\n\nFull option list at grdimage\n\nJ : proj : projection : – Str –     Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.   -J\nR : region : limits : – Str or list –    'xmin/xmax/ymin/ymax[+r][+uunit]'.   Specify the region of interest. Set to data minimum BoundinBox if not provided.   -R\nB : frame : axes : – Str –  '[p|s]parameters'   Set map boundary frame and axes attributes.   -B\nC : color : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nU : stamp : – Str or Bool or [] –   '[[just]/dx/dy/][c|label]'   Draw GMT time stamp logo on plot.\nV : verbose : – Bool or Str –   '[level]'   Select verbosity level    -V\nX : x_offset : – Str –   '[a|c|f|r][x-shift[u]]'\nY : y_offset : – Str –   '[a|c|f|r][y-shift[u]]'   Shift plot origin.    -Y\nn : interp : – Str –     -n\np : perspective : – Str –     -p\nt : alpha : transparency : – Str –     -t\n\n\n\n"
},

{
    "location": "#GMT.makecpt",
    "page": "Home",
    "title": "GMT.makecpt",
    "category": "Function",
    "text": "makecpt(cmd0::String=\"\", arg1=[]; data=[], kwargs...)\n\nMake static color palette tables (CPTs).\n\n#jldoctest #julia> cpt = makecpt(range=\"-1/1/0.1\"); #julia> (size(cpt.colormap,1) == 20) && (cpt.colormap[1,:] == [0.875, 0.0, 1.0]) #true #\n\nC : color : – Str –   Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color   master dynamic CPT.   -C\nbi : binary_in : – Str –\ndi : nodata_in : – Str –\ni : input_col : – Str –\n\n\n\n"
},

{
    "location": "#Functions-1",
    "page": "Home",
    "title": "Functions",
    "category": "section",
    "text": "psxy(cmd0::String=\"\", arg1=[]; caller=[], data=[], fmt=\"\",\n     K=false, O=false, first=true, kwargs...)\n\npscoast(cmd0::String=\"\"; fmt=\"\", clip=[], K=false, O=false, first=true, kwargs...)\n    \npsscale(cmd0::String=\"\", arg1=[]; fmt=\"\", K=false, O=false, first=true, kwargs...)\n\ngrdimage(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],\n         fmt=\"\", K=false, O=false, first=true, kwargs...)\n\ngrdcontour(cmd0::String=\"\", arg1=[]; data=[], fmt=\"\",\n           K=false, O=false, first=true, kwargs...)\n\ngrdview(cmd0::String=\"\", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],\n        fmt=\"\", K=false, O=false, first=true, kwargs...)\n\nmakecpt(cmd0::String=\"\", arg1=[]; data=[], kwargs...)"
},

]}
