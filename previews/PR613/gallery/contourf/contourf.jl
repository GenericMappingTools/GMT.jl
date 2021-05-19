### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ aeae4550-720d-11eb-3ef5-1f23537ec599
using GMT

# ╔═╡ 0745ac40-720d-11eb-1acd-2d4920b5c475
md"# Contourf examples

GMT does not actually have a *contourf* module like Matlab for example, but we can obtain the same result using *grdview*, *grdcontour* and *pscontour*. However, to make things the Julia wrapper wrapped up a module called *contourf* that makes it really easy to use. To show how it works let's start by creating an example grid and a CPT. 
"

# ╔═╡ b2cdb8a0-720d-11eb-200b-cd2c056c8375
G = GMT.peaks();

# ╔═╡ d747f28e-720d-11eb-0e68-a7242445823b
C = makecpt(T=(-7,9,2));

# ╔═╡ df241fc0-720d-11eb-13d2-c311aa8f5518
md"Now if we pass those two to the *contourf* module we get an annotated plot where the annotations come from the color CPT.
"

# ╔═╡ 0faaea20-720e-11eb-0ff8-1105205be52c
contourf(G, C, show=true)

# ╔═╡ 29a06c20-720e-11eb-312a-ff244a4d7a71
md"If we want to just draw some contours and not annotate them, we pass an array with the contours to be drawn.
"

# ╔═╡ 5ca0c200-720e-11eb-3a76-5db53780ef22
contourf(G, C, contour=[-2, 0, 2, 5], show=true)

# ╔═╡ 6a4f90c0-720e-11eb-29c7-1529f5116d73
md"### What if one has an *x,y,z* file instead of a grid? 
That is also simple, let's simulate it with synthetic data.
"

# ╔═╡ a9d59eae-720e-11eb-050a-d1737498f9a0
d = [0 2 5; 1 4 5; 2 0.5 5; 3 3 9; 4 4.5 5; 4.2 1.2 5; 6 3 1; 8 1 5; 9 4.5 5];

# ╔═╡ d12ce0e0-720e-11eb-05c4-3b65ee0d2da2
contourf(d, limits=(-0.5,9.5,0,5), pen=0.25, labels=(line=(:min,:max),), show=1)

# ╔═╡ b22ad6fe-720f-11eb-2de4-37064019d3f6
md"In the above since we did not specify a CPT the program picked the GMT's default one. But if we want use another one it's only a question of creating and passed it in.
"

# ╔═╡ f583bede-720f-11eb-0ff0-617f73c13447
cpt = makecpt(range=(0,10,1), cmap=:batlow);

# ╔═╡ feda3000-720f-11eb-2b2f-d546d65f4abe
contourf(d, contours=cpt, limits=(-0.5,9.5,0,5), pen=0.25, labels=(line=(:min,:max),), show=true)

# ╔═╡ Cell order:
# ╟─0745ac40-720d-11eb-1acd-2d4920b5c475
# ╠═aeae4550-720d-11eb-3ef5-1f23537ec599
# ╠═b2cdb8a0-720d-11eb-200b-cd2c056c8375
# ╠═d747f28e-720d-11eb-0e68-a7242445823b
# ╟─df241fc0-720d-11eb-13d2-c311aa8f5518
# ╠═0faaea20-720e-11eb-0ff8-1105205be52c
# ╠═29a06c20-720e-11eb-312a-ff244a4d7a71
# ╠═5ca0c200-720e-11eb-3a76-5db53780ef22
# ╟─6a4f90c0-720e-11eb-29c7-1529f5116d73
# ╠═a9d59eae-720e-11eb-050a-d1737498f9a0
# ╠═d12ce0e0-720e-11eb-05c4-3b65ee0d2da2
# ╟─b22ad6fe-720f-11eb-2de4-37064019d3f6
# ╠═f583bede-720f-11eb-0ff0-617f73c13447
# ╠═feda3000-720f-11eb-2b2f-d546d65f4abe
