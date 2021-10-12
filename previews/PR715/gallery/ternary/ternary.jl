### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ d5a6bdfa-fbcd-436e-99cd-eadb8f5c63c8
using GMT

# ╔═╡ 89b3b5b0-d071-11eb-3994-7932442f1611
md"
# Ternary plots


To plot points on a ternary diagram at the positions listed in the file ternary.txt (that GMT knows where to find it), with default annotations and gridline spacings, using the specified labeling, do
"

# ╔═╡ 9ffa3892-5e30-4e46-a00a-a1682eebd888
ternary("@ternary.txt", labels=("Clay","Silt","Sand"), marker=:p, show=true)

# ╔═╡ be06e94b-ec5c-442b-9273-d55b6a6fede8
md"
-- Ok, good but a bit dull. What about coloring the points? And if I want to have the axes runing in clock-wise order? And what about adding a percentage symbol to the annotations?

Simple. First we create a colormap and to rotte the axes we use the option `clockwise=true`. Regarding the `%` sign, it requires using the `frame` option and that obliges to be explicit on the axes labels because we are no longer using handy defaults.
"

# ╔═╡ d9a81565-1dc7-482f-ac74-5102b5c79969
# Make use of the knowledge that z ranges berween 0 and 71 (gmtinfo module is a friend)
C = makecpt(T=(0,71));

# ╔═╡ 20979dbf-3d32-4764-975b-286469458b92
ternary("@ternary.txt", frame=(annot=:auto, grid=:a, ticks=:a, alabel="Clay", blabel="Silt", clabel="Sand", suffix=" %"), marker=:p, cmap=C, clockwise=true, show=true)

# ╔═╡ 6c7960c0-d0a4-11eb-3147-f92e4a7436e6
md"
-- Ah, much better, but now I would like to display the above data as an image.


Solution: use the `image=true` option. Note that we may skip the `cmap` option and an automatic `cmap` is compute for us (but one can use whatever cmap we want, just create a colormap with the wished colors)
"

# ╔═╡ ceff64b0-d0a4-11eb-1881-7d9a7b2be78e
ternary("@ternary.txt", frame=(annot=:auto, grid=:a, ticks=:a, alabel="Clay", blabel="Silt", clabel="Sand", suffix=" %"), marker=:p, image=true, clockwise=true, show=true)

# ╔═╡ 4700fb42-d0a5-11eb-3914-53b959143ec5
md"
-- And to overlay some contours?

Add the `contour` option. This option works either with automatically picked parameters or under the user full control (which contours to draw and which to annotate, etc). For simplicity we could use the automatic mode (just set `contour=true`) but the ternary plots may have several short contour lines that would not be annotated because they are too short for the default setting. So, and for demonstration sake, we will use the explicit `contour` form where we set also the distance between the labels.
"

# ╔═╡ c636e63e-d0a5-11eb-2d6a-ab44a74366a1
ternary("@ternary.txt", frame=(annot=:auto, grid=:a, ticks=:a, alabel="Clay", blabel="Silt", clabel="Sand", suffix=" %"), clockwise=true, image=true, contour=(annot=10,cont=5,labels=(distance=3,)), colorbar=true, show=true)

# ╔═╡ f9c30160-d0a5-11eb-18ea-81a47cb85b76
md"
And we can do a `contourf` style plot too, but in this case only the area inside the data cloud is imaged since the method used involves a Delaunay triangulation.
"

# ╔═╡ 161efc10-d0a6-11eb-3d7f-af1d658a3cf0
ternary("@ternary.txt", frame=(annot=:auto, grid=:a, ticks=:a, alabel="Clay", blabel="Silt", clabel="Sand", suffix=" %"), marker=:p, clockwise=true, contourf=(annot=10, cont=5), show=true)

# ╔═╡ Cell order:
# ╟─89b3b5b0-d071-11eb-3994-7932442f1611
# ╠═d5a6bdfa-fbcd-436e-99cd-eadb8f5c63c8
# ╠═9ffa3892-5e30-4e46-a00a-a1682eebd888
# ╟─be06e94b-ec5c-442b-9273-d55b6a6fede8
# ╠═d9a81565-1dc7-482f-ac74-5102b5c79969
# ╠═20979dbf-3d32-4764-975b-286469458b92
# ╟─6c7960c0-d0a4-11eb-3147-f92e4a7436e6
# ╠═ceff64b0-d0a4-11eb-1881-7d9a7b2be78e
# ╟─4700fb42-d0a5-11eb-3914-53b959143ec5
# ╠═c636e63e-d0a5-11eb-2d6a-ab44a74366a1
# ╟─f9c30160-d0a5-11eb-18ea-81a47cb85b76
# ╠═161efc10-d0a6-11eb-3d7f-af1d658a3cf0
