"""
    orbits(xyz::Matrix{<:Real}; first=true, radius=6371.007, height=0, lon0=0, lat0=0, show=false, kw...)

Plots the orbit, or whatever the input data in `xyz` represents, about the Earth or other planetary bodies.

### Args
- `xyz`: The orbit coordinates. By default, we expect the coordinates in the Earth Centered Earth Fixed (ECEF)
  system but they can be in spherical coordinates (lon, lat) as well. In this case `xyz` must be a Mx2 matrix
  and `height` (the orbit height) must be > 0. If this argument is omitted, we plot a demo spiral "orbit".

### Kwargs
- `radius`: The planetary body (spherical) radius. This value may be passed in meters or km and is only used
  when input is passed in spherical coordinates.
- `first`: Boolean that indicates if ``orbits`` creates the first layer of the image plot. If the default
  value of `true` is used, we also make a call to ``coast`` to plot the Earth using an Orthographic projection.
  The default option for this is plot the coastlines only, bur other options, *e.g.* colorizing the continents,
  are also available via the `kw...` arguments. Setting `first=false`, or better, use the ``orbits!`` form,
  skips the ``coast`` call, which lets this plot be appended to a previous plot as for example the one produced
  by ``grdimage`` on a Eart's DEM. Note, however, that in this case the previous plot must have used the same
  `lon0` and `lat0` otherwise the visible orbit will be wrong. 
- `lon0`: Central longitude of the Orthographic projection.
- `lat0`:  Central latitude of the Orthographic projection.
- `height`: Used when input `xyz` is a Mx2 (lon, lat) matrix and represents the height in *meters* above
  the sphere of radius `radius`. (MUST be > 0 and not 'too small' or this function's algorithm fails.) 
- `show`: Set this to `true` if want to see the produced image. Leaving it as `false` permits adding more
  elements by posterior plotting calls.
- `kw`: keyword arguments to be consumed in the ``coast`` and ``plot3`` calls. For example, `land=:tomato,
  lw=1, lc=:blue` paints the continent with the `tomato` color and plots the orbits with blue, 1pt thick lines.

### Example:
    orbits(show=true)
"""
function orbits(xyz::Matrix{<:AbstractFloat}=Array{Float64}(undef, 0, 0); first::Bool=true, radius=6371.007, height=0,
                lon0=0, lat0=0, show=false, savefig="", figname="", name="", kw...)
	d = KW(kw)
	orbits(xyz, first, Float64(radius), Float64(height), Float64(lon0), Float64(lat0), show==1, savefig, figname, name, d)
end
#function orbits(xyz::Matrix{<:AbstractFloat}=Array{Float64}(undef, 0, 0); first::Bool=true, radius=6371.007, height=0,
                #lon0=0, lat0=0, show=false, savefig="", figname="", name="", kw...)
