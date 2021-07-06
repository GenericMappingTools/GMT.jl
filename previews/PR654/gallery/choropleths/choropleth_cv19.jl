### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 064a4920-779b-11eb-0f3c-d72a8db494ba
using GMT, DataFrames, CSV

# ╔═╡ bef24730-779a-11eb-2898-236801295f32
md"# Choropleth example Covid rate of infection in Portugal
"

# ╔═╡ 0c3afa00-779b-11eb-2284-f5f77a1ed657
md"First, download the Portuguese district polygons shape file from this [Github repo](https://github.com/dssg-pt/covid19pt-data/tree/master/extra/mapas/concelhos)
Next load it with:
"

# ╔═╡ ea8cb480-779e-11eb-128a-034873e098bc
#Pt = gmtread("https://github.com/dssg-pt/covid19pt-data/blob/master/extra/mapas/concelhos/concelhos.shp");
Pt  = gmtread("C:\\programs\\compa_libs\\covid19pt\\extra\\mapas\\concelhos\\concelhos.shp");

# ╔═╡ 514155e0-77be-11eb-1357-a7f08aa8705f
md"
Download and load a CSV file from [same repo](https://github.com/dssg-pt/covid19pt-data/blob/master/data_concelhos_incidencia.csv) with rate of infection per district. Load it into a DataFrame to simplify data extraction.
"

# ╔═╡ fcdfb6f0-779e-11eb-3851-23b13e48f0da
#incidence = CSV.read("https://github.com/dssg-pt/covid19pt-data/blob/master/data_concelhos_incidencia.csv", DataFrame);
incidence = CSV.read("C:\\programs\\compa_libs\\covid19pt\\data_concelhos_incidencia.csv", DataFrame);

# ╔═╡ 7a3a5cd0-77a0-11eb-1697-21cc016a00c6
md"Get the rate of incidence in number of infected per 100_000 habitants for the last reported week."

# ╔═╡ 4c32c340-77a0-11eb-212d-158dae4cc702
r = collect(incidence[end, 2:end]);

# ╔═╡ 921da0a2-77a0-11eb-1f58-85feb4a2943d
md"But the damn polygon names above are all uppercase, Ghrrr. We will have to take care of that.
"

# ╔═╡ bd494360-77a0-11eb-04a8-53f52cf2988c
ids = names(incidence)[2:end];

# ╔═╡ ee946f30-77a0-11eb-3b1a-3bcc0ae50f90
md"
Because the multi-segment headers have several fields in a comma separated string and the one we care (the one that is common with the names in the **Pt** dataset) is in the seventh position we use argument **7**. Last argument, **2** means to convert all names in the **Pt** headers to upper case so we can compare them with the names in **ids**. The comparison is made inside the next call to the ``make\_zvals\_vec()`` function that takes care to return the numerical vector that we need in *plot's* **level** option
"

# ╔═╡ fd378900-77a0-11eb-304a-65d816ef0bb5
zvals = GMT.make_zvals_vec(Pt, ids, r, 7, 2);

# ╔═╡ 9364d130-77a1-11eb-2434-cba72ee71c9d
md"Create a Colormap to paint the polygons
"

# ╔═╡ a331c500-77a1-11eb-2428-ed715c229193
C = makecpt(range=(0,1500,10), inverse=true, cmap=:oleron, hinge=240, bg=:o);

# ╔═╡ 7b0a3db0-77a5-11eb-2d42-613993618852
md"Get the date for the data being represented to use in title
"

# ╔═╡ a6e0ed80-77a5-11eb-3555-154f927dd2c7
date = incidence[end,1];

# ╔═╡ bd8b6330-77a5-11eb-3bf8-6d35a73a8935
md"And finaly do the plot
"

# ╔═╡ c92caeb0-77a5-11eb-0e52-df880fa278b9
plot(Pt, level=zvals, cmap=C, close=true, fill="+z", pen=0.5, region=(-9.75,-5.9,36.9,42.1), proj=:Mercator, title="Infected / 100.000 habitants " * date)

# ╔═╡ 3e211d90-77ac-11eb-336a-61a8a2220e7a
colorbar!(pos=(anchor=:MR,length=(12,0.6), offset=(-2.4,-4)), color=C, axes=(annot=100,), show=true)

# ╔═╡ Cell order:
# ╟─bef24730-779a-11eb-2898-236801295f32
# ╠═064a4920-779b-11eb-0f3c-d72a8db494ba
# ╟─0c3afa00-779b-11eb-2284-f5f77a1ed657
# ╠═ea8cb480-779e-11eb-128a-034873e098bc
# ╟─514155e0-77be-11eb-1357-a7f08aa8705f
# ╠═fcdfb6f0-779e-11eb-3851-23b13e48f0da
# ╟─7a3a5cd0-77a0-11eb-1697-21cc016a00c6
# ╠═4c32c340-77a0-11eb-212d-158dae4cc702
# ╟─921da0a2-77a0-11eb-1f58-85feb4a2943d
# ╠═bd494360-77a0-11eb-04a8-53f52cf2988c
# ╟─ee946f30-77a0-11eb-3b1a-3bcc0ae50f90
# ╠═fd378900-77a0-11eb-304a-65d816ef0bb5
# ╟─9364d130-77a1-11eb-2434-cba72ee71c9d
# ╠═a331c500-77a1-11eb-2428-ed715c229193
# ╟─7b0a3db0-77a5-11eb-2d42-613993618852
# ╠═a6e0ed80-77a5-11eb-3555-154f927dd2c7
# ╟─bd8b6330-77a5-11eb-3bf8-6d35a73a8935
# ╠═c92caeb0-77a5-11eb-0e52-df880fa278b9
# ╠═3e211d90-77ac-11eb-336a-61a8a2220e7a
