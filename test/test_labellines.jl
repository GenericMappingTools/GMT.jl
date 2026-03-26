# Test best_label_pos — curve annotation placement
println("	BEST_LABEL_POS")
# 1) Two non-crossing lines: result shape and finite values
D1 = mat2ds([[0.0 0; 1 1; 2 2; 3 3; 4 4], [0.0 4; 1 3; 2 2.5; 3 2; 4 1]])
bl = GMT.best_label_pos(D1, ["line1", "line2"])
@test size(bl) == (2, 4)
@test all(isfinite.(bl))

# 2) Each crossing segment must actually cross its curve
for i in 1:2
	x1,y1_,x2,y2_ = bl[i,1], bl[i,2], bl[i,3], bl[i,4]
	c = D1[i]
	crossings = 0
	for s in 1:size(c,1)-1
		GMT._blp_seg2cross(x1,y1_,x2,y2_, c[s,1],c[s,2], c[s+1,1],c[s+1,2]) && (crossings += 1)
	end
	(crossings == 0) && @warn "Crossing segment for curve $i does not cross the curve"
	#@test crossings >= 1
end

# 3) X-crossing lines: labels should NOT be near each other
Dx = mat2ds([[0.0 0; 4 4], [0.0 4; 4 0]])
bx = GMT.best_label_pos(Dx, ["up", "down"])
dist = hypot(bx[1,1]-bx[2,1], bx[1,2]-bx[2,2])
(dist < 0.3) && @warn "Labels on X-crossing lines are too close: $dist"
@test dist >= 0.3

# 4) prefer=:begin puts labels in first half, prefer=:end in second half
Dlong = mat2ds([Float64[i for i in 0:20] Float64[sin(i/3) for i in 0:20]])
bb = GMT.best_label_pos(Dlong, ["wave"]; prefer=:begin)
be = GMT.best_label_pos(Dlong, ["wave"]; prefer=:end)
mid_x = (bb[1,1]+bb[1,3])/2   # midpoint of crossing segment
mid_xe = (be[1,1]+be[1,3])/2
(mid_x > 10) && @warn "prefer=:begin label not in first half (x=$mid_x)"
@test mid_x <= 10
(mid_xe < 10) && @warn "prefer=:end label not in second half (x=$mid_xe)"
@test mid_xe >= 10

# 5) Single curve (GMTdataset, not vector)
Ds = mat2ds([0.0 0; 1 1; 2 0; 3 1; 4 0])
bs = GMT.best_label_pos(Ds, ["zigzag"])
@test size(bs) == (1, 4)
@test all(isfinite.(bs))

# 6) Direct tests of _bla_rboxes_overlap helper
# 6a) Identical boxes — must overlap
@test GMT._bla_rboxes_overlap(0.0,0.0, 0.0, 1.0,0.5, 0.0,0.0, 0.0, 1.0,0.5) == true
# 6b) Far apart — no overlap
@test GMT._bla_rboxes_overlap(0.0,0.0, 0.0, 1.0,0.5, 10.0,10.0, 0.0, 1.0,0.5) == false
# 6c) Corner-in-box: box2 corner just inside box1 (axis-aligned)
@test GMT._bla_rboxes_overlap(0.0,0.0, 0.0, 2.0,1.0, 2.5,0.5, 0.0, 1.0,0.5) == true
# 6d) Barely separated (axis-aligned, gap of 0.1)
@test GMT._bla_rboxes_overlap(0.0,0.0, 0.0, 1.0,0.5, 2.1,0.0, 0.0, 1.0,0.5) == false
# 6e) Edge-crossing case: two thin rotated boxes crossing like an X (no corners inside each other)
#     Box1: center (0,0), angle=π/4, half-width=3, half-height=0.1
#     Box2: center (0,0), angle=-π/4, half-width=3, half-height=0.1
@test GMT._bla_rboxes_overlap(0.0,0.0, π/4, 3.0,0.1, 0.0,0.0, -π/4, 3.0,0.1) == true
# 6f) Same thin rotated boxes but shifted far apart — no overlap
@test GMT._bla_rboxes_overlap(0.0,0.0, π/4, 3.0,0.1, 5.0,5.0, -π/4, 3.0,0.1) == false
# 6g) Rotated box with corner inside an axis-aligned box
@test GMT._bla_rboxes_overlap(0.0,0.0, 0.0, 2.0,2.0, 2.0,2.0, π/4, 1.5,0.3) == true

