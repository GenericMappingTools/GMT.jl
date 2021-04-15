### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ 6ec070b0-7214-11eb-04d3-a54e83e79e71
using GMT

# ╔═╡ 411f1300-7214-11eb-0cf5-7b1317346330
md"# Plotyy example
Likewise *contourf* GMT does not have a *plotyy* module. A `plotyy` plot is a one where we plot Y1 versus X1 with y-axis labeling on the left and plots Y2 versus X2 with y-axis labeling on the right. So it's basically a two plots overlain but the details to make it nice can be a bit boring and long.
"

# ╔═╡ 73ff5dc0-7214-11eb-21db-232604c38428
begin
	x = 0:0.01:20;
	y1 = 200 * exp.(-0.05x) .* sin.(x);
	y2 = 0.8 * exp.(-0.5x)  .* sin.(10x);
end;

# ╔═╡ 967ba4d0-7214-11eb-10a9-23ca5705e4ea
plotyy(y1, y2, title="Vibrating dishes", ylabel=:Knifes, xlabel=:Forks, seclabel=:Spoons, show=true)

# ╔═╡ 571727a0-721f-11eb-0d87-dbe6673f8e03
md"Note that to make the command shorter and nicer to read we have used a less known option in GMT. The *secondary* label of an axes. In this example we also didn't set the *xx* coordinates so the program plotted from 1 to numbers of points.

In the general case the data has *xx* coordinates and they don't even need to be the same for Y1 and Y2 (but they need to have a shared interval). In that case we **should** set the plot limits because otherwise the guessing done from *xx*,Y1 risk to not capture the total Y1+Y2 extent.
"

# ╔═╡ 320ffa82-7220-11eb-1c74-b1f9e7d3e8a0
plotyy([x[:] y1[:]], [x[:] y2[:]], title="Vibrating dishes", ylabel=:Knifes, xlabel="2000 Forks", seclabel=:Spoons, show=true)

# ╔═╡ Cell order:
# ╟─411f1300-7214-11eb-0cf5-7b1317346330
# ╠═6ec070b0-7214-11eb-04d3-a54e83e79e71
# ╠═73ff5dc0-7214-11eb-21db-232604c38428
# ╠═967ba4d0-7214-11eb-10a9-23ca5705e4ea
# ╟─571727a0-721f-11eb-0d87-dbe6673f8e03
# ╠═320ffa82-7220-11eb-1c74-b1f9e7d3e8a0
