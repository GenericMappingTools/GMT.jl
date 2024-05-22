"""
    pcolor(X, Y, C::Matrix{<:Real}; kwargs...)

Creates a colored cells plot using the values in matrix `C`. The color of each cell depends on the value of each
value of `C` after consulting a color table (cpt). If a color table is not provided via option `cmap=xxx` we
compute a default one.

- `X`, `Y`: Vectors or 1 row matrices with the x- and y-coordinates for the vertices. The number of
  elements of `X` must match the number of columns in `C` (is using the grid registration model) or exceed
  it by one (pixel registration). The same for `Y` and the number of rows in `C`. Notice that `X` and `Y`
  do not need to be equispaced.
- `X`, `Y`: Matrices with the x- and y-coordinates for the vertices. In this case the if `X` and `Y` define an
  m-by-n grid, then `C` should be an (m-1)-by-(n-1) matrix, though we also allow it to be m-by-n but we then
  drop the last row and column from `C`
- `C`: A matrix with the values that will be used to color the cells.
- `kwargs`: This form of `pcolor` is in fact a wrap up of ``plot`` so any option of that module can be used here.
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

### Examples

    # Create an example grid
	G = GMT.peaks(N=21);

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
"""
function pcolor(X_::VMr, Y_::VMr, C::Union{Nothing, AbstractMatrix{<:Real}}=nothing; first::Bool=true, kwargs...)
	((isvector(X_) && !isvector(Y_)) || (isvector(Y_) && !isvector(X_))) &&
		error("X and Y must be both vectors or matrices, not one of each color.")

	# Only the tiles mesh is requested? If yes, we are done.
	(C === nothing) && return boxes(X_, Y_; kwargs...)

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

	D::Vector{GMTdataset}, k = Vector{GMTdataset}(undef, length(C)), 0
	if (isvector(X))
		for col = 1:length(X)-1, row = 1:length(Y)-1	# Gdal.wkbPolygon = 3
			if (k == 0) D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3, kwargs...)
			else        D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3)
			end
		end
		D[1].ds_bbox = [X[1], X[end], Y[1], Y[end]]
	else
		for col = 1:size(X_,2)-1, row = 1:size(X_,1)-1
			if (k == 0)
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3, kwargs...)
			else
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3)
			end
		end
		D[1].ds_bbox = vec([extrema(X)... extrema(Y)...])
	end

	Z = istransposed(C) ? vec(copy(C)) : vec(C)
	kwargs, do_show, got_labels, ndigit, opt_F = helper_pcolor(kwargs, Z)

	d = KW(kwargs)
	got_fn = ((fname = find_in_dict(d, [:name :figname :savefig])[1]) !== nothing)
	d[:show] = got_labels ? false : do_show
	(!got_labels && got_fn) && (d[:name] = fname)


	if (find_in_kwargs(kwargs, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag], false)[1] === nothing)
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
	# Method for grids

	function get_grid_xy(reg, bbox, inc, nx, ny)	# Return the grid registration x,y coord vectors.
		_bbox = copy(bbox)		# Make a copy to not risk to change the original
		if (reg == 1)
			_bbox[1] += inc[1] / 2;	_bbox[2] -= inc[1] / 2;
			_bbox[3] += inc[2] / 2;	_bbox[4] -= inc[2] / 2;
		end
		x, y = linspace(_bbox[1], _bbox[2], nx), linspace(_bbox[3], _bbox[4], ny)
		return x,y
	end

	got_labels = false
	if (haskey(kwargs, :labels))		# If want to plot the cell values
		G = (isa(arg1, GMTgrid)) ? arg1 : gmtread(cmd0)		# If fname we have to read the grid
		x,y = (G.registration == 0) ? (G.x, G.y) : get_grid_xy(G.registration, G.range, G.inc, size(G,2), size(G,1))
		kwargs, do_show, got_labels, ndigit, opt_F = helper_pcolor(kwargs, G.range[5:6])
	end

	if (find_in_kwargs(kwargs, [:T :no_interp :tiles])[1] === nothing)	# If no -T, make one here
		opt_T = "+s"
		if ((val = find_in_kwargs(kwargs, [:outline])[1]) !== nothing)	# -T+o is bugged for line styles
			opt_T *= "+o" * add_opt_pen(Dict(:outline => val), [:outline])
		end
		grdview_helper(cmd0, arg1; first=first, T=opt_T, kwargs...)
	else
		grdview_helper(cmd0, arg1; first=first, kwargs...)
	end

	if (got_labels)
		X,Y = meshgrid(x, y)
		Dt = mat2ds([X[:] Y[:]], string.(round.(G.z[:], digits=ndigit)))
		text!(Dt, F=opt_F, show=do_show)
	end
