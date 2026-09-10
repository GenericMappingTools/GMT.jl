using GMT, Test, Printf, Dates

# Tsunami travel times — Wessel's Huygens/Dijkstra solver (ttt) and the station ETA reader
# (tttimes). Everything here runs on a synthetic flat ocean, so the tests need no network and
# can be checked against the closed-form shallow-water solution  t = d / sqrt(g*h).

@testset "TTT" begin

	# A flat 4000 m deep ocean. For constant depth the wavefront is a circle expanding at
	# sqrt(g*h), so the travel time to any point is just distance / speed.
	DEPTH  = 4000.0
	SPEED  = sqrt(DEPTH * 9.8062)			# m/s   (normal gravity at ~45 deg, as the solver uses)
	DEG_KM = 111194.9						# meters per degree on the sphere the solver assumes
	analytic(deg) = deg * DEG_KM / SPEED / 3600.0		# hours

	G = mat2grid(fill(Float32(-DEPTH), 121, 121);
	             hdr=[-6.0, 6.0, -6.0, 6.0, -DEPTH, -DEPTH, 0.0, 0.1, 0.1])

	# ---------------------------------------------------------------- ttt(): grid in, grid out
	Gtt = ttt(G, (0.0, 0.0))

	@test isa(Gtt, GMTgrid)
	@test size(Gtt.z) == size(G.z)
	@test Gtt.layout == G.layout
	@test Gtt.registration == G.registration
	@test Gtt.range[1:4] == G.range[1:4]
	@test !all(isnan.(Gtt.z))
	@test Gtt.range[5] >= 0					# no negative travel times
	@test occursin("slope at source", Gtt.remark)

	jeq = findfirst(isapprox.(Gtt.y, 0.0; atol=1e-9))		# equator row
	i0  = findfirst(isapprox.(Gtt.x, 0.0; atol=1e-9))		# source column
	@test Gtt.z[jeq, i0] == 0.0				# zero travel time at the source itself

	# Accuracy against the analytic solution. The Huygens stencil is slightly slow, ~0.11%.
	for d in (1.0, 3.0, 5.0)
		i = findfirst(isapprox.(Gtt.x, d; atol=1e-9))
		@test Gtt.z[jeq, i] ≈ analytic(d) rtol=0.005
	end

	# Travel time must grow monotonically away from the source along the equator
	@test issorted(Gtt.z[jeq, i0:end])

	# ---------------------------------------------------------------- fewer stencil nodes
	Gtt8 = ttt(G, (0.0, 0.0), nodes=8)
	i5 = findfirst(isapprox.(Gtt.x, 5.0; atol=1e-9))
	@test Gtt8.z[jeq, i5] > 0
	# The 8-node stencil is much coarser, so it only has to land in the right ballpark.
	# (Measured: it comes out ~5% FAST here, where the 120-node one is ~0.1% slow.)
	@test Gtt8.z[jeq, i5] ≈ analytic(5.0) rtol=0.10
	@test !isapprox(Gtt8.z[jeq, i5], Gtt.z[jeq, i5], rtol=1e-4)		# nodes= actually changes it

	# ---------------------------------------------------------------- layout invariance
	# The old load_gmtgrid() assumed column-major/south-first and was wrong for TRB/BRB.
	fn = joinpath(tempdir(), "ttt_flat_test.grd")
	gmtwrite(fn, G)
	ref = ttt(gmtread(fn, grd=true), (0.0, 0.0))
	for lay in ("TRB", "BRB")
		Gl = gmtread(fn, grd=true, layout=lay)
		Tl = ttt(Gl, (0.0, 0.0))
		@test size(Tl.z) == size(Gl.z)
		@test Tl.range[5] ≈ ref.range[5] atol=1e-4
		@test Tl.range[6] ≈ ref.range[6] atol=1e-4
	end

	# ---------------------------------------------------------------- pixel registration
	# GMT uses 0=gridline, 1=pixel; the solver core wants the opposite. ttt() converts it once,
	# so a pixel grid must come out just as accurate as a gridline one.
	Gp  = mat2grid(fill(Float32(-DEPTH), 120, 120); reg=1,
	               hdr=[-6.0, 6.0, -6.0, 6.0, -DEPTH, -DEPTH, 1.0, 0.1, 0.1])
	Tp  = ttt(Gp, (0.0, 0.0))
	@test Tp.registration == 1
	@test size(Tp.z) == size(Gp.z)
	jp = argmin(abs.(Tp.y));  ip = argmin(abs.(Tp.x .- 3.0))
	@test Tp.z[jp, ip] ≈ analytic(hypot(Tp.x[ip], Tp.y[jp])) rtol=0.005

	# ---------------------------------------------------------------- multiple sources
	Gm = ttt(G, [-3.0 0.0; 3.0 0.0])
	@test Gm.z[jeq, i0] > 0					# midpoint is no longer a source
	@test Gm.z[jeq, findfirst(isapprox.(Gm.x, -3.0; atol=1e-9))] == 0.0
	@test Gm.z[jeq, findfirst(isapprox.(Gm.x,  3.0; atol=1e-9))] == 0.0

	# ---------------------------------------------------------------- wave_travel_time(method=)
	@test isequal(wave_travel_time(G, (0.0, 0.0), method=:ttt).z, Gtt.z)
	Cm = wave_travel_time(G, (0.0, 0.0))				# default :mirone must keep working
	@test isa(Cm, GMTgrid) && size(Cm.z) == size(G.z)
	@test_throws ErrorException wave_travel_time(G, (0.0, 0.0), method=:bogus)

	# ---------------------------------------------------------------- tttimes()
	D = tttimes(Gtt, [5.02 0.0; 1.03 0.0; 3.04 0.0], names=["far", "near", "mid"])
	@test isa(D, GMTdataset)
	@test size(D.data, 1) == 3
	@test D.colnames == ["lat", "lon", "ttt_hours", "dist_km", "slope_s_km"]
	@test issorted(D.data[:,3])							# sorted by arrival time
	@test [split(s, " | ")[1] for s in D.text] == ["near", "mid", "far"]
	@test all(D.data[:,3] .> 0)
	@test occursin("h ", D.text[1]) && occursin("m ", D.text[1])		# elapsed-time format

	# Bilinear interpolation between nodes. Along the equator fy == 0, so the result must be
	# the exact linear blend of the two bracketing nodes. This is the regression test for the
	# swapped bilinear weights (and for using the nearest node instead of the containing cell).
	i3 = findfirst(isapprox.(Gtt.x, 3.0; atol=1e-9))
	lo, hi = Gtt.z[jeq, i3], Gtt.z[jeq, i3+1]			# nodes at lon 3.0 and 3.1
	t = tttimes(Gtt, [3.04 0.0]).data[1,3]
	@test lo < t < hi									# must interpolate, never extrapolate
	@test t ≈ lo + 0.4 * (hi - lo) atol=1e-6

	# Same, in 2-D: a station inside the cell whose corners are (3.0,2.0)..(3.1,2.1)
	slon, slat = 3.03, 2.07
	ix = findfirst(isapprox.(Gtt.x, 3.0; atol=1e-9))
	iy = findfirst(isapprox.(Gtt.y, 2.0; atol=1e-9))
	v00, v10 = Gtt.z[iy, ix],   Gtt.z[iy, ix+1]
	v01, v11 = Gtt.z[iy+1, ix], Gtt.z[iy+1, ix+1]
	fx, fy = (slon - 3.0) / 0.1, (slat - 2.0) / 0.1
	want = (1-fx)*(1-fy)*v00 + fx*(1-fy)*v10 + (1-fx)*fy*v01 + fx*fy*v11
	@test tttimes(Gtt, [slon slat]).data[1,3] ≈ want atol=1e-6

	# A station sitting exactly on a node returns that node's value
	@test tttimes(Gtt, [3.0 0.0]).data[1,3] ≈ lo atol=1e-9

	# ---------------------------------------------------------------- tttimes() with origin time
	D2 = tttimes(Gtt, [3.0 0.0], names=["Sta"], origin=DateTime(2026,9,3,12,0,0), utc=true)
	@test occursin("Sta | ", D2.text[1])
	@test occursin("2026", D2.text[1])					# absolute date, not elapsed
	@test occursin("UTC", D2.comment[1])

	# ---------------------------------------------------------------- error paths
	@test_throws ErrorException ttt(G, (0.0, 0.0), nodes=7)			# not 8|16|32|48|64|120
	@test_throws ErrorException ttt(G, (99.0, 0.0))					# source outside the grid
	@test_throws ErrorException tttimes(Gtt, [1.0 0.0; 2.0 0.0], names=["only_one"])
	@test_throws ErrorException tttimes(Gtt, [1.0 0.0], Gdepth=G[1:10, 1:10])	# size mismatch

	# A grid whose 'z' disagrees with the nx,ny implied by its x,y and registration used to read
	# out of bounds inside an @inbounds loop and segfault. It must raise instead.
	Gbad = mat2grid(fill(Float32(-DEPTH), 120, 120);
	                hdr=[-6.0, 6.0, -6.0, 6.0, -DEPTH, -DEPTH, 1.0, 0.1, 0.1])
	@test length(Gbad.x) - Gbad.registration != size(Gbad.z, 2)		# the inconsistency
	@test_throws ErrorException ttt(Gbad, (0.0, 0.0))

	rm(fn, force=true)
end
