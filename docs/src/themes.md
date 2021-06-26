# Themes

Currently GMT.jl offers 3 themes (classic, modern, and dark). Classic theme has been the default
up to version 0.34.0. Starting in 0.35.0 the so called (by GMT) modern theme has become the default.
Differences may not be obvious at first (except for the default axes line width that was decreased
to half-width [0.75p]) but it holds a significant improvement in its capability to scale the size
of fonts and line thicknesses in function of figure size.

A third theme is the `dark` mode. Besides these 3 themes the last two (modern and dark) can still
be tweaked with some other parameters. Basically one can use the `theme` as a function or as an
option in the `plot` (and its avatars) module.

```
theme(name; kwrgs...)
```

- `modern`: - This is the default theme (same as GMT modern theme but with thinner FRAME_PEN [0.75p])
- `classic`: - The GMT classic theme
- `drak`: - A modern theme variation with dark background.

On top of the modern mode variations (so far `dark` only) one can set the following `kwargs` options:

- `noticks` or `no_ticks`: Axes will have annotations but no tick marks
- `inner_ticks` or `innerticks`: - Ticks will be drawn inside the axes instead of outside.
- `gray_grid` or `graygrid`: - When drawing grid line use `gray` instead of `black`
- `save`: - Save the name in the directory printed in shell by gmt --show-userdir and make it permanent.
- `reset`: - Remove the saved theme name and return to the default `modern` theme.

Note: Except `save` and `reset`, the changes operated by the `kwargs` are temporary and operate only until
an image is `show`(n) or saved.

This function can be called alone, e.g. `theme("dark")` or as an keyword option in the `plot()` module. *e.g.*
`plot(..., theme=:dark)` or `plot(..., theme=(modern, noticks=true))`