end

# ---------------------------------------------------------------------------------------------------
pcolor(arg1; kw...) = pcolor("", arg1; first=true, kw...)
pcolor!(cmd0::String="", arg1=nothing; kw...) = pcolor(cmd0, arg1; first=false, kw...)
pcolor!(arg1; kw...) = pcolor("", arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function helper_pcolor(kwargs, Z)
	# Lots of gymn to see if we have a show request and suspend it in case we also want to plot text labels
	# Also fishes contents of the 'labels' and 'font' keywords.
	do_show, got_labels = false, false
	ndigit, opt_F = 2, "+f6p+jMC"		# Just default value to always have these vars defined
	if (haskey(kwargs, :labels))
		got_labels = true
		if ((isa(kwargs[:labels], Bool) && kwargs[:labels]) || isa(kwargs[:labels], String) || isa(kwargs[:labels], Symbol))
			dif = (length(Z) == 2) ? abs(Z[2] - Z[1]) : abs(maximum_nan(Z) - minimum_nan(Z))
			ndigit = (dif < 1) ? 3 : (dif <= 10 ? 2 : (dif < 100 ? 1 : 0))
		elseif (isa(kwargs[:labels], Int))
			ndigit = abs(kwargs[:labels])
		end

		if (haskey(kwargs, :font))
			opt_F = add_opt(KW(kwargs), "", "F", [:font], (angle="+a", font=("+f", font)), false, true)
		end

		if (is_in_kwargs(kwargs, [:show]))
			do_show = (kwargs[:show] != 0)
			kwargs = pairs(Base.structdiff(NamedTuple(kwargs), NamedTuple{(:show,:labels,:font)}))	# All this to remove keywords...
		else
			kwargs = pairs(Base.structdiff(NamedTuple(kwargs), NamedTuple{(:labels,:font)}))	# Still have to remove the keyword
		end
	else
		is_in_kwargs(kwargs, [:show]) && (do_show = (kwargs[:show] != 0))
	end
	return kwargs, do_show, got_labels, ndigit, opt_F
end

# ---------------------------------------------------------------------------------------------------
function boxes(X::VMr, Y::VMr; kwargs...)
	# ...
	((isvector(X) && !isvector(Y)) || (isvector(Y) && !isvector(X))) &&
		error("X and Y must be both vectors or matrices, not one of each color.")
	(!isvector(X) && ((size(X) != size(Y)))) && error("When X,Y are 2D matrices they MUST have the same size.")

	d = KW(kwargs)
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
	D::Vector{GMTdataset}, k = Vector{GMTdataset}(undef, n_tiles), 0
	if (isvector(X))
		for col = 1:length(X)-1, row = 1:length(Y)-1
			(isautomask && Gmask.z[row, col] != mask_true) && continue
			if (k == 0) D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3, kwargs...)
			else        D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3)
			end
		end
		k == 0 && return GMTdataset[]
		(isautomask && k != (length(X)-1)*(length(Y)-1)) && deleteat!(D, k+1:n_tiles)	# Remove the unused D's
		D[1].ds_bbox = [X[1], X[end], Y[1], Y[end]]
		isautomask && set_dsBB!(D, false) 
	else
		for col = 1:size(X,2)-1, row = 1:size(X,1)-1
			if (k == 0)
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3, kwargs...)
			else
				D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3)
			end
		end
		D[1].ds_bbox = vec([extrema(X)... extrema(Y)...])
	end
	D
end