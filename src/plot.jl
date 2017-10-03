# ----------------------------------------------------------------------------------------------------------
plot(arg1::GMTdataset; V=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; V=V, caller="plot", data=data, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::GMTdataset; V=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; V=V, caller="plot", data=data, portrait=portrait, fmt=fmt, K=K, O=O, first=false, kw...)

# ----------------------------------------------------------------------------------------------------------
plot(arg1::Array; V=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; V=V, caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::Array; V=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; V=V, caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=K, O=O, first=false, kw...)

# -----------------------------------------------------------------------------------------------------------
plot(arg1::String; V=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; V=V, caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::String; V=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; V=V, caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=K, O=O, first=false, kw...)

# ----------------------------------------------------------------------------------------------------------
function plot(arg1::Array, arg2::Array; V=false, extra="", data=[], portrait=true, fmt="",
              K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	psxy(extra, arg; V=V, caller="plot", data=[], portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
end
function plot!(arg1::Array, arg2::Array; V=false, extra="", data=[], portrait=true, fmt="",
               K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	psxy(extra, arg; V=V, caller="plot", data=[], portrait=portrait, fmt=fmt, K=K, O=O, first=false, kw...)
end
# ----------------------------------------------------------------------------------------------------------