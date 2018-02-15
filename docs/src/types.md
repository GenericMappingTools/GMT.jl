# The GMT.jl types

Grid type
---------

    type GMTgrid                  # The type holding a local header and data of a GMT grid
       proj4::String              # Projection string in PROJ4 syntax (Optional)
       wkt::String                # Projection string in WKT syntax (Optional)
       range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]
       inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]
       registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration
       nodata::Float64            # The value of nodata
       title::String              # Title (Optional)
       comment::String            # Remark (Optional)
       command::String            # Command used to create the grid (Optional)
       datatype::String           # 'float' or 'double'
       x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates
       y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates
       z::Array{Float32,2}        # [n_rows x n_columns] grid array
       x_units::String            # Units of XX axis (Optional)
       y_units::String            # Units of YY axis (Optional)
       z_units::String            # Units of ZZ axis (Optional)
       layout::String             # A three character string describing the grid memory layout
    end

Image type
----------

    type GMTimage                 # The type holding a local header and data of a GMT image
       proj4::String              # Projection string in PROJ4 syntax (Optional)
       wkt::String                # Projection string in WKT syntax (Optional)
       range::Array{Float64,1}    # 1x6 vector with [x_min x_max y_min y_max z_min z_max]
       inc::Array{Float64,1}      # 1x2 vector with [x_inc y_inc]
       registration::Int          # Registration type: 0 -> Grid registration; 1 -> Pixel registration
       nodata::Float64            # The value of nodata
       title::String              # Title (Optional)
       comment::String            # Remark (Optional)
       command::String            # Command used to create the image (Optional)
       datatype::String           # 'uint8' or 'int8' (needs checking)
       x::Array{Float64,1}        # [1 x n_columns] vector with XX coordinates
       y::Array{Float64,1}        # [1 x n_rows]    vector with YY coordinates
       image::Array{UInt8,3}      # [n_rows x n_columns x n_bands] image array
       x_units::String            # Units of XX axis (Optional)
       y_units::String            # Units of YY axis (Optional)
       z_units::String            # Units of ZZ axis (Optional) ==> MAKES NO SENSE
       colormap::Array{Clong,1}   # 
       alpha::Array{UInt8,2}      # A [n_rows x n_columns] alpha array
       layout::String             # A four character string describing the image memory layout
    end

Dataset type
------------

    type GMTdataset
        data::Array{Float64,2}     # Mx2 Matrix with segment data
        text::Array{Any,1}         # Array with text after data coordinates (mandatory only when plotting Text)
        header::String             # String with segment header (Optional but sometimes very useful)
        comment::Array{Any,1}      # Array with any dataset comments [empty after first segment]
        proj4::String              # Projection string in PROJ4 syntax (Optional)
        wkt::String                # Projection string in WKT syntax (Optional)
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
        model::String
        comment::Array{Any,1}   # Cell array with any comments
    end

Postscript type
---------------

    type GMTps
        postscript::String      # Actual PS plot (text string)
        length::Int             # Byte length of postscript
        mode::Int               # 1 = Has header, 2 = Has trailer, 3 = Has both
        comment::Array{Any,1}   # Cell array with any comments
    end
