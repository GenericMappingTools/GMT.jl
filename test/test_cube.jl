cube = gdaltranslate("cube.nc");

slicecube(cube, 2.);
slicecube(cube, 2., axis="y");
slicecube(cube, 2., axis="x");
slicecube(cube, 2);
slicecube(cube, 2, axis="y");
slicecube(cube, 2, axis="x");

x,y = GMT.meshgrid(-10:10);
u = 2 .* x .* y;
v = y .^2 - x .^ 2;
U = mat2grid(u, x[1,:], y[:,1]);
V = mat2grid(v, x[1,:], y[:,1]);
r, = streamlines(U, V);
r, = streamlines(x[1,:], y[:,1], u, v, 0., 0.);

U = grdinterpolate("U.nc");
V = grdinterpolate("V.nc");
W = grdinterpolate("W.nc");
Us = slicecube(U,5); Vs = slicecube(V,5);

streamlines(Us, Vs, side="left");
streamlines(Us, Vs, side="bot");
streamlines(Us, Vs, side="top");
streamlines(Us, Vs, side="right");
streamlines(Us, Vs);
streamlines(Us, Vs, 80, 20);
streamlines(Us, Vs, 80, [20,30,40,50]);
streamlines(Us, Vs, [80,100], 20);

streamlines(U, V, W, startz=5, axis=true);
streamlines(U, V, W, 80, 20, 5);
streamlines(U, V, W, [80], [20], [5., 10.])
