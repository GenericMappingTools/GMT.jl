coast(region=[110 140 20 35], 
      proj=(name=:Albers, center=[125 20], parallels=[25 45]),
      frame=:ag,
      resolution=:low,
      area=250,
      land=:green,
      shore=:thinnest,
      fmt=:png, savefig="1")

coast(region=[-88 -70 18 24], proj=(name=:eqdc, center=[-79 21], parallels=[19 23]),
      frame=:ag, res=:intermediate, borders=(type=1,pen=("thick","red")), land=:green,
      shore=:thinnest, fmt=:png, savefig="2")

coast(region=[-130 -70 24 52], proj=(name=:lambertConic, center=[-100 35], parallels=[33 45]),
      frame=:ag, res=:low, borders=((type=1, pen=("thick","red")), (type=2, pen=("thinner",))),
      area=500, land=:tan, water=:blue, shore=(:thinnest,:white), fmt=:png, savefig="3")

coast(region=(-180,-20,0,90), proj=:poly, xaxis=(annot=30,grid=10), yaxis=(annot=10,grid=10),
      res=:crude, area=1000, land=:lightgray, shore=:thinnest, figsize=10, fmt=:png, savefig="4")

coast(region="0/-40/60/-10+r", proj=(name=:laea, center=[30,-30]), frame=:ag, res=:low,
      area=500, land=(pattern=10,dpi=300), shore=:thinnest, figsize=10, fmt=:png, savefig="5")
gmt("destroy")

coast(region=:g, proj=(name=:laea, center=[280,30]), frame=:g, res=:crude, area=1000,
      land=:navy, figsize=8, fmt=:png, savefig="6")

coast(region=(-30,30,60,72), proj=(name=:Stereographic, center=[0,90], paralles=60),
      frame=:a10g, res=:low, area=250, land=:royalblue, water=:seashell,
      figscale="1:30000000", fmt=:png, savefig="7")

coast(region="-25/59/70/72+r", proj=(name=:stereographic, center=(10,90)), frame=:a20g, res=:low,
      area=250, land=:darkbrown, shore=:thinnest, water=:lightgray, figsize=11, fmt=:png, savefig="8")

coast(region="100/-42/160/-8r", proj=(name=:stereographic, center=(130,-30)), frame=:ag, res=:low,
      area=500, land=:green, ocean=:lightblue, shore=:thinnest, figsize=10, fmt=:png, savefig="1")


coast(region=:g, proj="G4/52/230/90/60/180/60/60", xaxis=(annot=2,grid=2), yaxis=(annot=1,grid=1),
      rivers=:all, res=:intermediate, land=:lightbrown, ocean=:lightblue, shore=:thinnest, figsize=10,
      par=(:MAP_ANNOT_MIN_SPACING,0.65), fmt=:png, savefig="9")

coast(region=:g, proj=(name=:ortho, center=(-75,41)), frame=:g, res=:crude, area=5000,
      land=:pink, ocean=:thistle, figsize=10, fmt=:png, savefig="10")

coast(region=:g, proj=(name=:azimuthalEquidistant, center=(-100,40)), frame=:g,
      res=:crude, area=10000, land=:lightgray, shore=:thinnest, figsize=10, fmt=:png, savefig="11")

coast(region=:g, proj=(name=:Gnomonic, center=(-120,35), horizon=60),
      frame=(annot=30, grid=15), res=:crude, area=10000, land=:tan, ocean=:cyan,
      shore=:thinnest, figsize=10, fmt=:png, savefig="12")

coast(region=(0,360,-70,70), proj=:Mercator, xaxis=(annot=60,ticks=15), yaxis=(annot=30,ticks=15),
      res=:crude, area=:5000, land=:red, scale=0.03, par=(:MAP_FRAME_TYPE,"fancy+"), fmt=:png, savefig="13")

coast(region="20/30/50/45r", proj=(name=:tmerc, center=35), frame=:ag, res=:low,
      area=250, land=:lightbrown, ocean=:seashell, shore=:thinnest, scale=0.45, fmt=:png, savefig="14")

coast(region=(0,360,-80,80), proj=(name=:tmerc, center=[330 -45]),
      frame=(annot=30, grid=:auto, axes=:WSne), res=:crude, area=2000, land=:black,
      water=:lightblue, figsize=9, fmt=:png, savefig="15")

