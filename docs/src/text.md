# text

	text(cmd0::String="", arg1=nothing; kwargs...)

Plot or typeset text on maps

Description
-----------

**text** plots text strings of variable size, font type, and orientation. Various map projections are provided, with the option to draw and annotate the map boundaries. Greek characters, subscript, superscript, and small caps are supported as follows: The sequence @~ toggles between the selected font and Greek (Symbol). @%\ *no*\ % sets the font to *no*; @%% resets the font to the starting font, @- toggles subscripts on/off, @+ toggles superscript on/off, @# toggles small caps on/off, @;\ *color*; changes the font color (@;; resets it), @:\ *size*: changes the font size (@:: resets it), and @\_ toggles underline on/off. @@ prints the @ sign. @e, @o, @a, @E, @O, @A give the accented Scandinavian characters. Composite characters (overstrike) may be indicated with the @!<char1><char2> sequence, which will print the two characters on top of each other. To learn the octal codes for symbols not available on the keyboard and some accented European characters, see Section `Char-esc-seq` and Appendix `Chart-Octal-Codes-for-Chars` in the GMT Technical Reference and Cookbook. Note that `PS_CHAR_ENCODING` must be set to an extended character set in your `gmt.conf` file in order to use the accented characters. Using the **fill** or **pen** options, a rectangle underlying the text may be plotted (does not work for strings with sub/super scripts, symbols, or composite characters, except in paragraph mode (**paragraph**)). 

Required Arguments
------------------

- **J** or **proj** : *proj=<parameters>*\
   Select map projection. More at [proj](@ref)

- **R** or **region** or **limits** : *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more 
   Specify the region of interest. More at [limits](@ref)

Optional Arguments
------------------

*textfiles*
    This is one or more files containing 1 or more records with (*x*, *y*\ [, *font*, *angle*, *justify*], *text*). The attributes in brackets can alternatively be set directly via **attrib**. If no files are given, **text** will read standard input. *font* is a font specification with format [*size*,][\ *font*,][*color*\ ]where *size* is text size in points, *font* is the font to use, and *color* sets the font color. To draw outline fonts you append =\ *pen* to the font specification. The *angle* is measured in degrees counter-clockwise from horizontal, and *justify* sets the alignment. If *font* is not an integer, then it is taken to be a text string with the desired font name (see **list** for available fonts). The alignment refers to the part of the text string that will be mapped onto the (*x*,\ *y*) point. Choose a 2 character combination of L, C, R (for left, center, or right) and T, M, B for top, middle, or bottom. e.g., BL for lower left.

- **A** or **azimuths** : -- *azimuths=true*\
    Angles are given as azimuths; convert them to directions using the current projection. 

- **B** or **axis** or *frame*\
   Set map boundary frame and axes attributes. More at [axis](@ref)

- **-C** or **clearance** : -- *clearance=true* **|** *clearance=(margin=(dx,dy), round=true, concave=true, comvex=true)*\
    Adjust the clearance between the text and the surrounding box [15%]. Only used if **pen** or **fill** are specified. Append the unit you want (**c**\ m, **i**\ nch, or **p**\ oint; if not given we consult
    `PROJ_LENGTH_UNIT`) or % for a percentage of the font size. Optionally, use options *round* (rounded rectangle) or, for **paragraph** mode only, *concave* or *convex* to set the shape of the textbox when using **fill** and/or **pen**. Default gets a straight rectangle.

- **D** or **offset** : -- *offset=([away=true, corners=true,] shift=(dx,dy) [,line=pen])*\
    Offsets the text from the projected (*x, y*) point by *shift=(dx, dy)*. If *dy* is not specified then it is set equal to *dx*. Use **offset=(away=true,)** to offset the text away from the point instead (i.e., the text justification will determine the direction of the shift). Using **offset=(corners=true,)** will shorten diagonal offsets at corners by sqrt(2). Optionally, use **offset=(line=true,)** which will draw a line from the original point to the shifted point; use **offset=(line=pen,)** to change the *pen* attributes for this line.

