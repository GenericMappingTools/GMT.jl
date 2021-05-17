### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 92fa7440-6b38-11eb-0f13-dd8cc31baaee
using GMT

# ╔═╡ ca2e6c40-6b39-11eb-2416-5f9501d31726
md"# Bar plots

A simple bar plot showing color and bar width (in data units) assignement.
"

# ╔═╡ e6c6d3b2-6b39-11eb-0392-593da0f77eb6
bar(1:5, (20, 35, 30, 35, 27), width=0.5, color=:lightblue, limits=(0.5,5.5,0,40), show=true)

# ╔═╡ d7ddbbb0-6bf3-11eb-233e-3f2155a88415
md"### -

A colored bar plot with colors proportional to bar heights. In this case we let the plot limits be determined from data. We also plot a colorbar by using the **colorbar**=*true* option."

# ╔═╡ 099787d0-6bf4-11eb-0a54-e3133dd45400
bar(rand(15), color=:turbo, figsize=(14,8), title="Colored bars", colorbar=true, show=true)

# ╔═╡ 524f7d00-6bf6-11eb-0d30-531720224196
md"### -
Example showing how to plot bar groups and at same time assign variable transparency to each of the group's *band* usinf the **fillalpha** option. Here, each row on the input data represents a bar group that has as many *bands* as n_columns - 1. -1 because first column must hold the *xx* coordinates of each group. The colors come from the automatic cyclic scheme.
"

# ╔═╡ 3e636a70-6b3a-11eb-183c-7fcb8a761de1
bar([0. 1 2 3; 1 2 3 4], fillalpha=[0.3 0.5 0.7], show=true)

# ╔═╡ 6cb27160-6bf7-11eb-029a-0b54adf510fe
md"### -
Next example shows how to plot error bars in a grouped bar. Similar to this [mapplotlib's example](https://matplotlib.org/3.1.1/gallery/lines_bars_and_markers/barchart.html#sphx-glr-gallery-lines-bars-and-markers-barchart-py) (labels will come later).
"

# ╔═╡ 2c820e2e-6b3d-11eb-39aa-630c8d82953b
bar(1:5, [20 25; 35 32; 30 34; 35 20; 27 25], width=0.7, fill=["lightblue", "brown"],
    error_bars=(y=[2 3; 3 5; 4 2; 1 3; 2 3],), xticks=(:G1, :G2, :G3, :G4, :G5), yaxis=(annot=5,label=:Scores), frame=(title="Scores by group and gender", axes=:WSrt), show=true)

# ╔═╡ 43b175e2-6b3e-11eb-141e-71bb8c1253c2
md"### -
Example of a verticaly stacked bar plot. In this exampled we pass the *xx* coordinates as first argument and the individual bar heights in a matrix with smae number of rows as the number of elements in the *x* vector. To make it plot a stracked bar we used the option **stacked**=*true*.
"

# ╔═╡ 52167540-6b3e-11eb-343a-596dd9483996
bar(1:3,[-5 -15 20; 17 10 21; 10 5 15], stacked=1, show=1)

# ╔═╡ 92f28e50-6be3-11eb-2e4a-5798e1617080
md"To create an horizontal bar plot we use the **hbar**=*true* option"

# ╔═╡ bb6ca5a0-6be3-11eb-268d-d510fa533101
bar([0. 1 2 3; 1 2 3 4], hbar=true, show=true, name="bars5.png")

# ╔═╡ d47d45de-6be3-11eb-12c0-edfff29dced9
md"### -
And one horizontal and stacked but this time we pick the colors.
"

# ╔═╡ 9a94db40-6bed-11eb-35b6-b1ac3148df98
bar([0. 1 2 3; 1 2 3 4], stack=true, hbar=true, fill=["red", "green", "blue"], show=true)

# ╔═╡ Cell order:
# ╟─ca2e6c40-6b39-11eb-2416-5f9501d31726
# ╠═92fa7440-6b38-11eb-0f13-dd8cc31baaee
# ╠═e6c6d3b2-6b39-11eb-0392-593da0f77eb6
# ╟─d7ddbbb0-6bf3-11eb-233e-3f2155a88415
# ╠═099787d0-6bf4-11eb-0a54-e3133dd45400
# ╟─524f7d00-6bf6-11eb-0d30-531720224196
# ╠═3e636a70-6b3a-11eb-183c-7fcb8a761de1
# ╟─6cb27160-6bf7-11eb-029a-0b54adf510fe
# ╠═2c820e2e-6b3d-11eb-39aa-630c8d82953b
# ╟─43b175e2-6b3e-11eb-141e-71bb8c1253c2
# ╠═52167540-6b3e-11eb-343a-596dd9483996
# ╟─92f28e50-6be3-11eb-2e4a-5798e1617080
# ╠═bb6ca5a0-6be3-11eb-268d-d510fa533101
# ╟─d47d45de-6be3-11eb-12c0-edfff29dced9
# ╠═9a94db40-6bed-11eb-35b6-b1ac3148df98
