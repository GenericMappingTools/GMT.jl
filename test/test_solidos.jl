@testset "SOLIDS" begin

	GMT.icosahedron();
	GMT.octahedron();
	GMT.dodecahedron();
	GMT.tetrahedron();
	GMT.cube();
	torus();

	FV = sphere();
	D  = replicant(FV, replicate=(centers=rand(10,3), scales=0.1));
	D  = replicant(FV, replicate=(rand(5,3)*100, 0.1));
	D  = replicant(FV, replicate=rand(5,3)*100);

	FV = gmtread("file.obj");
	FV = cylinder(1,4, np=5);
	
	ns=15; x=linspace(0,2*pi,ns).+1; y=zeros(size(x)); z=-cos.(x); Vc=[x[:] y[:] z[:]];
	FV = revolve(Vc);

	ellipse3D(center=(2,0,0), e=0.8, plane=:xz);
	ellipse3D(center=(2,0,0), e=0.8, plane=:xz, rot=45);
	ellipse3D(e=0.8, is2D=true);
	ellipse3D(e=0.8, is2D=true, rot=45);
end
