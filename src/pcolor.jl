"""
    pcolor(X, Y, C::Matrix{<:Real}; kwargs...)

Creates a colored cells plot using the values in matrix `C`. The color of each cell depends on the value of each
value of `C` after consulting a color table (cpt). If a color table is not provided via option `cmap=xxx` we
compute a default one.

### Args
- `X`, `Y`: Vectors or 1 row matrices with the x- and y-coordinates for the vertices. The number of
  elements of `X` must match the number of columns in `C` (is using the grid registration model) or exceed
  it by one (pixel registration). The same for `Y` and the number of rows in `C`. Notice that `X` and `Y`
  do not need to be equispaced.
- `X`, `Y`: Matrices with the x- and y-coordinates for the vertices. In this case the if `X` and `Y` define an
  m-by-n grid, then `C` should be an (m-1)-by-(n-1) matrix, though we also allow it to be m-by-n but we then
  drop the last row and column from `C`
- `C`: A matrix with the values that will be used to color the cells.

### Kwargs
This form of `pcolor` is in fact a wrap up of ``plot`` so any option of that module can be used here.
- `labels`: If this ``keyword`` is used then we plot the value of each node in the corresponding cell. Use `label=n`,
  where ``n`` is integer and represents the number of printed decimals. Any other value like ``true``, ``"y"``
  or ``:y`` tells the program to guess the number of decimals.
- `font`: When `label` is used one may also control text font settings. Options are a subset of the ``text`` `attrib`
  option. Namely, the angle and the ``font``. Example: ``font=(angle=45, font=(5,:red))``. If not specified, it
  defaults to ``font=(font=(6,:black),)``.

---
    D = pcolor(X, Y; kwargs...)

This form, that is without a color matrix, accepts `X` and `Y` as before but returns the tiles in a vector of
GMTdatasets. Use the `kwargs` option to pass for example a projection setting (as for example ``proj=:geo``).

---
    pcolor(G::GMTgrid; kwargs...)

This form takes a grid (or the file name of one) as input an paints it's cell with a constant color.

- `outline`: Draw the tile outlines and specify a custom pen if the default pen is not to your liking.
- `kwargs`: This form of `pcolor` is a wrap of ``grdview`` so any option of that module can be used here.
  One can for example control the tilling option via ``grdview's`` ``tiles`` option.

---
    pcolor(GorD; kwargs...)

If `GorD` is either a GMTgrid or a GMTdataset containing a Pearson correlation matrix obtained with ``GMT.cor()``,
the processing recieves a special treatment. In this case, other than the `labels` keyword, user is also
interested in seing if the automatic choice of x-annotaions angle is correct. If not, one can force it
by setting the `rotx` (ot `slanted`) keywords.

### Examples

```julia
    # Create an example grid
	G = peaks(N=21);

	pcolor(G, outline=(0.5,:dot), show=true)

	# Now use the G x,y coordinates in the non-regular form
	pcolor(G.x, G.y, G.z, show=true)

	# Add labels to cells using default settings (font size = 6p)
	pcolor(G.x, G.y, G.z, labels=:y, show=true)

	# Similar to above but now set the number of decimlas in labels as well as it font settings
	pcolor(G.x, G.y, G.z, labels=2, font=(angle=45, font=(5,:red)), show=1)

	# An irregular grid
	X,Y = meshgrid(-3:6/17:3);
	XX = 2*X .* Y;	YY = X.^2 .- Y.^2;
	pcolor(XX,YY, reshape(repeat([1:18; 18:-1:1], 9,1), size(XX)), lc=:black, show=true)
```

Display a Pearson's correlation matrix

```julia
pcolor(GMT.cor(rand(4,4)), labels=:y, colorbar=1, show=true)
```
"""
function pcolor(X_::VMr, Y_::VMr, C::Union{Nothing, AbstractMatrix{<:Real}}=nothing; first::Bool=true, kwargs...)
	pcolor(X_, Y_, C, first, KW(kwargs))
