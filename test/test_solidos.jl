@testset "SOLIDS" begin

	GMT.icosahedron();
	GMT.octahedron();
	GMT.dodecahedron();
	GMT.tetrahedron();
	GMT.cube();
	torus();

	FV = sphere();
	D  = GMT.replicant(FV, replicate=(centers=rand(10,3), scales=0.1));
	D  = GMT.replicant(FV, replicate=(rand(5,3)*100, 0.1));
	D  = GMT.replicant(FV, replicate=rand(5,3)*100);

	FV = gmtread("file.obj");
	FV = cylinder(1,4, np=5);
	
end
