# This function is from the LinearFitXYerrors package (https://github.com/rafael-guerra-www/LinearFitXYerrors.jl)
# Extracted insted of making LinearFitXYerrors a dependency because we don't want to bring in more
# dependencies. Original dependencies, 'Distributions' and 'Plots' were entirely replaced by GMT alone.
#
# In the process the output is now a GMTdataset type with some fitting parameters stored as attributes.
"""
linearfitxy(X, Y; σX=0, σY=0, r=0, ci=95)

Performs 1D linear fitting of experimental data with uncertainties in  X and Y:
- Linear fit:             `Y = a + b*X`                               [1]
- Errors:                 ``X ± σX;  Y ± σY``                         [2]
- Errors' correlation:    ``r =  = cov(σX, σY) / (σX * σY)``          [3]

# Arguments:
- `X` and `Y` are input data vectors with length ≥ 3
- Optional standard deviation errors ``σX`` and ``σY`` are vectors or scalars
- Optional `r` is the correlation between the ``σX`` and ``σY`` errors. `r` can be a vector or scalar
- `ci` is the confidence interval for the statistics. By default it's 95% but any integer number > 0 < 100 will do.

``σX`` and ``σY`` errors (error ellipses) with bivariate Gaussian distribution assumed.
If no errors, or if only ``σX`` or ``σY`` are provided, then the results are equivalent
to those from the [LsqFit.jl](https://github.com/JuliaNLSolvers/LsqFit.jl) package.

Based on York et al. (2004) with extensions (confidence intervals, diluted corr. coeff.).

# Examples:
```julia-repl
D = linearfitxy(X, Y)    # no errors in X and Y, no plot displayed

D = linearfitxy(X, Y; σX, σY) # XY errors not correlated (r=0);

D = linearfitxy([91., 104, 107, 107, 106, 100, 92, 92, 105, 108], [9.8, 7.4, 7.9, 8.3, 8.3, 9.0, 9.7, 8.8, 7.6, 6.9]);

D = linearfitxy([0.0, 0.9, 1.8, 2.6, 3.3, 4.4, 5.2, 6.1, 6.5, 7.4], [5.9, 5.4, 4.4, 4.6, 3.5, 3.7, 2.8, 2.8, 2.4, 1.5], sx=1 ./ sqrt.([1000., 1000, 500, 800, 200, 80,  60, 20, 1.8, 1]), sy=1 ./ sqrt.([1., 1.8, 4, 8, 20, 20, 70, 70, 100, 500]));

D = linearfitxy([0.037 0.0080; 0.035 0.0084; 0.032 0.0100; 0.040 0.0085; 0.013 0.0270; 0.038 0.0071; 0.042 0.0043; 0.030 0.0160], sx=0.03, sy=0.1, r=0.7071);
```

The results are added as new columns of a GMTdataset structure when they are vectors (`σX σY r`)
and stored as attributes when they are scalars (`a`, `b`, `σa`, `σb`, `σa95`, `σb95`, `ρ` and `S`):
- The intercept `a`, the slope `b` and their uncertainties `σa` and `σb`
- ``σa95`` and ``σb95``: 95%-confidence interval using two-tailed t-Student distribution,
    e.g.: ``b ± σb95 = b ± t(0.975,N-2)*σb``
- Goodness of fit `S` (reduced ``Χ²`` test): quantity with ``Χ²`` N-2 degrees of freedom
  `S ~ 1`: fit consistent with errors, `S > 1`: poor fit, `S >> 1`: errors underestimated,
  `S < 1`: overfitting or errors overestimated
- Pearson's correlation coefficient ``ρ`` that accounts for data errors

For more information and references see the LinearFitXYerrors.jl package at 
https://github.com/rafael-guerra-www/LinearFitXYerrors.jl
"""
function linearfitxy(XY::Matrix{<:Real}; sx=0, sy=0, r=0, ci::Int=95)
	x = view(XY, :, 1);	y = view(XY, :, 2);
	linearfitxy(x, y; sx=sx, sy=sy, r=r, ci=ci)