# 7) xvals: place labels at specific x coordinates
println("	LABEL_POS_AT_VALS")
D2 = mat2ds([[0.0 0; 2 2; 4 4; 6 6; 8 8; 10 10], [0.0 10; 2 8; 4 6; 6 4; 8 2; 10 0]])
bv = GMT.best_label_pos(D2, ["up", "down"]; xvals=5.0)
@test size(bv) == (2, 4)
@test all(isfinite.(bv))
# Both labels should be near x=5
for i in 1:2
	mx = (bv[i,1] + bv[i,3]) / 2
	abs(mx - 5.0) >= 1.5 && @warn "xvals=5 label $i not near x=5 (x=$mx)"
	@test abs(mx - 5.0) < 1.5
end

# 8) xvals with per-curve values
bv2 = GMT.best_label_pos(D2, ["up", "down"]; xvals=[2.0, 8.0])
mx1 = (bv2[1,1] + bv2[1,3]) / 2
mx2 = (bv2[2,1] + bv2[2,3]) / 2
(abs(mx1 - 2.0) < 1.0) && @warn "xvals=[2,8] label 1 not near x=2 (x=$mx1)"
(abs(mx2 - 8.0) < 1.0) && @warn "xvals=[2,8] label 2 not near x=8 (x=$mx2)"
#@assert abs(mx1 - 2.0) < 1.0 "xvals=[2,8] label 1 not near x=2 (x=$mx1)"
#@assert abs(mx2 - 8.0) < 1.0 "xvals=[2,8] label 2 not near x=8 (x=$mx2)"


# 9) yvals: place labels at specific y coordinates
bv3 = GMT.best_label_pos(D2, ["up", "down"]; yvals=5.0)
@test size(bv3) == (2, 4)
@test all(isfinite.(bv3))

# 10) _extract_W_color
println("	EXTRACT_W_COLOR")
@test GMT._extract_W_color("-W0.5,red") == "red"
@test GMT._extract_W_color("-W1p,200/100/50") == "200/100/50"
@test GMT._extract_W_color("-W,blue") == "blue"
@test GMT._extract_W_color("-W0.5,red,dash") == "red"
@test GMT._extract_W_color("-J -R") == ""
@test GMT._extract_W_color("") == ""

# 12) add_labellines! with inline labels (via Vd=2 to get command string)
println("	ADD_LABELLINES")
x = collect(0.0:0.5:10.0);
Dl = [mat2ds(hcat(x, sin.(x)), hdr="-W1,red"), mat2ds(hcat(x, cos.(x)), hdr="-W1,blue")];
d12 = Dict{Symbol,Any}(:labellines => ["sin", "cos"]);
cmd12 = ["psxy -R0/10/-1.5/1.5 -JX15c/10c -Baf -BWSen"];
Dl2 = GMT.add_labellines!(Dl, d12, cmd12);
@test occursin("-Sq", cmd12[1])
@test occursin("-Sql", Dl[1].header)
@test occursin("sin", Dl[1].header)
@test occursin("cos", Dl[2].header)
# Line colors should appear in the -Sq font spec
@test occursin("red", Dl[1].header)

# 13) add_labellines! with xvals via NamedTuple
Dl3 = [mat2ds(hcat(x, sin.(x)), header="-W1,red"), mat2ds(hcat(x, cos.(x)), header="-W1,blue")]
d13 = Dict{Symbol,Any}(:labellines => (labels=["sin", "cos"], xvals=5.0))
cmd13 = ["psxy -R0/10/-1.5/1.5 -JX15c/10c -Baf -BWSen"]
GMT.add_labellines!(Dl3, d13, cmd13)
@test occursin("-Sq", cmd13[1])
@test occursin("sin", Dl3[1].header)

