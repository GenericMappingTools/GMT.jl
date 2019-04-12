
# Setting color

Color can be selected in several different ways. One of the is to create color maps with the *makecpt* and
*grd2cpt* modules (see their own man pages). This is the method we use to colorize images, sets of points, etc.
The other option sets the color via keyword/value pairs and is appropriate to color fill polygons, individual
symbols, etc and the one documented here.

We may use this in modules that expect the *color* or *fill* keywords, then the value can be a string or a
symbol with the color's name (or names separated by commas); a number in the [0 255] range to indicate a
gray shade tone; or a 3-elements tuple (more tricky) or array (simpler) where each element contains the
R,G,B component in either [0 255] or [0 1] range.

Examples:

- *color=:red*                     Single color
- *color=200*                      Single gray
- *color="#aabbcc"*                Single color
- *color="30/20/180"*              Single color
- *color="yellow,brown"*           Two colors
- *color=(30,180)*                 Two gray levels
- *color=((30,20,180),)*           Single color
- *color=((10,50,99),(20,60,90))*  Two colors
- *color=[0.118 0.078 0.706]*      Single color in [0 1]
- *color=[10 50 99; 20 60 90]*     Two colors
- *color=(:red,:green,:blue)*      Three colors

But there are other options that expect color in one of its elements. For example, to set a text font we
may want to choose a color (i.e. not use the default which is black). Then we would do drop the *color=*
and use the value in that other option value. For example *font=(12, "Helvetica", (30,20,180))*, where the color
is the third element in the *font* keyword option. 