### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 4fc69b90-72c2-11eb-3c8d-5ffa667de01f
using GMT, CSV, DataFrames, HTTP

# ╔═╡ 91c16f80-72c1-11eb-0d19-5903f6ef7d1e
md"
# Choropleth maps
A choropleth is a thematic map where areas are colored in proportion to a variable such as population density. GMT lets us plot choropleth maps but the process is not straightforward because we need to put the color information in the header of a multi-segment file. To facilitate this, some tools were added to the Julia wrapper.
"

# ╔═╡ 55e740a0-72c3-11eb-3680-370bee35effa
md"
Load packages needed to download data and put into a DataFrame 
"

# ╔═╡ 5b77eca0-72c2-11eb-161c-6b6c3581cede
paises = CSV.File(HTTP.get("https://raw.githubusercontent.com/tillnagel/unfolding/master/data/data/countries-population-density.csv").body, delim=';') |> DataFrame;

# ╔═╡ eb759ed0-72c5-11eb-16b6-191c48be50da
md"
Extract the european countries from the DCW file
"

# ╔═╡ 63e05440-72c2-11eb-1c2f-851a0cf3b553
# Extract the Europe countries from the DCW file
eu = coast(DCW="=EU+z", dump=true);

# ╔═╡ f4fb64b0-72c2-11eb-18d2-9720e67e3dad
md"
Generate two vector with country codes (2 chars codes) and the population density for European countries
"

# ╔═╡ 82ec2cb0-72c2-11eb-1140-95c37ebdef78
codes, vals = GMT.mk_codes_values(paises[!, 2], paises[!, 3], region="eu");

# ╔═╡ a5fa0560-72c2-11eb-3b9b-950358050b24
md"
Create a Categorical CPT that allows plotting the choropleth.
Note that we need to limit the CPT range to leave out the very high density *states* like Monaco otherwise all others would get the same color.
"

# ╔═╡ b9626f6e-72c2-11eb-0bd3-b3fc48195d9e
C = cpt4dcw(codes, vals, range=[10, 500, 10]);

# ╔═╡ 02f51f20-72c3-11eb-02e7-436644e34088
md"
Show the result
"

# ╔═╡ 1e4c05e2-72c3-11eb-32a2-89200f2e26d1
plot(eu, cmap=C, fill="+z", proj=:guess, region="-76/36/26/84",
	title="Population density", colorbar=true, show=true)

# ╔═╡ Cell order:
# ╟─91c16f80-72c1-11eb-0d19-5903f6ef7d1e
# ╟─55e740a0-72c3-11eb-3680-370bee35effa
# ╠═4fc69b90-72c2-11eb-3c8d-5ffa667de01f
# ╠═5b77eca0-72c2-11eb-161c-6b6c3581cede
# ╟─eb759ed0-72c5-11eb-16b6-191c48be50da
# ╠═63e05440-72c2-11eb-1c2f-851a0cf3b553
# ╟─f4fb64b0-72c2-11eb-18d2-9720e67e3dad
# ╠═82ec2cb0-72c2-11eb-1140-95c37ebdef78
# ╟─a5fa0560-72c2-11eb-3b9b-950358050b24
# ╠═b9626f6e-72c2-11eb-0bd3-b3fc48195d9e
# ╟─02f51f20-72c3-11eb-02e7-436644e34088
# ╠═1e4c05e2-72c3-11eb-32a2-89200f2e26d1
