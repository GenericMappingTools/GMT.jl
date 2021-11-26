Tables.schema(D::GMTdataset)::Nothing = nothing
Tables.istable(::Type{<:GMTdataset})::Bool = true
Tables.rowaccess(::Type{<:GMTdataset})::Bool = true
Tables.rows(D::T) where {T<:GMTdataset} = D

Tables.getcolumn(D::GMTdataset, i::Int) = D[:,i]
function Tables.getcolumn(D::GMTdataset, name)
	isempty(D.colnames) && return nothing
	((i = findfirst(string(name) .== D.colnames)) === nothing) && error("Column name - $(string(name)) - not found in this dataset")
	D[:,i]
end

function Tables.columnnames(D::GMTdataset)
	(D.colnames[:])
end
