Base.@kwdef mutable struct GMTgrid{T<:Real,N} <: AbstractArray{T,N}
	proj4::String
	wkt::String
	epsg::Int
	geog::Int
	range::Union{Vector{Float64}, Vector{Any}}
	inc::Union{Vector{Float64}, Vector{Any}}
	registration::Int
	nodata::Union{Float64, Float32}
	title::String
	remark::String
	command::String
	cpt::String
	names::Vector{String}
	x::Array{Float64,1}
	y::Array{Float64,1}
	v::Union{Vector{<:Real}, Vector{String}, Vector{<:TimeType}}
	z::Array{T,N}
	x_unit::String
	y_unit::String
	v_unit::String
	z_unit::String
	layout::String
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

mutable struct GMTimage{T<:Unsigned, N} <: AbstractArray{T,N}
	proj4::String
	wkt::String
	epsg::Int
	geog::Int
	range::Array{Float64,1}
	inc::Array{Float64,1}
	registration::Int
	nodata::T
	color_interp::String
	metadata::Vector{String}
	names::Vector{String}
	x::Array{Float64,1}
	y::Array{Float64,1}
	v::Array{Float64,1}
	image::Array{T,N}
	colormap::Array{Int32,1}
	n_colors::Int
	alpha::Array{UInt8,2}
	layout::String
	pad::Int
end
Base.size(I::GMTimage) = size(I.image)
Base.getindex(I::GMTimage{T,N}, inds::Vararg{Int,N}) where {T,N} = I.image[inds...]
Base.setindex!(I::GMTimage{T,N}, val, inds::Vararg{Int,N}) where {T,N} = I.image[inds...] = val

Base.BroadcastStyle(::Type{<:GMTimage}) = Broadcast.ArrayStyle{GMTimage}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTimage}}, ::Type{ElType}) where ElType
	I = find4similar(bc.args)		# Scan the inputs for the GMTimage:
	GMTimage(I.proj4, I.wkt, I.epsg, I.geog, I.range, I.inc, I.registration, I.nodata, I.color_interp, I.metadata, I.names, I.x, I.y, I.v, similar(Array{ElType}, axes(bc)), I.colormap, I.n_colors, I.alpha, I.layout, I.pad)
end
find4similar(I::GMTimage, rest) = I

mutable struct GMTcpt
	colormap::Array{Float64,2}	# Mx3 matrix equal to the first three columns of cpt
	alpha::Array{Float64,1}		# Vector of alpha values. One for each color.
	range::Array{Float64,2}		# Mx2 matrix with z range for each slice
	minmax::Array{Float64,1}	# Two elements Vector with zmin,zmax
	bfn::Array{Float64,2}		# A 3x3(4?) matrix with BFN colors (one per row) in [0 1] interval
	depth::Cint					# Color depth 24, 8, 1
	hinge::Cdouble				# Z-value at discontinuous color break, or NaN
	cpt::Array{Float64,2}		# Mx6 matrix with r1 g1 b1 r2 g2 b2 for z1 z2 of each slice
	label::Vector{String}		# Labels of a Categorical CPT
	key::Vector{String}			# Keys of a Categorical CPT
	model::String				# String with color model rgb, hsv, or cmyk [rgb]
	comment::Array{String,1}	# Cell array with any comments
end
GMTcpt() = GMTcpt(Array{Float64,2}(undef,0,0), Vector{Float64}(undef,0), Array{Float64,2}(undef,0,0), Vector{Float64}(undef,0), Array{Float64,2}(undef,0,0), 0, 0.0, Array{Float64,2}(undef,0,0), String[], String[], string(), String[])
Base.size(C::GMTcpt) = size(C.range, 1)
Base.isempty(C::GMTcpt) = (size(C) == 0)

mutable struct GMTps
	postscript::String			# Actual PS plot (text string)
	length::Int 				# Byte length of postscript
	mode::Int 					# 1 = Has header, 2 = Has trailer, 3 = Has both
	comment::Vector{String}		# Cell array with any comments
end
GMTps() = GMTps(string(), 0, 0, String[])
Base.size(P::GMTps) = P.length
Base.isempty(P::GMTps) = (P.length == 0)

