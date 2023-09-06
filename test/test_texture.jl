@testset "LELAND" begin

	println("	LELAND TEXTURE")
	
	lelandshade(GMT.peaks(), color=true, equalize=true);
	lelandshade(GMT.peaks(), color=true);
	lelandshade(GMT.peaks());

end
