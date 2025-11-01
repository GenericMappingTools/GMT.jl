"""
    BW = cc2bw(cc::GMTConComp; obj2keep::Union{Int, Vector{Int}}=0)

Convert connected components to binary image
"""
function cc2bw(cc::GMTConComp; obj2keep::Union{Int, Vector{Int}}=0)
	# Create a binary image of the same size as the original
	I = mat2img(zeros(Bool, cc.image_size), x=cc.x, y=cc.y, inc=cc.inc, layout=cc.layout,
	            is_transposed=(cc.layout[2] == 'R'), proj4=cc.proj4, wkt=cc.wkt, epsg=cc.epsg)
	
	# Mark pixels belonging to any connected component as true
	plist = (obj2keep == 0) ? (1:cc.num_objects) : isvector(obj2keep) ? obj2keep : (obj2keep:obj2keep)
	for k = 1:numel(plist)
		for rc in cc.pixel_list[plist[k]]
			I[rc] = true
		end
	end
	I.range[6] = 1.0
	return I
end