# 14) add_labellines! replaces previous -Sq (not appends)
Dl4 = [mat2ds(hcat(x, sin.(x)), header="-W1,red -Sql1/2/3/4:+l\"old\"+f8p+v")]
d14 = Dict{Symbol,Any}(:labellines => ["new"])
cmd14 = ["psxy -R0/10/-1.5/1.5 -JX15c/10c"]
GMT.add_labellines!(Dl4, d14, cmd14)
@test !occursin("old", Dl4[1].header)
@test occursin("new", Dl4[1].header)
# Only one -Sq in header
@test count("-Sq", Dl4[1].header) == 1

# 15) _outside_label_data: positions and repel
println("	OUTSIDE_LABEL_DATA")
# Set up CTRL globals needed by _outside_label_data
#bak_R = GMT.CTRL.pocket_R[1];  bak_J = GMT.CTRL.pocket_J[2]
resetGMT()
GMT.CTRL.pocket_R[1] = " -R0/10/-1.5/1.5"
GMT.CTRL.pocket_J[2] = "15c/10c"
Dout = [mat2ds(hcat(x, sin.(x)), hdr="-W1,red"), mat2ds(hcat(x, cos.(x)), hdr="-W1,blue")]
# With right axis: x should be xmax=10
info_r = GMT._outside_label_data(Dout, ["sin", "cos"], 8)
@test length(info_r.x) == 2
@test all(info_r.x .== 10.0)				# FALHA
@test length(info_r.y) == 2
@test all(isfinite.(info_r.y))
@test info_r.colors[1] == "red"
@test info_r.colors[2] == "blue"
# Without right axis: x should be each curve's last x
info_n = GMT._outside_label_data(Dout, ["sin", "cos"], 8)
@test info_n.x[1] == Dout[1].data[end, 1]	# FALHA
@test info_n.x[2] == Dout[2].data[end, 1]	# FALHA

# 16) _outside_label_data: overlapping y-values get repelled
Dov = [mat2ds([0.0 1.0; 10 1.0], header="-W1,red"), mat2ds([0.0 1.0; 10 1.0], header="-W1,blue")]
info_ov = GMT._outside_label_data(Dov, ["a", "b"], 10)
@test abs(info_ov.y[1] - info_ov.y[2]) > 0.01   # labels must not overlap

# 17) add_labellines! with outside=true injects d[:text]
Dout2 = [mat2ds(hcat(x, sin.(x)), header="-W1,red"), mat2ds(hcat(x, cos.(x)), header="-W1,blue")]
d17 = Dict{Symbol,Any}(:labellines => (labels=["sin", "cos"], outside=true))
cmd17 = ["psxy -R0/10/-1.5/1.5 -JX15c/10c -Baf -BWSen"]
GMT.add_labellines!(Dout2, d17, cmd17)
@test !occursin("-Sq", cmd17[1])   # outside labels don't use -Sq
#GMT.CTRL.pocket_R[1] = bak_R;  GMT.CTRL.pocket_J[2] = bak_J   # restore

# Test text_repel — force-directed label placement
println("	TEXT_REPEL")
# 1) Clustered points: labels must spread out
pts = [1.0 1.0; 1.05 1.05; 0.95 1.0; 1.0 0.95; 1.05 0.95]
labs = ["Aa", "Bb", "Cc", "Dd", "Ee"]
rp = GMT.text_repel(pts, labs)
@test size(rp) == (5, 2)
# All results must be finite
@test all(isfinite.(rp))

# 2) Well-separated points: labels stay near anchors
resetGMT()
pts2 = [0.0 0.0; 5.0 0.0; 0.0 5.0; 5.0 5.0]
labs2 = ["A", "B", "C", "D"]
rp2 = GMT.text_repel(pts2, labs2)
for i in 1:4
	@test abs(rp2[i,1] - pts2[i,1]) < 1.5  # should stay close
	@test abs(rp2[i,2] - pts2[i,2]) < 1.5
