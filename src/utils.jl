# Collect generic utility functions in this file

""" Return the decimal part of a float number `x`"""
getdecimal(x::AbstractFloat) = x - trunc(Int, x)

""" Return an ierator over data skipping non-finite values"""
skipnan(itr) = Iterators.filter(el->isfinite(el), itr)

square(x) = x^2

function funcurve(f::Function, lims::VMr, n=100)
	# Geneate a corve between lims[1] and lims[2] having the form of function 'f'
	if     (f == exp)    x = log.(lims)
	elseif (f == log)    x = exp.(lims)
	elseif (f == log10)  x = exp10.(lims)
	elseif (f == exp10)  x = log10.(lims)
	elseif (f == sqrt)   x = square.(lims)
	elseif (f == square) x = sqrt.(lims)
	else   error("Function $f not implemented in funcurve().")
	end
	f.(linspace(x[1], x[2], n))
end