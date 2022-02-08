# Choropleth example Covid rate of infection in Portugal

First, download the Portuguese district polygons shape file from this [Github repo](https://github.com/dssg-pt/covid19pt-data/tree/master/extra/mapas/concelhos)
Next load it with:

```julia
using GMT, DataFrames, CSV
```

```julia
Pt = gmtread("C:\\programs\\compa_libs\\covid19pt\\extra\\mapas\\concelhos\\concelhos.shp");
```

Download and load a CSV file from [same repo](https://github.com/dssg-pt/covid19pt-data/blob/master/data_concelhos_incidencia.csv) with rate of infection per district. Load it into a DataFrame to simplify data extraction.

```julia
incidence = CSV.read("C:\\programs\\compa_libs\\covid19pt\\data_concelhos_incidencia.csv", DataFrame);
```

Get the rate of incidence in number of infected per 100_000 habitants for the last reported week.

```julia
r = collect(incidence[end, 2:end]);
```

But the damn polygon names above are all uppercase, Ghrrr. We will have to take care of that.

```julia
ids = names(incidence)[2:end];
```

Each of the `Pt` datasets have attributes (*e.g.*, Pt[1].attrib) and the one that is common with the names in **ids** is the
``Pt[1].attrib["NAME_2]`` (the *conselho* name). But the names in *data_concelhos_incidencia.csv* (from which the **ids** are derived)
and the *concelhos.shp* (that we read into ``Pt``) do not use the same case (one is full upper case) so we need to use the
``nocase=true`` below. The comparison is made inside the next call to the ``polygonlevels()`` function that takes care to
return the numerical vector that we need in *plot's* **level** option.

```julia
zvals = polygonlevels(Pt, ids, r, att="NAME_2", nocase=true);
```

Create a Colormap to paint the district polygons

```julia
C = makecpt(range=(0,1500,10), inverse=true, cmap=:oleron, hinge=240, bg=:o);
```

Get the date for the data being represented to use in title

```julia
date = incidence[end,1];
```

And finaly do the plot

```julia
plot(Pt, level=zvals, cmap=C, pen=0.5, region=(-9.75,-5.9,36.9,42.1), proj=:Mercator, title="Infected / 100.000 habitants " * date)
```

```julia
colorbar!(pos=(anchor=:MR,length=(12,0.6), offset=(-2.4,-4)), color=C, axes=(annot=100,), show=true)
```

```@raw html
<img src="../choropleth_cv19.png" width="400" class="center"/>
```

---

*Download a [Pluto Notebook here](choropleth_cv19.jl)*
