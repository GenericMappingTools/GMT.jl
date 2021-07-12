### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ ed395a10-6eef-11eb-2fa4-dfcefc661d71
using GMT

# ╔═╡ 6e509b82-6f2d-11eb-06a5-8f0c95ad5ecb
md"# Spirals
This started when Kristoff wanted to pain patterns on maps depicting sandy soils.
See the all story in this [Forum discussion](https://forum.generic-mapping-tools.org/t/how-to-generate-random-coordinates-for-pattern-fill/1322/19)
"

# ╔═╡ c95d34e0-6eef-11eb-0d6b-050d0a2904eb
md"## Archimedean spiral
From https://en.wikipedia.org/wiki/Archimedean_spiral
"

# ╔═╡ 0254aed0-6ef1-11eb-1893-55b56cbc6076
md"The begin end of this block **are NOT** the GMT's modern mode *gmt begin ... gmt end*. They are forced by the Nootebook to have more than one command per cell."

# ╔═╡ 590d7540-6ef1-11eb-2db5-316ba4efd866
begin
	# Play arround with these parameters
	
	T = 1;
	omega = omega = 2pi / T;
	v = 0.2;
	t = 0:0.01:5pi;
	x = v.*t .* cos.(omega .* t);
	y = v.*t .* sin.(omega .* t);
end;

# ╔═╡ 2d09b770-6ef0-11eb-3f50-0388a2cb1d46
plot(x, y, aspect=:equal, show=true)

# ╔═╡ 08699a70-6efa-11eb-1a17-1d1a287490a8
md"## Fermati spiral"

# ╔═╡ 8457d480-6efa-11eb-3a2e-f137efb6c1e8
teta = 0:0.01:5pi;

# ╔═╡ a6f62d10-6efb-11eb-3004-4dbc1a5fe7fd
xf = sqrt.(teta) .* cos.(teta);

# ╔═╡ a6f7b3b0-6efb-11eb-2004-8b152d668695
yf = sqrt.(teta) .* sin.(teta);

# ╔═╡ a6f87700-6efb-11eb-2443-3b78c63192b9
plot(xf,yf, aspect=:equal, show=true)

# ╔═╡ 04a8cc70-6efb-11eb-3aea-df71f7e7b780
md"## Sunflower
From [This FEX contribution](https://www.mathworks.com/matlabcentral/fileexchange/10796-model-a-sunflower-with-the-golden-ratio). The author here wanted to reflect the fact that on a sunflower the seeds close to the center are smaller and have a higher density.
"

# ╔═╡ 1842f4e0-6efb-11eb-17dd-c74c91e5792f
phi = (sqrt(5)-1)/2;

# ╔═╡ 1c958620-6efb-11eb-35f9-d51c907524fe
n = 2618;

# ╔═╡ 38c2cfb0-6efb-11eb-1daf-c1883c2b8443
rho = (2:n-1) .^ phi;

# ╔═╡ 802977a0-6efb-11eb-1f34-997996793d9e
theta = (2:n-1)*2pi*phi;

# ╔═╡ 8c5ca2e0-6efb-11eb-2e5b-3fe95be4a166
scatter(rho .* cos.(theta), rho .* sin.(theta), marker=:point, aspect=:equal, show=true)

# ╔═╡ d5e2e7f0-6f26-11eb-3bc0-2bb0532670ff
md"## Another Sunflower
This one was reversed from the javascript in [this page](https://github.com/jacquerie/sunflower/blob/gh-pages/js/application.js), which follows the original work of Helmut Vogel in [A better Way to Construct the Sunflower Head](http://dx.doi.org/10.1016%2F0025-5564%2879%2990080-4), where he proposed that spiral branches of seeds in a sunflower head are added from the center at an angle of 137.5∘ from the preceding one.

This time we will also color the seed points in function of *r*, the distance to the center and pain with a dark background.
"

# ╔═╡ 3ed0c890-6f27-11eb-0395-d309ad06bd06
begin
	angle = 137.5;	# Play with this angle between [137.0 138.0]. Amazing the effect, no?
	alfa = 2pi * angle / 360;
	n_seeds = 1500;
	seeds = 0:n_seeds;
	r = sqrt.(seeds);
	ϕ = alfa * seeds;
	C = makecpt(range=(1,sqrt(n_seeds),1), cmap=:buda);	# Color map to paint the seeds
	scatter(r .* cos.(ϕ), r .* sin.(ϕ), marker=:point, cmap=C, zcolor=r,
	#scatter(r, ϕ, proj=:polar, marker=:point, cmap=C, zcolor=r,
		frame=(fill=20,), aspect=:equal, show=true)
end

# ╔═╡ Cell order:
# ╟─6e509b82-6f2d-11eb-06a5-8f0c95ad5ecb
# ╟─c95d34e0-6eef-11eb-0d6b-050d0a2904eb
# ╠═ed395a10-6eef-11eb-2fa4-dfcefc661d71
# ╟─0254aed0-6ef1-11eb-1893-55b56cbc6076
# ╠═590d7540-6ef1-11eb-2db5-316ba4efd866
# ╠═2d09b770-6ef0-11eb-3f50-0388a2cb1d46
# ╠═08699a70-6efa-11eb-1a17-1d1a287490a8
# ╠═8457d480-6efa-11eb-3a2e-f137efb6c1e8
# ╠═a6f62d10-6efb-11eb-3004-4dbc1a5fe7fd
# ╠═a6f7b3b0-6efb-11eb-2004-8b152d668695
# ╠═a6f87700-6efb-11eb-2443-3b78c63192b9
# ╟─04a8cc70-6efb-11eb-3aea-df71f7e7b780
# ╠═1842f4e0-6efb-11eb-17dd-c74c91e5792f
# ╠═1c958620-6efb-11eb-35f9-d51c907524fe
# ╠═38c2cfb0-6efb-11eb-1daf-c1883c2b8443
# ╠═802977a0-6efb-11eb-1f34-997996793d9e
# ╠═8c5ca2e0-6efb-11eb-2e5b-3fe95be4a166
# ╟─d5e2e7f0-6f26-11eb-3bc0-2bb0532670ff
# ╠═3ed0c890-6f27-11eb-0395-d309ad06bd06
