# Spirals
This started when Kristoff wanted to pain patterns on maps depicting sandy soils.
See the all story in this [Forum discussion](https://forum.generic-mapping-tools.org/t/how-to-generate-random-coordinates-for-pattern-fill/1322/19)

## Archimedean spiral
From https://en.wikipedia.org/wiki/Archimedean_spiral

The begin end of this block **are NOT** the GMT's modern mode *gmt begin ... gmt end*. They are forced by the Nootebook to have more than one command per cell.


```julia
# Play arround with these parameters
T = 1;
omega = omega = 2pi / T;
v = 0.2;
t = 0:0.01:5pi;
x = v.*t .* cos.(omega .* t);
y = v.*t .* sin.(omega .* t);
plot(x, y, aspect=:equal, show=true)
```

```@raw html
<img src="../spir_archim.png" width="400" class="center"/>
```

## Fermati spiral

```julia
teta = 0:0.01:5pi;
xf = sqrt.(teta) .* cos.(teta);
yf = sqrt.(teta) .* sin.(teta);
plot(xf,yf, aspect=:equal, show=true)
```

```@raw html
<img src="../spir_fermati.png" width="400" class="center"/>
```

## Sunflower
From [This FEX contribution](https://www.mathworks.com/matlabcentral/fileexchange/10796-model-a-sunflower-with-the-golden-ratio). The author here wanted to reflect the fact that on a sunflower the seeds close to the center are smaller and have a higher density.

```julia
phi = (sqrt(5)-1)/2;
n = 2618;
rho = (2:n-1) .^ phi;
theta = (2:n-1)*2pi*phi;
scatter(rho .* cos.(theta), rho .* sin.(theta), marker=:point, aspect=:equal, show=true)
```

```@raw html
<img src="../sunflower1.png" width="400" class="center"/>
```

## Another Sunflower
This one was reversed from the javascript in [this page](https://github.com/jacquerie/sunflower/blob/gh-pages/js/application.js), which follows the original work of Helmut Vogel in [A better Way to Construct the Sunflower Head](http://dx.doi.org/10.1016%2F0025-5564%2879%2990080-4), where he proposed that spiral branches of seeds in a sunflower head are added from the center at an angle of 137.5∘ from the preceding one.

This time we will also color the seed points in function of *r*, the distance to the center and pain with a dark background.

```julia
	angle = 137.5;	# Play with this angle between [137.0 138.0]. Amazing the effect, no?
	alfa = 2pi * angle / 360;
	n_seeds = 1500;
	seeds = 0:n_seeds;
	r = sqrt.(seeds);
	ϕ = alfa * seeds;
	C = makecpt(range=(1,sqrt(n_seeds),1), cmap=:buda);	# Color map to paint the seeds
	scatter(r .* cos.(ϕ), r .* sin.(ϕ), marker=:point, cmap=C, zcolor=r,
		frame=(fill=20,), aspect=:equal, show=true)
```

```@raw html
<img src="../sunflower2.png" width="400" class="center"/>
```

---

*Download a [Pluto Notebook here](spirals.jl)*
