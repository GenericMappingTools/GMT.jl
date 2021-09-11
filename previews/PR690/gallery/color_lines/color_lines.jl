### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ cb162dc0-6713-11eb-2681-ffafd6baf172
using GMT

# ╔═╡ f9bdec00-6720-11eb-326e-51e2f53b642b
md"## Line colors with custom CPT and auto color wrap

In this example the lines color is set using a custom CPT. Pen thickness is assigned automatically.

The custom CPT is used by setting the plot command’s cmap argument to ``true``. This workas because we previously computed the CPT and it will remain in memory until it's consumed when we finish the plot. The **level** argument sets the color to be used from the custom CPT.

In fact, in this case with a CPT already in memory, the **level** option alone would have triggered the line coloring and the **cmap** option could have been droped.
"

# ╔═╡ 4bb76890-6714-11eb-3573-73aa8df83b62
C = makecpt(range=(0,10,1));

# ╔═╡ ff01bd70-6754-11eb-231c-43976dec9ae5
md"Normally we don't need to start a figure with a call to *basemap* because the *plot* function takes care of guessing reasonable  defaults, but in this case we start with a curve with small amplitude and we grow the figure by adding more lines. So if we leave it to automatic guessing one would have to start by the largest amplitude curve."

# ╔═╡ 8a0fcbf0-6714-11eb-12ea-51e244aa662d
basemap(region=(20,30,-10,10), figsize=(12,8))

# ╔═╡ dc6295a0-6713-11eb-330d-0f4f8e3a60e1
x = 20:0.1:30;

# ╔═╡ 8e7f8220-6714-11eb-24fa-c746e71c6f35
for amp=0:10
	y = amp .* sin.(x)
	plot!(x, y, cmap=true, level=amp)
end

# ╔═╡ 3391f530-6720-11eb-2ca9-137fb5325fea
colorbar!(show=true)

# ╔═╡ 7d0fc080-6724-11eb-028e-958fc8284904
md"## Line colors with the automatic color scheme

Here we are showing how to plot several lines at once and color them according to a circular color scheme comprised of 7 distinct colors. We start by generating a dummy matrix 8x5, where rows represent the vertex and the columns hold the lines. To tell the program that first column contains the coordinates and the remaining are all lines to be plotted we use the option **multicol**=*true*
"

# ╔═╡ 5eea7020-6727-11eb-3514-9307a1afbee7
mat = GMT.fakedata(8, 5);

# ╔═╡ b4f7f1b0-6743-11eb-197b-372a05795fdc
lines(mat, multicol=true, name="clines2.png", show=true)

# ╔═╡ 0624c710-6745-11eb-2f33-57f86d0b7c17
md"But if we want choose the colors ourselves, it is also easy though we need to go a bit lower in the data preparation.

The basic data type to transfer tabular data to GMT is the *GMTdataset* and the above command has converted the matrix into a *GMTdataset* under the hood but now we need to create one ourselves and fine control more details, like the colors and line thickness of the individual lines. Not that we have 5 lines but will provide 3 colors and 3 lines thicknesses. When we do this those properties are wrapped modulo its number."

# ╔═╡ c2be1c30-6747-11eb-3650-41893fcf806f
D = mat2ds(mat, color=["brown", "green", "blue"], linethick=[2, 1.0, 0.5, 0.25], multi=true);

# ╔═╡ a6175150-6751-11eb-17dc-b39fcfa29302
md"And now we just call *lines* (but using *plot* would have been the same) with the **D** argument."

# ╔═╡ d7d2cb20-6751-11eb-3e47-d7ac04cfbaac
lines(D, show=true)

# ╔═╡ Cell order:
# ╟─f9bdec00-6720-11eb-326e-51e2f53b642b
# ╠═cb162dc0-6713-11eb-2681-ffafd6baf172
# ╠═4bb76890-6714-11eb-3573-73aa8df83b62
# ╟─ff01bd70-6754-11eb-231c-43976dec9ae5
# ╠═8a0fcbf0-6714-11eb-12ea-51e244aa662d
# ╠═dc6295a0-6713-11eb-330d-0f4f8e3a60e1
# ╠═8e7f8220-6714-11eb-24fa-c746e71c6f35
# ╠═3391f530-6720-11eb-2ca9-137fb5325fea
# ╟─7d0fc080-6724-11eb-028e-958fc8284904
# ╠═5eea7020-6727-11eb-3514-9307a1afbee7
# ╠═b4f7f1b0-6743-11eb-197b-372a05795fdc
# ╟─0624c710-6745-11eb-2f33-57f86d0b7c17
# ╠═c2be1c30-6747-11eb-3650-41893fcf806f
# ╟─a6175150-6751-11eb-17dc-b39fcfa29302
# ╠═d7d2cb20-6751-11eb-3e47-d7ac04cfbaac
