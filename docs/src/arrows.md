# Arrow controls

Set arrow parameters. They are specified by a keyword (*arrow*) and a named tuple.
Several modifiers may be provided for specifying the placement of vector heads, their shapes, and the justification
of the vector. Below, left and right refers to the side of the vector line when viewed from the start point to the
end point of a segment:

    arrow=(length=..., start=..., shape=..., pen=..., norm=..., etc)

- *len=xx* or *length=xx* is the length of the vector head. *xx* may be numeric, a string with the length and the
   units attached (as in len="2c") or a tuple with length and units as in *len=(2,:centimeters)*
- *angle=xx* sets the angle of the vector head apex [default 30]
- *start=true* places a vector head at the beginning of the vector path [none]. Optionally, set
  - *start=:line* for a terminal line
  - *start=:arrow* for a arrow (the default)
  - *start=:circle* for a circle
  - *start=:tail* for a tail
  - *start=:open_arrow* for a plain open arrow
  - *start=:open_tail* for a plain open tail
  - *start=:left_side* for draw the left half-side
  - *start=:right_side* for draw the right half-side
- *stop=true* places a vector head at the end of the vector path [none]. Optionally, set the same values as the *start* case.
- *middle=true* places a vector head at the mid-point of the vector path [none]. Optionally, set the same values as the *start* case
   but it can't be used with the *start* and *stop* options. But it accepts two further options:
  - *middle=:forward* for forward direction of the vector [the default]
  - *middle=:reverse* for reverse direction of the vector.
- *fill=color* sets the vector head fill. The *color* value may contain any of valid ways ways of specifying color.
  - *fill=:none* turns off vector head fill
- *shape=xx* sets the shape of the vector head (range -2/2). Determines the shape of the head of a vector. Normally
   (i.e., for vector_shape = 0), the head will be triangular, but can be changed to an arrow (1) or an open V (2).
   Intermediate settings give something in between. Negative values (up to -2) are allowed as well. Shortcuts available as:
  - *shape=:triang*     same as *shape=0*
  - *shape=:arrow*      same as *shape=1*
  - *shape=:V*          same as *shape=2*
- *half_arrow=:left*  draws half-arrows, using only the left side of specified heads [default is both sides].
- *half_arrow=:right* draws half-arrows, using only the right side of specified heads [default is both sides].
- *norm=xx* scales down vector attributes (pen thickness, head size) with decreasing length, where vector plot lengths
   shorter than norm will have their attributes scaled by length/norm. *xx* may be a number or a string (number&unit).
- *oblique_pole=(plon,plat)*  specifies the oblique pole for the great or small circles.
- *pen=pen*  sets the vector pen attributes. The *pen* value may contain any of valid ways of specifying pens.
   If pen has a leading '-' (and hence the *pen* value must be a string) then the head outline is not drawn.
- *ang1_ang2=true* or *start_stop=true* means the input angle, length data instead represent the start and stop opening
   angles of the arc segment relative to the given point.
- *trim=trim*  will shift the beginning or end point (or both) along the vector segment by the given trim. To select
   begin or end prepend a 'b' or a 'e' to the *trim* value (hence it must be a string). Append suitable unit (c, i, or p).
   If the modifiers b|e are not used then trim may be two values separated by a slash, which is used to specify different
   trims for the beginning and end. Positive trims will shorted the vector while negative trims will lengthen it [no trim].

In addition, all but circular vectors may take these options:

- *justify=* determines how the input x,y point relates to the vector. Choose from
  - *justify=:beginning*          The default
  - *justify=:end*
  - *justify=:center*
- *endpoint=true*   means the input angle, length are instead the x, y coordinates of the vector end point.

Finally, Cartesian vectors may take this option:

- *uv=scale*     expects input vx,vy vector components and uses the scale to convert to polar coordinates with length in given unit.
