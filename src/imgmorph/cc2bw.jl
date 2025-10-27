"""
"""
function cc2bw(cc::GMTConComp)
	# Create a binary image of the same size as the original
	I = mat2img(zeros(Bool, cc.image_size), x=cc.x, y=cc.y, inc=cc.inc, layout=cc.layout,
	            is_transposed=(cc.layout[2] == 'R'), proj4=cc.proj4, wkt=cc.wkt, epsg=cc.epsg)
	
	# Mark pixels belonging to any connected component as true
	for pixel_list in cc.pixel_list
		for rc in pixel_list
			I[rc] = true
		end
	end
	I.range[6] = 1.0
	return I
end