end
function pcolor(X_::VMr, Y_::VMr, C::Union{Nothing, AbstractMatrix{<:Real}}, first::Bool, d)
	((isvector(X_) && !isvector(Y_)) || (isvector(Y_) && !isvector(X_))) &&
		error("X and Y must be both vectors or matrices, not one of each color.")

	# Only the tiles mesh is requested? If yes, we are done.
	(C === nothing) && return boxes(X_, Y_, d)

	if (isvector(X_))
		gridreg = (length(X_) == size(C,2)) && (length(Y_) == size(C,1))
		(!gridreg && ((length(X_) != size(C,2) + 1) || (length(Y_) != size(C,1) + 1))) &&
			error("The X,Y vectors sizes are not compatible with the size(C)")
	else
		(size(X_) != size(Y_)) && error("When X,Y are 2D matrices they MUST have the same size.")
		(size(C) == size(X_)) && (C = C[1:end-1, 1:end-1])
		(size(X_) != size(C) .+ 1) && error("X,Y and C matrices must either have the same size or X,Y exceed C by 1 row and 1 column.")
	end

	X,Y = X_,Y_
	if (isvector(X) && gridreg)		# Expand X,Y to make them pix reg
		X,Y = copy(X_), copy(Y_)
		xinc, yinc = X[2]-X[1], Y[2]-Y[1];		xinc2, yinc2 = xinc/2, yinc/2
		[X[k] -= xinc2 for k = 1:numel(X)];	append!(X, X[end]+xinc)
		[Y[k] -= yinc2 for k = 1:numel(Y)];	append!(Y, Y[end]+yinc)
	end

	D, k = Vector{GMTdataset{Float64,2}}(undef, length(C)), 0
	if (isvector(X))
		for col = 1:length(X)-1, row = 1:length(Y)-1	# Gdal.wkbPolygon = 3
			if (k == 0) 
				D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3, d...)
			else        D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3)
			end
		end
		D[1].ds_bbox = [X[1], X[end], Y[1], Y[end]]
	else
		for col = 1:size(X_,2)-1, row = 1:size(X_,1)-1
			if (k == 0)
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3, d...)
			else
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3)
			end
		end
		D[1].ds_bbox = vec([extrema(X)... extrema(Y)...])
	end

	Z = istransposed(C) ? vec(copy(C)) : vec(C)
	do_show, got_labels, ndigit, opt_F = helper_pcolor(d, Z, round(Int, sqrt(length(Z))))

	got_fn = ((fname = find_in_dict(d, [:name :figname :savefig])[1]) !== nothing)
	d[:show] = got_labels ? false : do_show
	(!got_labels && got_fn) && (d[:name] = fname)


	if (is_in_dict(d, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag]) === nothing)
		plot(D; first=first, Z=Z, R=@sprintf("%.12g/%.12g/%.12g/%.12g", D[1].ds_bbox...), d...)
	else
		plot(D; first=first, Z=Z, d...)
	end

	if (got_labels)
		mat = Matrix{Float64}(undef, length(D), 2)
		for k = 1:numel(D)
			mat[k,1], mat[k,2] = mean(D[k].bbox[1:2]), mean(D[k].bbox[3:4])
		end
		Dt = mat2ds(mat, string.(round.(Z,digits=ndigit)))
		text!(Dt, F=opt_F, name=fname, show=do_show)
	end

