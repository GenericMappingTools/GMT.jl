@testset "COMMON OPTS" begin
	# -------------------- Test common_options ----------------------------------------
	@test GMT.get_GMTver()[1] >= v"6.0"
	GMT.__init__(true);
	GMT.dict2nt(Dict(:a =>1, :b => 2))
	@test GMT.parse_R(Dict(:xlim => (1,2), :ylim => (3,4), :zlim => (5,6)), "")[1] == " -R1/2/3/4/5/6"
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
	@test GMT.opt_R2num(" -R1/2/3/4") == [1.0, 2, 3, 4]
	@test_throws ErrorException("The only valid case to provide a number to the 'proj' option is when that number is an EPSG code, but this (1500) is clearly an invalid EPSG")  GMT.build_opt_J(1500)
	@test GMT.build_opt_J(:X5)[1] == " -JX5"
	@test GMT.build_opt_J(2500)[1] == " -J2500"
	@test GMT.build_opt_J([])[1] == " -J"
	@test GMT.arg2str((1,2,3)) == "1/2/3"
	@test GMT.arg2str(("aa",2,3)) == "aa/2/3"
	@test GMT.arg2str(Dict(:shaded => "-4p/-6p/grey20@40"), [:shaded]) == "-4p/-6p/grey20@40"
	@test GMT.arg2str(Dict(:shaded => "aa bb"), [:shaded]) == "\"aa bb\""
	@test_throws ErrorException("arg2str: argument 'arg' can only be a String, Symbol, Number, Array or a Tuple, but was DataType") GMT.arg2str(typeof(1))
	@test GMT.parse_b(Dict(:b => (ncols=2, swapp_bytes=true, little_endian=true, type=:char)), "")[2] == " -b2cw+l"
	@test GMT.parse_b(Dict(:b => (ncols=2, type=:double)), "")[2] == " -b2d"
	@test GMT.parse_b(Dict(:b => (ncols=2, type=:ai)), "")[2] == " -b2d"
	@test GMT.parse_bi(Dict(:bi => (ncols=2, type=:float)), "")[2] == " -bi2f"
	@test GMT.parse_bo(Dict(:bo => (ncols=2, type=:int16)), "")[2] == " -bo2h"
	@test GMT.parse_c(Dict(:c => (1,2)), "")[1] == " -c0,1"
	@test GMT.parse_c(Dict(:c => [1,2]), "")[1] == " -c0,1"
	@test GMT.parse_c(Dict(:c => "1,2"), "")[1] == " -c0,1"
	@test GMT.parse_c(Dict(:c => 1), "")[1] == " -c0"
	@test GMT.parse_c(Dict(:c => "1"), "")[1] == " -c0"
	@test GMT.parse_l(Dict(:l => "ai ai"), "")[2] == " -l\"ai ai\""
	@test GMT.parse_l(Dict(:l => (text="ai ai", vspace=3)), "")[2] == " -l\"ai ai\"+G3"
	@test GMT.parse_n(Dict(:n => (bicubic=true,antialiasing=true,bc=:g)), "")[2] == " -nc+bg"
	@test GMT.parse_inc(Dict(:inc => (x=1.5, y=2.6, unit="meter")),"", [:I :inc], "I") == " -I1.5e/2.6e"
	@test GMT.parse_inc(Dict(:inc => (x=1.5, y=2.6, unit="m")),"", [:I :inc], "I") == " -I1.5m/2.6m"
	@test GMT.parse_inc(Dict(:inc => (x=1.5, y=2.6, unit="data")),"", [:I :inc], "I") == " -I1.5/2.6u"
	@test GMT.parse_inc(Dict(:inc => (x=1.5, y=2.6, extend="data")),"", [:I :inc], "I") == " -I1.5+e/2.6+e"
	@test GMT.parse_inc(Dict(:inc => (x=1.5, y=2.6, unit="nodes")),"", [:I :inc], "I") == " -I1.5+n/2.6+n"
	@test GMT.parse_inc(Dict(:inc => (2,4)),"", [:I :inc], "I") == " -I2/4"
	@test GMT.parse_inc(Dict(:inc => [2 4]),"", [:I :inc], "I") == " -I2/4"
	@test GMT.parse_inc(Dict(:inc => "2"),"", [:I :inc], "I") == " -I2"
	@test GMT.parse_inc(Dict(:inc => "2"),"", [:I :inc], "") == "2"
	@test GMT.parse_JZ(Dict(:JZ => "5c"), "")[1] == " -JZ5c"
	@test GMT.parse_JZ(Dict(:Jz => "5c"), "")[1] == " -Jz5c"
	@test GMT.parse_JZ(Dict(:aspect3 => 1), " -JX10")[1] == " -JX10 -JZ10"
	@test GMT.parse_J(Dict(:J => "X5"), "", "", false)[1] == " -JX5"
	@test GMT.parse_J(Dict(:a => ""), "", "", true, true)[1] == " -J"
	@test GMT.parse_J(Dict(:J => "X", :figsize => 10), "")[1] == " -JX10"
	@test GMT.parse_J(Dict(:J => "X", :scale => "1:10"), "")[1] == " -Jx1:10"
	@test GMT.parse_J(Dict(:proj => "Ks0/15"), "")[1] == " -JKs0/15"
	@test GMT.parse_J(Dict(:scale=>"1:10"), "")[1] == " -Jx1:10"
	@test GMT.parse_J(Dict(:s=>"1:10"), "", " -JU")[1] == " -JU"
	@test GMT.parse_J(Dict(:J => "Merc", :figsize => 10), "", "", true, true)[1] == " -JM10"
	@test GMT.parse_J(Dict(:J => "+proj=merc"), "")[1] == " -J+proj=merc+width=" * split(GMT.def_fig_size, '/')[1]
	@test GMT.parse_J(Dict(:J => (name=:albers, parallels=[45 65])), "", "", false)[1] == " -JB0/0/45/65"
	@test GMT.parse_J(Dict(:J => (name=:albers, center=[10 20], parallels=[45 65])), "", "", false)[1] == " -JB10/20/45/65"
	@test GMT.parse_J(Dict(:J => "winkel"), "", "", false)[1] == " -JR"
	@test GMT.parse_J(Dict(:J => "M0/0"), "", "", false)[1] == " -JM0/0"
	@test GMT.parse_J(Dict(:J => (name=:merc,center=10)), "","", false)[1] == " -JM10"
	@test GMT.parse_J(Dict(:J => (name=:merc,parallels=10)), "","", false)[1] == " -JM0/0/10"
	@test GMT.parse_J(Dict(:J => (name=:Cyl_,center=(0,45))), "", "", false)[1] == " -JCyl_stere/0/45"
	@test_throws ErrorException("When projection arguments are in a NamedTuple the projection 'name' keyword is madatory.") GMT.parse_J(Dict(:J => (parallels=[45 65],)), "", "", false)
	@test_throws ErrorException("When projection is a named tuple you need to specify also 'center' and|or 'parallels'") GMT.parse_J(Dict(:J => (name=:merc,)), "", "", false)
	r = GMT.parse_params(Dict(:par => (MAP_FRAME_WIDTH=0.2, IO=:lixo, OI="xoli")), "");
	@test r == " --MAP_FRAME_WIDTH=0.2 --IO=lixo --OI=xoli"
	@test GMT.parse_params(Dict(:par => (:MAP_FRAME_WIDTH,0.2)), "") == " --MAP_FRAME_WIDTH=0.2"
	@test GMT.parse_params(Dict(:par => ("MAP_FRAME_WIDTH",0.2)), "") == " --MAP_FRAME_WIDTH=0.2"
	@test GMT.opt_pen(Dict(:lw => 5, :lc => :red),'W', nothing) == " -W5,red"
	@test GMT.opt_pen(Dict(:lw => 5),'W', nothing) == " -W5"
	@test GMT.opt_pen(Dict(:a => (10,:red)),'W', [:a]) == " -W10,red"
	@test_throws ErrorException("Nonsense in W option") GMT.opt_pen(Dict(:a => [1 2]),'W', [:a])
	@test GMT.get_color(((1,2,3),)) == "1/2/3"
	@test GMT.get_color(((1,2,3),100)) == "1/2/3,100"
	@test GMT.get_color(((0.1,0.2,0.35),)) == "26/51/89"
	@test GMT.get_color([1 2 3]) == "1/2/3"
	@test GMT.get_color([0.4 0.5 0.8; 0.1 0.2 0.75]) == "102/128/204,26/51/191"
	@test GMT.get_color([1 2 3; 3 4 5; 6 7 8]) == "1/2/3,3/4/5,6/7/8"
	@test GMT.get_color(:red) == "red"
	@test GMT.get_color((:red,:blue)) == "red,blue"
	@test GMT.get_color((200,300)) == "200,300"
	@test_throws ErrorException("GOT_COLOR, got an unsupported data type") GMT.get_color([1,2])
	@test_throws ErrorException("Color tuples must have only one or three elements") GMT.get_color(((0.2,0.3),))
	@test GMT.parse_unit_unit("data") == "u"
	@test GMT.parse_units((2,:p)) == "2p"
	@test GMT.add_opt((a=(1,0.5),b=2), (a="+a",b="-b")) == "+a1/0.5-b2"
	@test GMT.add_opt((symb=:circle, size=7, unit=:point), (symb="1", size="", unit="1")) == "c7p"
	@test GMT.add_opt(Dict(:L => "pen"), "", "L", [:L], (pen="_+p",)) == " -L+p"
	@test GMT.add_opt_1char("", Dict(:N=>"abc"), [[:N :geod2aux]]) == " -Na"
	@test GMT.add_opt_1char("", Dict(:N => ("abc", "sw", "x"), :Q=>"datum"), [[:N :geod2aux], [:Q :list]]) == " -Nasx -Qd"
	r = GMT.add_opt_fill("", Dict(:G=>(inv_pattern=12,fg="white",bg=[1,2,3], dpi=10) ), [:G :fill], 'G');
	@test r == " -GP12+b1/2/3+fwhite+r10"
	@test GMT.add_opt_fill("", Dict(:G=>:red), [:G :fill], 'G') == " -Gred"
	@test_throws ErrorException("For 'fill' option as a NamedTuple, you MUST provide a 'patern' member") GMT.add_opt_fill("", Dict(:G=>(inv_pat=12,fg="white")), [:G], 'G')
	d = Dict(:offset=>5, :bezier=>true, :cline=>"", :ctext=>true, :pen=>("10p",:red,:dashed));
	@test GMT.add_opt_pen(d, [:W :pen], "W") == " -W10p,red,dashed+cl+cf+s+o5"
	d = Dict(:W=>(offset=5, bezier=true, cline="", ctext=true, pen=("10p",:red,:dashed), arrow=(lenght=0.1,)));
	@test GMT.add_opt_pen(d, [:W :pen], "W") == " -W10p,red,dashed+cl+cf+s+o5+v"
	GMT.add_opt_cpt(Dict(:a=>1), "", [:b], 'A', 0, nothing, nothing, false, true, "-T0/10/1");
	GMT.add_opt_cpt(Dict(:a=>:red), "", [:a], 'A', 0, nothing, nothing, false, true, "-T0/10/1");

	r = vector_attrib(len=2.2,stop=[],norm="0.25i",shape=:arrow,half_arrow=:right,
	                  justify=:end,fill=:none,trim=0.1,endpoint=true,uv=6.6);
	@test r == "2.2+e+je+r+g-+n0.25i+h1+t0.1+s+z6.6"

	r = decorated(dist=("0.4i",0.25), symbol=:arcuate, pen=2, offset="10i", right=1);
	@test r == " -Sf0.4i/0.25+r+S+o10i+p2"
	r = decorated(dist=("0.8i","0.1i"), symbol=:star, symbsize=1, pen=(0.5,:green), fill=:blue, n_data=20, nudge=1, debug=1, dec2=1);
	@test r == " -S~d0.8i/0.1i:+sa1+d+gblue+n1+w20+p0.5,green"
	r = decorated(n_symbols=5, symbol=:star, symbsize=1, pen=(0.5,:green), fill=:blue, quoted=1);
	@test r == " -Sqn5:+p0.5,green"
	GMT.decorated((symbol="aiai",))		# Trigger a warning

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
	GMT.parse_quoted(Dict(:label => 1),"")		# Trigger a warning
	GMT.helper_arrows(Dict(:geovec => "bla"));
	GMT.helper_arrows(Dict(:vecmap => "bla"));

	@test GMT.font(("10p","Times", :red)) == "10p,Times,red"
	r = text(text_record([0 0], "TopLeft"), R="1/10/1/10", J=:X10, F=(region_justify=:MC,font=("10p","Times", :red)), Vd=dbg2);
	ind = findfirst("-F", r); @test GMT.strtok(r[ind[1]:end])[1] == "-F+cMC+f10p,Times,red"

	@test GMT.build_pen(Dict(:lw => 1, :lc => [1,2,3])) == "1,1/2/3"
	@test GMT.parse_pen((0.5, [1 2 3])) == "0.5,1/2/3"

	@test GMT.helper0_axes((:left_full, :bot_full, :right_ticks, :top_bare, :up_bare)) == "WSetu"
	d=Dict(:xaxis => (axes=:WSen,title=:aiai, label=:ai, annot=:auto, ticks=[], grid=10, annot_unit=:ISOweek,seclabel=:BlaBla), :xaxis2=>(annot=5,ticks=1), :yaxis=>(custom="lixo.txt",), :yaxis2=>(annot=2,));
	@test GMT.parse_B(d, "")[1] == " -Bsya2 -Bsxa5f1 -Bpyclixo.txt -BpxaUfg10 -Bpx+lai+sBlaBla -BWSen+taiai"
	@test GMT.parse_B(Dict(:B=>:same), "")[1] == " -B"
	@test GMT.parse_B(Dict(:title => :bla), "")[1] == " -Baf -BWSen+tbla"
	@test GMT.parse_B(Dict(:frame => :auto, :title => :bla), "")[1] == " -Baf -BWSen+tbla"
	@test GMT.parse_B(Dict(:B=>:WS), "")[1] == " -Baf -BWS"
	@test GMT.parse_B(Dict(:title => "bla"), "", " -Baf")[1] == " -Baf -B+tbla"
	@test GMT.parse_B(Dict(:frame => (annot=10, title="Ai Ai"), :grid => (pen=2, x=10, y=20)), "", " -Baf -BWSen")[1] == " -Bpa10 -Byg20 -Bxg10 -BWSen+t\"Ai Ai\""
	@test GMT.parse_B(Dict(:frame => (axes=(:left_full, :bottom_full, :right_full, :top_full), annot=10)), "")[1] == " -Bpa10 -BWSEN"
	@test GMT.parse_B(Dict(:xaxis => (axes=:full, annot=10)), "")[1] == " -Bpxa10 -BWSEN"
	@test GMT.parse_B(Dict(:frame => (fill=220,)), "", " -Baf -Bg -BWSne")[1] == " -Baf -Bg -BWSne+g220"
	@test GMT.parse_B(Dict(:frame => :full), "")[1] == " -Baf -BWSEN"
	GMT.helper2_axes("lolo");
	@test_throws ErrorException("Custom annotations NamedTuple must contain the member 'pos'") GMT.helper3_axes((a=0,),"","")

	@test GMT.consolidate_Baxes(" -Baf -BWSen -BpxaUfg10 -BWSen+taiai -Bpx+lai+sBlaBla -Bpyclixo.txt -Bsxa5f1") ==
		" -BWSen -BpxaUfg10 -BWSen+taiai -Bpx+lai+sBlaBla -Bpyclixo.txt -Bsxa5f1"
	@test GMT.consolidate_Baxes(" -Baf -Bza -BWSrt -Bpxapi2f0.5 -Bpx+lpis -Bpya1 -Bpy+a60") ==
		" -Byf -Bza -BWSrt -Bpxapi2f0.5+lpis -Bpya1+a60"
	@test GMT.helper_consolidate_B("","a",false,false) == ""
	@test GMT.consolidate_Bframe(" -Bpx+lx -B+gwhite -Baf -BWSen -By+lx") == " -Bpx+lx -Baf -By+lx -BWSen+gwhite"
	@test GMT.consolidate_Bframe(" -Bpx+lx -Bpy+lx -BWSrt+gwhite") == " -Bpx+lx -Bpy+lx -BWSrt+gwhite"
	@test GMT.consolidate_Bframe(" -Bpx+lx -BWSrt+gwhite -Bpy+lx") == " -Bpx+lx -Bpy+lx -BWSrt+gwhite"

	d=Dict(:L => (pen=(lw=10,lc=:red),) );
	@test GMT.add_opt(d, "", "", [:L], (pen=("+p",GMT.add_opt_pen),) ) == "+p10,red"
	r = psxy([0.0, 1],[0, 1.1], L=(pen=(10,:red),bot=true), Vd=dbg2);
	@test startswith(r,"psxy  -JX" * GMT.def_fig_size * " -Baf -BWSen -R-0.04/1.04/-0.04/1.12 -L+p10,red+yb")
	r = psxy([0.0, 1],[0, 1.1], L=(pen=(lw=10,cline=true),bot=true), Vd=dbg2);
	@test startswith(r,"psxy  -JX" * GMT.def_fig_size * " -Baf -BWSen -R-0.04/1.04/-0.04/1.12 -L+p10+cl+yb")
	@test startswith(psxy([0.0, 1],[0, 1.1], figsize=(10,12), aspect=:equal, Vd=dbg2), "psxy  -JX10/12")
	@test startswith(psxy([0.0, 1],[0, 1.1], figsize=10, aspect=:equal, Vd=dbg2), "psxy  -JX10/0")
	@test startswith(psxy([0.0, 1],[0, 1.1], aspect=:equal, Vd=dbg2), "psxy  -JX" * split(GMT.def_fig_size, '/')[1] * "/0")
	psxy!([0 0; 1 1.1], Vd=dbg2);
	psxy!("", [0 0; 1 1.1], Vd=dbg2);
	GMT.get_marker_name(Dict(:y => "y"), nothing, [:y], false)
	@test GMT.line_decorated_with_symbol(Dict()) == " -S~d0.88:+sc0.11+gwhite+p0.75,black"
	@test_throws ErrorException("Argument of the *bar* keyword can be only a string or a NamedTuple.") GMT.parse_bar_cmd(Dict(:a => 0), :a, "", "")

	@test_throws ErrorException("Custom annotations NamedTuple must contain the member 'pos'") GMT.helper3_axes((post=1:5,), "p", "x")
	GMT.helper3_axes(1,"","")		# Trigger a warning

	dt = collect(Dates.DateTime(Dates.now()):Dates.Month(6):Dates.DateTime(Dates.now() + Dates.Year(10)));
	GMT.read_data(Dict{Symbol, Any}(), "", "", dt)
	GMT.read_data(Dict{Symbol, Any}(), "", "", [dt rand(length(dt))])

	GMT.round_wesn([1.333 17.4678 6.66777 33.333], true);
	GMT.round_wesn([1 1 2 2]);
	GMT.round_wesn([1. 350 1. 180], true)
	GMT.round_wesn([0. 1.1 0. 0.1], true)

	GMT.GMTdataset([0.0 0]);
	GMT.GMTdataset([0.0 0], Array{String,1}());

	img16 = rand(UInt16, 16, 16, 3);
	I = GMT.mat2img(img16);
	img16 = rand(UInt16, 4, 4, 3);
	I = GMT.GMTimage("", "", 0, [1.,4,1,4,0,255], [1., 1], 1, NaN, "", String[], collect(1.:4),collect(1.:4),zeros(3),img16, vec(zeros(Clong,1,3)), 0, Array{UInt8,2}(undef,1,1), "TCBa", 0)
	GMT.mat2img(I);
	GMT.mat2img(img16, histo_bounds=8440);
	GMT.mat2img(img16, histo_bounds=[8440 13540]);
	GMT.mat2img(img16, histo_bounds=[8440 13540 800 20000 1000 30000]);
	GMT.mat2img(rand(UInt16,32,32,3),stretch=:auto);
	GMT.mat2img(img16, I)

	D = mat2ds([0 0; 1 1],["a", "b"]);	D.header = "a";
	GMT.make_zvals_vec(D, ["a", "b"], [1,2]);
	GMT.edit_segment_headers!([D], [1], "0")
	GMT.edit_segment_headers!(D, [1], "0")

	@test_throws ErrorException("Bad 'stretch' argument. It must be a 1, 2 or 6 elements array and not 3") GMT.mat2img(img16, histo_bounds=[8440 13540 0]);
	@test_throws ErrorException("Memory layout option must have 3 characters and not 1") GMT.parse_mem_layouts("-%1")
	@test_throws ErrorException("Memory layout option must have at least 2 chars and not 1") GMT.parse_mem_layouts("-&1")
	@test GMT.parse_mem_layouts("-&BR")[3] == "BR"
	@test_throws ErrorException("parse_arg_and_pen: Nonsense first argument") GMT.parse_arg_and_pen(([:a],0))
	@test_throws ErrorException("GMT: No module by that name -- bla -- was found.") gmt("bla")
	#@test_throws ErrorException("grd_init: input (Int64) is not a GRID container type") GMT.grid_init(C_NULL,0,0)
	@test_throws ErrorException("image_init: input is not a IMAGE container type") GMT.image_init(C_NULL,0)
	@test_throws ErrorException("Bad family type") GMT.GMT_Alloc_Segment(C_NULL, -1, 0, 0, "", C_NULL)
	#@test_throws ErrorException("Unknown family type") GMT.GMT_Create_Data(C_NULL, -99, 0, 0)
	@test_throws ErrorException("Expected a PS structure for input") GMT.ps_init(C_NULL, 0, 0)
	@test_throws ErrorException("size of x,y vectors incompatible with 2D array size") GMT.grdimg_hdr_xy(rand(3,3), 0, 0, [1 2], [1])
	GMT.strncmp("abcd", "ab", 2)
	GMT.parse_proj((name="blabla",center=(0,0)))

	@test GMT.parse_i(Dict(:i=>(0,1,2,2)), "")[1] == " -i0,1,2,2"
	@test GMT.parse_j(Dict(:spheric_dist => "f"), "")[1] == " -jf"
	@test GMT.parse_t(Dict(:t=>0.2), "")[1] == " -t20.0"
	@test GMT.parse_t(Dict(:t=>20), "")[1]  == " -t20"
	@test GMT.parse_contour_AGTW(Dict(:A => [1]), "")[1] == " -A1,"
	GMT.helper2_axes("");
	@test GMT.axis(ylabel="bla")[1] == " -Bpy+lbla";
	@test GMT.axis(Yhlabel="bla")[1] == " -Bpy+Lbla";
	@test GMT.axis(scale="exp")[1] == " -Bpp";
	@test GMT.axis(phase_add=10)[1] == " -Bp+10";
	@test GMT.axis(phase_sub=10)[1] == " -Bp-10";

	@test GMT.parse_grid(Dict(), (z=25,)) == " -Bzg25"
	@test GMT.parse_grid(Dict(), ()) == " -Bg"
	@test GMT.parse_grid(Dict(), (xyz=1,)) == " -Bg -Bzg"
	@test GMT.parse_grid(Dict(), "x") == " -Bxg"
	@test GMT.parse_grid(Dict(), "x25") == " -Bxg25"
	@test GMT.parse_grid(Dict(), "y25") == " -Byg25"
	@test GMT.parse_grid(Dict(), "xyz") == " -Bg -Bzg"
	@test GMT.parse_grid(Dict(), :on) == " -Bg"
	r = coast(region=:global, proj=:Winkel, par=(MAP=1,), grid=(pen=:red,), Vd=2)
	@test occursin("--MAP=1 --MAP_GRID_PEN_PRIMARY=red", r)

	r,o = GMT.prepare2geotif(Dict(:geotif => :trans), ["pscoast  -Rd -JX12cd/0 -Baf -BWSen -W0.5p -Da"], "", false);
	@test startswith(r[1],"pscoast  -Rd -JX30cd/0 -W0.5p -Da  -B0 --MAP_FRAME_TYPE=inside --MAP_FRAME_PEN=0.1,254")
	@test o == " -TG -W+g"
	r,o = GMT.prepare2geotif(Dict(:kml => :trans), ["pscoast  -Rd -JX12cd/0 -Baf -BWSen -W0.5p -Da"], "", false);
	@test startswith(r[1],"pscoast  -Rd -JX30cd/0 -W0.5p -Da  -B0 --MAP_FRAME_TYPE=inside --MAP_FRAME_PEN=0.1,254")
	@test o == " -TG -W+k"
	o = GMT.prepare2geotif(Dict(:kml => "+tLoLo"), ["pscoast  -Rd -JX12cd/0 -Baf -W0.5p -Da"], "", false)[2];
	@test o == " -TG -W+k+tLoLo"
	o = GMT.prepare2geotif(Dict(:kml => (title=:Lolo, layer=:bla, fade=(1,2), URL="http")), ["pscoast  -Rd -JX12 -Baf -W0.5p -Da"], "", false)[2];
	@test o == " -TG -W+k+tLolo+nbla+f1/2+uhttp"
	coast(region=:global, kml=:trans, proj=:merc,Vd=dbg2)

	@test (GMT.check_axesswap(Dict(:axesswap => (y=1,)), "?") == "-?")
	@test (GMT.check_axesswap(Dict(:axesswap => ("x", :y)), "?/?") == "-?/-?")
	@test (GMT.check_axesswap(Dict(:axesswap => (xy=1,)), "?/?") == "-?/-?")
	@test (GMT.check_axesswap(Dict(:axesswap => ("xy")), "?/?") == "-?/-?")
	@test (GMT.check_axesswap(Dict(:axesswap => ("y")), "?/?") == "?/-?")

	@test (GMT.parse_opt_range(Dict(:T => (1,2,0.1,:num)), "", "")[1] == "1/2/0.1+n")
	@test (GMT.parse_opt_range(Dict(:T => (1,2,0.1,:num)), "", "T")[1] == " -T1/2/0.1+n")
	@test (GMT.parse_opt_range(Dict(:T => (1,2,0.1,:log1)), "")[1] == "1/2/0.1+l")
	@test (GMT.parse_opt_range(Dict(:T => [1]), "")[1] == "1,")
	GMT.parse_opt_range(Dict(:T => (1,2,0.1,:mum,:log2)), "")[1]	# Prints a warning
	
	GMT.round_datetime([DateTime(2013,1,1), DateTime(2013,1,1,0,0,1)]);

	GMT.GMT_PEN();
	GMT.GMT_PEN(0.0, 0.0, (0.0, 0.0, 0.0, 0.0), map(UInt8, (repeat('\0', 128)...,)), 0, 0, (pointer([0]), pointer([0])));

	GMT.guess_proj([0.0 0.0], [0.0 0.0])
	GMT.guess_proj([0., 20.], [0.0, 20.])
	GMT.guess_proj([0., 20.], [35.0, 45.])
	GMT.guess_proj([0., 20.], [80.0, 90.])
	GMT.guess_proj([0., 20.], [-90.0, -80.])
	GMT.guess_proj([0., 20.], [-6.0, 90.])
	GMT.guess_proj([0., 20.], [-30.0, 30.])
	GMT.guess_proj([0., 20.], [-40.0, 60.])
	GMT.guess_WESN(Dict(:p=>(350,2)), "")
	GMT.guess_WESN(Dict(:p=>"350/2"), "")
	GMT.parse_q(Dict(:p=>(350,2)), "")

	@test_throws ErrorException("Only integer or floating point types allowed in input. Not this: Char") GMT.dataset_init(GMT.API, ' ', [0])
	@test_throws ErrorException("Wrong type (Int64) for the 'text' argin") GMT.text_record(rand(2,2), 0)

	GMT.show_non_consumed(Dict(:lala => 0), "prog");
	GMT.dbg_print_cmd(Dict(:lala => 0, :Vd=>2), "prog");

	GMT.justify("aiai")		# A warning

	GMT.grid2pix(GMT.peaks())
	GMT.grid2pix([0., 1, 0, 1, 0, 1, 1, 1, 1], pix=false)

	gmthelp([:n :sphinterpolate])
	gmthelp(:wW)

	# Test here is to the showfig fun
	grdimage([1 2;3 4])
	showfig(savefig="lixo.png",show=false)

	y = [NaN 2 3 4;5 6 NaN 8;9 10 11 12];
	@test nanmean(y,1) == [7.0  6.0  7.0  8.0]
	nanstd(y,1)

	gmtbegin()
	GMT.gmt_restart(false)
	resetGMT()
end