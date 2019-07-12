using GMT
using Test

try
	run(`gmt --version`)	# Will fail if GMT is not installed.
	global got_it = true
catch
	@test 1 == 1			# Let tests pass for sake of not triggering a PkgEval failure
	global got_it = false
end

if (got_it)					# Otherwise go straight to end

	if (GMTver >= 6)
		GMT.GMT_Get_Version();
		ma=[0];mi=[0];pa=[0];
		GMT.GMT_Get_Version(ma,mi,pa);
		API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL);
		GMT.GMT_Get_Ctrl(API);
	end

	# -------------------- Test common_options ----------------------------------------
	@test GMT.parse_R("", Dict(:xlim => (1,2), :ylim => (3,4), :zlim => (5,6)))[1] == " -R1/2/3/4/5/6"
	G1 = gmt("grdmath -R-2/2/-2/2 -I0.5 X Y MUL");
	@test GMT.build_opt_R(G1) == " -R-2/2/-2/2"
	@test GMT.build_opt_R(:d) == " -Rd"
	@test GMT.build_opt_R([]) == ""
	@test GMT.build_opt_R((bb=:global,)) == " -R-180/180/-90/90"
	@test GMT.build_opt_R((bb=:global360,)) == " -R0/360/-90/90"
	@test GMT.build_opt_R((bb=(1,2,3,4),)) == " -R1/2/3/4"
	@test GMT.build_opt_R((bb=(1,2,3,4), diag=1)) == " -R1/3/2/4+r"
	@test GMT.build_opt_R((bb_diag=(1,2,3,4),)) == " -R1/3/2/4+r"
	@test GMT.build_opt_R((continent=:s,)) == " -R=SA"
	@test GMT.build_opt_R((continent=:s,extend=4)) == " -R=SA+R4"
	@test GMT.build_opt_R((iso="PT,ES",extend=4)) == " -RPT,ES+R4"
	@test GMT.build_opt_R((iso="PT,ES",extend=[2,3])) == " -RPT,ES+R2/3"
	@test GMT.build_opt_R((bb=:d,unit=:k)) == " -Rd+uk"			# Idiot but ok
	@test_throws ErrorException("argument to the ISO key must be a string with country codes") GMT.build_opt_R((iso=:PT,))
	@test_throws ErrorException("No, no, no. Nothing useful in the region named tuple arguments") GMT.build_opt_R((zz=:x,))
	@test_throws ErrorException("Unknown continent name") GMT.build_opt_R((continent='a',extend=4))
	@test_throws ErrorException("Increments for limits must be a String, a Number, Array or Tuple") GMT.build_opt_R((iso="PT",extend='8'))
	@test_throws ErrorException("The only valid case to provide a number to the 'proj' option is when that number is an EPSG code, but this (1500) is clearly an invalid EPSG")  GMT.build_opt_J(1500)
	@test GMT.build_opt_J(:X5)[1] == " -JX5"
	@test GMT.build_opt_J(2500)[1] == " -J2500"
	@test GMT.build_opt_J([])[1] == " -J"
	@test GMT.arg2str((1,2,3)) == "1/2/3"
	@test GMT.arg2str(("aa",2,3)) == "aa/2/3"
	@test GMT.arg2str(Dict(:shaded => "-4p/-6p/grey20@40"), [:shaded]) == "-4p/-6p/grey20@40"
	@test_throws ErrorException("arg2str: argument 'arg' can only be a String, Symbol, Number, Array or a Tuple, but was DataType") GMT.arg2str(typeof(1))
	@test GMT.parse_inc("", Dict(:inc => (x=1.5, y=2.6, unit="meter")),[:I :inc], "I") == " -I1.5e/2.6e"
	@test GMT.parse_inc("", Dict(:inc => (x=1.5, y=2.6, unit="m")),[:I :inc], "I") == " -I1.5m/2.6m"
	@test GMT.parse_inc("", Dict(:inc => (x=1.5, y=2.6, unit="data")),[:I :inc], "I") == " -I1.5/2.6u"
	@test GMT.parse_inc("", Dict(:inc => (x=1.5, y=2.6, extend="data")),[:I :inc], "I") == " -I1.5+e/2.6+e"
	@test GMT.parse_inc("", Dict(:inc => (x=1.5, y=2.6, unit="nodes")),[:I :inc], "I") == " -I1.5+n/2.6+n"
	@test GMT.parse_inc("", Dict(:inc => (2,4)),[:I :inc], "I") == " -I2/4"
	@test GMT.parse_inc("", Dict(:inc => [2 4]),[:I :inc], "I") == " -I2/4"
	@test GMT.parse_inc("", Dict(:inc => "2"),[:I :inc], "I") == " -I2"
	@test GMT.parse_inc("", Dict(:inc => "2"),[:I :inc], "") == "2"
	@test GMT.parse_JZ("", Dict(:JZ => "5c"))[1] == " -JZ5c"
	@test GMT.parse_JZ("", Dict(:Jz => "5c"))[1] == " -Jz5c"
	@test GMT.parse_J("", Dict(:J => "X5"), "", false)[1] == " -JX5"
	@test GMT.parse_J("", Dict(:a => ""), "", true, true)[1] == " -J"
	@test GMT.parse_J("", Dict(:J => "X", :figsize => 10))[1] == " -JX10"
	@test GMT.parse_J("", Dict(:J => "X", :scale => "1:10"))[1] == " -Jx1:10"
	@test GMT.parse_J("", Dict(:proj => "Ks0/15"))[1] == " -JKs0/15"
	@test GMT.parse_J("", Dict(:scale=>"1:10"))[1] == " -Jx1:10"
	@test GMT.parse_J("", Dict(:s=>"1:10"), " -JU")[1] == " -JU"
	@test GMT.parse_J("", Dict(:J => "Merc", :figsize => 10), "", true, true)[1] == " -JM10"
	@test GMT.parse_J("", Dict(:J => "+proj=merc"))[1] == " -J+proj=merc+width=12c"
	@test GMT.parse_J("", Dict(:J => (name=:albers, parallels=[45 65])), "", false)[1] == " -JB0/0/45/65"
	@test GMT.parse_J("", Dict(:J => (name=:albers, center=[10 20], parallels=[45 65])), "", false)[1] == " -JB10/20/45/65"
	@test GMT.parse_J("", Dict(:J => "winkel"), "", false)[1] == " -JR"
	@test GMT.parse_J("", Dict(:J => "M0/0"), "", false)[1] == " -JM0/0"
	@test GMT.parse_J("", Dict(:J => (name=:merc,center=10)), "", false)[1] == " -JM10"
	@test GMT.parse_J("", Dict(:J => (name=:merc,parallels=10)), "", false)[1] == " -JM0/0/10"
	@test GMT.parse_J("", Dict(:J => (name=:Cyl_,center=(0,45))), "", false)[1] == " -JCyl_stere/0/45"
	@test_throws ErrorException("When projection arguments are in a NamedTuple the projection 'name' keyword is madatory.") GMT.parse_J("", Dict(:J => (parallels=[45 65],)), "", false)
	@test_throws ErrorException("When projection is a named tuple you need to specify also 'center' and|or 'parallels'") GMT.parse_J("", Dict(:J => (name=:merc,)), "", false)
	r = GMT.parse_params("", Dict(:par => (MAP_FRAME_WIDTH=0.2, IO=:lixo, OI="xoli")));
	@test r == " --MAP_FRAME_WIDTH=0.2 --IO=lixo --OI=xoli"
	@test GMT.parse_params("", Dict(:par => (:MAP_FRAME_WIDTH,0.2))) == " --MAP_FRAME_WIDTH=0.2"
	@test GMT.parse_params("", Dict(:par => ("MAP_FRAME_WIDTH",0.2))) == " --MAP_FRAME_WIDTH=0.2"
	@test GMT.opt_pen(Dict(:lw => 5, :lc => :red),'W', nothing) == " -W5,red"
	@test GMT.opt_pen(Dict(:lw => 5),'W', nothing) == " -W5"
	@test GMT.opt_pen(Dict(:a => (10,:red)),'W', [:a]) == " -W10,red"
	@test_throws ErrorException("Nonsense in W option") GMT.opt_pen(Dict(:a => [1 2]),'W', [:a])
	@test GMT.get_color(((1,2,3),)) == "1/2/3"
	@test GMT.get_color(((1,2,3),100)) == "1/2/3,100"
	@test GMT.get_color(((0.1,0.2,0.3),)) == "26/51/77"
	@test GMT.get_color([1 2 3]) == "1/2/3"
	@test GMT.get_color([0.4 0.5 0.8; 0.1 0.2 0.7]) == "102/128/204,26/51/179"
	@test GMT.get_color([1 2 3; 3 4 5; 6 7 8]) == "1/2/3,3/4/5,6/7/8"
	@test GMT.get_color(:red) == "red"
	@test GMT.get_color((:red,:blue)) == "red,blue"
	@test GMT.get_color((200,300)) == "200,300"
	@test_throws ErrorException("GOT_COLOR, got an unsupported data type: Array{Int64,1}") GMT.get_color([1,2])
	@test_throws ErrorException("Color tuples must have only one or three elements") GMT.get_color(((0.2,0.3),))
	@test GMT.parse_unit_unit("data") == "u"
	@test GMT.parse_units((2,:p)) == "2p"
	@test GMT.add_opt((a=(1,0.5),b=2), (a="+a",b="-b")) == "+a1/0.5-b2"
	@test GMT.add_opt((symb=:circle, size=7, unit=:point), (symb="1", size="", unit="1")) == "c7p"
	r = GMT.add_opt_fill("", Dict(:G=>(inv_pattern=12,fg="white",bg=[1,2,3], dpi=10) ), [:G :fill], 'G');
	@test r == " -GP12+b1/2/3+fwhite+r10"
	@test GMT.add_opt_fill("", Dict(:G=>:red), [:G :fill], 'G') == " -Gred"
	@test_throws ErrorException("For 'fill' option as a NamedTuple, you MUST provide a 'patern' member") GMT.add_opt_fill("", Dict(:G=>(inv_pat=12,fg="white")), [:G], 'G')
	d = Dict(:offset=>5, :bezier=>true, :cline=>"", :ctext=>true, :pen=>("10p",:red,:dashed));
	@test GMT.add_opt_pen(d, [:W :pen], "W") == " -W10p,red,dashed+cl+cf+s+o5"
	d = Dict(:W=>(offset=5, bezier=true, cline="", ctext=true, pen=("10p",:red,:dashed), arrow=(lenght=0.1,)));
	@test GMT.add_opt_pen(d, [:W :pen], "W") == " -W10p,red,dashed+cl+cf+s+o5+v"

	r = vector_attrib(len=2.2,stop=[],norm="0.25i",shape=:arrow,half_arrow=:right,
	                  justify=:end,fill=:none,trim=0.1,endpoint=true,uv=6.6);
	@test r == "2.2+e+je+r+g-+n0.25i+h1+t0.1+s+z6.6"

	r = decorated(dist=("0.4i",0.25), symbol=:arcuate, pen=2, offset="10i", right=1);
	@test r == " -Sf0.4i/0.25+r+S+o10i+p2"
	r = decorated(dist=("0.8i","0.1i"), symbol=:star, symbsize=1, pen=(0.5,:green), fill=:blue, n_data=20, nudge=1, debug=1, dec2=1);
	@test r == " -S~d0.8i/0.1i:+sa1+d+gblue+n1+w20+p0.5,green"
	r = decorated(n_symbols=5, symbol=:star, symbsize=1, pen=(0.5,:green), fill=:blue, quoted=1);
	@test r == " -Sqn5:+p0.5,green"

	r = decorated(dist=("0.4i",0.25), angle=7, clearance=(2,3), debug=1, delay=1, font=10, color=:red, justify=:TC, const_label=:Ai, pen=(0.5,:red), fill=:blue, nudge=(3,4), rounded=1, unit=:TT, min_rad=0.5, curved=1, n_data=20, prefix="Pre", suffices="a,b", label=(:map_dist,"d"), quoted=1)
	@test r == " -Sqd0.4i/0.25:+a7+d+c2/3+e+f10+gred+jTC+lAi+n3/4+o+r0.5+uTT+v+w20+=Pre+xa,b+LDd+p0.5,red"

	@test GMT.helper_decorated(Dict(:line => [1 2 3 4; 5 6 7 8]), true) == "l1/2/3/4,5/6/7/8"
	@test GMT.helper_decorated(Dict(:Line => "CT/CB"), true) == "LCT/CB"
	@test GMT.helper_decorated(Dict(:Line => (1,2,"CB")), true) == "L1/2/CB"
	@test GMT.helper_decorated(Dict(:N_labels => 5), true) == "N5"
	@test_throws ErrorException("DECORATED: 'line' option. When array, it must be an Mx4 one") GMT.helper_decorated(Dict(:line => [1 2 3]), true)
	@test_throws ErrorException("DECORATED: 'dist' (or 'distance') option. Unknown data type.") GMT.helper_decorated(Dict(:dist => (a=1,)))
	@test GMT.parse_quoted(Dict(:label => "aa"), "") == "+Laa"
	@test GMT.parse_quoted(Dict(:label => :header), "") == "+Lh"
	@test GMT.parse_quoted(Dict(:label => :input), "") == "+Lf"
	@test_throws ErrorException("Wrong content for the :label option. Must be only :header or :input") GMT.parse_quoted(Dict(:label => :x), "")
	@test_throws ErrorException("Wrong content for the :label option. Must be only :plot_dist or :map_dist") GMT.parse_quoted(Dict(:label => (:x,)), "")
	GMT.helper_arrows(Dict(:geovec => "bla"));
	GMT.helper_arrows(Dict(:vecmap => "bla"));

	@test GMT.font(("10p","Times", :red)) == "10p,Times,red"
	r = text(text_record([0 0], "TopLeft"), R="1/10/1/10", J=:X10, F=(region_justify=:MC,font=("10p","Times", :red)), Vd=2);
	ind = findfirst("-F", r); @test GMT.strtok(r[ind[1]:end])[1] == "-F+cMC+f10p,Times,red"

	@test GMT.build_pen(Dict(:lw => 1, :lc => [1,2,3])) == "1,1/2/3"
	@test GMT.parse_pen((0.5, [1 2 3])) == "0.5,1/2/3"

	@test GMT.helper0_axes((:left_full, :bot_full, :right_ticks, :top_bare, :up_bare)) == "WSetu"
	d=Dict(:xaxis => (axes=:WSen,title=:aiai, label=:ai, annot=:auto, ticks=[], grid=10, annot_unit=:ISOweek,seclabel=:BlaBla), :xaxis2=>(annot=5,ticks=1), :yaxis=>(custom="lixo.txt",), :yaxis2=>(annot=2,));
	@test GMT.parse_B("", d)[1] == " -BWSen+taiai -Bpx+lai+sBlaBla -BpxaUfg10 -Bpyclixo.txt -Bsxa5f1 -Bsya2"
	@test GMT.parse_B("",Dict(:B=>:same))[1] == " -B"
	@test GMT.parse_B("", Dict(:title => :bla))[1] == " -Baf -BWSen+tbla"
	GMT.helper2_axes("lolo");
	@test_throws ErrorException("Custom annotations NamedTuple must contain the member 'pos'") GMT.helper3_axes((a=0,),"","")

	d=Dict(:L => (pen=(lw=10,lc=:red),) );
	@test GMT.add_opt("", "", d, [:L], (pen=("+p",GMT.add_opt_pen),) ) == "+p10,red"
	r = psxy([0.0, 1],[0, 1.1], L=(pen=(10,:red),bot=true), Vd=2);
	@test startswith(r,"psxy  -JX12c/8c -Baf -BWSen -R0/1/0/1.2 -L+p10,red+yb")
	r = psxy([0.0, 1],[0, 1.1], L=(pen=(lw=10,cline=true),bot=true), Vd=2);
	@test startswith(r,"psxy  -JX12c/8c -Baf -BWSen -R0/1/0/1.2 -L+p10+cl+yb")
	@test startswith(psxy([0.0, 1],[0, 1.1], figsize=(10,12), aspect=:equal, Vd=2), "psxy  -JX10/12")
	@test startswith(psxy([0.0, 1],[0, 1.1], figsize=10, aspect=:equal, Vd=2), "psxy  -JX10/0")
	@test startswith(psxy([0.0, 1],[0, 1.1], aspect=:equal, Vd=2), "psxy  -JX12c/0")
	psxy!([0 0; 1 1.1], Vd=2);
	psxy!("", [0 0; 1 1.1], Vd=2);
	GMT.get_marker_name(Dict(:y => "y"), [:y], false)
	@test_throws ErrorException("Argument of the *bar* keyword can be only a string or a NamedTuple.") GMT.parse_bar_cmd(Dict(:a => 0), :a, "", "")

	@test_throws ErrorException("Custom annotations NamedTuple must contain the member 'pos'") GMT.helper3_axes((post=1:5,), 'p', "x")

	GMT.round_wesn([1.333 17.4678 6.66777 33.333], true);
	GMT.round_wesn([1 1 2 2]);
	GMT.round_wesn([1. 350 1. 180], true)
	GMT.round_wesn([0. 1.1 0. 0.1], true)

	GMT.GMTdataset([0.0 0]);
	GMT.GMTdataset([0.0 0], Array{String,1}());

	@test_throws ErrorException("Memory layout option must have 3 characters and not 1") GMT.parse_mem_layouts("-%1")
	@test_throws ErrorException("Memory layout option must have at least 2 chars and not 1") GMT.parse_mem_layouts("-&1")
	@test GMT.parse_mem_layouts("-&BR")[3] == "BR"
	@test_throws ErrorException("parse_arg_and_pen: Nonsense first argument") GMT.parse_arg_and_pen(([:a],0))
	@test_throws ErrorException("GMT: No module by that name -- bla -- was found.") gmt("bla")
	@test_throws ErrorException("grd_init: input (Int64) is not a GRID container type") GMT.grid_init(C_NULL,0,0)
	@test_throws ErrorException("image_init: input is not a IMAGE container type") GMT.image_init(C_NULL,0,0)
	@test_throws ErrorException("Expected a CPT structure for input") GMT.palette_init(C_NULL,0,0,0)
	@test_throws ErrorException("Bad family type") GMT.GMT_Alloc_Segment(C_NULL, -1, 0, 0, "", C_NULL)
	GMT.strncmp("abcd", "ab", 2)
	GMT.parse_proj((name="blabla",center=(0,0)))

	@test GMT.parse_j("", Dict(:spheric_dist => "f"))[1] == " -jf"

	# ---------------------------------------------------------------------------------------------------

	gmt("psxy -");
	r = gmt("gmtinfo -C", ones(Float32,9,3)*5);
	@assert(r[1].data == [5.0 5 5 5 5 5])
	r = gmtinfo(ones(Float32,9,3)*5, C=true, V=:q);
	@assert(r[1].data == [5.0 5 5 5 5 5])

	# BLOCK*s
	d = [0.1 1.5 1; 0.5 1.5 2; 0.9 1.5 3; 0.1 0.5 4; 0.5 0.5 5; 0.9 0.5 6; 1.1 1.5 7; 1.5 1.5 8; 1.9 1.5 9; 1.1 0.5 10; 1.5 0.5 11; 1.9 0.5 12];
	G = blockmedian(region=[0 2 0 2], inc=1, fields="z", reg=true, d);
	if (G !== nothing)	# If run from GMT5 it will return nothing
		G = blockmean(d, region=[0 2 0 2], inc=1, grid=true, reg=true, S=:n);	# Number of points in cell
		G,L = blockmode(region=[0 2 0 2], inc=1, fields="z,l", reg=true, d);
		G,L,H = blockmode(d, region=[0 2 0 2], inc=1, fields="z,l,h", reg=true)
	end
	D = blockmedian(region=[0 2 0 2], inc=1,  reg=true, d);
	D = blockmean(region=[0 2 0 2], inc=1,  reg=true, d);
	D = blockmode(region=[0 2 0 2], inc=1,  reg=true, d);

	# FILTER1D
	filter1d([collect((1.0:50)) rand(50)], F="m15");

	# FITCIRCLE
	d = [-3.2488 -1.2735; 7.46259 6.6050; 0.710402 3.0484; 6.6633 4.3121; 12.188 18.570; 8.807 14.397; 17.045 12.865; 19.688 30.128; 31.823 33.685; 39.410 32.460; 48.194 47.114; 62.446 46.528; 59.865 46.453; 68.739 50.164; 64.334 32.984];
	fitcircle(d, L=3);

	# GMT2KML & KML2GMT
	if (GMTver >= 6)
		D = gmt("pscoast -R-5/-3/56/58 -Jm1i -M -W0.25p -Di");
		K = gmt2kml(D, F=:l, W=(1,:red));
		gmtwrite("lixo.kml", K)
		kml2gmt("lixo.kml", Z=true);
		kml2gmt(nothing, "lixo.kml", Z=true);	# yes, cheating
		rm("lixo.kml")
	end

	# GMTCONNECT
	gmtconnect([0 0; 1 1], [1.1 1.1; 2 2], T=0.5);

	# GMTCONVERT
	gmtconvert([1.1 2; 3 4], o=0)

	# GMTREGRESS
	d = [0 5.9 1e3 1; 0.9 5.4 1e3 1.8; 1.8 4.4 5e2 4; 2.6 4.6 8e2 8; 3.3 3.5 2e2 2e1; 4.4 3.7 8e1 2e1; 5.2 2.8 6e1 7e1; 6.1 2.8 2e1 7e1; 6.5 2.4 1.8 1e2; 7.4 1.5 1 5e2];
	regress(d, E=:y, F=:xm, N=2, T="-0.5/8.5/2+n");

	# GMTLOGO
	logo(D="x0/0+w2i")
	logo(julia=8)
	logo(GMTjulia=8, fmt=:png, Vd=2)
	logo!(julia=8, Vd=2)
	logo!("", julia=8, Vd=2)

	@show("GMTSPATIAL")
	# GMTSPATIAL
	# Test  Cartesian centroid and area
	result = gmt("gmtspatial -Q", [0 0; 1 0; 1 1; 0 1; 0 0]);
	@assert(isapprox(result[1].data, [0.5 0.5 1]))
	# Test Geographic centroid and area
	result = gmt("gmtspatial -Q -fg", [0 0; 1 0; 1 1; 0 1; 0 0]);
	@assert(isapprox(result[1].data, [0.5 0.500019546308 12308.3096995]))
	# Intersections
	l1 = gmt("project -C22/49 -E-60/-20 -G10 -Q");
	l2 = gmt("project -C0/-60 -E-60/-30 -G10 -Q");
	#int = gmt("gmtspatial -Ie -Fl", l1, l2);       # Error returned from GMT API: GMT_ONLY_ONE_ALLOWED (59)
	d = [-300 -3500; -200 -800; 400 -780; 500 -3400; -300 -3500];
	gmtspatial(d, C=true, R="0/100/-3100/-3000");

	@show("GMTSELECT")
	# GMTSELECT
	gmtselect([2 2], R=(0,3,0,3));		# But is bugged when answer is []
	gmtselect([1.0 2], C=([1 2],10), Vd=1);
	@test gmtselect([1 2], C=("aa",10), Vd=2) == "gmtselect  -Caa+d10"
	@test gmtselect([1 2], C=(pts=[1 2],dist=10), Vd=2) == "gmtselect  -C+d10"
	@test gmtselect([1 2], C="aa+d0", Vd=2) == "gmtselect  -Caa+d0"
	@test gmtselect([1 2], C=(pts=[1 2],dist=10), L=(line=[1 2;3 4], dist=10), Vd=2) == "gmtselect  -C+d10 -L+d10"

	# GMTSET
	gmtset(MAP_FRAME_WIDTH=0.2)

	# GMTSIMPLIFY
	gmtsimplify([0.0 0; 1.1 1.1; 2 2.2; 3.3 3], T="3k")

	@show("GMTREADWRITE")
	# GMTREADWRITE
	G=gmt("grdmath", "-R0/10/0/10 -I1 5");
	if (GMTver >= 6)
		gmtwrite("lixo.grd", G,  scale=10, offset=-10)
		GG = gmtread("lixo.grd", grd=true, varname=:z);
		GG = gmtread("lixo.grd", varname=:z);
		GG = gmtread("lixo.grd", grd=true, layout=:TR);
		GG = gmtread("lixo.grd", grd=true, layout=:TC);
		#GG = gmtread("lixo.grd", grd=true, layer=1);	# This crashes GMT or GDAL in Linux
		@test(sum(G.z[:] - GG.z[:]) == 0)
		gmtwrite("lixo.grd", rand(5,5), id=:cf, layout=:TC)
		gmtwrite("lixo.tif", rand(UInt8,32,32,3), driver=:GTiff)
		@show("           1")
		I = gmtread("lixo.tif", img=true, layout="TCP");
		I = gmtread("lixo.tif", img=true, band=0);
		I = gmtread("lixo.tif", img=true, band=[0 1 2]);
		imshow(I, show=false)			# Test this one here because we have a GMTimage at hand
		gmtwrite("lixo.tif", mat2img(rand(UInt8,32,32,3)), driver=:GTiff)
		@show("           2")
		@test GMT.parse_grd_format(Dict(:nan => 0)) == "+n0"
		@test_throws ErrorException("Number of bands in the 'band' option can only be 1 or 3") GMT.gmtread("", band=[1 2])
		@test_throws ErrorException("Format code MUST have 2 characters and not bla") GMT.parse_grd_format(Dict(:id => "bla"))
	else
		gmtwrite("lixo.grd", G)
		GG = gmtread("lixo.grd", grd=true, varname=:z);
	end
	@show("           3")
	@test_throws ErrorException("Must select one input data type (grid, image, dataset, cmap or ps)") GG = gmtread("lixo.grd");
	cpt = makecpt(T="-6/8/1");
	gmtwrite("lixo.cpt", cpt)
	cpt = gmtread("lixo.cpt", cpt=true);
	gmtwrite("lixo.dat", [1 2 10; 3 4 20])
	D = gmtread("lixo.dat", i="0,1s10", table=true);
	@test(sum(D[1].data) == 64.0)
	gmtwrite("lixo.dat", D)
	gmt("gmtwrite lixo.cpt", cpt)		# Same but tests other code chunk in gmt_main.jl
	gmt("gmtwrite lixo.dat", D)
	gmt("write lixo.tif=gd:GTiff", mat2img(rand(UInt8,32,32,3)))
	gmt("grdinfo lixo.tif");
	@test_throws ErrorException("First argument cannot be empty. It must contain the file name to write.") gmtwrite("",[1 2]);

	@show("GMTVECTOR")
	# GMTVECTOR
	d = [0 0; 0 90; 135 45; -30 -60];
	gmtvector(d, T=:D, S="0/0", f=:g);

	# GMTWICH
	gmtwhich("lixo.dat", C=true);

	@show("GRDINFO")
	# GRDINFO
	G=gmt("grdmath", "-R0/10/0/10 -I1 5");
	r=gmt("grdinfo -C", G);
	@assert(r[1].data == [0.0  10.0  0.0  10.0  5.0  5.0  1.0  1.0  11.0  11.0])
	r2=grdinfo(G, C=true, V=true);
	@assert(r[1].data == r2[1].data)

	# GRD2CPT
	G=gmt("grdmath", "-R0/10/0/10 -I2 X");
	C=grd2cpt(G);

	# GRD2XYZ (It's tested near the end)
	#D=grd2xyz(G); # Use G of previous test
	gmtwrite("lixo.grd", G)
	D1=grd2xyz(G);
	D2=grd2xyz("lixo.grd");
	@assert(sum(D1[1].data) == sum(D2[1].data))

	# GRDBLEND
	if (GMTver >= 6)
		@show("GRD2KML")
		# GRD2KML
		G=gmt("grdmath", "-R0/10/0/10 -I1 X -fg");
		grd2kml(G, I="+", N="NULL")

		G3=gmt("grdmath", "-R5/15/0/10 -I1 X Y");
		G2=grdblend(G,G3);
	end

	# GRDCLIP
	G2=grdclip(G,above="5/6", low=[2 2], between=[3 4 4.5]);	 # Use G of previous test
	@test_throws ErrorException("Wrong number of elements in S option") G2=grdclip(G,above="5/6", low=[2], between=[3 4 4.5]);
	@test_throws ErrorException("OPT_S: argument must be a string or a two elements array.") G2=grdclip(G,above=5, low=[2 2]);

	@show("GRDCONTOUR")
	# GRDCONTOUR
	G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	C = grdcontour(G, C="+0.7", D=[]);
	@assert((size(C[1].data,1) == 21) && abs(-0.6 - C[1].data[1,1]) < 1e-8)
	# Do the same but write the file on disk first
	gmt("write lixo.grd", G)
	GG = gmt("read -Tg lixo.grd");
	C = grdcontour("lixo.grd", C="+0.7", D=[]);
	@assert((size(C[1].data,1) == 21) && abs(-0.6 - C[1].data[1,1]) < 1e-8)
	r = grdcontour("lixo.grd", cont=10, A=(int=50,labels=(font=7,)), G=(dist="4i",), L=(-1000,-1), W=((contour=1,pen="thinnest,-"), (annot=1, pen="thin,-")), T=(gap=("0.1i","0.02i"),), Vd=2);
	@test startswith(r, "grdcontour lixo.grd  -JX12c/0 -Baf -BWSen -L-1000/-1 -A50+f7 -Gd4i -T+d0.1i/0.02i -Wcthinnest,- -Wathin,- -C10")
	r = grdcontour("lixo.grd", A="50+f7p", G="d4i", W=((contour=1,pen="thinnest,-"), (annot=1, pen="thin,-")), Vd=2);
	@test startswith(r, "grdcontour lixo.grd  -JX12c/0 -Baf -BWSen -A50+f7p -Gd4i -Wcthinnest,- -Wathin,-")
	G = GMT.peaks()
	cpt = makecpt(T="-6/8/1");
	if (GMTver >= 6)
		grdcontour(G, axis="a", fmt="png", color=cpt, pen="+c", X=1, Y=1, N=true, U=[])
		grdcontour!(G, axis="a", color=cpt, pen="+c", X=1, Y=1, N=true, Vd=2)
		grdcontour!("", G, axis="a", color=cpt, pen="+c", X=1, Y=1, N=cpt, Vd=2)
	end

	# GRDCUT
	G=gmt("grdmath", "-R0/10/0/10 -I1 X Y MUL");
	G2=grdcut(G, limits=[3 9 2 8]);
	G2=grdcut("lixo.grd", limits=[3 9 2 8]);	# lixo.grd was written above in the gmtwrite test
	G2=grdcut(data="lixo.grd", limits=[3 9 2 8]);
	G2=grdcut(data=G, limits=[3 9 2 8]);

	# GRDEDIT
	grdedit(G, C=true);

	@show("GRDFFT")
	# GRDFFT
	G2=grdfft(G, upward=800); 	# Use G of previous test
	G2=grdfft(G, G, E=[]);

	# GRDFILTER
	G2=grdfilter(G, filter="m600", distflag=4, inc=0.5); # Use G of previous test

	# GRDGRADIENT
	G2=grdgradient(G, azim="0/270", normalize="e0.6");
	if (GMTver >= 6)
		G2=grdgradient(G, azim="0/270", normalize="e0.6", Q=:save, Vd=2);
	end

	# GRDHISTEQ
	G2 = grdhisteq(G, gaussian=[]);	# Use G of previous test

	# GRDLANDMASK
	G2 = grdlandmask(R="-10/4/37/45", res=:c, inc=0.1);
	G2 = grdlandmask("-R-10/4/37/45 -Dc -I0.1");			# Monolithitc

	# GRDPASTE
	G3 = gmt("grdmath", "-R10/20/0/10 -I1 X");
	G2 = grdpaste(G,G3);

	@show("GRDPROJECT")
	# GRDPROJECT	-- Works but does not save projection info in header
	G2 = grdproject(G, proj="u29/1:1", F=[], C=[]); 		# Use G of previous test
	G2 = grdproject("-Ju29/1:1 -F -C", G);					# Monolithic

	# GRDSAMPLE
	G2 = grdsample(G, inc=0.5);		# Use G of previous test

	# GRDTREND
	G  = gmt("grdmath", "-R0/10/0/10 -I1 X Y MUL");
	G2 = grdtrend(G, model=3);
	W = mat2grid(ones(Float32, size(G.z,1), size(G.z,2)));
	G2 = grdtrend(G, model=3, diff=[], trend=true);
	#G2 = grdtrend(G, model="3+r", W=W);
	G2 = grdtrend(G, model="3+r", W=(W,0), Vd=2);

	# GRDTRACK
	#G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	G = gmt("grdmath -R-2/2/-2/2 -I1 1");
	gmtwrite("lixo.grd", G)
	D = grdtrack([0 0], G);
	@assert(D[1].data == [0.0 0 1])
	D = grdtrack([0 0], G="lixo.grd");
	@assert(D[1].data == [0.0 0 1])
	D = grdtrack("lixo.grd", [0 0]);
	D = grdtrack(G, [0 0]);
	D = grdtrack([0 0], G=G);
	D = grdtrack([0 0], G=(G,G));
	@assert(D[1].data == [0.0 0 1 1])

	@show("GRDVECTOR")
	# GRDVECTOR
	G = gmt("grdmath -R-2/2/-2/2 -I0.1 X Y R2 NEG EXP X MUL");
	dzdy = gmt("grdmath ? DDY", G);
	dzdx = gmt("grdmath ? DDX", G);
	grdvector(dzdx, dzdy, I=0.2, vector=(len=0.25, stop=1, norm=0.65, shape=0.5), G=:black, W="1p", S=12)
	grdvector!(dzdx, dzdy, I=0.2, vector=(len=0.25, stop=1, norm=0.65, shape=0.5), W="1p", S=12, Vd=2)
	r = grdvector!("",dzdx, dzdy, I=0.2, vector=(len=0.25, stop=1, norm=0.65), W="1p", S=12, Vd=2);
	if (GMTver >= 6)  @test startswith(r, "grdvector  -R -J -I0.2 -S12 -Q0.25+e+n0.65 -W1p")  end
	r = grdvector!("", 1, 2, I=0.2, vec="0.25+e+n0.66", W=1, S=12, Vd=2);
	@test startswith(r, "grdvector  -R -J -I0.2 -S12 -Q0.25+e+n0.66 -W1")

	@show("GRDVOLUME")
	# GRDVOLUME
	grdvolume(G);

	# Just create the figs but no check if they are correct.
	@test_throws ErrorException("Missing input data to run this module.") grdimage("", J="X10", Vd=2)
	PS = grdimage(G, J="X10", ps=1);
	gmt("destroy")
	grdimage!(G, J="X10", Vd=2);
	grdimage!("", G, J="X10", Vd=2);
	Gr=mat2grid(rand(Float32, 128, 128)*255); Gg=mat2grid(rand(Float32, 128, 128)*255); Gb=mat2grid(rand(Float32, 128, 128)*255);
	@show("GRDIMAGE")
	grdimage(rand(Float32, 128, 128)*255, rand(Float32, 128, 128)*255, rand(Float32, 128, 128)*255, J="X10")
	grdimage(data=(Gr,Gg,Gb), J=:X10, I=mat2grid(rand(Float32,128,128)), Vd=2)
	grdimage(rand(Float32, 128, 128), shade=(default=30,), coast=(W=1,), Vd=2)
	grdimage(rand(Float32, 128, 128), colorbar=(color=:rainbow, pos=(anchor=:RM,length=8)), Vd=2)
	grdimage("lixo.grd", coast=true, colorbar=true, Vd=2)
	G = gmt("grdmath -Rg -fg -I5 X");
	gmtwrite("lixo.grd", G)
	grdimage("lixo.grd", proj=:Winkel, colorbar=true, coast=true)
	@show("GRDVIEW")
	PS = grdview(G, J="X6i", JZ=5,  I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", ps=1);
	gmt("destroy")
	grdview!("",G, J="X6i", JZ=5, I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", Vd=2);
	grdview!(G, J="X6i", JZ=5,  I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", Vd=2);
	grdview!(G, G=G, J="X6i", JZ=5,  I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", Vd=2);
	r = grdview!(G, plane=(-6,:lightgray), surftype=(surf=true,mesh=:red), view="120/30", Vd=2);
	@test startswith(r, "grdview  -R -J -p120/30 -N-6+glightgray -Qsmred")
	@test_throws ErrorException("Wrong way of setting the drape (G) option.")  grdview(rand(16,16), G=(1,2))
	if (GMTver >= 6)		# Crashes GMT5
		I = mat2grid(rand(Float32,128,128))
		grdview(rand(128,128), G=(Gr,Gg,Gb), I=I, J=:X12, JZ=5, Q=:i, view="145/30")
		gmtwrite("lixo.grd", I)
		grdview(rand(128,128), G=I, I=I, J=:X12, JZ=5, Q=:i, view="145/30")
	end

	@show("GREENSPLINE")
	# GREENSPLINE
	d = [0 6.44; 1820 8.61; 2542 5.24; 2889 5.73; 3460 3.81; 4586 4.05; 6020 2.95; 6841 2.57; 7232 3.37; 10903 3.84; 11098 2.86; 11922 1.22; 12530 1.09; 14065 2.36; 14937 2.24; 16244 2.05; 17632 2.23; 19002 0.42; 20860 0.87; 22471 1.26];
	greenspline(d, R="-2000/25000", I=100, S=:l, D=0, Vd=2)

	@show("IMSHOW")
	# IMSHOW
	imshow(rand(128,128),show=false)
	imshow(G, axis=:a, shade="+a45",show=false)
	imshow(rand(128,128), shade="+a45",show=false)
	if (GMTver >= 6)  imshow("lixo.tif",show=false)  end

	# MAKECPT
	cpt = makecpt(range="-1/1/0.1");
	@assert((size(cpt.colormap,1) == 20) && (cpt.colormap[1,:] == [0.875, 0.0, 1.0]))
	if (GMTver >= 6)
		makecpt(rand(10,1), E="", C=:rainbow);
		@test_throws ErrorException("E option requires that a data table is provided as well") makecpt(E="", C=:rainbow)
	end

	# MAPPROJECT
	mapproject([-10 40], J=:u29, C=true, F=true);
	mapproject(region=(-15,35,30,48), proj=:merc, figsize=5, map_size=true);

	# PLOT
	plot(collect(1:10),rand(10), lw=1, lc="blue", fmt=:ps, marker="circle", markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla", xlabel="Spoons", ylabel="Forks", savefig="lixo")
	plot(mat2ds(GMT.fakedata(6,6), x=:ny, color=[:red, :green, :blue, :yellow], ls=:dashdot), leg=true, label="Bla")
	plot("",hcat(collect(1:10)[:],rand(10,1)))
	plot!("",hcat(collect(1:10)[:],rand(10,1)), Vd=2)
	plot(hcat(collect(1:10)[:],rand(10,1)), Vd=2)
	plot!(hcat(collect(1:10)[:],rand(10,1)), Vd=2)
	plot!(collect(1:10),rand(10), fmt="ps")
	plot(0.5,0.5, R="0/1/0/1", Vd=2)
	plot!(0.5,0.5, R="0/1/0/1", Vd=2)
	plot(1:10,rand(10), S=(symb=:c,size=7,unit=:point), color=:rainbow, zcolor=rand(10))
	plot(1:10,rand(10)*3, S="c7p", color=:rainbow, Vd=2)
	plot(1:10,rand(10)*3, S="c7p", color=:rainbow, zcolor=rand(10)*3)
	plot(1:2pi, rand(6), xaxis=(pi=1,), Vd=2)
	plot(1:2pi, rand(6), xaxis=(pi=(1,2),), Vd=2)
	plot(1:4, rand(4,4), leg=true)
	plot([5 5], region=(0,10,0,10), frame=(annot=:a, ticks=:a, grid=5), figsize=10, symbol=:p, markerline=0.5, fill=:lightblue, E=(Y=[2 3 6 9],pen=1,cap="10p"), Vd=2);
	plot(rand(10,4), S=:c, ms=0.2, markeredgecolor=:red, ml=2, Vd=2)
	plot(rand(10,4), S=:c, ms=0.2, ml=2, W=1, Vd=2)
	@test startswith(plot!([1 1], marker=(:r, [2 3]), Vd=2), "psxy  -R -J -Sr")
	@test_throws ErrorException("Wrong number of extra columns for marker (r). Got 3 but expected 2") plot!([1 1], marker=(:r, [2 3 4]), Vd=2)
	@test startswith(plot!([1 1], marker=(:Web, [2 3], (inner=5, arc=30,radial=45, pen=(2,:red))), Vd=2), "psxy  -R -J -SW/5+a30+r45+p2,red")
	@test startswith(plot!([1 1], marker=(Web=true, inner=5, arc=30,radial=45, pen=(2,:red)), Vd=2), "psxy  -R -J -SW/5+a30+r45+p2,red")
	@test startswith(plot!([1 1], marker="W/5+a30", Vd=2), "psxy  -R -J -SW/5+a30")
	@test startswith(plot!([1 1], marker=:Web, Vd=2), "psxy  -R -J -SW")
	@test startswith(plot!([1 1], marker=:W, Vd=2), "psxy  -R -J -SW")
	@test startswith(plot([5 5], marker=(:E, 500), Vd=2), "psxy  -JX12c/8c -Baf -BWSen -R4.5/5.5/4.5/5.5 -SE-500")
	@test startswith(plot(region=(0,10,0,10), marker=(letter="blaBla", size="16p"), Vd=2), "psxy  -R0/10/0/10 -JX12c/8c -Baf -BWSen -Sl16p+tblaBla")
	@test startswith(plot([5 5], region=(0,10,0,10), marker=(bar=true, size=0.5, base=0,), Vd=2), "psxy  -R0/10/0/10 -JX12c/8c -Baf -BWSen -Sb0.5+b0")
	@test startswith(plot([5 5], region=(0,10,0,10), marker=(custom=:sun, size=0.5), Vd=2), "psxy  -R0/10/0/10 -JX12c/8c -Baf -BWSen -Sksun/0.5")
	plot([5 5 0 45], region=(0,10,0,10), marker=(pie=true, arc=15, radial=30), Vd=2)
	plot([0.5 1 1.75 5 85], region=(0,5,0,5), figsize=12, marker=(matang=true, arrow=(length=0.75, start=true, stop=true, half=:right)), ml=(0.5,:red), fill=:blue, Vd=2)
	plot([2.5 2.5], region=(0,4,0,4), figsize=12, marker=(:matang, [2 50 350], (length=0.75, start=true, stop=true, half=:right)), ml=(0.5,:red), fill=:blue, Vd=2)

	plot3d(rand(5,3), marker=:cube)
	plot3d!(rand(5,3), marker=:cube, Vd=2)
	plot3d("", rand(5,3), Vd=2)
	plot3d!("", rand(5,3), Vd=2)
	plot3d(1:10, rand(10), rand(10), Vd=2)
	plot3d!(1:10, rand(10), rand(10), Vd=2)

	@show("ARROWS")
	# ARROWS
	arrows([0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,stop=1,shape=0.5,fill=:red), J=:X14, B=:a, pen="6p")
	arrows([0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,start=:arrow,stop=:tail,shape=0.5), J=:X14, B=:a, pen="6p")
	arrows!([0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,start=:arrow,shape=0.5), pen="6p", Vd=2)
	arrows!("", [0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,start=:arrow,shape=:V, pen=(1,:red)), pen="6p", Vd=2)
	@test_throws ErrorException("Bad data type for the 'shape' option") arrows!("", [0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,justify=:center,middle=:reverse,shape='1'), pen="6p", Vd=2)
	@test occursin("-SvB4p/18p/7.5p", arrows([1 0 45 4], R="0/6/-1/1", J="x2.5", pen=(1,:blue), arrow4=(align=:mid, head=(arrowwidth="4p", headlength="18p", headwidth="7.5p"), double=true), Vd=2))
	@test occursin("-SvB4p/18p/7.5p", arrows([1 0 45 4], R="0/6/-1/1", J="x2.5", lw=1, arrow4=(align=:mid, head=("4p","18p", "7.5p"), double=true), Vd=2))
	@test occursin("-Svs4p/18p/7.5p", arrows([1 0 45 4], R="0/6/-1/1", J="x2.5", lw=1, arrow4=(align=:pt, head="4p/18p/7.5p"), Vd=2))

	# LINES
	lines([0 0; 10 20], R="-2/12/-2/22", J="M2.5", W=1, G=:red, decorated=(dist=(1,0.25), symbol=:box))
	lines([-50 40; 50 -40],  R="-60/60/-50/50", J="X10", W=0.25, B=:af, box_pos="+p0.5", leg_pos=(offset=0.5,), leg=:TL)
	lines!([-50 40; 50 -40], R="-60/60/-50/50", W=1, offset="0.5i/0.25i", vec=(size=0.65, fill=:red), Vd=2)
	lines(1:10,rand(10), W=0.25, Vd=2)
	lines!(1:10,rand(10), W=0.25, Vd=2)
	lines!("", rand(10), W=0.25, Vd=2)
	xy = gmt("gmtmath -T0/180/1 T SIND 4.5 ADD");
	lines(xy, R="-5/185/-0.1/6", J="X6i/9i", B=:af, W=(1,:red), decorated=(dist=(2.5,0.25), symbol=:star, symbsize=1, pen=(0.5,:green), fill=:blue, dec2=1))
	D = histogram(randn(1000), I=:o, W=0.1);
	lines(D, steps=(x=true,), close=(bot="",))
	x = GMT.linspace(0, 2pi);  y = cos.(x)*0.5;
	r = lines(x,y, limits=(0,6.0,-1,0.7), figsize=(40,8), pen=(lw=2,lc=:sienna), decorated=(quoted=true, n_labels=1, const_label="ai ai", font=60, curved=true, fill=:blue, pen=(0.5,:red)), par=(:PS_MEDIA, :A1), axis=(fill=220,),Vd=2);
	@test startswith(r, "psxy  -Sqn1:+f60+l\"ai ai\"+v+p0.5,red -R0/6.0/-1/0.7 -JX40/8 -B+g220 --PS_MEDIA=A1 -W2,sienna")

	# SCATTER
	sizevec = [s for s = 1:10] ./ 10;
	scatter(1:10, 1:10, markersize = sizevec, axis=:equal, B=:a, marker=:square, fill=:green)
	scatter(rand(10), leg=:bottomrigh, fill=:red)	# leg wrong on purpose
	scatter(1:10,rand(10)*3, S="c7p", color=:rainbow, zcolor=rand(10)*3, show=1, Vd=2)
	scatter(rand(50),rand(50), markersize=rand(50), zcolor=rand(50), aspect=:equal, alpha=50, Vd=2)
	scatter(1:10, rand(10), fill=:red, B=:a)
	scatter!(1:10, rand(10), fill=:red, B=:a, Vd=2)
	scatter(1:10, Vd=2)
	scatter!(1:10, Vd=2)
	scatter(rand(5,5))
	scatter!(rand(5,5), Vd=2)
	scatter("",rand(5,5), Vd=2)
	scatter!("",rand(5,5), Vd=2)
	scatter3(rand(5,5,3))
	scatter3!(rand(5,5,3), Vd=2)
	scatter3("", rand(5,5,3), Vd=2)
	scatter3!("", rand(5,5,3), Vd=2)
	scatter3(1:10, rand(10), rand(10), fill=:red, B=:a, Vd=2)
	scatter3!(1:10, rand(10), rand(10), Vd=2)

	@show("BARPLOT")
	# BARPLOT
	bar(sort(randn(10)), G=0, B=:a)
	bar(rand(20),bar=(width=0.5,), Vd=2)
	bar!(rand(20),bar=(width=0.5,), Vd=2)
	bar(1:20,  rand(20),bar=(width=0.5,), Vd=2)
	bar!(1:20, rand(20),bar=(width=0.5,), Vd=2)
	bar(rand(20),hbar=(width=0.5,unit=:c, base=9), Vd=2)
	bar(rand(20),bar="0.5c+b9",  Vd=2)
	bar(rand(20),hbar="0.5c+b9",  Vd=2)
	bar(rand(10), xaxis=(custom=(pos=1:5,type="A"),), Vd=2)
	bar(rand(10), axis=(custom=(pos=1:5,label=[:a :b :c :d :e]),), Vd=2)
	@test_throws ErrorException("Number of labels in custom annotations must be the same as the 'pos' element") bar(rand(10), frame=(custom=(pos=1:5,label=[:a :b :c :d]),), axis=:noannot, Vd=:2)
	bar((1,2,3), Vd=2)
	bar((1,2,3), (1,2,3), Vd=2)
	bar!((1,2,3), Vd=2)
	bar!((1,2,3), (1,2,3), Vd=2)
	bar([3 31], C=:lightblue, Vd=2)
	bar("", [3 31], C=:lightblue, Vd=2)
	bar!("", [3 31], C=:lightblue, frame=:noannot, Vd=2)
	men_means, men_std = (20, 35, 30, 35, 27), (2, 3, 4, 1, 2);
	x = collect(1:length(men_means));
	bar(x.-0.35/2, collect(men_means), width=0.35, color=:lightblue, limits=(0.5,5.5,0,40), frame=:none, error_bars=(y=men_std,), Vd=2)
	T = mat2ds([1.0 0.446143; 2.0 0.581746; 3.0 0.268978], text=[" "; " "; " "]);
	bar(T, color=:rainbow, figsize=(14,8), title="Colored bars", Vd=2)
	T = mat2ds([1.0 0.446143 0; 2.0 0.581746 0; 3.0 0.268978 0], text=[" "; " "; " "]);
	bar(T, color=:rainbow, figsize=(14,8), mz=[3 2 1], Vd=2)
	mat2ds([0 0],["aa"]);

	# BAR3
	G = gmt("grdmath -R-15/15/-15/15 -I1 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	gmtwrite("lixo.grd", G)
	bar3(G, lw=:thinnest)
	bar3("lixo.grd", grd=true, lw=:thinnest, Vd=2)
	bar3!(G, lw=:thinnest, Vd=2)
	bar3!("", G, lw=:thinnest, Vd=2)
	bar3(G, lw=:thinnest, bar=(width=0.085,), Vd=2)
	bar3(G, lw=:thinnest, width=0.085, nbands=3, Vd=2)
	bar3(G, region="-15/15/-15/15/-2/2", lw=:thinnest, noshade=1, Vd=2)
	bar3(rand(4,4), Vd=2)
	D = grd2xyz(G);
	bar3(D, width=0.01, Nbands=3, Vd=2)
	@test_throws ErrorException("BAR3: When first arg is a name, must also state its type. e.g. grd=true or dataset=true") bar3("lixo.grd")
	gmtwrite("lixo.gmt", D)
	@test_throws ErrorException("BAR3: When NOT providing *width* data must contain at least 5 columns.") bar3("lixo.gmt", dataset=true)

	# Test ogrread. STUPID OLD Linux for travis is still on GDAL 1.11
	#if (GMTver >= 6)
		#API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
		#GMT.gmt_ogrread(API, "lixo.gmt");
	#end

	# PROJECT
	if (GMTver >= 6)
		project(C="15/15", T="85/40", G="1/110", L="-20/60");	# Fails in GMT5
		project(nothing, C="15/15", T="85/40", G="1/110", L="-20/60");	# bit of cheating
	end

	@show("PSBASEMAP")
	# PSBASEMAP
	basemap(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth")
	basemap!(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth", Vd=2)
	basemap!("", region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth", Vd=2)
	basemap(region="416/542/0/6.2831852", proj="X-12/6.5",
	        axis=(axes=(:left_full, :bot_full), fill=:lightblue),
	        xaxis=(annot=25, ticks=5, grid=25, suffix=" Ma"),
	        xaxis2=(custom=(pos=[416.0; 443.7; 488.3; 542],
					type_=["ig Devonian", "ig Silurian", "ig Ordovician", "ig Cambrian"]),),
	        yaxis=(custom=(pos=[0 1 2 2.71828 3 3.1415926 4 5 6 6.2831852],
				   type_=["a", "a", "f", "ag e", "f", "ag @~p@~", "f", "f", "f", "ag 2@~p@~"]),),
	        par=(MAP_ANNOT_OFFSET_SECONDARY="10p", MAP_GRID_PEN_SECONDARY="2p"), Vd=2)
	r = basemap(rose=(anchor="10:35/0.7", width=1, fancy=2, offset=0.4), Vd=2);
	@test startswith(r,"psbasemap  -JX12c/0 -Baf -BWSen -Tdg10:35/0.7+w1+f2+o0.4")
	r = basemap(rose=(anchor=[0.5 0.7], width=1, fancy=2, offset=0.4), Vd=2);
	@test startswith(r,"psbasemap  -JX12c/0 -Baf -BWSen -Tdn0.5/0.7+w1+f2+o0.4")
	r = basemap(rose=(anchor=:TR, width=1, fancy=2, offset=0.4), Vd=2);
	@test startswith(r,"psbasemap  -JX12c/0 -Baf -BWSen -TdjTR+w1+f2+o0.4")
	r = basemap(rose=(anchor=:TR, width=1, fancy=2, offset=0.4), Vd=2);
	@test startswith(r,"psbasemap  -JX12c/0 -Baf -BWSen -TdjTR+w1+f2+o0.4")
	r = basemap(compass=(anchor=:TR, width=1, dec=-14, offset=0.4), Vd=2);
	@test startswith(r,"psbasemap  -JX12c/0 -Baf -BWSen -TmjTR+w1+d-14+o0.4")
	r = basemap(L=(anchor=:TR, width=1, align=:top, fancy=0.4), Vd=2);
	@test startswith(r,"psbasemap  -JX12c/0 -Baf -BWSen -LjTR+w1+at+f")
	@test startswith(basemap(frame=(annot=10, slanted=:p), Vd=2), "psbasemap  -JX12c/0 -Bpa10+ap")
	r = basemap(region=(1,1000,0,1), proj=:logx, figsize=(8,0.7), frame=(annot=1, ticks=2, grid=3, scale=:pow), Vd=2);
	@test startswith(r, "psbasemap  -R1/1000/0/1 -JX8l/0.7 -Bpa1f2g3p")
	r = basemap(region=(1,1000,0,1), proj=:logx, figsize=8, frame=(annot=1, ticks=2, scale=:pow), Vd=2)
	@test startswith(r, "psbasemap  -R1/1000/0/1 -JX8l -Bpa1f2p")
	@test_throws ErrorException("slanted option: Only 'parallel' is allowed for the y-axis") basemap(yaxis=(slanted=:o,), Vd=2)

	# PSCLIP
	d = [0.2 0.2; 0.2 0.8; 0.8 0.8; 0.8 0.2; 0.2 0.2];
	psclip(d, J="X3i", R="0/1/0/1", N=true);
	psclip!(d, J="X3i", R="0/1/0/1", Vd=2);
	psclip!("", d, J="X3i", R="0/1/0/1", Vd=2);

	@show("PSCONVERT")
	# PSCONVERT
	gmt("psbasemap -R-10/0/35/45 -Ba -P -JX10d > lixo.ps")
	if (GMTver >= 6)
		psconvert("lixo.ps", adjust=true, fmt="eps", C="-dDOINTERPOLATE")
		psconvert("lixo.ps", adjust=true, fmt="eps", C=["-dDOINTERPOLATE" "-dDOINTERPOLATE"])
	end
	psconvert("lixo.ps", adjust=true, fmt="tif")
	psconvert("lixo.ps", adjust=true, Vd=2)
	P = gmtread("lixo.ps", ps=true);
	gmtwrite("lixo.ps", P)
	psconvert(P, adjust=true, in_memory=true, Vd=2)
	gmt("psconvert lixo.ps");
	gmt("psconvert -A lixo.ps");
	gmt("write lixo.ps", P)		# Test also this case in gmt_main

	@show("PSCOAST")
	# PSCOAST
	coast(R=[-10 1 36 45], J=:M12c, B="a", shore=1, E=("PT",(10,"green")), D=:c, borders="1/0.5p")
	coast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=(("PT",(20,"green"),"+gcyan"),("ES","+gblue")), fmt="ps")
	coast(R=[-10 1 36 45], J="M12c", B="a", shore2=1, E=("PT", (0.5,"red","--"), "+gblue"), Vd=2)
	coast(R=[-10 1 36 45], J="M", B="a", shore4=1,  E="PT,+gblue", borders="a", rivers="a", Vd=2)
	coast(R="-10/0/35/45", J="M12c", W=(0.5,"red"), B=:a, N=(type=1,pen=(1,"green")), water=:blue, clip=:land, Vd=2)
	coast!(R="-10/0/35/45", J="M12c", W=(0.5,"red"), B=:a, N=(type=1,pen=(1,"green")), clip=:stop, rivers="1/0.5p", Vd=2)
	@test GMT.parse_dcw("", ((country=:PT, pen=(2,:red), fill=:blue), (country=:ES, pen=(2,:blue)) )) == " -EPT+p2,red+gblue -EES+p2,blue"
	r = coast(region=:g, proj=(name=:Gnomonic, center=(-120,35), horizon=60), frame=(annot=30, grid=15), res=:crude, area=10000, land=:tan, ocean=:cyan, shore=:thinnest, figsize=10, Vd=2);
	@test startswith(r, "pscoast  -Rg -JF-120/35/60/10 -Bpa30g15 -A10000 -Dcrude -Gtan -Scyan -Wthinnest")
	r = coast(region=:g, proj="A300/30/14c", axis=:g, resolution=:crude, title="Hello Round World", Vd=2);
	@test startswith(r, "pscoast  -Rg -JA300/30/14c -Bg -B+t\"Hello Round World\" -Dcrude")
	@test startswith(coast(R=:g, W=(level=1,pen=(2,:green)), Vd=2), "pscoast  -Rg -JX12cd/0 -Baf -BWSen -W1/2,green")
	@test startswith(coast(R=:g, W=(2,:green), Vd=2), "pscoast  -Rg -JX12cd/0 -Baf -BWSen -W2,green")
	r = coast(R=:g, N=((level=1,pen=(2,:green)), (level=3,pen=(4,:blue, "--"))), Vd=2);
	@test startswith(r, "pscoast  -Rg -JX12cd/0 -Baf -BWSen -N1/2,green -N3/4,blue,--")
	r = coast(proj=:Mercator, DCW=((country="GB,IT,FR", fill=:blue, pen=(0.25,:red)), (country="ES,PT,GR", fill=:yellow)), Vd=2);
	@test startswith(r, "pscoast  -JM12c -Baf -BWSen -EGB,IT,FR+gblue+p0.25,red -EES,PT,GR+gyellow -Da")
	@test_throws ErrorException("In Overlay mode you cannot change a fig scale and NOT repeat the projection") coast!(region=(-20,60,-90,90), scale=0.03333, Vd=2)

	@show("PSCONTOUR")
	# PSCONTOUR
	x,y,z=GMT.peaks(grid=false);
	contour([x[:] y[:] z[:]], cont=1, annot=2, axis="a")
	contour!([x[:] y[:] z[:]], cont=1, Vd=2)
	contour!([x[:] y[:] z[:]], cont=1, E="lixo", Vd=2)	# Cheating E opt because Vd=2 prevents its usage
	contour!("", [x[:] y[:] z[:]], cont=1, Vd=2)

	# PSIMAGE
	if (GMTver >= 6)
		psimage("@warning.png", D="x0.5c/0.5c+jBL+w6c", R="0/1/0/1", J=:X7)
		psimage!("@warning.png", D="x0.5c/0.5c+jBL+w6c", R="0/1/0/1", J=:X7, Vd=2)
	end

	# PSSCALE
	C = makecpt(T="-200/1000/100", C="rainbow");
	colorbar(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", fmt="ps", par=(MAP_FRAME_WIDTH=0.2,))
	colorbar!("", C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=2)
	colorbar!(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=2)
	colorbar(C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=2)
	colorbar!(C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=2)

	@show("PSHISTOGRAM")
	# PSHISTOGRAM
	histogram(randn(1000),W=0.1,center=true,B=:a,N=0, x_offset=1, y_offset=1, stamp=[], t=50)
	histogram!("", randn(1000),W=0.1,center=true,N="1+p0.5", Vd=2)
	histogram!(randn(1000),W=0.1,center=true,N=(2,(1,:red)), Vd=2)

	# PSLEGEND
	T = text_record(["P", "T d = [0 0; 1 1; 2 1; 3 0.5; 2 0.25]"]);
	legend(T, R="-3/3/-3/3", J=:X12,  D="g-1.8/2.6+w12c+jTL", F="+p+ggray")
	legend!(T, R="-3/3/-3/3", J=:X12, D="g-1.8/2.6+w12c+jTL", Vd=2)
	legend!("", T, R="-3/3/-3/3", J=:X12, D="g-1.8/2.6+w12c+jTL", Vd=2)

	# PSROSE
	data=[20 5.4 5.4 2.4 1.2; 40 2.2 2.2 0.8 0.7; 60 1.4 1.4 0.7 0.7; 80 1.1 1.1 0.6 0.6; 100 1.2 1.2 0.7 0.7; 120 2.6 2.2 1.2 0.7; 140 8.9 7.6 4.5 0.9; 160 10.6 9.3 5.4 1.1; 180 8.2 6.2 4.2 1.1; 200 4.9 4.1 2.5 1.5; 220 4 3.7 2.2 1.5; 240 3 3 1.7 1.5; 260 2.2 2.2 1.3 1.2; 280 2.1 2.1 1.4 1.3;; 300 2.5 2.5 1.4 1.2; 320 5.5 5.3 2.5 1.2; 340 17.3 15 8.8 1.4; 360 25 14.2 7.5 1.3];
	rose(data, yx=[], A=20, R="0/25/0/360", B="xa10g10 ya10g10 +t\"Sector Diagram\"", W=1, G="orange", F=1, D=1, S=4)
	rose!(data, yx=[], A=20, R="0/25/0/360", B="xa10g10 ya10g10", W=1, G="orange", D=1, S=4, Vd=2)
	rose!("",data, yx=[], A=20, R="0/25/0/360", B="xa10g10 ya10g10", W=1, G="orange", D=1, S=4, Vd=2)
	if (GMTver >= 6)
		rose(data, yx=[], A=20, I=1);		# Broken in GMT5`
	end

	@show("PSMASK")
	# PSMASK
	D = gmt("gmtmath -T-90/90/10 -N2/1 0");
	mask(D, G=:yellow, I="30m", R="-75/75/-90/90", J="Q0/7i", S="4d", T=true, B="xafg180 yafg10")
	mask!(D, G=:yellow, I="30m", R="-75/75/-90/90", J="Q0/7i", S="4d", T=true, Vd=2)
	mask!("", D, G=:yellow, I="30m", R="-75/75/-90/90", J="Q0/7i", S="4d", T=true, Vd=2)

	# PSSOLAR
	#D=solar(I="-7.93/37.079+d2016-02-04T10:01:00");
	#@assert(D[1].text[end] == "\tDuration = 10:27")
	solar(R="d", W=1, J="Q0/14c", B="a", T="dc")
	solar!(R="d", W=1, J="Q0/14c", T="dc", Vd=2)
	solar(sun=(date="2016-02-09T16:00:00",), formated=true);

	# PSTERNARY
	ternary([0.16 0.331 0.509 9.344], R="0/100/0/100/0/100", J="X6i", X=:c, B=:a, S="c0.1c");
	ternary!([0.16 0.331 0.509 9.344], R="0/100/0/100/0/100", J="X6i", shape=:square, ms=0.1, markerline=1,Vd=2);
	ternary!("", [0.16 0.331 0.509 9.344], R="0/100/0/100/0/100", J="X6i", ms=0.1, lw=1,markeredgecolor=:red,aspect=:equal, Vd=2);

	@show("PSTEXT")
	# PSTEXT
	text(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",fmt="ps",showfig="lixo.ps")
	text!(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",Vd=2)
	text!("", text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",Vd=2)
	t = ["46p A Tale of Two Cities", "32p Dickens, Charles", "24p 1812-1973"];
	pstext(text_record([3 8; 3 7; 3 6.4],t), R="0/6/0/9", J=:x1i, B=0, F="+f+jCM")
	t = ["\tIt was the best of times, it was the worst of times, it was the age of wisdom, it was the age of,",
		"",
		"\tThere were a king with a large jaw and a queen with a plain face,"];
	T = text_record(t,"> 3 5 18p 5i j");
	pstext!(T, F="+f16p,Times-Roman,red+jTC", M=true)
	pstext!(T, font=(16,"Times-Roman",:red), justify=:TC, M=true)
	@test startswith(GMT.text([1 2 3; 4 5 6], Vd=2), "pstext  -JX12c/0 -Baf -BWSen -R1/4/2/5")
	@test_throws ErrorException("TEXT: input file must have at least three columns") text([1 2; 4 5], Vd=2)

	# PSWIGGLE
	t=[0 7; 1 8; 8 3; 10 7];
	t1=gmt("sample1d -I5k", t); t2 = gmt("mapproject -G+uk", t1); t3 = gmt("math ? -C2 10 DIV COS", t2);
	wiggle(t3,R="-1/11/0/12", J="M8",B="af WSne", W="0.25p", Z="4c", G="+green", T="0.5p", A=1, Y="0.75i", S="8/1/2")
	wiggle!(t3,R="-1/11/0/12", J="M8",Z="4c", A=1, Y="0.75i", S="8/1/2", Vd=2)
	wiggle!("",t3,R="-1/11/0/12", J="M8",Z="4c", A=1, Y="0.75i", S="8/1/2", Vd=2)

	# SAMPLE1D
	d = [-5 74; 38 68; 42 73; 43 76; 44 73];
	sample1d(d, I="2c", A=:r);	

	@show("SPECTRUM1D")
	# SPECTRUM1D
	D = gmt("gmtmath -T0/10239/1 T 10240 DIV 360 MUL 400 MUL COSD");
	spectrum1d(D, S=256, W=true, par=(GMT_FFT=:brenner), N=true, i=1);

	# SPHTRIANGULATE
	D = sphtriangulate(rand(10,3), I=0.1, R="0/1/0/1");		# One dataset per triangle????

	# SPHINTERPOLATE
	sphinterpolate(rand(10,3), I=0.1, R="0/1/0/1");

	# SPHDISTANCE  (would fail with: Could not obtain node-information from the segment headers)
	G = sphdistance(R="0/10/0/10", I=0.1, Q=D, L=:k, Vd=2);	# But works with data from sph_3.sh test
	@test sphdistance(nothing, R="0/10/0/10", I=0.1, Q="D", L=:k, Vd=2) == "sphdistance  -I0.1 -R0/10/0/10 -Lk -QD"

	# MODERN
	if (GMTver >= 6)
		@test GMT.helper_sub_F("1/2") == "1/2"
		#@test GMT.helper_sub_F((size=(1,2), frac=((2,3),(3,4,5))) ) == "1/2+f2,3/3,4,5"
		@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=([1 2]), Vd=2), "-F1/2")
		@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=("1i",2), Vd=2), "-F1i/2")
		@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=(size=(1,2), frac=((2,3),(3,4,5))), name="lixo.ps", Vd=2), "-F1/2+f2,3/3,4,5")
		@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=(width=1,height=5,fwidth=(0.5,1),fheight=(10,), name="lixo"), Vd=2), "-F1/5+f0.5,1/10")
		@test GMT.helper_sub_F((width=1,)) == "1/0"
		#@test GMT.helper_sub_F((width=1,height=5,fwidth=(0.5,1),fheight=(10,))) == "1/5+f0.5,1/10"
		@test_throws ErrorException("SUBPLOT: when using 'fwidth' must also set 'fheight'") GMT.helper_sub_F((width=1,height=5,fwidth=(0.5,1)))
		@test_throws ErrorException("SUBPLOT: 'width' is a mandatory parameter") GMT.helper_sub_F((height=5,))
		@test_throws ErrorException("'frac' option must be a tuple(tuple, tuple)") subplot(grid=(1,1),  F=(size=(1,2), frac=((2,3))), Vd=2)
		@test_throws ErrorException("SUBPLOT: garbage in DIMS option") GMT.helper_sub_F([1 2 3])
		@test_throws ErrorException("SUBPLOT: 'grid' keyword is mandatory") subplot(F=("1i"), Vd=2)
		@test_throws ErrorException("Cannot call subplot(set, ...) before setting dimensions") subplot(:set, F=("1i"), Vd=2)
		subplot(name="lixo", grid="1x1", limits="0/5/0/5", frame="west", F="s7/7", title="VERY VERY");subplot(:set, panel=(1,1));plot([0 0; 1 1]);subplot(:end)
		gmtbegin("lixo.ps");  gmtend()
		gmtbegin("lixo", fmt=:ps);  gmtend()
		gmtbegin("lixo");  gmtend()
		gmtbegin();  gmtend()

		gmtbegin("inset.ps")
		basemap(region=(0,40,20,60), proj=:merc, figsize=16, frame=(annot=:afg, fill=:lightgreen))
		inset(D="jTR+w2.5i+o0.2i", F="+gpink+p0.5p", margins=0.6)
			basemap(region=:global360, J="A20/20/2i", frame=:afg)
			text(text_record([1 1],["INSET"]), font=18, region_justify=:TR, D="j-0.15i", noclip=true)
		inset(:end)
		text(text_record([0 0],[" "]), text="MAP", font=18, region_justify=:BL, D="j0.2i")
		gmtend()

		gmtbegin(); gmtfig("lixo.ps");	gmtend()
	end

	# SURFACE
	G = surface(rand(100,3) * 150, R="0/150/0/150", I=1, Ll=-100, upper=100);
	@assert(size(G.z) == (151, 151))

	# SPLITXYZ (fails)
	if (GMTver >= 6)
		splitxyz([-14.0708 35.0730 0; -13.7546 35.5223 0; -13.7546 35.5223 0; -13.2886 35.7720 0; -13.2886 35.7720 0; -12.9391 36.3711 0], C=45, A="45/15", f="g")
	end

	# TRIANGULATE
	G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1, grid=[]);

	# NEARNEIGHBOR
	G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, S=10, r=true);

	# XYZ2GRD
	D=grd2xyz(G); # Use G of previous test
	xyz2grd(D, R="0/150/0/150", I=1, r=true);
	xyz2grd(D, xlim=(0,150), ylim=(0,150), I=1, r=true);

	# TREND1D
	D = gmt("gmtmath -T10/110/1 T 50 DIV 2 POW 2 MUL T 60 DIV ADD 4 ADD 0 0.25 NRAND ADD T 25 DIV 2 MUL PI MUL COS 2 MUL 2 ADD ADD");
	trend1d(D, N="p2,F1+o0+l25", F=:xm);

	@show("TREND2D")
	# TREND2D
	trend2d(D, F=:xyr, N=3);

	@show("MISC")
	# MISC
	G = GMT.mat2grid(G.z, 0, [G.range; G.registration; G.inc]);
	G1 = gmt("grdmath -R-2/2/-2/2 -I0.5 X Y MUL");
	G2 = G1;
	G3 = G1 + G2;
	G3 = G1 + 1
	G3 = G1 - G2;
	G3 = G1 - 1
	G3 = G1 * G2;
	G3 = G1 * 2
	G3 = G1 / G2;
	G3 = G1 / 2
	G2 = GMT.mat2grid(rand(Float32,5,5))
	@test_throws ErrorException("The HDR array must have 9 elements") mat2grid(rand(4,4), 0, [0. 1 0 1 0 1])
	@test_throws ErrorException("Grids have different sizes, so they cannot be added.") G1 + G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be subtracted.") G1 - G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be multiplied.") G1 * G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be divided.") G1 / G2;
	plot(mat2ds(GMT.fakedata(6,6), x=:ny, color=:cycle), leg=true, Vd=2)
	mat2ds(rand(6,6), color=[:red :blue]);
	mat2ds(rand(5,4), x=:ny, color=:cycle, hdr=" -W1");
	mat2ds(rand(5,4), x=1:5, hdr=[" -W1" "a" "b" "c"]);

	GMT.get_datatype([]);
	GMT.get_datatype(Float32(8));
	GMT.get_datatype(UInt64(8));
	GMT.get_datatype(Int64(8));
	GMT.get_datatype(UInt32(8));
	GMT.get_datatype(Int32(8));
	GMT.get_datatype(UInt16(8));
	GMT.get_datatype(Int16(8));
	GMT.get_datatype(UInt8(8));
	GMT.get_datatype(Int8(8));
	GMT.mat2grid(rand(Float32, 10,10), 1);
	GMT.num2str(rand(2,3));
	text_record([-0.4 7.5; -0.4 3.0], ["a)", "b)"]);
	text_record(["aa", "bb"], "> 3 5 18p 5i j");
	text_record(["> 3 5 18p 5i j", "aa", "bb"]);
	text_record(Array[["aa", "bb"],["cc", "dd", "ee"]]);
	text_record([["aa", "bb"],["cc", "dd", "ee"]]);

	# TEST THE API DIRECTLY (basically to improve coverage under GMT6)
	if (GMTver >= 6)
		PS = plot(rand(3,2), ps=1);
		API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
		GMT.ps_init(API, "", PS, 0);
		@test_throws ErrorException("Failure to alloc GMT source TEXTSET for input") GMT.text_init(API, "", "aaaa", 0);
		gmt("destroy")

		# Test ogr2GMTdataset
		D = gmtconvert([1.0 2 3; 2 3 4], a="2=lolo+gPOINT");	# Ther's a bug in GMT for this. No data points are printed
		gmtwrite("lixo.gmt", D)
		#API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
		#GMT.ogr2GMTdataset(GMT.gmt_ogrread(API, "lixo.gmt"));
		rm("lixo.gmt")
	end

	GMT.linspace(1,1,100);
	GMT.logspace(1,5);
	GMT.fakedata(50,1);
	GMT.contains("aiai", "ia");
	GMT.meshgrid(1:5, 1:5, 1:5);
	fields(7);
	tic();toc()
	@test_throws ErrorException("`toc()` without `tic()`") toc()

	@show("EXAMPLES")
	# EXAMPLES
	plot(1:10,rand(10), lw=1, lc="blue", marker="square",
	markeredgecolor=:white, size=0.2, markerfacecolor="red", title="Hello World",
		xlabel="Spoons", ylabel="Forks", show=1, Vd=2)

	x = range(0, stop=2pi, length=180);	seno = sin.(x/0.2)*45;
	coast(region="g", proj="A300/30/6c", axis="g", resolution="c", land="navy")
	plot!(collect(x)*60, seno, lw=0.5, lc="red", marker="circle",
		markeredgecolor=0, size=0.05, markerfacecolor="cyan")

	G = GMT.peaks()
	grdcontour(G, cont=1, annot=2, axis="a")
	cpt = makecpt(T="-6/8/1");      # Create the color map
	grdcontour(G, axis="a", color=cpt, pen="+c", fmt=:png, savefig="lixo")

	# Remove garbage
	rm("gmt.history")
	rm("gmt.conf")
	rm("lixo.ps")
	rm("lixo.png")
	rm("lixo.eps")
	rm("lixo.grd")
	rm("lixo.tif")
	rm("lixo.cpt")
	rm("lixo.dat")
	#@static if (Sys.iswindows())  run(`rmdir /S /Q NULL`)  end

end					# End valid testing zone
