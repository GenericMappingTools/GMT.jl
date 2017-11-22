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
plot(arg1::Array; fmt="", kwargs...)

imshow(arg1; fmt="", kwargs...)

basemap(cmd0::String=""; fmt="", kwargs...)

coast(cmd0::String=""; fmt="", clip=[], kwargs...)

histogram(cmd0::String="", arg1=[]; fmt::String="", kwargs...)

colorbar(cmd0::String="", arg1=[]; fmt="", kwargs...)

text(cmd0::String="", arg1=[]; fmt="", kwargs...)

rose(cmd0::String="", arg1=[]; fmt="", kwargs...)

solar(cmd0::String="", arg1=[]; fmt="", kwargs...)

xy(cmd0::String="", arg1=[]; fmt="", kwargs...)

gmtinfo(cmd0::String="", arg1=[]; kwargs...)

grdcontour(cmd0::String="", arg1=[]; fmt="", kwargs...)

grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; fmt="", kwargs...)

grdinfo(cmd0::String="", arg1=[]; kwargs...)

grdtrack(cmd0::String="", arg1=[], arg2=[]; kwargs...)

grdview(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; 
        fmt="", kwargs...)

makecpt(cmd0::String="", arg1=[]; kwargs...)

nearneighbor(cmd0::String="", arg1=[]; fmt="", kwargs...)

psconvert(cmd0::String="", arg1=[]; kwargs...)

splitxyz(cmd0::String="", arg1=[]; kwargs...)

surface(cmd0::String="", arg1=[]; fmt="", kwargs...)

triangulate(cmd0::String="", arg1=[]; fmt="", kwargs...)

wiggle(cmd0::String="", arg1=[]; fmt="", kwargs...)
```