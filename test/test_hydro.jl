using GMT, Test

# Hydrology (src/hydro): flow directions, accumulation, basins, streams, TWI, LDD. Everything runs on
# small synthetic DEMs, so no network is needed.

@testset "HYDRO" begin

	# A valley draining south, with two artificial pits and a NaN hole.
	x = collect(0.0:1.0:99.0);  y = collect(0.0:1.0:79.0)
	Z = Float32[0.5yy + 0.3abs(xx - 50) + 2sin(xx / 7) * cos(yy / 5) for yy in y, xx in x]
	Z[40, 30] -= 20;  Z[60, 70] -= 15
	Z[20:24, 80:84] .= NaN32
	G  = mat2grid(Z, x=x, y=y)
	nv = count(!isnan, Z)

	# ------------------------------------------------------------ flowdir + D8 accumulation
	for m in (:fill, :carve)
		F = flowdir(G, method=m)
		@test F isa GMT.flownet
		@test length(F.order) == nv
		@test all(F.dem[F.rcv[k]] <= F.dem[k] for k in F.order)			# never flows uphill
		pos = zeros(Int, length(F.rcv))
		for (i, k) in enumerate(F.order)  pos[k] = i  end
		@test all(F.rcv[k] == k || pos[F.rcv[k]] < pos[k] for k in F.order)	# receivers before donors
		A = flowacc(F)
		@test sum(A.z[k] for k in F.order if F.rcv[k] == k) == nv			# all water reaches an outlet
		@test size(A) == size(G) && A.x == G.x && A.y == G.y && A.inc == G.inc
	end
	F = flowdir(G)
	@test F.dem[40, 30] > Z[40, 30] && F.dem[60, 70] > Z[60, 70]			# the pits were filled

	# ------------------------------------------------------------ multiple flow directions
	for m in (:mfd, :dinf)
		A = flowacc(F, method=m)
		@test isapprox(sum(A.z[k] for k in F.order if F.rcv[k] == k), nv; rtol=1e-9)
	end
	# D∞ is exact on a plane: away from the edges each cell carries (upslope length) * cos(φ).
	let n = 101, φ = deg2rad(30)
		Zp = Float32[-(j * cos(φ) + i * sin(φ)) for i in 1:n, j in 1:n]
		Fp = flowdir(mat2grid(Zp, x=collect(1.0:n), y=collect(1.0:n)))
		Ap = flowacc(Fp, method=:dinf).z
		r  = vec([Ap[i, j] / (min((j - 0.5) / cos(φ), (i - 0.5) / sin(φ)) * cos(φ)) for i in 30:70, j in 30:70])
		mr = sum(r) / length(r)
		@test abs(mr - 1) < 0.03 && sqrt(sum((r .- mr) .^ 2) / length(r)) < 0.06
	end

	# ------------------------------------------------------------ basins
	B = drainagebasins(F)
	@test count(!isnan, B.z) == nv
	@test maximum(filter(!isnan, B.z)) == count(k -> F.rcv[k] == k, F.order)
	@test all(isnan, drainagebasins(F, minarea=nv + 1).z)					# every basin is smaller
	Bo = drainagebasins(F, outlets=[50.0 0.0; 50.0 40.0], snap=3)			# nested outlets
	n1, n2 = count(==(1f0), Bo.z), count(==(2f0), Bo.z)
	@test n1 > 0 && n2 > 0 && n1 + n2 <= nv
	A  = flowacc(F)
	xy = snap2stream(F, [48.0 41.0], radius=3)
	@test A.z[round(Int, xy[2]) + 1, round(Int, xy[1]) + 1] >= A.z[42, 49]

	# ------------------------------------------------------------ streams, order, distance, LDD, TWI
	S  = streamorder(F, threshold=50)
	N  = streamnet(F, threshold=50)
	@test !isempty(N)
	# each reach carries the Strahler order of the cell it starts at (row = y + 1, column = x + 1 here)
	@test all(S.z[round(Int, d.data[1, 2]) + 1, round(Int, d.data[1, 1]) + 1] == d.data[1, 4] for d in N)
	@test all(size(d.data, 2) == 4 && size(d.data, 1) >= 2 for d in N)
	D = flowdistance(F)
	@test all(D.z[k] == 0 for k in F.order if F.rcv[k] == k) && minimum(filter(!isnan, D.z)) == 0
	L = ldd(F)
	@test issubset(unique(filter(!isnan, L.z)), 1f0:9f0)
	@test count(==(5f0), L.z) == count(k -> F.rcv[k] == k, F.order)
	T = twi(F)
	@test all(isfinite(T.z[k]) for k in F.order)

	# ------------------------------------------------------------ sealevel
	Fs = flowdir(mat2grid(Z .- 10f0, x=x, y=y), sealevel=0)
	@test length(Fs.order) == count(v -> !isnan(v) && v > 10, Z)

	# ------------------------------------------------------------ a top-down / row-major grid (GDAL)
	f  = tempname() * ".tif"
	Gu = mat2grid(Z, x=x, y=y, proj4="+proj=utm +zone=29 +datum=WGS84")
	gmtwrite(f, Gu)
	G2 = GMT.gdalread(f)
	@test startswith(G2.layout, "TR")				# really the other memory layout
	Fu, F2 = flowdir(Gu), flowdir(G2)
	@test isequal(F2.dem, Fu.dem) && F2.rcv == Fu.rcv
	rm(f, force=true)

	# ------------------------------------------------------------ progress and cancel
	fr = Float64[]
	flowdir(G, progress=(f, s) -> push!(fr, f))
	@test !isempty(fr) && fr[end] == 1.0 && issorted(fr)
	Gb = mat2grid(rand(Float32, 600, 600))
	@test_throws GMT.HydroCancelled flowdir(Gb, progress=(f, s) -> f < 0.2)
	@test_throws GMT.HydroCancelled flowacc(flowdir(Gb), method=:mfd, progress=(f, s) -> f < 0.2)
end
