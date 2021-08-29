### Plot Landsat 8 images

The data used in this example is the band 4 (red channel) of a Landsat 8 scene. Those are relatively big images (~116 MB) so we will download it first and take that into account when the results of the commands bellow do not show instantly.

```julia
Ir = gmtread("/vsicurl/http://landsat-pds.s3.amazonaws.com/c1/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1/LC08_L1TP_037034_20160712_20170221_01_T1_B4.TIF");
```

and have a look at what we got

```julia
imshow(Ir)
```

```@raw html
<img src="../b4raw.png" width="700" class="center"/>
```

_Ah, nice ... but it's so dark that we can't really see much!_

Well that is true and has one explanation. Modern satellite data is acquired with sensors of 12 bits or more but the data is stored in variables with 16 bits. This means that many of those data bits will not be used. But on screens we are limited to 8 bits per channel so we must scale the full 16 bits range [0 65535] to the [0 255] interval and in this process we tend to have much more dark pixels.

To see this better, let's look at the image's histogram.

```julia
histogram(Ir, auto=true, bin=20, show=true)
```

```@raw html
<img src="../b4hist.png" width="500" class="center"/>
```

We have used here the option **auto**=*true* that will try to guess where the data in histogram plot starts and ~ ends. It did behave well and we will use those numbers to do an operation that is called *histogram stretch* that consists in picking only part of the histogram and stretch it to [0 255]. Note that in fact we have data to the 40000 DN (Digital Number) but they are very few and at the end we must choose a balance to show *almost all* DNs and not making the image too dark.

```julia
imshow(I, stretch=[6000 23800])
```

```@raw html
<img src="../b4stretched.png" width="700" class="center"/>
```

Now that we feel confident with the auto-stretching algorithm we can create a true color image. True color images
are obtained by inserting the Landsat8 band 4 in the Red channel, band 3 in Green and band 2 in Blue. Looking at
the file name that we downloaded it's easy to guess that bands "...T1_B3.TIF" and "...T1_B2.TIF" contain the
green and blue channels that we need. So download them (takes a little time)

```julia
Ig = gmtread("/vsicurl/http://landsat-pds.s3.amazonaws.com/c1/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1/LC08_L1TP_037034_20160712_20170221_01_T1_B3.TIF");

Ib = gmtread("/vsicurl/http://landsat-pds.s3.amazonaws.com/c1/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1/LC08_L1TP_037034_20160712_20170221_01_T1_B2.TIF");
```

and compose a true color image with the function `truecolor()` from the [RemoteS](https://github.com/GenericMappingTools/RemoteS.jl)
package that will do the auto-stretching automatically for us

```julia
using RemoteS
Irgb = truecolor(Ir, Ig, Ib);
```

```@raw html
<img src="../truecolor.png" width="700" class="center"/>
```

---

*Download a [Pluto Notebook here](histogram_stretch.jl)*