end
function linearfitxy(D::GMTdataset; sx=0, sy=0, r=0, ci::Int=95)
	x = view(D, :, 1);	y = view(D, :, 2);
	Df = linearfitxy(x, y; sx=sx, sy=sy, r=r, ci=ci)
	Df.colnames[1:2], Df.text, Df.header, Df.proj4, Df.wkt, Df.epsg = D.colnames[1:2], D.text, D.header, D.proj4, D.wkt, D.epsg
	!isempty(D.text) && append!(Df.colnames, [D.colnames[3]])
	return Df
end
function linearfitxy(X, Y; sx=0, sy=0, r=0, ci::Int=95)
	
	N = length(X)
	_ci = (ci + (100 - ci) / 2) / 100
	cf::Float64 = gmt("gmtmath -Q $(_ci) $(N-2) TCRIT").data[1]	# correction factor for 95% confidence intervals (two-tailed distribution)

	is_sorted = issorted(X)
	if (!is_sorted)			# If we latter plot with ribbon we'll need them sorted, so better do it right now.
		I = sortperm(X);
		X, Y = X[I], Y[I]
	end

	if (sx == 0) && (sy == 0)
		M = [ones(N) X]
		(a, b) = M \ Y
		X̄ = mean(X)    # Ȳ = mean(Y)

		# standard error * Ŝ factor defined in Cantrell (2008)
		S = sqrt(sum((Y - b*X .- a).^2)/(N-2))  # goodness of fit
		σb = sqrt(1/sum((X .- X̄ ).^2))
		σa = S * sqrt(1/N + X̄^2 * σb^2)
		σb *= S 
		ρ = cov(X,Y)/sqrt(var(X) * var(Y))		# Pearson's correlation coefficient:

		attribs = Dict("linearfit" => "1", "a" => "$a", "b" => "$b", "sigma_a" => "$(σa)", "sigma_b" => "$(σb)",
		               "sigma95_a" => "$(cf*σa)", "sigma95_b" => "$(cf*σb)", "Goodness_of_fit" => "$S", "Pearson" => "$ρ", "ci" => "$ci")
		D = mat2ds([vec(X) vec(Y)], attrib=attribs, colnames=["X", "Y"])
	else
		Nmax = 50;                  # maximum number of iterations
		tol = 1e-15;                #relative tolerance to stop at
	
		(r == 0 && (sx != 0 || sy != 0)) && (r = zeros(N))

		sx == 0 && (sx = 1e-16)
		sy == 0 && (sy = 1e-16)
		length(sx) == 1 &&  (sx = sx*ones(N))
		length(sy) == 1 &&  (sy = sy*ones(N))
		length(r)  == 1 &&  (r = r*ones(N))
	
		M = [ones(N) X]
		(a, b) = M \ Y              # initial guess for b
		bᵢ = zeros(Nmax+1);         #vector to save b iterations in
		bᵢ[1] = b
		X̄ = 0; Ȳ = 0;
		β = zeros(N)
		W = zeros(N)
		local i
		for outer i = 1:Nmax        # KEY TRICK
			ωX = 1 ./sx.^2
			ωY = 1 ./sy.^2
			α = sqrt.(ωX .* ωY)
			W .= ωX .* ωY ./(ωX + b^2 * ωY - 2*b * r .* α)
			X̄ = sum(W .* X)/sum(W)
			Ȳ = sum(W .* Y)/sum(W)
			U = X .- X̄
			V = Y .- Ȳ
			β .= W .* (U ./ ωY + b * V ./ ωX - (b * U + V) .* r ./ α)
			b = sum(W .* β .* V)/sum(W .* β .* U)
			bᵢ[i+1] = b
			abs((bᵢ[i+1] - bᵢ[i])/bᵢ[i+1]) < tol && break
		end
		a = Ȳ - b*X̄
		x = X̄ .+ β                  # y = Ȳ + b*β
		X̄ = sum(W .* x)/sum(W)      # Ȳ = sum(W .* y)/sum(W)

		# compare to: Ŝ = sqrt(sum((Y - b*X .- a).^2)/(N-2))
		S = sqrt(sum(W .* (Y - b*X .- a).^2) /(N-2))  # goodness of fit (York, 2004), (Cantrell, 2008)
	
		σb = sqrt(1/sum(W .* (x .- X̄).^2))
		σa = S * sqrt(1/sum(W) + X̄^2 * σb^2)
		σb *= S             # standard error * Ŝ factor (Cantrell, 2008)
	
		# See Wikipedia Regression dilution (Pearson's correlation coefficient with errors in variables)
		vX = var(X); vY = var(Y)
		ρ = cov(X,Y)/sqrt(vX*vY) * sqrt(vX/(vX + var(sx))) * sqrt(vY/(vY + var(sy))) 

		attribs = Dict("linearfit" => "1", "a" => "$a", "b" => "$b", "sigma_a" => "$(σa)", "sigma_b" => "$(σb)",
		               "sigma95_a" => "$(cf*σa)", "sigma95_b" => "$(cf*σb)", "Goodness_of_fit" => "$S", "Pearson" => "$ρ", "ci" => "$ci")
		D = mat2ds([vec(X) vec(Y) sx sy r], colnames=["X", "Y", "σX", "σY", "corr(σX,σY)"], attrib=attribs)
	end

	D.comment = [@sprintf("[± σ]  Y = (%.4f ± %.4f) + (%.4f ± %.4f)*X", a, σa, b, σb),
                 @sprintf("[± %d%% CI]  Y = (%.4f ± %.4f) + (%.4f ± %.4f)*X", ci, a, cf*σa, b, cf*σb),
                 @sprintf("Pearson ρ = %.2f; Goodness of fit = %.2f", ρ, S)]

	return D
