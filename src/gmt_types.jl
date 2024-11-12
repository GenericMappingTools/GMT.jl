"""
    mutable struct GMTgrid{T<:Number,N} <: AbstractArray{T,N}

The GMTgrid type is how grids, 2D or multi-layered, (geo)referenced or not, communicate in/out
with the GMT and GDAL libraries. They implement the AbstractArray interface.

The fields of this struct are:
- `proj4::String`:                      Projection string in PROJ4 syntax (Optional)
- `wkt::String`:                        Projection string in WKT syntax (Optional)
- `epsg::Int`:                          EPSG code
- `geog::Int`:                          Is geographic coords? 0 -> No; 1 -> [-180 180]; 2 -> [0 360]
- `range::Vector{Float64}`:             1x6[8] vector with [x_min, x_max, y_min, y_max, z_min, z_max [, v_min, v_max]]
- `inc::Vector{Float64}`:               1x2[3] vector with [x_inc, y_inc [,v_inc]]
- `registration::Int`:                  Registration type: 0 -> Grid registration; 1 -> Pixel registration
- `nodata::Union{Float64, Float32}`:    The value of nodata
- `title::String`:                      Title (Optional)
- `comment::String`:                    Remark (Optional)
- `command::String`:                    Command used to create the grid (Optional)
- `cpt::String`:                        Name of a recommended GMT CPT name for this grid.
- `names::Vector{String}`:              To use whith multi-layered and when layers have names (Optional)
- `x::Vector{Float64}`:                 [1 x n_columns] vector with XX coordinates
- `y::Vector{Float64}`:                 [1 x n_rows]    vector with YY coordinates
- `v::Union{Vector{<:Real}, Vector{String}}`:    [v x n_bands]   vector with VV (vertical for 3D grids) coordinates
- `z::Array{T,N}`:                      [n_rows x n_columns] grid array
- `x_unit::String`:                     Units of XX axis (Optional)
- `y_unit::String`:                     Units of YY axis (Optional)
- `v_unit::String`:                     Units of Vertical axis (Optional)
- `z_unit::String`:                     Units of z vlues (Optional)
- `layout::String`:                     A three character string describing the grid memory layout
- `scale::Union{Float64, Float32}=1f0`: When saving in file apply `z = z * scale + offset`
- `offset::Union{Float64, Float32}=0f0`
- `pad::Int=0`:                         When != 0 means that the array is placed in a padded array of PAD rows/cols
- `hasnans::Int=0`:                     0 -> "don't know"; 1 -> confirmed, "have no NaNs"; 2 -> confirmed, "have NaNs"
"""
Base.@kwdef mutable struct GMTgrid{T<:Number,N} <: AbstractArray{T,N}
	proj4::String=""
	wkt::String=""
	epsg::Int=0
	geog::Int=0
	range::Union{Vector{Float64}, Vector{Any}}=Float64[]
	inc::Union{Vector{Float64}, Vector{Any}}=Float64[]
	registration::Int=0
	nodata::Union{Float64, Float32}=0.0
	title::String=""
	remark::String=""
	command::String=""
	cpt::String=""
	names::Vector{String}=String[]
	x::Array{Float64,1}=Float64[]
	y::Array{Float64,1}=Float64[]
	v::Union{Vector{<:Real}, Vector{String}, Vector{<:TimeType}}=String[]
	z::Array{T,N}=Array{Float64,2}(undef,0,0)
	x_unit::String=""
	y_unit::String=""
	v_unit::String=""
	z_unit::String=""
	layout::String=""
	scale::Union{Float64, Float32}=1f0
	offset::Union{Float64, Float32}=0f0
	pad::Int=0
	hasnans::Int=0
end
Base.size(G::GMTgrid) = size(G.z)
Base.getindex(G::GMTgrid{T,N}, inds::Vararg{Int,N}) where {T,N} = G.z[inds...]
Base.setindex!(G::GMTgrid{T,N}, val, inds::Vararg{Int,N}) where {T,N} = G.z[inds...] = val

Base.BroadcastStyle(::Type{<:GMTgrid}) = Broadcast.ArrayStyle{GMTgrid}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTgrid}}, ::Type{ElType}) where ElType
	G = find4similar(bc.args)		# Scan the inputs for the GMTgrid:
	GMTgrid(G.proj4, G.wkt, G.epsg, G.geog, G.range, G.inc, G.registration, G.nodata, G.title, G.remark, G.command, G.cpt, G.names, G.x, G.y, G.v, similar(Array{ElType}, axes(bc)), G.x_unit, G.y_unit, G.v_unit, G.z_unit, G.layout, 1f0, 0f0, G.pad, G.hasnans)
