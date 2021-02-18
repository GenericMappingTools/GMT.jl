# Bar plots

A simple bar plot showing color and bar width (in data units) assignement.

```julia
bar(1:5, (20, 35, 30, 35, 27), width=0.5, color=:lightblue, limits=(0.5,5.5,0,40), show=true)
```

```@raw html
<img src="../bars0.png" width="600" class="center"/>
```

A colored bar plot with colors proportional to bar heights. In this case we let the plot limits be determined from data. We also plot a colorbar by using the **colorbar**=*true* option.

```julia
bar(rand(15), color=:turbo, figsize=(14,8), title="Colored bars", colorbar=true, show=true)
```

```@raw html
<img src="../bars1.png" width="600" class="center"/>
```

Example showing how to plot bar groups and at same time assign variable transparency to each of the group's *band* usinf the **fillalpha** option. Here, each row on the input data represents a bar group that has as many *bands* as n_columns - 1. -1 because first column must hold the *xx* coordinates of each group. The colors come from the automatic cyclic scheme.

```julia
bar([0. 1 2 3; 1 2 3 4], fillalpha=[0.3 0.5 0.7], show=true)
```

```@raw html
<img src="../bars2.png" width="600" class="center"/>
```

Next example shows how to plot error bars in a grouped bar. Similar to this [mapplotlib's example](https://matplotlib.org/3.1.1/gallery/lines_bars_and_markers/barchart.html#sphx-glr-gallery-lines-bars-and-markers-barchart-py) (labels will come later).

```julia
bar(1:5, [20 25; 35 32; 30 34; 35 20; 27 25], width=0.7, fill=["lightblue", "brown"],
    error_bars=(y=[2 3; 3 5; 4 2; 1 3; 2 3],), xticks=(:G1, :G2, :G3, :G4, :G5), yaxis=(annot=5,label=:Scores), frame=(title="Scores by group and gender", axes=:WSrt), show=true)
```

```@raw html
<img src="../bars3.png" width="600" class="center"/>
```

Example of a verticaly stacked bar plot. In this exampled we pass the *xx* coordinates as first argument and the individual bar heights in a matrix with smae number of rows as the number of elements in the *x* vector. To make it plot a stracked bar we used the option **stacked**=*true*.

```julia
bar(1:3,[-5 -15 20; 17 10 21; 10 5 15], stacked=1, show=1)
```

```@raw html
<img src="../bars4.png" width="600" class="center"/>
```

To create an horizontal bar plot we use the **hbar**=*true* option"

```julia
bar([0. 1 2 3; 1 2 3 4], hbar=true, show=true)
```

```@raw html
<img src="../bars5.png" width="600" class="center"/>
```

And one horizontal and stacked but this time we pick the colors.

```julia
bar([0. 1 2 3; 1 2 3 4], stack=true, hbar=true, fill=["red", "green", "blue"], show=true)
```

```@raw html
<img src="../bars6.png" width="600" class="center"/>
```

---

*Download a [Pluto Notebook here](bars.jl)*
