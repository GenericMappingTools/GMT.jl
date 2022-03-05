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
- `kwargs`: This form of `pcode` is in fact a wrap up of ``plot`` so any option of that module can be used here.

    pcolor(G::GMTgrid; kwargs...)

This form takes a grid (or the file name of one) as input an paints it's cell with a constant color.

- `outline`: Draw the tile outlines, and specify a custom pen if the default pen is not to your liking.
- `kwargs`: This form of `pcode` is a wrap of ``grdview`` so any option of that module can be used here.
  One can for example control the tilling option via ``grdview's`` ``tiles`` option.

### Examples

    # Create an example grid
	G = GMT.peaks(N=21);

	pcolor(G, outline=(0.5,:dot), show=true)

	# Now use the G x,y coordinates in the non-regular form
	pcolor(G.x, G.y, G.z, show=true)

	# An irregular grid
	X,Y = GMT.meshgrid(-3:6/17:3);
	XX = 2*X .* Y;	YY = X.^2 .- Y.^2;
	pcolor(XX,YY, reshape(repeat([1:18; 18:-1:1], 9,1), size(XX)), lc=:black, show=true)
"""
function pcolor(X::VMr, Y::VMr, C::AbstractMatrix{<:Real}; first::Bool=true, kwargs...)
	(isvector(X) && !isvector(Y)) && error("X and Y must be both vectors or matrices, not one of each color.")
	if (isvector(X))
		gridreg = (length(X) == size(C,2)) && (length(Y) == size(C,1))
		(!gridreg && ((length(X) != size(C,2) + 1) || (length(Y) != size(C,1) + 1))) &&
			error("The X,Y vectors sizes are not compatible with the size(C)")
	else
		(size(X) != size(Y)) && error("When X,Y are 2D matrices they MUST have the same size.")
		(size(C) == size(X)) && (C = C[1:end-1, 1:end-1])
		(size(X) != size(C) .+ 1) && error("X,Y and C matrices must either have the same size or X,Y exceed C by 1 row and 1 column.")
	end

	if (isvector(X) && gridreg)		# Expand X,Y to make them pix reg
		xinc, yinc = X[2]-X[1], Y[2]-Y[1];		xinc2, yinc2 = xinc/2, yinc/2
		[X[k] -= xinc2 for k = 1:length(X)];	append!(X, X[end]+xinc)
		[Y[k] -= yinc2 for k = 1:length(Y)];	append!(Y, Y[end]+yinc)
	end

	D::Vector{GMTdataset}, k = Vector{GMTdataset}(undef, length(C)), 0
	if (isvector(X))
		for col = 1:length(X)-1, row = 1:length(Y)-1	# Gdal.wkbPolygon = 3
			D[k+=1] = mat2ds([X[col] Y[row]; X[col] Y[row+1]; X[col+1] Y[row+1]; X[col+1] Y[row]; X[col] Y[row]]; geom=3, kwargs...)
		end
		D[1].ds_bbox = [X[1], X[end], Y[1], Y[end]]
	else
		for col = 1:size(C,2), row = 1:size(C,1)
			D[k+=1] = mat2ds([X[row,col] Y[row,col]; X[row+1,col] Y[row+1,col]; X[row+1,col+1] Y[row+1,col+1]; X[row,col+1] Y[row,col+1]; X[row,col] Y[row,col]]; geom=3, kwargs...)
		end
		D[1].ds_bbox = vec([extrema(X)... extrema(Y)...])
	end

	Z = istransposed(C) ? vec(copy(C)) : vec(C)
	if (find_in_kwargs(kwargs, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag], false)[1] === nothing)
		plot(D; first=first, Z=Z, R=@sprintf("%.12g/%.12g/%.12g/%.12g", D[1].ds_bbox...), kwargs...)
	else
		plot(D; first=first, Z=Z, kwargs...)
	end
end
pcolor!(X::VMr, Y::VMr, C::Matrix{<:Real}; kw...) = pcolor(X, Y, C; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function pcolor(cmd0::String="", arg1=nothing; first=true, kwargs...)
	if (find_in_kwargs(kwargs, [:T :no_interp :tiles])[1] === nothing)	# If no -T, make one here
		opt_T = "+s"
		if ((val = find_in_kwargs(kwargs, [:outline])[1]) !== nothing)	# -T+o is bugged for line styles
			opt_T *= "+o" * add_opt_pen(Dict(:outline => val), [:outline])
		end
		grdview(cmd0, arg1; first=first, T=opt_T, kwargs...)
	else
		grdview(cmd0, arg1; first=first, kwargs...)
	end
end
# ---------------------------------------------------------------------------------------------------
pcolor(arg1; kw...) = pcolor("", arg1; first=true, kw...)
pcolor!(cmd0::String="", arg1=nothing; kw...) = pcolor(cmd0, arg1; first=false, kw...)
pcolor!(arg1; kw...) = pcolor("", arg1; first=false, kw...)