function orbits(xyz::Matrix{<:AbstractFloat}, first::Bool, radius::Float64, height::Float64, lon0::Float64,
                lat0::Float64, show::Bool, savefig::String, figname::String, name::String, d::Dict{Symbol, Any})

	!first && !contains(CTRL.pocket_J[1], "-JG") && error("Only Orthographic projection is allowed.")
	r_lon = [cosd(-lon0) sind(-lon0) 0; -sind(-lon0) cosd(-lon0) 0; 0 0 1]
	r_lat = [cosd(-lat0) 0 sind(-lat0); 0.0 1 0; -sind(-lat0) 0 cosd(-lat0)]
	xyz::Matrix{Float64} = xyz

	R = radius
	if (isempty(xyz))
		R, t = 7.5, 0:pi/180:pi
		xyz = [R .* sin.(t).*cos.(10t)  R .* sin.(t).*sin.(10t)  R .* cos.(t)]
		R = 7.0
	end

	if (size(xyz, 2) == 2)							# Input came in degrees
		(R < 1e6) && (R *= 1e3)						# Here radius must be in meters
		xyz = [xyz fill(height,size(xyz,1))]
		xyz = mapproject(xyz, E=true, par=(PROJ_ELLIPSOID=R,)).data
		(height == 0) && error("Orbit height cannot be 0 when input is in degrees.")	# At bot so we can run a CI on it.
	end
	(size(xyz, 2) > 3) && (xyz = view(xyz, :, 1:3))	# Allow more than 3 columns

	_xyz = (lon0 != 0 || lat0 != 0) ? xyz * (r_lon * r_lat) : copy(xyz)
	x, y, z = view(_xyz, :, 1), view(_xyz, :, 2), view(_xyz, :, 3)
	(R < 1e6 && (maximum(x) > 1e4 || maximum(y) > 1e4)) && (R *= 1000)	# Input coords are in meters and radius in km

	t = linspace(0, 2pi, 361)
	circ = [R .* cos.(t) R .* sin.(t)]
	ind = x .< 0									# Those that have negative xx are candidates to be hiden. 
	ind_h = findall(diff(ind) .!= 0) .+ 1			# Indices of begin/end of the segments to hide
	(x[1] < 0) && (ind_h = [1, ind_h...])			# If first segment is negative, needs to be included
	(x[end] < 0) && append!(ind_h, [length(x)])		# If last segment is negative,		""
	for k = 1:2:numel(ind_h)						# We jump 2 to always start at the to be hiden segments.
		int::Matrix{Float64} = gmtspatial(([y[ind_h[k]:ind_h[k+1]] z[ind_h[k]:ind_h[k+1]]], circ), I="e", sort=1).data
		isempty(int) && continue

		if (size(int,1) == 1)						# Only one intersection. It means the curve doesn't reenter.
			kk = (ind_h[k] + ceil(Int, int[1,3]))
			y[kk:end] .= NaN
			y[kk], z[kk] = int[1], int[2]
			continue
		end
		k1, k2 = (ind_h[k] + ceil(Int, int[1,3])), (ind_h[k] + ceil(Int, int[2,3])-1)
		y[k1:k2] .= NaN
		y[k1], z[k1] = int[1,1], int[1,2]
		y[k2], z[k2] = int[2,1], int[2,2]
		if (size(int,1) == 3)						# More complicated case. Line reenters. Last part is to be hidden.
			k3 = ind_h[k] + ceil(Int, int[3,3])
			y[k3:ind_h[k+1]] .= NaN
			y[k3], z[k3] = int[3,1], int[3,2]
		end
	end

	d = Dict{Symbol, Any}()
	first && (coast(; region=:global, projection=(name=:ortho, center=(lon0,lat0)), A=100, Vd=-1, d...); d = CTRL.pocket_d[1])
	fname = (savefig != "") ? string(savefig) : (figname != "") ? string(figname) : (name != "") ? string(name) : ""
	(fname != "") && (d[:figname] = fname)		# If we have a figure name request
	D = mat2dsnan([x y z])						# Because of a bug in GMT plot3 that screws when NaNs
	opt_R = (R > 10) ? @sprintf("%.8g/%.8g/%.8g/%.8g/%.8g/%.8g", -R,R,-R,R,-R,R) : "-7/7/-7/7/-7/7"	# R < 10 is for demo
	plot3!(D; J="X"*CTRL.pocket_J[2], R=opt_R, aspect3=:equal, N=true, p=(90,0.00001), show=show, d...)
	#plot3d!([x[ind_h] y[ind_h] z[ind_h]], marker=:u, ms=0.1, mc=:blue, N=true, p=(90,0.00001), show=true)
end

orbits!(xyz::Matrix{<:Real}=Array{Float64}(undef, 0, 0); radius=6371.007, height=0, lon0=0, lat0=0, show=false, kw...) =
	orbits(xyz; first=false, radius=radius, height=height, lon0=lon0, lat0=lat0, show=show, kw...)

orbits(D::GMTdataset; radius=6371.007, height=0, lon0=0, lat0=0, show=false, kw...) =
	orbits(D.data; first=true, radius=radius, height=height, lon0=lon0, lat0=lat0, show=show, kw...)

orbits!(D::GMTdataset; radius=6371.007, height=0, lon0=0, lat0=0, show=false, kw...) =
	orbits(D.data; first=false, radius=radius, height=height, lon0=lon0, lat0=lat0, show=show, kw...)
