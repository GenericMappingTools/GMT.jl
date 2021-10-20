### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ a10408d0-6b1a-11eb-26d1-ade2b8bc5570
using GMT

# ╔═╡ 21c0d760-6b1a-11eb-1dbe-557799ae1164
md"# Ploting functions

There are a couple of predefined functions that can plotted for demonstration purposes.
For example the [_ackley_](https://en.wikipedia.org/wiki/Ackley_function) function
"

# ╔═╡ a5c49e20-6b1a-11eb-09e6-ab92f5f2cbc6
imshow("ackley", view=(159,30), shade=true)

# ╔═╡ f4134f40-6b1a-11eb-2e01-93c3ba5e52a6
md" Or the *rosenbrock* that looks like a manta ray (other options are *parabola, eggbox,  sombrero*)"

# ╔═╡ 0e50fdd0-6b1b-11eb-1971-4f1f5d7064b6
imshow("rosenbrock", view=(159,30), shade=true)

# ╔═╡ c5b1442e-6b1b-11eb-3292-e3ae7c257923
md"But besides these predefined functions one can any function that defines a surface.
For example a parabola can be plotted with the code bellow. First argument can be an anonymous function (like the example) of a function. Second and third args contain the plotting domain and step used to evaluate the function."

# ╔═╡ 1bde9e10-6b1d-11eb-0356-65dfa0dbe4c3
imshow((x,y) -> sqrt(x^2 + y^2), -5:0.05:5, -5:0.05:5, view=(159,30), shade=true, frame=:autoXYZg)

# ╔═╡ 437448ce-6b1d-11eb-0350-85821c4d8826
md"And we can plot 3D lines too. Same thing, give a parametric equation and"

# ╔═╡ 657c4a40-6b1d-11eb-25aa-49118e1f7460
plot3d(x -> sin(x)*cos(10x), y -> sin(y)*sin(10y), z -> cos(z), 0:pi/200:pi, lt=2, lc=:brown, frame=:autoXYZg, show=true)

# ╔═╡ 78903ba0-6b31-11eb-1ff4-e9cf2d6f2978
md"And a 2D example"

# ╔═╡ 89a23290-6b31-11eb-2e75-2db7eb10552a
lines(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2.1pi,100), region=(-4,7,-5.5,2.5),
	lw=2, lc=:sienna, decorated=(quoted=true, const_label=" I am the center of the Universe", font=(34,"Times-Italic"), curved=true), aspect=:equal, show=true)

# ╔═╡ Cell order:
# ╟─21c0d760-6b1a-11eb-1dbe-557799ae1164
# ╠═a10408d0-6b1a-11eb-26d1-ade2b8bc5570
# ╠═a5c49e20-6b1a-11eb-09e6-ab92f5f2cbc6
# ╟─f4134f40-6b1a-11eb-2e01-93c3ba5e52a6
# ╠═0e50fdd0-6b1b-11eb-1971-4f1f5d7064b6
# ╟─c5b1442e-6b1b-11eb-3292-e3ae7c257923
# ╠═1bde9e10-6b1d-11eb-0356-65dfa0dbe4c3
# ╟─437448ce-6b1d-11eb-0350-85821c4d8826
# ╠═657c4a40-6b1d-11eb-25aa-49118e1f7460
# ╟─78903ba0-6b31-11eb-1ff4-e9cf2d6f2978
# ╠═89a23290-6b31-11eb-2e75-2db7eb10552a
