# Choropleth maps

A choropleth is a thematic map where areas are colored in proportion to a variable such as population density. GMT lets us plot choropleth maps but the process is not straightforward because we need to put the color information in the header of a multi-segment file. To facilitate this, some tools were added to the Julia wrapper.

Load packages needed to download data and put into a DataFrame


```julia
paises = CSV.File(HTTP.get("https://raw.githubusercontent.com/tillnagel/unfolding/master/data/data/countries-population-density.csv").body, delim=';') |> DataFrame;
```

Extract the Europe countries from the DCW file

```julia
eu = coast(DCW="=EU+z", dump=true);
```

Generate two vector with country codes (2 chars codes) and the population density for European countries.

```julia
codes, vals = GMT.mk_codes_values(paises[!, 2], paises[!, 3], region="eu");
```

Create a Categorical CPT that allows plotting the choropleth.
Note that we need to limit the CPT range to leave out the very high density *states* like Monaco otherwise all others would get the same color.

```julia
C = cpt4dcw(codes, vals, range=[10, 500, 10]);
```

Show the result

```julia
plot(eu, cmap=C, fill="+z", proj=:guess, R="-76/36/26/84", title="Population density",
	colorbar=true, show=true)
```

```@raw html
<img src="../choro1_dcw.png" width="500" class="center"/>
```

---

*Download a [Pluto Notebook here](contourf.jl)*