end

find4similar(bc::Base.Broadcast.Broadcasted) = find4similar(bc.args)
find4similar(args::Tuple) = find4similar(find4similar(args[1]), Base.tail(args))
find4similar(x) = x
find4similar(::Tuple{}) = nothing
find4similar(G::GMTgrid, rest) = G
find4similar(::Any, rest) = find4similar(rest)

"""
    mutable struct GMTimage{T<:Union{Unsigned, Bool}, N} <: AbstractArray{T,N}

The GMTimage type is how images (UInt8, UInt16), 2D or multi-layered, (geo)referenced or not, communicate in/out
with the GMT and GDAL libraries. They implement the AbstractArray interface.

The fields of this struct are:
- `proj4::String`:              Projection string in PROJ4 syntax (Optional)
- `wkt::String`:                Projection string in WKT syntax (Optional)
- `epsg::Int`:                  EPSG code
- `geog::Int`:                  Is geographic coords? 0 -> No; 1 -> [-180 180]; 2 -> [0 360]
- `range::Vector{Float64}`:     1x6[8] vector with [x_min, x_max, y_min, y_max, z_min, z_max [, v_min, v_max]]
- `inc::Vector{Float64}`:       1x2[3] vector with [x_inc, y_inc [,v_inc]]
- `registration::Int`:          Registration type: 0 -> Grid registration; 1 -> Pixel registration
- `nodata::Float32`:            The value of nodata
- `color_interp::String`:       If equal to "Gray" an indexed image with no cmap will get a gray cmap
- `metadata::Vector{String}`:   To store any metadata that can eventually be passed to GDAL (Optional)
- `names::Vector{String}`:      To use whith multi-band and when bands have names (Optional)
- `x::Vector{Float64}`:         [1 x n_columns] vector with XX coordinates
- `y::Vector{Float64}`:         [1 x n_rows]    vector with YY coordinates
- `v::Vector{Float64}`:         [v x n_bands]   vector with vertical coords or wavelengths in hypercubes (Optional)
- `image::Array{T,N}`:          [n_rows x n_columns x n_bands] image array
- `labels::Vector{String}`:     Labels of a Categorical CPT
- `n_colors::Int`:              Number of colors stored in the vector 'colormap'
- `colormap::Vector{Int32}`:    A vector with n_colors-by-4 saved column-wise
- `alpha::Matrix{UInt8}`:       A [n_rows x n_columns] alpha array
- `layout::String`:             A four character string describing the image memory layout
- `pad::Int`:                   When != 0 means that the array is placed in a padded array of PAD rows/cols
"""
Base.@kwdef mutable struct GMTimage{T<:Union{Unsigned, Bool}, N} <: AbstractArray{T,N}
	proj4::String=""
	wkt::String=""
	epsg::Int=0
	geog::Int=0
	range::Vector{Float64}=Float64[]
	inc::Vector{Float64}=Float64[]
	registration::Int=0
	nodata::Float32=0f0
	color_interp::String=""
	metadata::Vector{String}=String[]
	names::Vector{String}=String[]
	x::Vector{Float64}=Float64[]
	y::Vector{Float64}=Float64[]
	v::Vector{Float64}=Float64[]
	image::Array{T,N}=Array{UInt8,2}(undef,0,0)
	colormap::Vector{Int32}=Int32[]
	labels::Vector{String}=String[]		# Labels of a Categorical CPT
	n_colors::Int=0
	alpha::Matrix{UInt8}=Array{UInt8,2}(undef,0,0)
	layout::String=""
	pad::Int=0
end
Base.size(I::GMTimage) = size(I.image)
Base.getindex(I::GMTimage{T,N}, inds::Vararg{Int,N}) where {T,N} = I.image[inds...]
Base.setindex!(I::GMTimage{T,N}, val, inds::Vararg{Int,N}) where {T,N} = I.image[inds...] = val

