G = gmt("grdmath -R-179.2/-176.5/-5/-3 -I0.01 X");
I = gmt("grdmath -R-179.2/-176.5/-5/-3 -I0.01 X 100 MUL COSD Y 50 MUL SIND MUL");
C = makecpt(T="-179.2/-176.5/0.01");
grdimage(G, I=I, J="M6i", C=C, B="1 WSne", X=:c, Y=0.5, show=1, Vd=1)
grdimage(data=G, I=I, J="M6i", C=C, B="1 WSne", X=:c, Y=0.5, show=1, Vd=1)

Gr = gmt("grdmath -R0/6/0/6 -I0.1 X 6 DIV 255 MUL");
Gg = gmt("grdmath -R0/6/0/6 -I0.1 Y 6 DIV 255 MUL");
Gb = gmt("grdmath -R0/6/0/6 -I0.1 3 3 CDIST DUP UPPER DIV 255 MUL");
G = grdcut("@earth_relief_06m", R="0/6/0/6");
grdview(G, I=:+, J=:M4i, JZ="2i", p="145/35", G=(Gr,Gg,Gb), B="af WSne", Q=:i, X="1.5i", Y="0.75i", show=1, Vd=1)


G = grdcut("@earth_relief_01m", R="0/10/0/10");
grdview(G, I="+nt0.5", J=:M5i, JZ="2i", p="145/35", G="@wood_texture.jpg", B="af WSne", Q=:i, Y="0.75i", show=1, Vd=1)