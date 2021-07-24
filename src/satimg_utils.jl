"""
    Irgb = truecolor(bndR, bndG, bndB)

Take three Landsat8 UIN16 GMTimages or the file names of those bands and compose
an RGB true color image applying automatic histogram auto-stretching.

Return an UInt8 RGB GMTimage
"""
function truecolor(bndR, bndG, bndB)
	#pato = "C:\\SIG_AnaliseDadosSatelite\\SIG_ADS\\DadosEx2\\LC82040332015145LGN00\\"
	#bndR = pato * "LC82040332015145LGN00_B4.TIF"
	#bndG = pato * "LC82040332015145LGN00_B3.TIF"
	#bndB = pato * "LC82040332015145LGN00_B2.TIF"
	I = isa(bndR, GMTimage) ? bndR : gmtread(bndR)
	img = Array{UInt8}(undef, size(I,1), size(I,2), 3)
	_ = mat2img(I.image, stretch=true, img8=view(img,:,:,1), scale_only=1)
	I = isa(bndG, GMTimage) ? bndG : gmtread(bndG)
	@assert size(I,1) == size(img,1) && size(I,2) == size(img,2)
	_ = mat2img(I.image, stretch=true, img8=view(img,:,:,2), scale_only=1)
	I = isa(bndB, GMTimage) ? bndB : gmtread(bndB)
	@assert size(I,1) == size(img,1) && size(I,2) == size(img,2)
	_ = mat2img(I.image, stretch=true, img8=view(img,:,:,3), scale_only=1)
	Io = mat2img(img, I)
	Io.layout = "TRBa"
	Io
end