end


# --------------------------------------------------------------------------------------------------
"""
    plotlinefit(D::GMTdataset, kwargs...)

Plot the line fit of the points in the `D` GMTdataset type incliding confidence intervals ann error ellipses.
The `D` input is the result of having run your data through the `linearfitxy` function. See its docs for the
meaning of the parameters mentioned below.

- `band_ab` or `ribbon_ab`: Plot a band, `(a±σa) + (b±σb)`, around the fitted line. `band_ab=true` uses the default
   `lightblue` color. Use `band_ab=*color*` to paint it with a color of your choice (this color may include transparency)
- `band_ci` or `ribbon_ci`: Plot a band, `(a±σa95) + (b±σb95)`, with the 95% (or other Confidence Interval). `band_ci=true`
   uses the default `tomato` color. Use `band_ci=*color*` to paint it with a color of your choice (transparency included).
- `ellipses`: optionaly plot error ellipses when the `σX, `σY` errors are known.
- `legend`: By default we do not plot the legend boxes with line fit info. Set `legend=rue` to plot them. For the time
   being the legend locations are determine automaticaly and can't be manually controlled.``
- `lc or linecolor`: By default the fitted line is plotted with `red` color. Use `lc=*color*` to change it.
- `lt, lw or linethickness`: By default the fitted line thickness is set to `0.5`. Use `lt=*thickness*` to change it.

Other than the above options you can use most of the `plot` options that control line and marker symbol.

# Examples:
```julia-repl
plotlinefit(D, band_ab=true, band_ci=true, legend=true, show=1)
```
"""
function plotlinefit(D::Vector{<:GMTdataset}; first::Bool=true, kw...)
	d = KW(kw)
	N_clusters = numel(D) 
	cycle_colors = (N_clusters <= 7) ? matlab_cycle_colors : simple_distinct	# Will blow if > 20

	do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
	figname::String = ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) ? val : ""

	band_CI = ((val = find_in_dict(d, [:ribbon_CI :band_CI :ribbon_ci :band_ci])[1]) !== nothing) ? val : ""
	do_band_CI = (band_CI != 0 && band_CI != "")
	do_band_CI && (d[:band_CI] = (bc = edit_segment_headers!(D[1], 'G', :get)) != "" ? bc*"@85" : cycle_colors[1]*"@85")

	band_ab = ((val = find_in_dict(d, [:ribbon_ab :band_ab], false)[1]) !== nothing) ? val : ""
	do_band_ab = (band_ab != 0 && band_ab != "")
	do_band_ab && (d[:band_ab] = (bc = edit_segment_headers!(D[1], 'G', :get)) != "" ? bc*"@85" : cycle_colors[1]*"@85")

	legend = ((val = find_in_dict(d, [:legend :label], false)[1]) !== nothing) ? val : ""
	d[:legend] = legend

	_figname = find_in_dict(d, [:name :figname :savefig])[1]	# We can't let it go before last plot command

	plotlinefit(D[1]; first=first, grp=true, d...)
	d = CTRL.pocket_d[1]
	d[:band_ab], d[:band_CI], d[:legend] = band_ab, band_CI, legend
	for k = 2:N_clusters
		do_band_CI && (d[:band_CI] = (bc = edit_segment_headers!(D[k], 'G', :get)) != "" ? bc*"@85" : cycle_colors[k]*"@85")
		do_band_ab && (d[:band_ab] = (bc = edit_segment_headers!(D[k], 'G', :get)) != "" ? bc*"@85" : cycle_colors[k]*"@85")
		plotlinefit(D[k]; first=false, grp=true, d...)
		if (k < N_clusters)
			d = CTRL.pocket_d[1];
			d[:band_ab], d[:band_CI], d[:legend] = band_ab, band_CI, legend
		end
	end
	showfig(show=do_show, figname=figname)		# Only show if requested but also sets the figname if requested.
	(do_show || _figname !== nothing) && showfig(show=do_show, figname=_figname)	# Only show if requested and also sets the figname if requested.
