### Plot countries administrative units from [GADM](https://gadm.org) data

We start by download and save in cache the geopackage file with Mozambique data.
Note, a downloading message will be printed only once, and in this case it will say

*Downloading geographic data for country MOZ provided by the https://gadm.org project. It may take a while.
The file gadm36_MOZ.gpkg (after uncompressing) will be stored in c:/j/.gmt\cache*

```julia
using GMT
mozambique = gadm("MOZ");
```

```julia
imshow(mozambique, proj=:guess, title="Mozambique")
```

```@raw html
<img src="../mozambique.png" width="400" class="center"/>
```

Next let us add all the provincies of Mozambique. For that we'll use the country code as parent and the option `children=true` to indicate that we want all provincies boundaries.

```julia
mozambique = gadm("MOZ", children=true);
imshow(mozambique, proj=:guess, title="Provinces of Mozambique")
```

```@raw html
<img src="../moz_provinces.png" width="400" class="center"/>
```

To know the provinces names such that we can use them individually for example, we use the option `names=true`

```julia
gadm("MOZ", names=true)
```
```
"Cabo Delgado"
"Gaza"
"Inhambane"
"Manica"
"Maputo"
"Maputo City"
"Nampula"
"Nassa"
"Sofala"
"Tete"
"Zambezia"
```

Now we can plot only one of those provinces and its children

```julia
CD = gadm("MOZ", "Cabo Delgado", children=true);
imshow(CD, proj=:guess, title="Cabo Delgado")
```

```@raw html
<img src="../cabo_delgado.png" width="300" class="center"/>
```

---

*Download a [Neptune Notebook here](gadm_moz.jl)*