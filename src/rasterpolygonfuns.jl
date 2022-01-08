#function rasterpolygonfun(GI=nothing)
#end

colorzones!(shapes::Vector{GMTdataset}; img::GMTimage=nothing, url::AbstractString="", layer=0, pixelsize::Int=0, append::Bool=true) =
	colorzones!(shapes, meansqrt; img=img, url=url, layer=layer, pixelsize=pixelsize, append=append)
function colorzones!(shapes::Vector{GMTdataset}, fun::Function; img::GMTimage=nothing, url::AbstractString="", layer=0, pixelsize::Int=0, append::Bool=true)

	(img === nothing && url == "") && error("Must either pass a grid/image or a WMS URL.")
	(img !== nothing && url != "") && error("Make up your mind. Pass ONLY one of grid/image or a WMS URL.")
	(url != "" && (layer == 0 || pixelsize == 0)) && error("When passing a WMS URL must also provide the layer and the pixelsize.")

	function within(k)		# Check if the polygon BB is contained inside the image's region.
		shapes[k].bbox[1] >= img.range[1] && shapes[k].bbox[2] <= img.range[2] && shapes[k].bbox[3] >= img.range[3] && shapes[k].bbox[4] <= img.range[4]
	end

	(url != "") && (wms = wmsinfo(url))
	for k = 1:length(shapes)
		!within(k) && continue				# Catch any exterior polygon before it errors
		((shapes[k].bbox[2] - shapes[k].bbox[1]) * (shapes[k].bbox[4] - shapes[k].bbox[3]) < 0.0008) && continue
		_img = (url != "") ? wmsread(wms, layer=layer, region=shapes[k], pixelsize=pixelsize) : GMT.crop(img, region=shapes[k])

		mk = gdalrasterize(shapes[k], ["-of", "MEM", "-ts","$(size(_img,1))","$(size(_img,2))", "-burn", "1", "-ot", "Byte"]);
		mask = reinterpret(Bool, mk);

		opt_G = (ndims(_img) >= 3) ? @sprintf(" -G%.0f/%.0f/%.0f", fun(_img[mask,1]), fun(_img[mask,2]), fun(_img[mask,3])) :
		         (c = fun(_img[mask,1]); @sprintf(" -G%.0f/%.0f/%.0f", c,c,c)) 
		shapes[k].header = (append) ? shapes[k].header * opt_G : opt_G
		(rem(k, 10) == 0) && (println("Done ",k, " of ", length(shapes)); print(stdout, "\e[", 1, "A", "\e[1G"))
	end
	shapes
end

function meansqrt(x)
	sum = 0.0
	@inbounds for k = 1:length(x)
		sum += Float64(x[k]) * x[k]
	end
	sqrt(sum/length(x))
end
