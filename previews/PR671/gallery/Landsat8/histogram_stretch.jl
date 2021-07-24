### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ dfc4afc0-69ad-11eb-0ece-c7507e610108
using GMT

# ╔═╡ 832779c0-6a37-11eb-21ab-79e35f04da4e
md"### Plot Landsat 8 images

The data used in this example is the band 4 (red channel) of a Landsat 8 scene. Those are relatively big images (~116 MB) so we will download it first and take that into account when the results of the commands bellow do not show instantly."

# ╔═╡ c7c5e480-6a38-11eb-2273-7dc4ddd09418
I = gmtread("/vsicurl/http://landsat-pds.s3.amazonaws.com/c1/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1/LC08_L1TP_037034_20160712_20170221_01_T1_B4.TIF");

# ╔═╡ d07b0c8e-6a38-11eb-3371-69a77e57dae1
md"and have a look at what we got"

# ╔═╡ e0e5ee10-6a38-11eb-0b67-fb9fbf7cbdb4
imshow(I)

# ╔═╡ e905b3f0-6a38-11eb-3354-072a5d9152e0
md"_Ah, nice ... but it's so dark that we can't really see much!_

Well that is true and has one explanation. Modern satellite data is acquired with sensors of 12 bits or more but the data is stored in variables with 16 bits. This means that many of those data bits will not be used. But on screens we are limited to 8 bits per channel so we must scale the full 16 bits range [0 65535] to the [0 255] interval and in this process we tend to have much more dark pixels.

To see this better, let's look at the image's histogram.
"

# ╔═╡ 32c60de2-6a3a-11eb-1cfd-1b74d0ad957b
histogram(I, auto=true, bin=20, show=true)

# ╔═╡ 3a707cb0-6a3a-11eb-3975-b1b091d05e2f
md"We have used here the option **auto**=*true* that will try to guess where the data in histogram plot starts and ~ ends. It did behave well and we will use those numbers to do an operation that is called *histogram stretch* that consists in picking only part of the histogram and stretch it to [0 255]. And while at it we van visually observe that the limit [6000 24000] seems slightly better than the automatic one. Note that in fact we have data to the 40000 DN (Digital Number) but they are very few and at the end we must choose a balance to show *almos all* DNs and not making the image too dark. Reducing the higher value to 23400 would have made the image sligthy lighter."

# ╔═╡ 32e2c830-6a3b-11eb-2da3-cd08989b96a5
imshow(I, stretch=[6000 25000])

# ╔═╡ Cell order:
# ╠═dfc4afc0-69ad-11eb-0ece-c7507e610108
# ╠═a02af2c0-69ad-11eb-0cc5-57d1f41ddac5
# ╟─832779c0-6a37-11eb-21ab-79e35f04da4e
# ╠═c7c5e480-6a38-11eb-2273-7dc4ddd09418
# ╟─d07b0c8e-6a38-11eb-3371-69a77e57dae1
# ╠═e0e5ee10-6a38-11eb-0b67-fb9fbf7cbdb4
# ╟─e905b3f0-6a38-11eb-3354-072a5d9152e0
# ╠═32c60de2-6a3a-11eb-1cfd-1b74d0ad957b
# ╟─3a707cb0-6a3a-11eb-3975-b1b091d05e2f
# ╠═32e2c830-6a3b-11eb-2da3-cd08989b96a5
