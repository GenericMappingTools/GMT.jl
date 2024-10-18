@testset "SOLIDS" begin

	GMT.icosahedron()
	GMT.octahedron()
	GMT.dodecahedron()
	GMT.tetrahedron()
	GMT.cube()

	FV = sphere();
	D  = GMT.replicant(FV, replicate=(centers=rand(10,3), scales=0.1));
	D  = GMT.replicant(FV, replicate=(rand(5,3)*100, 0.1));
	D  = GMT.replicant(FV, replicate=rand(5,3)*100);
end
