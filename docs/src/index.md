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
plot(arg1=[], arg2=[]; fmt="", kwargs...)

imshow(input; fmt="", kwargs...)

coast(fmt="", clip=[], kwargs...)

histogram(arg1=[]; fmt="", kwargs...)

scale(arg1=[]; fmt="", kwargs...)

text(arg1=[]; fmt="", kwargs...)

rose(arg1=[]; fmt="", kwargs...)

soloar(arg1=[]; fmt="", kwargs...)

xy(arg1=[]; fmt="", kwargs...)

gmtinfo(arg1=[], kwargs...)

grdcontour(arg1=[]; data=[], fmt="", kwargs...)

grdimage(arg1=[], arg2=[], arg3=[], arg4=[]; data=[], fmt="", kwargs...)

grdinfo(arg1=[], kwargs...)

grdtrack(arg1=[], arg2=[], kwargs...)

grdview(arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
        fmt="", kwargs...)

makecpt(arg1=[]; data=[], kwargs...)

nearneighbor(arg1=[]; fmt="", kwargs...)

surface(arg1=[]; fmt="", kwargs...)

triangulate(arg1=[]; fmt="", kwargs...)
```