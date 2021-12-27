### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ 64500da0-15b3-11ec-2965-5dbae2ce1ca3
using GMT
mozambique = gadm("MOZ");

# ╔═╡ c235d97e-1587-11ec-0438-81130f8f5239
md"### Plot countries administrative units from [GADM](https://gadm.org)

We start by download and save in cache the geopackage file with Mozambique data.
Note, a downloading message will be printed only once, and in this case it will say

*Downloading geographic data for country MOZ provided by the https://gadm.org project. It may take a while.
The file gadm36_MOZ.gpkg (after uncompressing) will be stored in c:/j/.gmt\cache*
"

# ╔═╡ f1be5140-1588-11ec-0705-918d55480e3a
imshow(mozambique, proj=:guess, title="Mozambique")

# ╔═╡ 12178d42-15b5-11ec-11a3-01a7cb72aff1
md"
Next let us add all the provincies of Mozambique. For that we'll use the country code as parent and the option `children=true` to indicate that we want all provincies boundaries."

# ╔═╡ 89b7aa40-15b2-11ec-01d0-37cce7e20f24
mozambique = gadm("MOZ", children=true);
imshow(mozambique, proj=:guess, title="Provinces of Mozambique")

# ╔═╡ 734b2090-15b5-11ec-3394-d99ce6470590
md"To know the provinces names such that we can use them individually for example, we use the option `names=true`"

# ╔═╡ 54c19ee0-15b2-11ec-3cf0-b7e5cdc75d3a
gadm("MOZ", names=true)

# ╔═╡ a658e3f0-15b5-11ec-0809-69ce7675d096
md"
Now we can plot only one of those provinces and its children"

# ╔═╡ 75208430-15b2-11ec-0ae1-3724dade5f8e
CD = gadm("MOZ", "Cabo Delgado", children=true);
imshow(CD, proj=:guess, title="Cabo Delgado")

# ╔═╡ Cell order:
# ╠═c235d97e-1587-11ec-0438-81130f8f5239
# ╠═64500da0-15b3-11ec-2965-5dbae2ce1ca3
# ╠═f1be5140-1588-11ec-0705-918d55480e3a
# ╠═12178d42-15b5-11ec-11a3-01a7cb72aff1
# ╠═89b7aa40-15b2-11ec-01d0-37cce7e20f24
# ╠═734b2090-15b5-11ec-3394-d99ce6470590
# ╠═54c19ee0-15b2-11ec-3cf0-b7e5cdc75d3a
# ╠═a658e3f0-15b5-11ec-0809-69ce7675d096
# ╠═75208430-15b2-11ec-0ae1-3724dade5f8e