end

# --------------------------------------------------------------------------------------------------
plotlinefit(m::Matrix{<:Real}; first::Bool=true, grp::Bool=false, kw...) = plotlinefit(linearfitxy(m); first=first, grp=grp, kw...)
function plotlinefit(D::GMTdataset; first::Bool=true, grp::Bool=false, kw...)
	# Plot fit line, data points and confidence intervals (some optional) from GMTds created by linearfitxy.
	# `grp=true` only when originally called from plotlinefit(D::Vector{<:GMTdataset})
	
	(get(D.attrib, "a", "") == "" || get(D.attrib, "b", "") == "") && (@warn("Input must be the result of linearfitxy"); return nothing)
	d = KW(kw)
	
	function do_ribs(d, symbs, def_color::String)
		do_rib, rib_cor = false, ""
		if ((val = find_in_dict(d, symbs)[1]) !== nothing)	# Either 'true' or ribbon color
			rib_cor = (val == 1) ? def_color : string(val)::String 
			do_rib = (rib_cor != "")
		end
		return do_rib, rib_cor
	end

	do_rib_ab, rib_ab_cor = do_ribs(d, [:ribbon_ab :band_ab], "lightblue")
	do_rib_CI, rib_CI_cor = do_ribs(d, [:ribbon_CI :band_CI :ribbon_ci :band_ci], "pink")	
	do_ellipses = (find_in_dict(d, [:ellipses :ellipse])[1] !== nothing)
	(do_ellipses && size(D,2) < 5) && (@warn("Can't plot ellipses when σX and σY are not known");	do_ellipses = false)
	do_legends = (haskey(d, :legend) && (d[:legend] != "" || d[:legend] == true))		# see if user wants legends
	do_show = (haskey(d, :show) && d[:show] == 1);	delete!(d, :show)
	(grp) && (figname::String = ((val = find_in_dict(d, [:savefig])[1]) !== nothing) ? val : "")	# Only last call may have it != ""

	X = view(D, :, 1);	Y = view(D, :, 2);
	a, b   = parse(Float64, D.attrib["a"]), parse(Float64, D.attrib["b"])
	σa, σb = parse(Float64, D.attrib["sigma_a"]), parse(Float64, D.attrib["sigma_b"])
	σa95, σb95 = parse(Float64, D.attrib["sigma95_a"]), parse(Float64, D.attrib["sigma95_b"])
	ρ, S, ci = parse(Float64, D.attrib["Pearson"]), parse(Float64, D.attrib["Goodness_of_fit"]), parse(Int, D.attrib["ci"])
	
	tl, bl = (a - σa) .+ (b + σb)*X,  (a + σa) .+ (b - σb)*X
	recta = a .+ b * X
	if (do_rib_ab)
		σp, σm = vec(maximum([tl bl], dims=2)) .- recta, recta .- vec(minimum([tl bl], dims=2))
	end

	if (do_rib_CI)
		N = length(X)
		_ci = (ci + (100 - ci) / 2) / 100
		cf::Float64 = gmt("gmtmath -Q $(_ci) $(N-2) TCRIT").data[1]
		σx95 = cf * S * sqrt.(1/N .+ (X .- mean(X)).^2 / var(X) /(N-1))
		mi, ma = min(recta[1]-σx95[1], recta[end]-σx95[end]), max(recta[1]+σx95[1], recta[end]+σx95[end])
	elseif (do_rib_ab)
		mi, ma = min(D.bbox[3], min(recta[1]-σm[1], recta[end]-σm[end])), max(D.bbox[4], max(recta[1]+σp[1], recta[end]+σp[end]))
	else
		mi, ma = min(recta[1], D.ds_bbox[3]), max(recta[end], D.ds_bbox[4])
	end

	leg_off = "0.15"		# Default legend offset
	_figname = find_in_dict(d, [:name :figname :savefig])[1]	# We can't let it go before last plot command (no use when grp)
	inset = find_in_dict(d, [:inset])[1]

	if (first)
		mi, ma = min(mi, D.ds_bbox[3]), max(ma, D.ds_bbox[4])
		wesn::Vector{Float64} = round_wesn([D.ds_bbox[1], D.ds_bbox[2], mi, ma], false, [0.01, 0.01])
		opt_R = @sprintf("%.12g/%.12g/%.12g/%.12g", wesn[1], wesn[2], wesn[3], wesn[4])

		if (do_legends && (_cmd = parse_params(d, "", false)) != "")
			contains(_cmd, "inside") && (leg_off = "0.6")		# For inside annotations, offset must be larger
		end

		(haskey(d, :xlabel) && string(d[:xlabel]) == "auto") && (d[:xlabel] = D.colnames[1])	# Because basemap knows nikles on D
		(haskey(d, :ylabel) && string(d[:ylabel]) == "auto") && (d[:ylabel] = D.colnames[2])
		basemap(; R=opt_R, Vd=-1, d...)		# START THE PLOT
		d = CTRL.pocket_d[1]				# Get back what was not consumemd in basemap
	else
		opt_R = CTRL.pocket_R[1][4:end]
	end

	if (do_rib_CI)							# Plot a Ribbon with the % Cofidence limit
		leg = (do_legends && !grp) ? (ribbon="$(ci)% confidence", label=" ") : ""
		plot!([X recta]; fill=rib_CI_cor, ribbon=(σx95,σx95), legend=leg)
	end

	# Check these here (and store their values if they were passed in) before they get consumed in next plot call.
	# The problem here is that parameters passed in kwargs may be consumed in a previous call to plot when they
	# in fact meant to be used in a latter one (e.g. scatter) so we must make copies before theyare prematutrely
	# consumed, but this process is not complete enough and there will always be some that is not backed up.
	ms = ((val = find_in_dict(d, [:ms :markersize :MarkerSize])[1]) !== nothing) ? string(val)::String : "0.1"
	mc = ((val = find_in_dict(d, [:mc :markercolor :markerfacecolor :MarkerFaceColor])[1]) !== nothing) ? string(val)::String : "#0072BD"
	(grp) && (mc = ((mc = edit_segment_headers!(D, 'G', :get)) != "" ? mc : "#0072BD"))
	mk = ((val = find_in_dict(d, [:marker])[1]) !== nothing) ? arg2str(val)::String : "circ"
	
	if ((opt_W = edit_segment_headers!(D, 'W', :get)) == "")
		lc = ((val = find_in_dict(d, [:lc :linecolor])[1]) !== nothing) ? string(val)::String : "red"
		lt = ((val = find_in_dict(d, [:lt :lw :linethickness])[1]) !== nothing) ? string(val)::String : "0.5"
		ls = ((val = find_in_dict(d, [:ls :linestyle])[1]) !== nothing) ? string(val)::String : ""
		opt_W = lt * "," * lc * "," * ls
	end

	(do_legends && grp) && (d[:legend] = D.attrib["group_name"])
	# Plot the data points by default as small filled blue [if default] circles.
	if (inset !== nothing)
		CTRL.pocket_call[4] = D			# Don't know what happens if multi-segments
		kk = keys(inset)
		if (kk[1] == :zoom)				# If not set by user, replicate the scatter options (NOT TEST THE ALIAS)
			_mk = (:marker in kk) ? NamedTuple() : (marker=mk,)
			_mc = (:mc in kk) ? NamedTuple() : (mc=mc,)
			_ms = (:ms in kk) ? NamedTuple() : (ms="0.075",)
			inset = merge(inset, _mk, _ms, _mc, (plot=(data=[X[1] recta[1]; X[end]], W=opt_W),))
		end
		d[:inset] = inset				# Somehow this screws -R -J and that's why we repeat them in the plot! cmd below.
	end
	scatter!(D; marker=mk, ms=ms, mc=mc, R=opt_R, J=CTRL.pocket_J[1][4:end], d...)	# If inset this also triggers the inset plot
	(inset !== nothing) && (delete!(d, :inset))

	pos = (b > 0) ? "TL" : "TR"
	d[:W] = opt_W

	if (do_rib_ab)						# Plot a Ribbon with the errors in a & b parameters
		d[:legend] = (do_legends && !grp) ? (label=@sprintf("r = %.2f",ρ), ribbon="(a\\261@~s@~a)+(b\\261@~s@~b)X`14", pos=pos) : ""
		plot!([X recta]; R=opt_R, J=CTRL.pocket_J[1][4:end], fill=rib_ab_cor, ribbon=(σp,σm), d...)
	else
		d[:legend] = (do_legends && !grp) ? (label=@sprintf("r = %.2f",ρ), pos=pos) : ""
		plot!([X recta]; R=opt_R, J=CTRL.pocket_J[1][4:end], d...)
	end
	d = CTRL.pocket_d[1]				# Get back what was not consumemd in basemap

	if (do_ellipses)					# Plot ellipses?
		covXY = view(D, :, 3) .* view(D, :, 4) .* view(D, :, 5)		# covXY = σX .* σY .* r
		plot_covariance_ellipses!(X, Y, view(D, :, 3).^2,  covXY, view(D, :, 4).^2, lc=:darkgray)
	end

	if (!grp && do_legends)
		fs = 7		# Font size
		lab_width = 48 * fs / 72 * 2.54 * 0.50 - 0.35	# Guess label width in cm
		pos = (b > 0) ? "BR" : "BL"
		legend!((symbol1=(marker=:point, size=0, dx_right=0.0,
		                text=@sprintf("[\\261@~s@~ab] Y = (%.3f \\261 %.3f) + (%.3f \\261 %.3f)*X", a, σa, b, σb)),
		         symbol2=(marker=:point, size=0, dx_right=0.0,
		                text=@sprintf("[%d%%]  Y = (%.3f \\261 %.3f) + (%.3f \\261 %.3f)*X", ci, a, σa95, b, σb95))),
		         F="+p0.5+gwhite", D="j$(pos)+w$(lab_width)+o$(leg_off)", par=(:FONT_ANNOT_PRIMARY, fs))
	end
	(!grp && (do_show || _figname !== nothing)) && showfig(show=do_show, figname=_figname)		# Only show if requested but also sets the figname if requested.