mutable struct GMTdataset{T<:Real, N} <: AbstractArray{T,N}
	data::Array{T,N}
	ds_bbox::Vector{Float64}
	bbox::Vector{Float64}
	attrib::Dict{String, String}
	colnames::Vector{String}
	text::Vector{String}
	header::String
	comment::Vector{String}
	proj4::String
	wkt::String
	epsg::Int
	geom::Union{UInt32, Int}	# 0->Unknown, 1->Point, 2->Line, 3->Polygon, 4->MultiPoint, 5->MultiLine, 6->MultiPolyg
end
Base.size(D::GMTdataset) = size(D.data)
Base.getindex(D::GMTdataset{T,N}, inds::Vararg{Int,N}) where {T,N} = D.data[inds...]

Base.getindex(D::GMTdataset{T,N}, ind::Symbol) where {T,N} = Base.getindex(D, string(ind))
function Base.getindex(D::GMTdataset{T,N}, ind::String) where {T,N}
	mat = Tables.getcolumn(D, Symbol(ind))
	D2 = mat2ds(mat, colnames=[ind], proj4=D.proj4, wkt=D.wkt)::GMTdataset
	if ((Tc = get(D.attrib, "Timecol", "")) != "")		# If original has one, try to keep it but may need to recalculate
		Tcn = Tables.columnnames(D)[parse(Int,Tc)]		# The Timecol name in input D
		i = findfirst(Tables.columnnames(D) .== Tcn)
		c = findfirst(Tables.columnnames(D) .== ind)
		(i == c) && (D2.attrib = Dict("Timecol" => "$i"))	# The selected column was the Time one.
	end
	D2
end
Base.getindex(D::GMTdataset{T,N}, inds::Vararg{String,N}) where {T,N} = Base.getindex(D, Symbol.(inds)...)
function Base.getindex(D::GMTdataset{T,N}, inds::Vararg{Symbol,N}) where {T,N}
	# If accessed by column names, create a new GMTdataset.
	# Most of this and more should go into a new mat2ds method.
	mat = hcat([Tables.getcolumn(D, ind) for ind in inds]...)
	colnames_inds = [string.(inds)...]		# Because string.(inds) returns a Tuple of strings
	D2 = mat2ds(mat, colnames=colnames_inds, proj4=D.proj4, wkt=D.wkt)::GMTdataset
	if ((Tc = get(D.attrib, "Timecol", "")) != "")		# If original has one, try to keep it but may need to recalculate
		Tcn = Tables.columnnames(D)[parse(Int,Tc)]		# The Timecol name in input D
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

Base.setindex!(D::GMTdataset{T,N}, val, inds::Vararg{Int,N}) where {T,N} = D.data[inds...] = val

Base.BroadcastStyle(::Type{<:GMTdataset}) = Broadcast.ArrayStyle{GMTdataset}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTdataset}}, ::Type{ElType}) where ElType
	D = find4similar(bc.args)		# Scan the inputs for the GMTdataset:
	GMTdataset(D.data, D.ds_bbox, D.bbox, D.attrib, D.colnames, D.text, D.header, D.comment, D.proj4, D.wkt, D.epsg, D.geom)
end
find4similar(D::GMTdataset, rest) = D

GMTdataset(data::Array{Float64,2}, text::Vector{String}) = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], text, "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float64,2}, text::String) = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], [text], "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float64,2}) = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], String[], "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float32,2}, text::Vector{String}) = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], text, "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float32,2}, text::String) = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], [text], "", String[], "", "", 0, 0)
GMTdataset(data::Array{Float32,2}) = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], String[], "", String[], "", "", 0, 0)
GMTdataset() = GMTdataset(Array{Float64,2}(undef,0,0), Float64[], Float64[], Dict{String, String}(), String[], String[], "", String[], "", "", 0, 0)

struct WrapperPluto fname::String end

const global GItype = Union{GMTgrid, GMTimage}
const global GDtype = Union{GMTdataset, Vector{<:GMTdataset}}

#function meta(D::GMTdataset; kw...)
#end
