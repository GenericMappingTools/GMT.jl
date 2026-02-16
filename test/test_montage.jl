@testset "MONTAGE" begin

	println("	MONTAGE")

	# --- _montage_grid_size ---
	@test GMT._montage_grid_size(4, nothing) == (2, 2)
	@test GMT._montage_grid_size(6, nothing) == (2, 3)
	@test GMT._montage_grid_size(7, nothing) == (3, 3)
	@test GMT._montage_grid_size(1, nothing) == (1, 1)
	@test GMT._montage_grid_size(9, (3, 3)) == (3, 3)
	@test GMT._montage_grid_size(6, (2, 3)) == (2, 3)
	@test GMT._montage_grid_size(6, (0, 3)) == (2, 3)		# nrows=0 => auto
	@test GMT._montage_grid_size(6, (2, 0)) == (2, 3)		# ncols=0 => auto

	# --- subplot_panel_sizes (Matrix method) ---
	# All equal aspect ratios => equal widths and heights
	a = ones(2, 3)
	w, h = GMT.subplot_panel_sizes(a, total_width=12.0)
	@test length(w) == 3
	@test length(h) == 2
	@test isapprox(sum(w), 12.0, atol=0.1)
	@test isapprox(w[1], w[2], atol=0.01)	# All columns same width
	@test isapprox(w[2], w[3], atol=0.01)
	@test isapprox(h[1], h[2], atol=0.01)	# All rows same height

	# Wide vs narrow columns
	a = [2.0 0.5;
	     2.0 0.5]
	w, h = GMT.subplot_panel_sizes(a, total_width=20.0)
	@test w[1] > w[2]	# First column should be wider (landscape panels)

	# Tall vs short rows
	a = [1.0 1.0;
	     0.5 0.5]
	w, h = GMT.subplot_panel_sizes(a, total_width=20.0)
	@test h[2] > h[1]	# Second row should be taller (portrait panels)

	# With NaN entries (empty panels)
	a = [1.5 1.0;
	     NaN 0.8]
	w, h = GMT.subplot_panel_sizes(a, total_width=20.0)
	@test length(w) == 2
	@test length(h) == 2
	@test all(isfinite, w)
	@test all(isfinite, h)

	# Single panel
	a = reshape([1.5], 1, 1)
	w, h = GMT.subplot_panel_sizes(a, total_width=15.0)
	@test isapprox(w[1], 15.0, atol=0.01)

	# --- _fill_nans_ar! ---
	a = [1.0 NaN; NaN 2.0]
	GMT._fill_nans_ar!(a)
	@test all(isfinite, a)
	@test a[1, 1] == 1.0		# Original values preserved
	@test a[2, 2] == 2.0

	# All NaN => filled with 1.0 (global default)
	a = fill(NaN, 2, 2)
	GMT._fill_nans_ar!(a)
	@test all(a .== 1.0)

	# --- montage with GMTimage vector ---
	I1 = mat2img(rand(UInt8, 64, 48))
	I2 = mat2img(rand(UInt8, 64, 48))
	I3 = mat2img(rand(UInt8, 64, 48))
	I4 = mat2img(rand(UInt8, 64, 48))
	montage([I1, I2, I3, I4], grid=(2, 2), panels_size=5, show=false)

	# With titles
	montage([I1, I2, I3, I4], grid=(2, 2), panels_size=5, titles=["A","B","C","D"], title="Test", show=false)

	# With indices selection
	montage([I1, I2, I3, I4], grid=(1, 2), panels_size=5, indices=[1, 3], show=false)

	# --- subplot_panel_sizes with GMTimage vector ---
	w, h = GMT.subplot_panel_sizes([I1, I2], ncols=2, total_width=20.0)
	@test length(w) == 2
	@test length(h) == 1
	@test isapprox(sum(w), 20.0, atol=0.1)

end