Base.BroadcastStyle(::Type{<:GMTimage}) = Broadcast.ArrayStyle{GMTimage}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTimage}}, ::Type{ElType}) where ElType
	I = find4similar(bc.args)		# Scan the inputs for the GMTimage:
	GMTimage(I.proj4, I.wkt, I.epsg, I.geog, I.range, I.inc, I.registration, I.nodata, I.color_interp, I.metadata, I.names, I.x, I.y, I.v, similar(Array{ElType}, axes(bc)), I.colormap, I.labels, I.n_colors, I.alpha, I.layout, I.pad)
end
find4similar(I::GMTimage, rest) = I

"""
    mutable struct GMTcpt

The fields of this struct are:
- `colormap::Array{Float64,2}`:  Mx3 matrix equal to the first three columns of cpt
- `alpha::Array{Float64,1}`:     Vector of alpha values. One for each color.
- `range::Array{Float64,2}`:     Mx2 matrix with z range for each slice
- `minmax::Array{Float64,1}`:    Two elements Vector with zmin,zmax
- `bfn::Array{Float64,2}`:       A 3x3(4?) matrix with BFN colors (one per row) in [0 1] interval
- `depth::Cint`:                 Color depth: 24, 8, 1
- `hinge::Cdouble`:              Z-value at discontinuous color break, or NaN
- `cpt::Array{Float64,2}`:       Mx6 matrix with r1 g1 b1 r2 g2 b2 for z1 z2 of each slice
- `egorical::Int`:               Is this CPT categorical? 0 = No, 1 = Yes, 2 = Yes and keys are strings.
- `label::Vector{String}`:       Labels of a Categorical CPT
- `key::Vector{String}`:         Keys of a Categorical CPT
- `model::String`:               String with color model rgb, hsv, or cmyk [rgb]
- `comment::Vector{String}`:     Cell array with any comments
"""
mutable struct GMTcpt
	colormap::Array{Float64,2}
	alpha::Array{Float64,1}
	range::Array{Float64,2}
	minmax::Array{Float64,1}
	bfn::Array{Float64,2}
	depth::Cint
	hinge::Cdouble
	cpt::Array{Float64,2}
	categorical::Int
	label::Vector{String}
	key::Vector{String}
	model::String
	comment::Vector{String}
end
GMTcpt() = GMTcpt(Array{Float64,2}(undef,0,0), Vector{Float64}(undef,0), Array{Float64,2}(undef,0,0), Vector{Float64}(undef,0), Array{Float64,2}(undef,0,0), 0, 0.0, Array{Float64,2}(undef,0,0), 0, String[], String[], string(), String[])
Base.size(C::GMTcpt) = size(C.range, 1)
Base.isempty(C::GMTcpt) = (size(C) == 0)

"""
    mutable struct GMTps

The fields of this struct are:
- `postscript::String`:         Actual PS plot (text string)
- `length::Int`:                Byte length of postscript
- `mode::Int`:                  1 = Has header, 2 = Has trailer, 3 = Has both
- `comment::Vector{String}`:    A vector with any eventual comments
"""
mutable struct GMTps
	postscript::String
	length::Int
	mode::Int
	comment::Vector{String}
end
GMTps() = GMTps(string(), 0, 0, String[])
Base.size(P::GMTps) = P.length
Base.isempty(P::GMTps) = (P.length == 0)

"""
    mutable struct GMTdataset{T<:Real, N} <: AbstractArray{T,N}

The GMTdataset type is how tables, (geo)referenced or not, communicate in/out with the GMT and GDAL libraries.
They implement the AbstractArray and Tables interface.

The fields of this struct are:
- `data::Array{T,N}`:             Mx2 Matrix with segment data
- `ds_bbox::Vector{Float64}`:     Global BoundingBox (for when there are many segments)
- `bbox::Vector{Float64}`:        Segment BoundingBox
- `attrib::Dict{String, Union{String, Vector{String}}}`: Dictionary with attributes/values (optional)
- `colnames::Vector{String}`:     Column names. Antecipate using this with a future Tables inerface
- `text::Vector{String}`:         Array with text after data coordinates (mandatory only when plotting Text)
- `header::String`:               String with segment header (Optional but sometimes very useful)
- `comment::Vector{String}`:      Array with any dataset comments [empty after first segment]
- `proj4::String`:                Projection string in PROJ4 syntax (Optional)
- `wkt::String`:                  Projection string in WKT syntax (Optional)
- `epsg::Int`:                    EPSG projection code (Optional)
- `geom::Integer`:                Geometry type. One of the GDAL's enum (wkbPoint, wkbPolygon, etc...)
"""
Base.@kwdef mutable struct GMTdataset{T<:Real, N} <: AbstractArray{T,N}
	data::Array{T,N}=Array{Float64,2}(undef,0,0)
	ds_bbox::Vector{Float64}=Float64[]
	bbox::Vector{Float64}=Float64[]
	attrib::DictSvS=DictSvS()
	colnames::Vector{String}=String[]
	text::Vector{String}=String[]
	header::String=""
	comment::Vector{String}=String[]
	proj4::String=""
	wkt::String=""
	epsg::Int=0
	geom::Union{UInt32, Int}=0	# 0->Unknown, 1->Point, 2->Line, 3->Polygon, 4->MultiPoint, 5->MultiLine, 6->MultiPolyg
