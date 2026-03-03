using GMT, Test

source = [-11.0, 35.9]

# Reference result with default layout (BCB)
G_bc = gmtread("@earth_relief_06m", R=:PT)
ttt_bc = wave_travel_time(G_bc, source)

@test size(ttt_bc.z) == size(G_bc.z)
@test !all(isnan.(ttt_bc.z))
zmin_bc = minimum(x -> isnan(x) ? Inf : x, ttt_bc.z)
zmax_bc = maximum(x -> isnan(x) ? -Inf : x, ttt_bc.z)
@test zmin_bc >= 0
@test zmax_bc < 24		# Portugal is not 24 hours away from itself

# TRB layout — results must match BCB
G_tr = gmtread("@earth_relief_06m", R=:PT, layout="TRB")
ttt_tr = wave_travel_time(G_tr, source)

@test size(ttt_tr.z) == size(G_tr.z)
@test ttt_tr.range[5] ≈ ttt_bc.range[5] atol=1e-4
@test ttt_tr.range[6] ≈ ttt_bc.range[6] atol=1e-4

# BRB layout — results must match BCB
G_br = gmtread("@earth_relief_06m", R=:PT, layout="BRB")
ttt_br = wave_travel_time(G_br, source)

@test size(ttt_br.z) == size(G_br.z)
@test ttt_br.range[5] ≈ ttt_bc.range[5] atol=1e-4
@test ttt_br.range[6] ≈ ttt_bc.range[6] atol=1e-4