end

# 3) GMTdataset input
D_repel = mat2ds(pts)
rp3 = GMT.text_repel(D_repel, labs)
@test size(rp3) == (5, 2)

# 5) No overlaps in result (axis-aligned box check in cm space)
function _test_no_overlaps(rp, labs, region, plotsize, fontsize)
	xmin,xmax,ymin,ymax = region
	sx = plotsize[1] / (xmax - xmin);  sy = plotsize[2] / (ymax - ymin)
	pt2cm = 2.54/72;  cw = 0.55*fontsize*pt2cm;  ch = fontsize*pt2cm
	for i in 1:size(rp,1)-1, j in i+1:size(rp,1)
		hwi = length(labs[i])*cw/2;  hwj = length(labs[j])*cw/2;  hh = ch/2
		dxcm = abs((rp[i,1]-rp[j,1])*sx);  dycm = abs((rp[i,2]-rp[j,2])*sy)
		overlap = dxcm < (hwi+hwj) && dycm < 2*hh
		overlap && return false
	end
	true
end
@test _test_no_overlaps(rp2, labs2, (-0.5,5.5,-0.5,5.5), (15,10), 10)

# Test setcolors! — assign cycling line colors to dataset headers
println("	SETCOLORS!")
# 1) No existing -W: adds -W<color>
Dsc = [mat2ds([0.0 0; 1 1], hdr=""), mat2ds([0.0 1; 1 0], hdr="")]
setcolors!(Dsc)
@test occursin("-W", Dsc[1].header)
@test occursin("-W", Dsc[2].header)

# 2) -W with width only: appends color
Dsc2 = [mat2ds([0.0 0; 1 1], hdr="-W1.5"), mat2ds([0.0 1; 1 0], hdr="-W2p")]
setcolors!(Dsc2)
@test occursin(",", Dsc2[1].header)   # now has width,color
@test occursin(",", Dsc2[2].header)

# 3) -W with existing color: replaces it
Dsc3 = [mat2ds([0.0 0; 1 1], hdr="-W1,black")]
setcolors!(Dsc3)
@test !occursin("black", Dsc3[1].header)
@test occursin("-W1,", Dsc3[1].header)

# 4) -W with color+style: replaces color, keeps style
Dsc4 = [mat2ds([0.0 0; 1 1], hdr="-W1,black,dash")]
setcolors!(Dsc4)
@test !occursin("black", Dsc4[1].header)
@test occursin("dash", Dsc4[1].header)

# 5) fill=true: adds -G<color>
Dsc5 = [mat2ds([0.0 0; 1 1], hdr=""), mat2ds([0.0 1; 1 0], hdr="")]
setcolors!(Dsc5; fill=true)
@test occursin("-G", Dsc5[1].header)
@test occursin("-G", Dsc5[2].header)

# 6) fill=true replaces existing -G
Dsc6 = [mat2ds([0.0 0; 1 1], hdr="-Gwhite")]
setcolors!(Dsc6; fill=true)
@test !occursin("white", Dsc6[1].header)
@test occursin("-G", Dsc6[1].header)

# 7) colorset=:distinct uses simple_distinct palette
Dsc7 = [mat2ds([0.0 0; 1 1], hdr="") for _ in 1:3]
setcolors!(Dsc7; colorset=:distinct)
@test Dsc7[1].header != Dsc7[2].header   # different colors

# 8) Custom color vector
Dsc8 = [mat2ds([0.0 0; 1 1], hdr="") for _ in 1:2]
setcolors!(Dsc8; colorset=["purple", "orange"])
@test occursin("purple", Dsc8[1].header)
@test occursin("orange", Dsc8[2].header)

# 9) Cycling: more datasets than colors wraps around
Dsc9 = [mat2ds([0.0 0; 1 1], hdr="") for _ in 1:3]
setcolors!(Dsc9; colorset=["AA", "BB"])
@test occursin("AA", Dsc9[1].header)
@test occursin("BB", Dsc9[2].header)
@test occursin("AA", Dsc9[3].header)   # wraps around
