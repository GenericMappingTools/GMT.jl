## Line colors with custom CPT and auto color wrap

In this example the lines color is set using a custom CPT. Pen thickness is assigned automatically.

The custom CPT is used by setting the plot command’s cmap argument to ``true``. This workas because we previously computed the CPT and it will remain in memory until it's consumed when we finish the plot. The **level** argument sets the color to be used from the custom CPT.

In fact, in this case with a CPT already in memory, the **level** option alone would have triggered the line coloring and the **cmap** option could have been droped.

Normally we don't need to start a figure with a call to *basemap* because the *plot* function takes care of guessing reasonable  defaults, but in this case we start with a curve with small amplitude and we grow the figure by adding more lines. So if we leave it to automatic guessing one would have to start by the largest amplitude curve.

```julia
using GMT
C = makecpt(range=(0,10,1));
basemap(region=(20,30,-10,10), figsize=(12,8))
x = 20:0.1:30;
for amp=0:10
	y = amp .* sin.(x)
	plot!(x, y, cmap=true, level=amp)
end
colorbar!(figname="clines1.png", show=true)
```

```@raw html
<img src="../clines1.png" width="600" class="center"/>
```

## Line colors with the automatic color scheme

Here we are showing how to plot several lines at once and color them according to a circular color scheme comprised of 7 distinct colors. We start by generating a dummy matrix 8x5, where rows represent the vertex and the columns hold the lines. To tell the program that first column contains the coordinates and the remaining are all lines to be plotted we use the option **multicol**=*true*

```julia
mat = GMT.fakedata(8, 5);
lines(mat, multicol=true, figname="clines2.png", show=true)
```

```@raw html
<img src="../clines2.png" width="600" class="center"/>
```

But if we want choose the colors ourselves, it is also easy though we need to go a bit lower in the data preparation.

The basic data type to transfer tabular data to GMT is the *GMTdataset* and the above command has converted the matrix into a *GMTdataset* under the hood but now we need to create one ourselves and fine control more details, like the colors and line thickness of the individual lines. Not that we have 5 lines but will provide 3 colors and 3 lines thicknesses. When we do this those properties are wrapped modulo its number.

```julia
D = mat2ds(mat, color=["brown", "green", "blue"], linethick=[2, 1.0, 0.5, 0.25], multi=true);
```

And now we just call *lines* (but using *plot* would have been the same) with the **D** argument.

```julia
lines(D, figname="clines3.png", show=true)
```

```@raw html
<img src="../clines3.png" width="600" class="center"/>
```