- **F** or **attrib** : -- *attrib=(angle=val, font=font, justify=code, region\_justify=code, header=true, label=true, rec\_number=first, text=text, zvalues=format)*\
    By default, text will be placed horizontally, using the primary annotation font attributes (`FONT_ANNOT_PRIMARY`), and centered on the data point. Use this option to override these defaults by specifying up to three text attributes (font, angle, and justification). Use **font=font** to set the font (size,fontname,color). For example **font=18** or **font=(18, "Helvetica-Bold", :red)**; if no font info is given then the input file must have this information in one of its columns. Use **angle=val** to set the angle; if no angle is given then the input file must have this as a column. Alternatively, use **Angle=val** to force text-baselines to convert into the -90/+90 range.  Use **justify=code** to set the justification; if no justification is given then the input file must have this as a column. Items read from the data should be in the same order as specified with the **F** option. Example: **font=(18, "Helvetica-Bold", :red), justify="", angle=""** selects a 12p red Helvetica-Bold font and expects to read the justification and angle from the file, in that order, after *x*, *y* and before *text*.
    In addition, the **region\_justify** justification lets us use x,y coordinates extracted from the **region** string instead of providing them in the input file. For example **region\_justify=:TL** gets the *x\_min*, *y\_max* from the **region** string and plots the text at the Upper Left corner of the map. Normally,the text to be plotted comes from the data record. Instead, use **header=true** or **label=true** to select the text as the most recent segment header or segment label, respectively in a multisegment input file, **rec\_number=first** to use the record number (counting up from *first*), **text=text** to set a fixed *text* string, or **zvalues** to format incoming *z* values to a string using the supplied *format* (**zvalues=""** uses `FORMAT_FLOAT_MAP`). Note: If **threeD** is in effect then the *z* value used for formatting is in the 4th, not 3rd column.
    Exceptionally, this option can be broken up in its individual pieces by dropping the **attrib** keyword. 

- **G** or **fill** : -- *fill=color* **|** *fill=:c*\
    Sets the shade or color used for filling the text box [Default is no fill]. Alternatively, use **fill=:c** to plot the text and then use the text dimensions (and **clearance**) to build clip paths and turn clipping on. This clipping can then be turned off later with `clip` **C**. To *not* plot the text but activate clipping, use **fill=:C** instead.

- **L** or **list** : -- *list=true*\
    Lists the font-numbers and font-names available, then exits.

- **M** or **paragraph** : -- *paragraph=true*\
    Paragraph mode. Files must be multiple segment files. Segments are separated by a special record whose first character must be *flag* [Default is **>**]. Starting in the 3rd column, we expect to find information pertaining to the typesetting of a text paragraph (the remaining lines until next segment header). The information expected is (*x y* [*font angle justify*\ ] *linespace parwidth parjust*), where *x y font angle justify* are defined above (*font*, *angle*, and *justify* can be set via **F**), while *linespace* and *parwidth* are the linespacing and paragraph width, respectively. The justification of the text paragraph is governed by *parjust* which may be **l**\ (eft), **c**\ (enter), **r**\ (ight), or **j**\ (ustified). The segment header is followed by one or more lines with paragraph text. Text may contain the escape sequences discussed above. Separate paragraphs with a blank line. Note that here, the justification set via **justify** applies to the box alignment since the text justification is set by *parjust*.

- **N** or **noclip** or **no\_clip** : *noclip=true*\
    Do NOT clip text at map boundaries [Default will clip]. 

- **Q** or **change\_case** : -- *change\_case=:lower* **|** *change\_case=:upper*\
    Change all text to either **change\_case=:lower** or **change\_case=:upper** case [Default leaves all text as is].

- **U** or **stamp** : *stamp=true* **|** *stamp=(just="code", pos=(dx,dy), label="label", com=true)*\
   Draw GMT time stamp logo on plot. More at [stamp](@ref)

- **V** or **verbose** : *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **W** or **pen** : -- *pen=pen*\
    Sets the pen used to draw a rectangle around the text string (see **clearance**) [Default is width = default, color = black, style = solid].

- **X** or **x_off** or **x_offset** : *x_off=[]* **|** *x_off=x-shift* **|** *x_off=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [x_off](@ref)

- **Y** or **y_off** or **y_offset** : *y_off=[]* **|** *y_off=y-shift* **|** *y_off=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [y_off](@ref)

- **Z** or **threeD** : -- *threeD=true*\
    For 3-D projections: expect each item to have its own level given in the 3rd column, and **noclip** is implicitly set. (Not implemented for paragraph mode). 



Limitations
-----------

In paragraph mode, the presence of composite characters and other escape sequences may lead to unfortunate word splitting. Also, if a font is requested with an outline pen it will not be used in paragraph mode. Note if any single word is wider than your chosen paragraph width then the paragraph width is automatically enlarged to fit the widest word.

Examples
--------

To plot just the red outlines of the (lon lat text strings) stored in the file text.txt on a Mercator plot with the given specifications, use

    text("text.txt", region=(-30,30,-10,20), proj=:merc, figscale=0.25, font=(18,:Helvetica,"-=0.5p",:red), frame=(annot=5,), show=true)