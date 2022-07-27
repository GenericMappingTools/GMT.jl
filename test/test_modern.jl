println("	MODERN")
@test GMT.helper_sub_F("1/2") == "1/2"
println("    SUBPLOT1")
subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=([1 2]), name=:png)
@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=([1 2]), Vd=dbg2), "-F1/2")
@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=("1i",2), Vd=dbg2), "-F1i/2")
@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=(figsize=(1,2), frac=((2,3),(3,4,5))), figname="lixo.ps", Vd=dbg2), "-Ff1/2+f2,3/3,4,5")
@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", F=(width=1,height=5,fwidth=(0.5,1),fheight=(10,), fill=:red, outline=(3,:red)), Vd=dbg2), "-F1/5+f0.5,1/10+gred+p3,red")
@test endswith(subplot(grid=(1,1), limits="0/5/0/5", frame="west", dims=(panels=((2,4),(2.5,5,1.25)),fill=:red), Vd=dbg2), "-Fs2,4/2.5,5,1.25+gred")
@test endswith(subplot(grid=(1,1), limits="0/5/0/5", F=(panels=((5,8),8),), Vd=dbg2), "-Fs5,8/8")
@test GMT.helper_sub_F((width=1,)) == "1/1"
@test GMT.helper_sub_F((width=1,height=5,fwidth=(0.5,1),fheight=(10,))) == "1/5+f0.5,1/10"
@test_throws ErrorException("SUBPLOT: when using 'fwidth' must also set 'fheight'") GMT.helper_sub_F((width=1,height=5,fwidth=(0.5,1)))
@test_throws ErrorException("'frac' option must be a tuple(tuple, tuple)") subplot(grid=(1,1),  F=(size=(1,2), frac=((2,3))), Vd=dbg2)
@test_throws ErrorException("SUBPLOT: garbage in DIMS option") GMT.helper_sub_F([1 2 3])
@test_throws ErrorException("SUBPLOT: 'grid' keyword is mandatory") subplot(F=("1i"), Vd=dbg2)
GMT.IamSubplot[1] = false
@test_throws ErrorException("Cannot call subplot(set, ...) before setting dimensions") subplot(:set, F=("1i"), Vd=dbg2)
println("    SUBPLOT2")
subplot(name="lixo", fmt=:ps, grid="1x1", limits="0/5/0/5", frame="west", F="s7/7", title="VERY VERY");subplot(:set, panel=(1,1));plot([0 0; 1 1]);subplot(:end)
gmtbegin("lixo.ps");  gmtend()
gmtbegin("lixo", fmt=:ps);  gmtend()
gmtbegin("lixo");  gmtend()
gmtbegin();  gmtend()

println("    BEGINEND")
gmtbegin("lixo.ps")
	basemap(region=(0,40,20,60), proj=:merc, figsize=16, frame=(annot=:afg, fill=:lightgreen))
	inset(D="jTR+w2.5i+o0.2i", F="+gpink+p0.5p", margins=0.6)
	basemap(region=:global360, J="A20/20/2i", frame=:afg)
	text(text_record([1 1],["INSET"]), font=18, region_justify=:TR, D="j-0.15i", noclip=true)
	inset(:end)
	text(text_record([0 0; 1 1.1],[" ";" "]), text="MAP", font=18, region_justify=:BL, D="j0.2i")
gmtend()

gmtbegin(); gmtfig("lixo.ps -Vq");	gmtend()

println("    MOVIE")
movie("main_sc.jl", pre="pre_sc.jl", C="7.2ix4.8ix100", N=:anim04, T="flight_path.txt", L="f+o0.1i", F=:mp4, A="+l+s10", Sf="", Vd=dbg2)
@test GMT.helper_fgbg("", "bla", "bla", " -Sf") == " -Sfbla"
@test_throws ErrorException("bla script has nothing useful") GMT.helper_fgbg("", rand, "bla", " -Sf")
GMT.resetGMT()		# This one is needed to reset the broken state left by calling helper_fgbg() directly
if (Sys.iswindows())
	rm("pre_script.bat");		rm("main_script.bat")
else
	rm("pre_script.sh");		rm("main_script.sh")
end
println("    EVENTS")
events("", R=:g, J="G200/5/6i", B=:af, S="E-", C=true, T="2018-05-01T", E="s+r2+d6", M=((size=5,coda=0.5),(intensity=true,)), Vd=dbg2);