end
plotlinefit!(D; kw...) = plotlinefit(D; first=false, kw...)

# --------------------------------------------------------------------------------------------------
function plot_covariance_ellipses!(X, Y, a, b, c; lc=:lightgray, lw=0.3)
	# https://cookierobotics.com/007/
	# covariance matrix = [a b; b c]
	# From https://github.com/rafael-guerra-www/LinearFitXYerrors.jl too
	# TODO: figure out how to compute native PS ellipses so that we can make a single call to plot them all.
	t = LinRange(0, 2π, 72)
	st, ct = sin.(t), cos.(t)
	for (X, Y, a, b, c) in zip(X, Y, a, b, c)
		r = sqrt(((a - c)/2)^2 + b^2)
		λ₁ = sqrt(abs((a + c)/2 + r))
		λ₂ = sqrt(abs((a + c)/2 - r))

		(b == 0 && a >= c) ? (θ = 0.) : (b == 0 && a < c)  ? (θ = π/2) : (θ = atan(λ₁^2 - a, b))

		xₜ = @. X + λ₁*cos(θ)*ct - λ₂*sin(θ)*st
		yₜ = @. Y + λ₁*sin(θ)*ct + λ₂*cos(θ)*st
		plot!(xₜ, yₜ, lc=lc, lw=0.3)
	end
