
# Setting fonts

    font = (size, fontname, color)

A text font is composed of three parts: 1) a *size*; 2) a *fontname; 3) the font *color*.
The *size* may be a scalar, a string with the units appended or a tuple with (size, units).
The *fontname* is a string or symbol with the font name. e.g "Helvetica". See [here](https://gmt.soest.hawaii.edu/doc/latest/GMT_Docs.html#postscript-fonts-used-by-gmt) for
the available font names.
The *color* is a color element, See [Setting color](@ref)

Both *fontname* and *color* are optional. So a font=10 is a valid setting, meaning a default font of size 10
points. It's also valid to provide a all font parametrs in a string using the compact GMT syntax.
The [GMT docs](https://gmt.soest.hawaii.edu/doc/latest/GMT_Docs.html#specifying-fonts) has further details on
this option.

Examples:

- *font="24p"*
- *font=("14p",:red)*
- *font=(12, :Helvetica, (30,20,180))*
- *font="12p,Helvetica-Bold,red"*