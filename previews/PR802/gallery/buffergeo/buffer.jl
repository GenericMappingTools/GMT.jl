### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ 263aba70-d11a-11eb-2ecb-05c55f92a63c
using GMT

# ╔═╡ 2b498c40-d119-11eb-10b0-bd14161ec72e
md"
# Geodesic buffers

Buffers polygons delimite areas that are within some distance of input features. We can have them arround points or lines. We will show here examples of both. 
"

# ╔═╡ 14b3b990-d125-11eb-0f85-4166a82a1131
md"
We start by computing a great circle, also known as an orthodrome between two points and interpolated at 1000 km increments.
"

# ╔═╡ af387600-d11a-11eb-277b-1126ed8360ac
ortho = orthodrome([0 0; 70 60], step=1000, unit=:k);

# ╔═╡ e37bd330-d11a-11eb-058d-019c85fceedc
coast(region=:global, proj=(name=:ortho, center=(0,45)), land=:peru, frame=:g)
plot!(ortho, lw=0.5, marker=:circ, ms=0.1, fill=:black, show=true)

# ╔═╡ df865940-d11e-11eb-2911-f17e7dd9501f
md"
Next we will draw geodesic circles with 500 km radius with center on the orthodrome vertices. And to do it we need ofc to compute those circles. We compute the circles with the `cirgeo` function. 
"

# ╔═╡ 45d991d0-d11f-11eb-37d1-8f0b5c3a1354
c = circgeo(ortho, radius=500, unit=:k);

# ╔═╡ 5fe9c7c0-d11f-11eb-080b-9713769ab827
coast(region=:global, proj=(name=:ortho, center=(0,45)), land=:peru, frame=:g)
plot!(c, lw=0.1, fill=:gray)
plot!(ortho, lw=0.5, marker=:circ, ms=0.1, fill=:black, show=true)

# ╔═╡ d6b946f0-d11f-11eb-03e4-c135f729e105
md"
Now imagine that we plot many close circles and compute the union of them all. That's how we get a geodesic buffer.
"

# ╔═╡ 390a9460-d122-11eb-3c0c-138acdd74cfe
# 
line = [-37. 1; -28 26; -45 35; -19 42; -9 55; 4 64; 32 72; 85 73; 135 73; 172 73; -144 73; -78 77; -27 72; -8 65; 8 54; 18 	39; 28 24; 34 1];
# Compute the buffer line
D = buffergeo(line, width=500000);
# and plot it
coast(region=:global, proj=(name=:ortho, center=(0,45)), land=:peru, frame=:g, plot=(data=D, fill=:green), show=true)


# ╔═╡ Cell order:
# ╠═2b498c40-d119-11eb-10b0-bd14161ec72e
# ╟─14b3b990-d125-11eb-0f85-4166a82a1131
# ╠═263aba70-d11a-11eb-2ecb-05c55f92a63c
# ╠═af387600-d11a-11eb-277b-1126ed8360ac
# ╠═e37bd330-d11a-11eb-058d-019c85fceedc
# ╠═df865940-d11e-11eb-2911-f17e7dd9501f
# ╠═45d991d0-d11f-11eb-37d1-8f0b5c3a1354
# ╠═5fe9c7c0-d11f-11eb-080b-9713769ab827
# ╠═d6b946f0-d11f-11eb-03e4-c135f729e105
# ╠═390a9460-d122-11eb-3c0c-138acdd74cfe
