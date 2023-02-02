# This function is from the LinearFitXYerrors package (https://github.com/rafael-guerra-www/LinearFitXYerrors.jl)
# Extracted insted of making LinearFitXYerrors a dependency because we don't want to bring in more
# dependencies. Original dependencies, 'Distributions' and 'Plots' were entirely replaced by GMT alone.
# 
# In the process the output is now a GMTdataset type with some fitting parameters stored as attributes.

"""
linearfitxy(X, Y; σX=0, σY=0, r=0)

Performs 1D linear fitting of experimental data with uncertainties in  X and Y:
- Linear fit:             `Y = a + b*X`                               [1]
- Errors:                 ``X ± σX;  Y ± σY``                         [2]
- Errors' correlation:    ``r =  = cov(σX, σY) / (σX * σY)``          [3]

# Arguments:
- `X` and `Y` are input data vectors with length ≥ 3
- Optional standard deviation errors ``σX`` and ``σY`` are vectors or scalars
- Optional `r` is the correlation between the ``σX`` and ``σY`` errors
`r` can be a vector or scalar

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
function linearfitxy(XY::Matrix{<:Real}; sx=0, sy=0, r=0)
	x = view(XY, :, 1);	y = view(XY, :, 2);
	linearfitxy(x, y; sx=sx, sy=sy, r=r)
end
function linearfitxy(D::GMTdataset; sx=0, sy=0, r=0)
	x = view(D, :, 1);	y = view(D, :, 2);
	linearfitxy(x, y; sx=sx, sy=sy, r=r)
end
function linearfitxy(X, Y; sx=0, sy=0, r=0)
	
	N = length(X)
	cf::Float64 = gmt("gmtmath -Q 0.975 $(N-2) TCRIT").data[1]	# correction factor for 95% confidence intervals (two-tailed distribution)

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
		               "sigma95_a" => "$(cf*σa)", "sigma95_b" => "$(cf*σb)", "Goodness_of_fit" => "$S", "Pearson" => "$ρ")
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
		               "sigma95_a" => "$(cf*σa)", "sigma95_b" => "$(cf*σb)", "Goodness_of_fit" => "$S", "Pearson" => "$ρ")
		D = mat2ds([vec(X) vec(Y) sx sy r], colnames=["X", "Y", "σX", "σY", "corr(σX,σY)"], attrib=attribs)
	end

	@printf("\n>>> [± σ]  Y = (%.4f ± %.4f) + (%.4f ± %.4f)*X \n", a,  σa, b, σb)
	@printf(">>> [± 95%% CI]  Y = (%.4f ± %.4f) + (%.4f ± %.4f)*X \n", a, cf*σa, b, cf*σb)
	@printf(">>> Pearson ρ = %.3f;  Goodness of fit = %.3f \n\n", ρ, S)

	return D
end