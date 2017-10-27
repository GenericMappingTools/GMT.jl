# GMT.jl Documentation

```@contents
```

## Index

```@index
```

## Functions

```@meta
DocTestSetup = quote
    using GMT
end
```

```@docs
plot(cmd0::String="", arg1=[]; fmt="", kwargs...)

psxy(cmd0::String="", arg1=[]; fmt="", kwargs...)

pscoast(cmd0::String=""; fmt="", clip=[], kwargs...)

pshistogram(cmd0::String="", arg1=[]; fmt="", kwargs...)

psscale(cmd0::String="", arg1=[]; fmt="", kwargs...)

pstext(cmd0::String="", arg1=[]; fmt="", kwargs...)

gmtinfo(cmd0::String="", arg1=[], kwargs...)

grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],
         fmt="", kwargs...)

grdcontour(cmd0::String="", arg1=[]; data=[], fmt="", kwargs...)

grdinfo(cmd0::String="", arg1=[], kwargs...)

grdview(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
        fmt="", kwargs...)

makecpt(cmd0::String="", arg1=[]; data=[], kwargs...)

surface(cmd0::String="", arg1=[]; fmt="", kwargs...)
```
