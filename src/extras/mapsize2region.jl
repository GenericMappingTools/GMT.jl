
# ---------------------------------------------------------------------------------------------------
"""
    region_opt, proj_opt = mapsize2region(proj=?, scale=?, clon=?, clat=?, width=?, height=0, bnds="", plot=false)

Compute the region for a map of user specified projection, scale, width and height.

### Kwargs
- `proj`: Projection. Either a string (e.g. "m" for Mercator, "lambert", "stere", etc.), or a tuple for
   projections that demand more parameters. Same syntax as `coast`, etc. 
- `scale`: Scale of the map in the form of "1:xxxx" (e.g. "1:1000000").
- `clon`: Center longitude of the map in degrees.
- `clat`: Center latitude of the map in degrees.
- `width`: Width of the map in centimeters.
- `height`: Height of the map in centimeters. If not specified, it defaults to `width`.
- `bnds`: We need a default limits as first approximation to obtain the seeked region. That normally is the global
   [-180 180 -90 90]. But that might not work for certain cases as for example the Mercator projection Where no poles
   are allowed). Thoug the Mercator case is dealt in internally, there are other projections that don't allow global
   limits. In those cases, you will need to specify `bnds` using the same syntax as for the `region` option of all
   GMT functions.
- `plot`: If true, we generate an example map representative of the requested region using `coast` function.
   Use this only to get an idea of the obtained region. No fine tunings are done here. Default is false.

### Returns
A tuple with the region in the form of "xmin/xmax/ymin/ymax" and the projection string used.
Use this ooutput as input on all odules that require a `region` and `projection`.

### Credits
Stolen fom Tim Hume's idea posted in the GMT forum:
https://forum.generic-mapping-tools.org/t/script-to-create-a-map-with-defined-width-and-height/5909/17?u=joaquim

### Example
```julia
opt_R, opt_J = mapsize2region(proj=(name=:tmerc, center=-177), scale="1:10000000", clon=-177, clat=-21, width=15, height=10)

# And now do a simple coastline map showing the region.
# Note that the same could be achieved by setting the `plot=true` but this shows more explicitly
# how to use the mapsize2region() output.
coast(region=opt_R, proj=opt_J, shore=true, show=true)
```
"""
function mapsize2region(; proj="", scale="", clon=NaN, clat=NaN, width=0, height=0, bnds="", plot=false)::Tuple{String, String}
	(height == 0) && (height = width)		# If height is not specified, use width
	@assert proj != "" "Projection must be specified"
	@assert clon != NaN && clat != NaN "Center longitude and latitude must be specified"
	@assert width > 0 && height > 0 "Width and height must be positive"
	@assert contains(scale, ':') "Scale must be in the form of '1:xxxx'"
	(!isa(proj, StrSymb)) && (proj = parse_J(Dict{Symbol,Any}(:J => proj, :scale => scale), "")[1][4:end];	scale="")	# scale is now in J
	(bnds != "") && (bnds = parse_R(Dict{Symbol,Any}(:R => bnds), "")[4:end])	# If bnds is not empty, parse it
	(!isa(scale, StrSymb)) && (scale = parse_Scale(Dict{Symbol,Any}(:S => scale), ""))	# If scale is not a StrSymb, parse it
	(bnds == "" && proj == "m" || startswith(proj, "merc") || startswith(proj, "Merc")) && (bnds="-180/180/-85/85")	# Default bounds for Mercator
	opt_R, opt_J = mapsize2region(string(proj), scale, Float64(clon), Float64(clat), Float64(width), Float64(height), bnds)
	(plot != 0) && coast(R=opt_R, J=opt_J, shore=true, show=true, Vd=1)
	return opt_R, opt_J
end
function mapsize2region(proj::String, scale::String, clon::Float64, clat::Float64, width::Float64, height::Float64, bnds)::Tuple{String, String}
	t::Matrix{Float64} = mapproject([clon clat], J=proj*scale, R=bnds).data
	t2 = [t[1]-width/2 t[2]-height/2; t[1]+width/2 t[2]+height/2]
	t3 = mapproject(t2, J=proj*scale, R=bnds, I=true)		# Convert back to lon lat
	@sprintf("%.8f/%.8f/%.8f/%.8f+r", t3[1,1], t3[1,2], t3[2,1], t3[2,2]), proj*scale
end
