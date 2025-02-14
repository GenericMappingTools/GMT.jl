@testset "MAGREF" begin
	@test magref(R=[-180,180,-90,90], I=0.25, onetime=2000, alt=10, F=:H, Vd=dbg2) == "mgd77magref -A+a10+t2000+y -Frh/H"
	@test magref([0. 0], onetime=2000, alt=10, H=1, Vd=dbg2) == "mgd77magref -A+a10+t2000+y -Fh/0"
	@test magref([0. 0], alt=10, H=1, CM4core=true, Vd=dbg2) == "mgd77magref -A+a10 -Fh/1"
	@test magref([0. 0], alt=10, F=:CM4litho, L=:iono_p, Vd=dbg2) == "mgd77magref -A+a10 -Frt/2"
	@test magref([0. 0], alt=10, L=:iono_p, Vd=dbg2) == "mgd77magref -A+a10 -Lrt/2"
	magref([0. 0 0], alt=10, L=:iono_p);
	@test magref([0. 0], alt=10, L=(T=true, iono_i=true), Vd=dbg2) == "mgd77magref -A+a10 -Lt/3"
	@test magref(R=:d, alt=10, L=(T=true, iono_i=true), Vd=dbg2) == "mgd77magref -A+a10 -Lrt/3"
	magref("", R=:d, L=:iono_p, Vd=dbg2)
end
