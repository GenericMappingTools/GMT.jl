"""
    imshow(arg1; kw...)

Is a simple front end to the [`grdimage`](@ref)  [`grdview`](@ref) programs that accepts GMTgrid, GMTimage,
2D array of floats or strings with file names of grids or images. The normal options of the *grdimage*
and *grdview* programs also apply here but some clever guessing of suitable necessary parameters is done
if they are not provided. Contrary to other image producing modules the "show' keyword is not necessary to
display the image. Here it is set by default. If user wants to use *imshow* to create layers of a more complex
fig he can use *show=false* for the intermediate layers.

# Examples
```julia-repl
# Plot vertical shaded illuminated view of the Mexican hat
julia> G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
julia> imshow(G, shade="+a45")

# Same as above but add automatic contours
julia> imshow(G, shade="+a45", contour=true)

# Plot a random heat map
julia> imshow(rand(128,128))

# Display a web downloaded jpeg image wrapped into a sinusoidal projection
julia> imshow("http://larryfire.files.wordpress.com/2009/07/untooned_jessicarabbit.jpg", region="d", frame="g", proj="I15", img_in="r", fmt=:jpg)
```
See also: [`grdimage`](@ref)
"""
function imshow(arg1; first=true, kw...)
	# Take a 2D array of floats and turn it into a GMTgrid or if input is a string assume it's a file name
	# In this later case try to figure if it's a grid or an image and act accordingly.
	is_image = false
	if (isa(arg1, String))		# If it's string it has to be a file name. Check extension to see if is an image
		ffname, ext = splitext(arg1)
		ext = lowercase(ext)
		if (ext == ".jpg" || ext == ".tif" || ext == ".tiff" || ext == ".png" || ext == ".bmp" || ext == ".gif")
			is_image = true
		end
		G = (arg1[1] == '@') ? arg1 : gmtread(arg1)			# If it screws ...
	elseif (isa(arg1, Array{UInt8}))
		G = mat2img(arg1; kw...)
	else
		G = mat2grid(arg1)
	end

	d = KW(kw)
	see = (!haskey(d, :show)) ? true : see = d[:show]	# No explicit 'show' keyword means show=true

	if (is_image)
		if (haskey(d, :D) || haskey(d, :img_in) || haskey(d, :image_in))	# OK, user set -D so don't repeat
			grdimage(G; first=first, show=see, kw...)
		else
			grdimage(G; first=first, D=1, show=see, kw...)
		end
	else
		if (isa(G, String))  grdimage(G; first=first, show=see, kw...)		# String when fname is @xxxx
		else                 imshow(G; first=first, kw...)
		end
	end
end

function imshow(arg1::GMTgrid; first=true, kw...)
	# Here the default is to show, but if a 'show' was used let it rule
	d = KW(kw)
	see = (!haskey(d, :show)) ? true : see = d[:show]	# No explicit 'show' keyword means show=true
	if ((cont_opts = find_in_dict(d, [:contour])[1]) !== nothing)
		new_see = see
		see = false			# because here we know that 'see' has to wait till last command
	end
	opt_p = parse_common_opts(d, "", [:p], first)
	if (opt_p == "")
		grdimage("", arg1; first=first, show=see, kw...)
	else
		zsize = ((val = find_in_dict(d, [:JZ :Jz :zscale :zsize])[1]) !== nothing) ? val : 5
		srf = ((val = find_in_dict(d, [:Q :surf :surftype])[1]) !== nothing) ? val : "i100"
		grdview("", arg1; first=first, show=see, p=opt_p[4:end], JZ=zsize, Q=srf, kw...)
	end
	if (isa(cont_opts, Bool))				# Automatic contours
		grdcontour!(arg1; J="", show=new_see)
	elseif (isa(cont_opts, NamedTuple))		# Expect a (cont=..., annot=..., ...)
		grdcontour!(arg1; J="", show=new_see, cont_opts...)
	end
end

function imshow(arg1::GMTimage; first=true, kw...)
	# Here the default is to show, but if a 'show' was used let it rule
	d = KW(kw)
	see = (!haskey(d, :show)) ? true : see = d[:show]	# No explicit 'show' keyword means show=true
	grdimage("", arg1; first=first, D=true, show=see, kw...)
end