end
Base.size(D::GMTdataset) = size(D.data)
Base.getindex(D::GMTdataset{T,N}, inds::Vararg{Int,N}) where {T,N} = D.data[inds...]

Base.getindex(D::GMTdataset{T,N}, ind::Symbol) where {T,N} = Base.getindex(D, string(ind))
function Base.getindex(D::GMTdataset{T,N}, ind::String) where {T,N}
	mat = Tables.getcolumn(D, Symbol(ind))
	D2 = mat2ds(mat, colnames=[ind], proj4=D.proj4, wkt=D.wkt)::GMTdataset
	if ((Tc = get(D.attrib, "Timecol", "")) != "")		# If original has one, try to keep it but may need to recalculate
		Tcn = Tables.columnnames(D)[parse.(Int,Tc)]		# The Timecol name in input D
		i = findfirst(Tables.columnnames(D) .== Tcn)
		c = findfirst(Tables.columnnames(D) .== ind)
		(i == c) && (D2.attrib = Dict("Timecol" => "$i"))	# The selected column was the Time one.
	end
	D2
end
Base.getindex(D::GMTdataset{T,N}, inds::Vararg{String}) where {T,N} = Base.getindex(D, Symbol.(inds)...)
function Base.getindex(D::GMTdataset{T,N}, inds::Vararg{Symbol}) where {T,N}
	# If accessed by column names, create a new GMTdataset.
	# Most of this and more should go into a new mat2ds method.
	mat = hcat([Tables.getcolumn(D, ind) for ind in inds]...)
	colnames_inds = [string.(inds)...]		# Because string.(inds) returns a Tuple of strings
	D2 = mat2ds(mat, colnames=colnames_inds, proj4=D.proj4, wkt=D.wkt)::GMTdataset
	if ((Tc = get(D.attrib, "Timecol", "")) != "")		# If original has one, try to keep it but may need to recalculate
		Tcn = Tables.columnnames(D)[parse.(Int,Tc)]		# The Timecol name in input D
		idx = [findfirst(Tables.columnnames(D) .== ind) for ind in colnames_inds]	# Find the column numbers of inds
		i = findfirst(Tables.columnnames(D) .== Tcn)
		itc = (i !== nothing) ? intersect(idx, i) : Int[]
		if (!isempty(itc))								# One of the selected columns has a Time column
			i = findfirst(idx .== itc)					# Find the new column number of the Time column
			D2.attrib = Dict("Timecol" => "$i")
		end
	end
	D2
end

#function Base.getindex(D::GMTdataset{T,N}, inds::Vararg) where {T,N}
	#length(inds) == 1 && return D.data[inds[1]]
	#mat2ds(D, (inds[1],inds[2]))
#end

Base.setindex!(D::GMTdataset{T,N}, val, inds::Vararg{Int}) where {T,N} = D.data[inds...] = val

Base.BroadcastStyle(::Type{<:GMTdataset}) = Broadcast.ArrayStyle{GMTdataset}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTdataset}}, ::Type{ElType}) where ElType
	D = find4similar(bc.args)		# Scan the inputs for the GMTdataset:
	GMTdataset(D.data, D.ds_bbox, D.bbox, D.attrib, D.colnames, D.text, D.header, D.comment, D.proj4, D.wkt, D.epsg, D.geom)
end
find4similar(D::GMTdataset, rest) = D