end
pcolor!(X::VMr, Y::VMr, C::Matrix{<:Real}; kw...) = pcolor(X, Y, C; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function pcolor(cmd0::String="", arg1=nothing; first=true, kwargs...)
	(cmd0 != "") && (arg1 = gmtread(cmd0))
	(isa(arg1, Matrix)) && (arg1 = mat2grid(Float32.(arg1)))
	isdataframe(arg1) && (arg1 = df2ds(arg1))
	if ((arg1 == arg1' && arg1[1] == 1 && arg1[end] == 1))		# A corr matrix (computed with GMT.cor())
		return pcolor(mat2ds(arg1.z); first=first, kwargs...)
	elseif (isa(arg1, GMTdataset))		# Arrive here when arg1 was originally a DataFrame
		return pcolor(arg1; first=first, kwargs...)
	end
	pcolor(arg1, first, KW(kwargs))
end

function pcolor(D::GMTdataset; first=true, kwargs...)
	d = KW(kwargs)
	z = Float32.(D.data)
	colnames = D.colnames[1:size(z,2)]
	ang::Float64 = 90.0
	if ((val = find_in_dict(d, [:slanted :rotx])[1]) !== nothing)
		ang = val
	elseif (is_in_dict(d, [:figscale :fig_scale :scale :figsize :fig_size]) === nothing)
		maxchars = maximum(length.(colnames))
		with_per_col = 15 / size(z,2)
		ang = (with_per_col / 0.25) >= maxchars ? 0 : 90
	end
	d[:xticks] = (colnames, ang)
	d[:yticks] = colnames[end:-1:1]
	if (D == D' && D[1] == 1 && D[end] == 1)		# A correlation matrix (that computed with GMT.cor())
		(is_in_dict(d, CPTaliases) === nothing) && (d[:C] = makecpt(T=(-1,1.0,0.1), C="tomato,azure1,dodgerblue4", Z=true))
		for n = 1:size(z,2), m = 1:size(z,1)
			m < n && (z[m,n] = NaN)					# Since the matrix is symmetric, remove the upper triangle
		end
	end
	pcolor(mat2grid(flipud(z)), first, d)
end

function pcolor(G::GMTgrid, first::Bool, d::Dict{Symbol,Any})
	# Method for grids

	changed_reg = false
	if (G.registration == 0)			# If not pixel reg, make it so
		G.registration = 1
		range_bak = copy(G.range)
		x_bak, y_bak = G.x, G.y
		G.range[1:4] .= range_bak[1:4] .- [G.inc[1], -G.inc[1], G.inc[2], -G.inc[2]] / 2
		G.x = linspace(G.range[1], G.range[2], size(G.z, 2)+1)
		G.y = linspace(G.range[3], G.range[4], size(G.z, 1)+1)
		changed_reg = true
	end

	got_labels = false
	if (is_in_dict(d, [:labels]) !== nothing)
		do_show, got_labels, ndigit, opt_F = helper_pcolor(d, G.range[5:6], size(G.z, 2))
	end

	if (find_in_dict(d, [:T :no_interp :tiles])[1] === nothing)	# If no -T, make one here
		opt_T = "+s"
		if ((val = find_in_dict(d, [:outline])[1]) !== nothing)	# -T+o is bugged for line styles
			opt_T *= "+o" * add_opt_pen(Dict(:outline => val), [:outline])
		end
		d[:T] = opt_T
	end
	grdview_helper("", G, !first, true, d)

	(changed_reg) && ((G.registration, G.range, G.x, G.y) = (0, range_bak, x_bak, y_bak))	# Undo the reg change

	if (got_labels)
		X,Y = (G.registration == 0) ? meshgrid(G.x, G.y) : meshgrid(G.x[1:end-1].+G.inc[1]/2, G.y[1:end-1].+G.inc[2]/2)
		z = G.z[:]
		ind = .!isnan.(z)				# We don't want to plot NaNs
		_X, _Y, _z = X[ind], Y[ind], z[ind]
		Dt = mat2ds([_X _Y], string.(round.(_z, digits=ndigit)))
		text!(Dt, F=opt_F, show=do_show)
	end
end

# ---------------------------------------------------------------------------------------------------
pcolor(arg1; kw...) = pcolor("", arg1; first=true, kw...)
pcolor!(cmd0::String="", arg1=nothing; kw...) = pcolor(cmd0, arg1; first=false, kw...)
pcolor!(arg1; kw...) = pcolor("", arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function helper_pcolor(d::Dict{Symbol,Any}, Z, nc::Int)
	# Lots of gymn to see if we have a show request and suspend it in case we also want to plot text labels
	# Also fishes contents of the 'labels' and 'font' keywords.
	do_show, got_labels = false, false
	opt_F = (nc < 5) ? "+f10p+jMC" : (nc < 8 ? "+f9p+jMC" : nc < 11 ? "+f8p+jMC" : nc <= 15 ? "+f7p+jMC" : nc < 30 ? "+f6p+jMC" : "+f5p+jMC")
	ndigit = 2		# Just default value to always have these vars defined
	if (is_in_dict(d, [:labels]) !== nothing)
		got_labels = true
		if ((isa(d[:labels], Bool) && d[:labels]) || isa(d[:labels], String) || isa(d[:labels], Symbol))
			dif = (length(Z) == 2) ? abs(Z[2] - Z[1]) : abs(maximum_nan(Z) - minimum_nan(Z))
			ndigit = (dif < 1) ? 3 : (dif <= 10 ? 2 : (dif < 100 ? 1 : 0)) + Int(nc <= 15)
		elseif (isa(d[:labels], Int))
			ndigit = abs(d[:labels])
		end

		if (is_in_dict(d, [:font]) !== nothing)
			opt_F = add_opt(d, "", "F", [:font], (angle="+a", font=("+f", font)); del=false)
		end

		if (is_in_dict(d, [:show]) !== nothing)
			do_show = (d[:show] != 0)
		end
		delete!(d, [:show, :labels, :font])		# Still have to remove these keywords
	else
		(is_in_dict(d, [:show]) !== nothing) && (do_show = (d[:show] != 0))
	end
	return do_show, got_labels, ndigit, opt_F
end

# ---------------------------------------------------------------------------------------------------
function boxes(X::VMr, Y::VMr; kwargs...)
	boxes(X, Y, KW(kwargs))
end
function boxes(X::VMr, Y::VMr, d::Dict{Symbol,Any})
	# ...
	((isvector(X) && !isvector(Y)) || (isvector(Y) && !isvector(X))) &&
		error("X and Y must be both vectors or matrices, not one of each color.")
	(!isvector(X) && ((size(X) != size(Y)))) && error("When X,Y are 2D matrices they MUST have the same size.")

	isautomask = false
	if ((val = find_in_dict(d, [:grdlandmask])[1]) !== nothing)
		y_inc = Y[2] - Y[1]		# Always good as long as when Y is a matrix it is a meshgrid one
		x_inc = isvector(X) ? X[2] - X[1] : X[1,2] - X[1]
		x_min, y_min, x_max, y_max = X[1], Y[1], X[end], Y[end]		# Should be good even for meshgrids
		cmd = @sprintf("grdlandmask -R%.12g/%.12g/%.12g/%.12g -I%.12g/%.12g -Da -A0/0/1 -r", x_min, x_max, y_min, y_max, x_inc, y_inc)
		Gmask = gmt(cmd)
		mask_true = (string(val)::String == "water") ? 0 : 1
		isautomask = true
	end

	n_tiles = isvector(X) ? (length(X) - 1)*(length(Y) - 1) : (size(X,1) - 1)*(size(X,2) - 1)
	D, k = Vector{GMTdataset{promote_type(eltype(X), eltype(Y)), 2}}(undef, n_tiles), 0
	if (isvector(X))
		for col = 1:length(X)-1, row = 1:length(Y)-1
			(isautomask && Gmask.z[row, col] != mask_true) && continue
			if (k == 0) D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3, d...)
			else        D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3)
			end
		end
		k == 0 && return GMTdataset{eltype(D.data),2}[]
		(isautomask && k != (length(X)-1)*(length(Y)-1)) && deleteat!(D, k+1:n_tiles)	# Remove the unused D's
		D[1].ds_bbox = [X[1], X[end], Y[1], Y[end]]
		isautomask && set_dsBB!(D, false) 
	else
		for col = 1:size(X,2)-1, row = 1:size(X,1)-1
			if (k == 0)
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3, d...)
			else
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3)
			end
		end
		D[1].ds_bbox = vec([extrema(X)... extrema(Y)...])
	end
	D
end