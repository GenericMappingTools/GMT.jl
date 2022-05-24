"""
	grdconvert(fname::AbstractString)

Read a gridded dataset stored in a ``x y z`` text file with an extension ``.xyz``
(note that this detail is mandatory) and return a GMTgrid object. By "gridded dataset" it is meant
that the file contains an already gridded dataset. Scattered ``xyz`` points are not wellcome here.

"""
function grdconvert(fname::AbstractString)
	(lowercase(splitext(fname)[2]) != ".xyz") && error("This short version of grdconvert deals only with text files ending with a .xyz extension.")
	gmt("grdconvert " * fname)
end