end

# --------------------------------------------------------------------------------------------------
"""
    ablines(a, b; kw...)
or

    ablines([a1, a2, ..., an], [b1, b2, ..., bn]; kw...)
or

    ablines(D::GMTdataset; kw...)

Creates a straight line(s) defined by Y = a + b * X. Input can be a pair of `a,b` parameters or a vector
of them, case in which multiple straight lines are plotted. Plot limits are passed through the usual `region`
option in `kw` or, if missing, we plot lines in the x = [0 10] interval. The third form, when input is a
`GMTdataset` type implies that this was computed with the `linearfitxy` function, which embeds the linear fit
parameters in the data type attributes. All `plot` options are available via the `kw` arguments.

# Examples:
```julia-repl
ablines([1, 2, 3], [1, 1.5, 2], linecolor=[:red, :orange, :pink], linestyle=:dash, linewidth=2, show=true)
```
```julia-repl
D = linearfitxy([0.0, 0.9, 1.8, 2.6, 3.3, 4.4, 5.2, 6.1, 6.5, 7.4], [5.9, 5.4, 4.4, 4.6, 3.5, 3.7, 2.8, 2.8, 2.4, 1.5],
                 sx = 1 ./ sqrt.([1000., 1000, 500, 800, 200, 80,  60, 20, 1.8, 1]), sy=1 ./
                 sqrt.([1., 1.8, 4, 8, 20, 20, 70, 70, 100, 500]));
plot(D, linefit=true, band_ab=true, band_CI=true, ellipses=true, Vd=2)
plot!(D, linefit=true, Vd=2)
ablines!(D, Vd=2)
ablines!(0,1, Vd=2)
```
"""
function ablines(D::GMTdataset; first::Bool=true, kw...)
	(get(D.attrib, "linearfit", "") == "") &&
		error("Invalid GMTdataset input into 'ablines'. Only valid ones are those produced by the 'linearfitxy' function")
	a, b = parse(Float64, D.attrib["a"]), parse(Float64, D.attrib["b"])
	d = KW(kw)
	mat = helper_ablines(d, a, b)
	plot(mat2ds(mat); first=first, kw...)