GMTdataset(data::Array{Float64,2}, text::Vector{String}) =
	GMTdataset(data, Float64[], Float64[], DictSvS(), String[], text, "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float64,2}, text::String) =
	GMTdataset(data, Float64[], Float64[], DictSvS(), String[], [text], "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float64,2}) =
	GMTdataset(data, Float64[], Float64[], DictSvS(), String[], String[], "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float32,2}, text::Vector{String}) =
	GMTdataset(data, Float64[], Float64[], DictSvS(), String[], text, "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float32,2}, text::String) =
	GMTdataset(data, Float64[], Float64[], DictSvS(), String[], [text], "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float32,2}) =
	GMTdataset(data, Float64[], Float64[], DictSvS(), String[], String[], "", String[], "", "", 0, 0)

"""
    struct GMTfv{T<:AbstractFloat} <: AbstractMatrix{T}

The GMTfv struct is used to store a (mostly) triangulated mesh.

The fields of this struct are:
- `verts::AbstractMatrix{T}`:        Mx3 Matrix with the data vertices
- `faces`::Vector{<:AbstractMatrix{<:Integer}}   A vector of matrices with the faces. Each row is a face
- `faces_view`::Vector{Matrix{Int}}  A subset of `faces` with only the visible faces from a certain perspective
- `color`::Vector{Vector{String}}    A vector with G option colors (in hexadecimal) for each face
- `bbox`::Vector{Float64}            The vertices BoundingBox
- `zscale`::Float64                  A multiplicative factor to scale the z values
- `bfculling`::Bool                  If culling of invisible faces is wished
- `isflat`::Bool                     If this is a flat mesh
- `proj4::String`                    Projection string in PROJ4 syntax (Optional)
- `wkt::String`                      Projection string in WKT syntax (Optional)
- `epsg::Int`                        EPSG projection code (Optional)
"""
Base.@kwdef mutable struct GMTfv{T<:AbstractFloat} <: AbstractArray{T,2}
	verts::AbstractMatrix{T}=Matrix{Float64}(undef,0,0)
	faces::Vector{<:AbstractMatrix{<:Integer}}=Vector{Matrix{Int}}(undef,0)
	faces_view::Vector{Matrix{Int}}=Vector{Matrix{Int}}(undef,0)
	color::Vector{Vector{String}}=[String[]]
	bbox::Vector{Float64}=zeros(6)
	zscale::Float64=1.0
	bfculling::Bool=true
	isflat::Bool=false
	proj4::String=""
	wkt::String=""
	epsg::Int=0
end
Base.size(FV::GMTfv) = size(FV.verts)
Base.getindex(FV::GMTfv{T}, inds::Vararg{Int}) where {T} = FV.verts[inds...]
Base.setindex!(FV::GMTfv{T}, val, inds::Vararg{Int}) where {T} = FV.verts[inds...] = val
Base.BroadcastStyle(::Type{<:GMTfv}) = Broadcast.ArrayStyle{GMTfv}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTfv}}, ::Type{ElType}) where ElType
	FV = find4similar(bc.args)		# Scan the inputs for the FV:
	#GMTfv(similar(Array{ElType}, axes(bc)), FV.faces, FV.faces_view, FV.color, FV.bbox, FV.zscale, FV.bfculling, FV.proj4, FV.wkt, FV.epsg)
	GMTfv(FV.verts, FV.faces, FV.faces_view, FV.color, FV.bbox, FV.zscale, FV.bfculling, FV.proj4, FV.wkt, FV.epsg)
end
find4similar(FV::GMTfv, rest) = FV

#=
Base.@kwdef struct GMTtypes
	stored::String = ""
	grd::GMTgrid = GMTgrid()
	img::GMTimage = GMTimage()
	ds::GMTdataset = GMTdataset()
	dsv::Vector{GMTdataset} = [GMTdataset()]
	cpt::GMTcpt = GMTcpt()
	ps::GMTps = GMTps()
	function GMTtypes(stored, grd, img, ds, dsv, cpt, ps)
		stored = (!isempty(grd)) ? "grd" : (!isempty(img)) ? "img" : (!isempty(ds)) ? "ds" : (!isempty(dsv)) ? "dsv" : (!isempty(cpt)) ? "cpt" : (!isempty(ps)) ? "ps" : ""
		new(stored, grd, img, ds, dsv, cpt, ps)
	end
end
=#

struct WrapperPluto fname::String end

const global GItype = Union{GMTgrid, GMTimage}
const global GDtype = Union{GMTdataset, Vector{<:GMTdataset}}

#function meta(D::GMTdataset; kw...)
#end
