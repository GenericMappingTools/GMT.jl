# ----------------------------------------------------------------------------------------------------------------
plot(arg1::GMTdataset; Vd=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; Vd=Vd, caller="plot", data=data, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::GMTdataset; Vd=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; Vd=Vd, caller="plot", data=data, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)

# ----------------------------------------------------------------------------------------------------------------
# Tested with plot(xyz, S="c0.1c", C=cpt, fmt="ps", show=1)
plot(arg1::Array; Vd=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; Vd=Vd, caller="plot", data=data, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::Array; Vd=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, arg1; Vd=Vd, caller="plot", data=data, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)

# -----------------------------------------------------------------------------------------------------------------
plot(arg1::String; Vd=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; Vd=Vd, caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
plot!(arg1::String; Vd=false, extra="", data=[], portrait=true, fmt="", K=false, O=false, first=true, kw...) =
	psxy(extra, []; Vd=Vd, caller="plot", data=arg1, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)

# ----------------------------------------------------------------------------------------------------------------
function plot(arg1::Array, arg2::Array; Vd=false, extra="", data=[], portrait=true, fmt="",
              K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	psxy(extra, arg; Vd=Vd, caller="plot", data=[], portrait=portrait, fmt=fmt, K=K, O=O, first=first, kw...)
end
function plot!(arg1::Array, arg2::Array; Vd=false, extra="", data=[], portrait=true, fmt="",
               K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	psxy(extra, arg; Vd=Vd, caller="plot", data=[], portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)
end
# ----------------------------------------------------------------------------------------------------------------