end
ablines(a, b; first::Bool=true, kw...) = plot(helper_ablines(KW(kw), a, b); first=first, kw...)
function ablines(a::Vector{<:Real}, b::Vector{<:Real}; first::Bool=true, kw...)
	@assert(length(a) == length(b))
	d = KW(kw)
	mat = Matrix{Float64}(undef, 2, length(a)+1)
	mat[:, 1:2] = helper_ablines(d, a[1], b[1])
	for k = 2:length(a)
		mat[:, k+1] = helper_ablines(d, a[k], b[k])[:,2]
	end
	D = mat2ds(mat; multi=true, d...)
	plot(D; first=first, CTRL.pocket_d[1]...)
end
ablines!(D::GMTdataset; kw...) = ablines(D; first=false, kw...)
ablines!(a::Vector{<:Real}, b::Vector{<:Real}; kw...) = ablines(a, b; first=false, kw...)
ablines!(a, b; kw...) = ablines(a, b; first=false, kw...)

function helper_ablines(d, a, b)
	# Deal with the two cases of whether or not a plotting limits was passed in.
	if ((opt_R = parse_R(d, "", false, false)[2]) != "")
		x1, x2 = CTRL.limits[7], CTRL.limits[8]
		y1, y2 = a + b * x1, a + b * x2
		[x1 y1; x2 y2]
	else		# OK, no -R, so we'll invent a line in the x =[0 10] interval
		[0. a; 10. a+10b]
	end
end
