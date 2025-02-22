Tables.schema(D::GMTdataset)::Nothing = nothing
Tables.istable(::Type{<:GMTdataset})::Bool = true
Tables.rowaccess(::Type{<:GMTdataset})::Bool = true
Tables.columnaccess(::Type{<:GMTdataset})::Bool = true
Tables.columns(D::T) where {T<:GMTdataset} = D
Tables.rows(D::T) where {T<:GMTdataset} = D

Tables.getcolumn(D::GMTdataset, i::Int) = D.data[:,i]
Tables.getcolumn(D::GMTdataset, name::Symbol) = Tables.getcolumn(D::GMTdataset, string(name))
function Tables.getcolumn(D::GMTdataset, name::AbstractString)
	# Search in both D.colnames (it it exists) and ["Column1", "Column2", ...]
	if ((i = findfirst(name .== D.colnames)) === nothing)
		Columnames = [join("Column" * "$(n)") for n = 1:size(D,2)]
		((i = findfirst(name .== Columnames)) === nothing) && error("Column name - $(name) - not found in this dataset")
	end
	(i > size(D.data, 2)) && return D.text		# It must be the text column
	D.data[:,i]
end

function Tables.columnnames(D::GMTdataset)
	!isempty(D.colnames) && return (D.colnames[:])
	return ([join("Column" * "$(n)") for n = 1:size(D,2)])
end
