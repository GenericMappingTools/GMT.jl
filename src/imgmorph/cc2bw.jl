"""
    BW = cc2bw(cc::GMTConComp; obj2keep::Union{Int, Vector{Int}}=0)

Convert connected components to binary image

- `cc`: Connected components created with `bwconncomp`
- `obj2keep`: (optional) Integer, vector of integers or a vector of booleans specifying which
   connected components to keep in the output binary image. By default, all components are kept.

Returns a binary `GMTimage` where pixels belonging to the specified connected components are set to `true`.
"""
function cc2bw(cc::GMTConComp; obj2keep=Int[])
	isscalar(obj2keep) && return _cc2bw(cc, [Int(obj2keep)])
	if (isa(obj2keep, Vector{Int}))
		return _cc2bw(cc, obj2keep)
	elseif (isa(obj2keep, Vector{Bool}) || isa(obj2keep, BitVector))
		ind = findall(obj2keep)
		isempty(ind) && error("No components selected to keep in the 'obj2keep' parameter")
		return _cc2bw(cc, ind)
	end
	error("Invalid type for 'obj2keep' parameter. Must be an integer, vector of integers, or vector of booleans.")
end
function _cc2bw(cc::GMTConComp, obj2keep::Vector{Int})
	# Create a binary image of the same size as the original
	!isempty(obj2keep) && any((k -> k < 1 || k > cc.num_objects), obj2keep) &&
	    error("Values in 'obj2keep' are out of range [1, $(cc.num_objects)]")
	I = mat2img(zeros(Bool, cc.image_size), x=cc.x, y=cc.y, inc=cc.inc, layout=cc.layout,
	            is_transposed=(cc.layout[2] == 'R'), proj4=cc.proj4, wkt=cc.wkt, epsg=cc.epsg)
	
	# Mark pixels belonging to any connected component as true
	plist = isempty(obj2keep) ? (1:cc.num_objects) : obj2keep
	@inbounds for k = 1:numel(plist)
		@inbounds for rc in cc.pixel_list[plist[k]]
			I[rc] = true
		end
	end
	I.range[6] = 1.0
	return I
end
