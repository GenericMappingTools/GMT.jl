println("	GHOST FUNS (ps2image, ps2raster, psbbox)")

# Minimal valid PostScript: 100x80 point box with bounding box hint.
const _TEST_PS = """%!PS-Adobe-3.0
%%BoundingBox: 10 20 110 100
%%HiResBoundingBox: 10.0 20.0 110.0 100.0
%%EndComments
newpath
10 20 moveto
110 20 lineto
110 100 lineto
10 100 lineto
closepath
0.5 setgray fill
showpage
"""

const _TEST_PS_FILE = joinpath(tempdir(), "gmt_ghost_test.ps")
write(_TEST_PS_FILE, _TEST_PS)

# ── psbbox ───────────────────────────────────────────────────────────────────
@testset "psbbox" begin
	# GS bbox device returns ink bounds — slightly outside the geometric rect.
	bb = GMT.psbbox(_TEST_PS)
	@test bb isa NamedTuple
	@test isapprox(bb.llx,  10.0; atol=0.1)
	@test isapprox(bb.lly,  20.0; atol=0.1)
	@test isapprox(bb.urx, 110.0; atol=0.1)
	@test isapprox(bb.ury, 100.0; atol=0.1)

	bb_file = GMT.psbbox(_TEST_PS_FILE)
	@test isapprox(bb_file.llx,  10.0; atol=0.1) && isapprox(bb_file.urx, 110.0; atol=0.1)
	@test isapprox(bb_file.lly,  20.0; atol=0.1) && isapprox(bb_file.ury, 100.0; atol=0.1)

	bb_bytes = GMT.psbbox(Vector{UInt8}(codeunits(_TEST_PS)))
	@test isapprox(bb_bytes.urx, 110.0; atol=0.1) && isapprox(bb_bytes.ury, 100.0; atol=0.1)
end

# ── ps2raster ────────────────────────────────────────────────────────────────
@testset "ps2raster" begin
	for (fmt, ext) in (("png", ".png"), ("jpg", ".jpg"), ("tif", ".tif"))
		out = GMT.ps2raster(_TEST_PS_FILE; fmt=fmt, dpi=72)
		@test isfile(out)
		@test endswith(out, ext)
		@test filesize(out) > 0
		rm(out; force=true)
	end

	out_gray = GMT.ps2raster(_TEST_PS_FILE; fmt="png", dpi=72, gray=true)
	@test isfile(out_gray)
	rm(out_gray; force=true)

	out_named = joinpath(tempdir(), "gmt_ghost_named.png")
	rm(out_named; force=true)
	r = GMT.ps2raster(_TEST_PS_FILE; outfile=out_named, dpi=72)
	@test r == out_named
	@test isfile(out_named)
	rm(out_named; force=true)

	@test_throws ErrorException GMT.ps2raster(_TEST_PS_FILE; fmt="bmp")
	@test_throws ErrorException GMT.ps2raster("no_such_file_xyz.ps")
end

# ── ps2image ─────────────────────────────────────────────────────────────────
@testset "ps2image" begin
	img = GMT.ps2image(_TEST_PS; dpi=72)
	@test img isa Array{UInt8,3}
	@test size(img, 3) == 3
	@test size(img, 1) > 0  && size(img, 2) > 0

	img_gray = GMT.ps2image(_TEST_PS; dpi=72, gray=true)
	@test img_gray isa Array{UInt8,2}
	@test size(img_gray, 1) == size(img, 1)
	@test size(img_gray, 2) == size(img, 2)

	img_bytes = GMT.ps2image(Vector{UInt8}(codeunits(_TEST_PS)); dpi=72)
	@test size(img_bytes) == size(img)

	img_hi = GMT.ps2image(_TEST_PS; dpi=144)
	@test size(img_hi, 1) > size(img, 1)
	@test size(img_hi, 2) > size(img, 2)
end

rm(_TEST_PS_FILE; force=true)
