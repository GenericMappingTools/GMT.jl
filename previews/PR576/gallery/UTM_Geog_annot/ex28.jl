### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 06f9a7b0-7a27-11eb-24d2-2398ba0ec9df
using GMT

# ╔═╡ cee6d350-7a23-11eb-1522-71dfaaac4fb9
md"# Mixing UTM and geographic axes annotations

This is a question that comes up regularly such that GMT has a gallery example (famous [example 28](https://docs.generic-mapping-tools.org/dev/gallery/ex28.html#example-28)) to show how to do it. But even with that example it's not a trivial thing to do.


However it's trivial from the Julia wrapper under the condition that the grid or image to be displayed is referenced internally. If it is not, `grdedit` can be used to assign a referencing system via its option `proj`. The other condition is that grid or image to be displayed is already in memory (so that the internal magicks can work). Given that, [example 28](https://docs.generic-mapping-tools.org/dev/gallery/ex28.html#example-28)) boils down to this (with a little bit less fancy details).
"

# ╔═╡ 1e769320-7a28-11eb-3eef-538e1a5734ea
G = gmtread("@Kilauea.utm.nc");

# ╔═╡ 2251f892-7a28-11eb-206e-b1a4702505e1
md"Create a cpt and display the map
"

# ╔═╡ 77b60470-7a28-11eb-368f-631b2b09db3f
C = makecpt(cmap="copper", range=(0,1500));

# ╔═╡ 45b59260-7a28-11eb-2d3b-5d9eed99c801
imshow(G, cmap=C, shade=true, frame=(axes="WS", annot=true),
	coast=(shore=true, ocean=:lightblue, frame=(axes="EN", annot=true, grid=true)))

# ╔═╡ Cell order:
# ╟─cee6d350-7a23-11eb-1522-71dfaaac4fb9
# ╠═06f9a7b0-7a27-11eb-24d2-2398ba0ec9df
# ╠═1e769320-7a28-11eb-3eef-538e1a5734ea
# ╟─2251f892-7a28-11eb-206e-b1a4702505e1
# ╠═77b60470-7a28-11eb-368f-631b2b09db3f
# ╠═45b59260-7a28-11eb-2d3b-5d9eed99c801
