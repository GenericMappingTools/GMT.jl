"""
    xc, yc, R, err = circfit(x,y; taubin=false)

Fits a circle in the x,y plane.

From FEX contribution https://www.mathworks.com/matlabcentral/fileexchange/5557-circle-fit

### Arguments
- `xy`: a Mx2 matrix or GMTdataset with x,y coordinates of n points

- `x,y`: Alternatively, pass two vectors where each (x(i),y(i)) is a given point

### Options
- `taubin`: If ``true``, use the Taubin algorithm instead. https://people.cas.uab.edu/~mosya/cl/TaubinSVD.m
  recomends this as best alghoritm. ~2x slower than the default method.

### Returns
- `xc`, `yc`, `R`, `err`; The center, radius and the error of the fit
"""
circfit(xy::Union{Matrix{<:Real}, GMTdataset}; taubin=false) = circfit(view(xy, :, 1), view(xy, :, 2); taubin=taubin)
function  circfit(x,y; taubin=false)
	(taubin == 1) && return circfit_tau(x,y)
	a  = [x y ones(size(x))] \ -(x.^2 .+ y.^2)
	xc = -0.5 * a[1]
	yc = -0.5 * a[2]
	R  =  sqrt((a[1]^2 + a[2]^2) / 4 - a[3])
	err = sqrt(mean((sqrt.((x .- xc).^2 .+ (y .- yc).^2) .- R).^2))	# RMSE
	return xc, yc, R, err
end

# -------------------------------------------------------------------------------
# https://people.cas.uab.edu/~mosya/cl/TaubinSVD.m

"""
    xc, yc, R, err = circfit_tau(X, Y)

Algebraic circle fit by Taubin. Note, this function is normally called via ``circfit`` that allows more
options for the input data.

      G. Taubin, "Estimation Of Planar Curves, Surfaces And Nonplanar
                  Space Curves Defined By Implicit Equations, With 
                  Applications To Edge And Range Image Segmentation",
      IEEE Trans. PAMI, Vol. 13, pages 1115-1138, (1991)

### Arguments
- `X, Y`: two vectors where each (x(i),y(i)) is a given point.

### Returns
- `xc`, `yc`, `R`, `err`; The center, radius and the error of the fit
"""
function  circfit_tau(X, Y)
	centroid = [mean(X) mean(Y)]					# centroid of data
	X .-= centroid[1];		Y .-= centroid[2]		# centering data
	Z = X.*X + Y.*Y
	Zmean = mean(Z)
	Z0 = (Z .- Zmean) / (2*sqrt(Zmean))
	ZXY = [Z0 X Y]
	U,S,V = svd(ZXY)
	A = V[:,3]
	A[1] = A[1]/(2*sqrt(Zmean))
	A = [A; -Zmean*A[1]]
	XcYc = -(A[2:3])' / A[1]/2 .+ centroid
	R = sqrt(A[2]*A[2]+A[3]*A[3]-4*A[1]*A[4])/abs(A[1])/2

	X .+= centroid[1];		Y .+= centroid[2]		# Reset true coordinates
	err = sqrt(mean((sqrt.((X .- XcYc[1]).^2 .+ (Y .- XcYc[2]).^2) .- R).^2))	# RMSE
	return XcYc[1], XcYc[2], R, err
end