coast(region="270/20/305/25+r", proj=(name=:omercp, center=[280 25.5], parallels=[22 69]),
      frame=:ag, res=:i, area=250, shore=:thinnest, land=:burlywood, water=:azure,
      rose="jTR+w1+f2+l+o0.4", figsize=12, par=(FONT_TITLE=8, MAP_TITLE_OFFSET=0.12), fmt=:png, savefig="16")

coast(region="7:30/38:30/10:30/41:30r", proj=(name=:Cassini, center=[8.75 40]),
      frame=:afg, map_scale="jBR+c40+w100+f+o0.4/0.5", land=:springgreen,
      res=:high, water=:azure, shore=:thinnest, rivers=(:all,:thinner), figsize=6,
      par=(:FONT_LABEL,12), fmt=:png, savefig="17")

coast(region=:g, proj=:equidistCylindrical, frame=(annot=60, ticks=30, grid=30),
      res=:crude, area=5000, land=:tan4, water=:lightcyan, figsize=12, fmt=:png, savefig="18")

coast(region=(-145,215,-90,90), proj=(name=:cylindricalEqualArea, center=(35,30)),
      frame=(annot=45, grid=45), res=:crude, area=10000, water=:dodgerblue,
      shore=:thinnest, figsize=12, fmt=:png, savefig="19")

coast(region=(-90,270,-80,90), proj=:Miller, xaxis=(annot=45,grid=45),
      yaxis=(annot=30,grid=30), res=:crude, area=10000, land=:khaki, water=:azure,
      shore=:thinnest, scale="1:400000000", fmt=:png, savefig="20")


coast(region=(-180,180,-60,80), proj=(name=:cylindricalStereographic, center=(0,45)),
      xaxis=(annot=60,ticks=30, grid=30), yaxis=(annot=30,grid=30), res=:crude,
      area=5000, shore=:black, land=:seashell4, ocean=:antiquewhite1, figsize=12, fmt=:png, savefig="21")

coast(region=:g, proj=:Hammer, frame=:g, res=:crude, area=10000, land=:black,
	  ocean=:cornsilk, figsize=12, fmt=:png, savefig="22")

coast(region=:d, proj=:Mollweide, frame=:g, res=:crude, area=10000, land=:tomato1,
	  water=:skyblue, figsize=12, fmt=:png, savefig="23")

coast(region=:d, proj=:Winkel, frame=:g, res=:crude, area=10000, land=:burlywood4,
	  water=:wheat1, figsize=12, fmt=:png, savefig="24")

coast(region=:d, proj=:Robinson, frame=:g, res=:crude, area=10000, land=:goldenrod,
	  water=:snow2, figsize=12, fmt=:png, savefig="25")

coast(region=:d, proj=:EckertIV, frame=:g, res=:crude, area=10000, land=:ivory,
	  water=:bisque3, shore=:thinnest, figsize=12, fmt=:png, savefig="26")

coast(region=:d, proj=:EckertVI, frame=:g, res=:crude, area=10000, land=:ivory,
	  water=:bisque3, shore=:thinnest, figsize=12, fmt=:png, savefig="27")

coast(region=:d, proj=:Sinusoidal, xaxis=(grid=30,), yaxis=(grid=15,), res=:crude,
      area=10000, land=:coral4, water=:azure3, figsize=12, fmt=:png, savefig="28")

coast(region=(200,340,-90,90), proj=:Sinusoidal, frame=:g, res=:crude, area=10000,
      land=:darkred, water=:azure, scale=0.03333)
coast!(region=(-20,60,-90,90), frame=:g, res=:crude, area=10000, land=:darkgreen,
       water=:azure, xoff=4.666)
coast!(region=(60,200,-90,90), frame=:g, res=:crude, area=10000, land=:darkblue,
       water=:azure, xoff=2.6664, fmt=:png, savefig="29")

coast(region=:g, proj=:VanderGrinten, xaxis=(grid=30,), yaxis=(grid=15,),res=:crude,
      land=:lightgray, water=:cornsilk, area=10000, shore=:thinnest, figsize=10, fmt=:png, savefig="30")
