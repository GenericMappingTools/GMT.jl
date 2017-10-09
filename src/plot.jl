# -------------------------------------------------------------------------------------------------------------
plot(arg1::GMTdataset; extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; caller="plot", data=data, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::GMTdataset; extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; caller="plot", data=data, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)

# -------------------------------------------------------------------------------------------------------------
# Tested with plot(xyz, S="c0.1c", C=cpt, fmt="ps", show=1)
plot(arg1::Array; extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; caller="plot", data=data, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::Array; extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; caller="plot", data=data, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)

# --------------------------------------------------------------------------------------------------------------
plot(arg1::String; extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::String; extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)

# -------------------------------------------------------------------------------------------------------------
function plot(arg1::Array, arg2::Array; extra="", data=[], portrait=true, fmt="",
              K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	psxy(extra, arg; caller="plot", data=[], portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
end
function plot!(arg1::Array, arg2::Array; extra="", data=[], portrait=true, fmt="",
               K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	psxy(extra, arg; caller="plot", data=[], portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)
end
# -------------------------------------------------------------------------------------------------------------