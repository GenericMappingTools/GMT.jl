# The GMT.jl types

Grid type
---------

    type GMTgrid{T<:Real,N} <: AbstractArray{T,N}      # The type holding a local header and data of a GMT grid
       proj4::String              # Projection string in PROJ4 syntax (Optional)
       wkt::String                # Projection string in WKT syntax (Optional)
       epsg::Int                  # EPSG code
       range::Array{Float64,1}    # 1x6[8] vector with [x_min, x_max, y_min, y_max, z_min, z_max [, v_min, v_max]]
       inc::Array{Float64,1}      # 1x2[3] vector with [x_inc, y_inc [,v_inc]]
       registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration
       nodata::Float64            # The value of nodata
       title::String              # Title (Optional)
       comment::String            # Remark (Optional)
       command::String            # Command used to create the grid (Optional)
       names::Vector{String}      # To use whith multi-layered and when layers have names (Optional)
       x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates
       y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates
       v::Union{Vector{<:Real}, Vector{String}}        # [v x n_bands]   vector with VV (vertical for 3D grids) coordinates
       z::Array{T,N}              # [n_rows x n_columns] grid array
       x_units::String            # Units of XX axis (Optional)
       y_units::String            # Units of YY axis (Optional)
       v_units::String            # Units of Vertical axis (Optional)
       z_units::String            # Units of z vlues (Optional)
       layout::String             # A three character string describing the grid memory layout
       scale::Union{Float64, Float32}=1f0  # When saving in file apply `z = z * scale + offset`
       offset::Union{Float64, Float32}=0f0
       pad::Int=0                 # When != 0 means that the array is placed in a padded array of PAD rows/cols
    end

Image type
----------

    type GMTimage{T<:Unsigned, N} <: AbstractArray{T,N}   # The type holding a local header and data of a GMT image
       proj4::String              # Projection string in PROJ4 syntax (Optional)
       wkt::String                # Projection string in WKT syntax (Optional)
       epsg::Int                  # EPSG code
       range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]
       inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]
       registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration
       nodata::Unsigned           # The value of nodata
       color_interp::String       # If equal to "Gray" an indexed image with no cmap will get a gray cmap
       metadata::Vector{String}   # To store any metadata that can eventually be passed to GDAL (Optional)
       names::Vector{String}      # To use whith multi-band and when bands have names (Optional)
       x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates
       y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates
       v::Array{Float64,1}        # [v x n_bands]   vector with vertical coords or wavelengths in hypercubes (Optional)
       image::Array{T,N}          # [n_rows x n_columns x n_bands] image array
       colormap::Array{Int32,1}   # 
       alpha::Array{UInt8,2}      # A [n_rows x n_columns] alpha array
       layout::String             # A four character string describing the image memory layout
       pad::Int                   # When != 0 means that the array is placed in a padded array of PAD rows/cols
    end

Dataset type
------------

    type GMTdataset{T<:Real, N} <: AbstractArray{T,N}
        data::Array{T,N}           # Mx2 Matrix with segment data
        ds_bbox::Vector{Float64}   # Global BoundingBox (for when there are many segments)
        bbox::Vector{Float64}      # Segment BoundingBox
        attrib::Dict{String, String} # Dictionary with attributes/values (optional)
        colnames::Vector{String}   # Column names. Antecipate using this with a future Tables inerface
        text::Vector{String}       # Array with text after data coordinates (mandatory only when plotting Text)
        header::String             # String with segment header (Optional but sometimes very useful)
        comment::Vector{String}    # Array with any dataset comments [empty after first segment]
        proj4::String              # Projection string in PROJ4 syntax (Optional)
        wkt::String                # Projection string in WKT syntax (Optional)
        geom::Integer              # Geometry type. One of the GDAL's enum (wkbPoint, wkbPolygon, etc...)
    end

CPT type
--------

    type GMTcpt
        colormap::Array{Float64,2}
        alpha::Array{Float64,1}
        range::Array{Float64,2}
        minmax::Array{Float64,1}
        bfn::Array{Float64,2}
        depth::Cint
        hinge::Cdouble
        cpt::Array{Float64,2}
        label::Vector{String}     # Labels of a Categorical CPT
        key::Vector{String}       # Keys of a Categorical CPT
        model::String
        comment::Array{Any,1}     # Cell array with any comments
    end

Postscript type
---------------

    type GMTps
        postscript::String      # Actual PS plot (text string)
        length::Int             # Byte length of postscript
        mode::Int               # 1 = Has header, 2 = Has trailer, 3 = Has both
        comment::Array{Any,1}   # Cell array with any comments
    end
