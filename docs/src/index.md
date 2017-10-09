# GMT.jl Documentation

```@contents
```

## Index

```@index
```

## Functions

```@docs
psxy(cmd0::String="", arg1=[]; caller=[], data=[], portrait=true, fmt="", K=false, O=false, first=true, kwargs...)

pscoast(cmd0::String=""; portrait=true, fmt="", clip=[], K=false, O=false, first=true, kwargs...)
    
psscale(cmd0::String="", arg1=[]; portrait=true, fmt="", K=false, O=false, first=true, kwargs...)

grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; data=[], portrait=true, 
fmt="", K=false, O=false, first=true, kwargs...)

grdcontour(cmd0::String="", arg1=[]; data=[], portrait=true, fmt="", K=false, O=false, first=true, kwargs...)

grdview(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
        portrait=true, fmt="", K=false, O=false, first=true, kwargs...)
```