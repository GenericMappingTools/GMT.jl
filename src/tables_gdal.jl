Tables.schema(layer::AbstractFeatureLayer)::Nothing = nothing
Tables.istable(::Type{<:AbstractFeatureLayer})::Bool = true
Tables.rowaccess(::Type{<:AbstractFeatureLayer})::Bool = true
Tables.rows(layer::T) where {T<:AbstractFeatureLayer} = layer

function Tables.getcolumn(row::Feature, i::Int)
	(i > nfield(row)) ? getgeom(row, i - nfield(row) - 1) : ((i > 0) ? getfield(row, i - 1) : missing)
end

function Tables.getcolumn(row::Feature, name::Symbol)
    field = getfield(row, name)
    (!ismissing(field)) && return field
    geom = getgeom(row, name)
    (geom.ptr != C_NULL) && return geom
    return missing
end

function Tables.columnnames(row::Feature)::NTuple{Int64(nfield(row) + ngeom(row)),Symbol}
    geom_names, field_names = schema_names(getfeaturedefn(row))
    return (geom_names..., field_names...)
end

function schema_names(featuredefn::IFeatureDefnView)
    fielddefns = (getfielddefn(featuredefn, i) for i in 0:nfield(featuredefn)-1)
    field_names = (Symbol(getname(fielddefn)) for fielddefn in fielddefns)
    geom_names = collect(Symbol(getname(getgeomdefn(featuredefn, i - 1))) for i in 1:ngeom(featuredefn))
    return (geom_names, field_names, featuredefn, fielddefns)
end
