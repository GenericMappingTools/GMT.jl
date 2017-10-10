# GMT.jl Documentation

```@contents
```

## Index

```@index
```

## Functions

```@docs
psxy(cmd0::String="", arg1=[]; caller=[], data=[], fmt="",
     K=false, O=false, first=true, kwargs...)

pscoast(cmd0::String=""; fmt="", clip=[], K=false, O=false, first=true, kwargs...)
    
psscale(cmd0::String="", arg1=[]; fmt="", K=false, O=false, first=true, kwargs...)

grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],
         fmt="", K=false, O=false, first=true, kwargs...)

grdcontour(cmd0::String="", arg1=[]; data=[], fmt="",
           K=false, O=false, first=true, kwargs...)

grdview(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
        fmt="", K=false, O=false, first=true, kwargs...)

makecpt(cmd0::String="", arg1=[]; data=[], kwargs...)
```