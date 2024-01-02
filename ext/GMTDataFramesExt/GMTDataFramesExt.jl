module GMTDataFramesExt
	using GMT, DataFrames

	function GMT.ds2df(D::GMTdataset)
		colnames = (length(D.colnames) == size(D.data, 2)) ? Symbol.(D.colnames) :
			isempty(D.colnames) ? [Symbol("col$i") for i = 1:size(D.data, 2)] : Symbol.(D.colnames[1:size(D.data, 2)-1])
		df = DataFrame(D.data, colnames, copycols=false)
		#!isempty(D.text) && (df[!, (length(D.colnames) == size(D.data, 2)+1) ? D.colnames[end] : :Text] = D.text)
		cname = (length(D.colnames) == size(D.data, 2)+1) ? D.colnames[end] : :Text
		!isempty(D.text) && insertcols!(df, 1, cname => D.text)
		return df
	end
	function GMT.Ginnerjoin(D1::GMTdataset, D2::GMTdataset;
	                   on::Union{<:DataFrames.OnType, AbstractVector} = Symbol[],
	                   makeunique::Bool=false,
	                   validate::Union{Pair{Bool, Bool}, Tuple{Bool, Bool}}=(false, false),
	                   renamecols::Pair=identity => identity,
	                   matchmissing::Symbol=:error,
	                   order::Symbol=:undefined)
		innerjoin(GMT.ds2df(D1), GMT.ds2df(D2), on=on, makeunique=makeunique, validate=validate, renamecols=renamecols, matchmissing=matchmissing, order=order)
	end
	function GMT.Gouterjoin(D1::GMTdataset, D2::GMTdataset;
	                   on::Union{<:DataFrames.OnType, AbstractVector} = Symbol[],
	                   makeunique::Bool=false,
	                   validate::Union{Pair{Bool, Bool}, Tuple{Bool, Bool}}=(false, false),
	                   renamecols::Pair=identity => identity,
	                   matchmissing::Symbol=:error,
	                   order::Symbol=:undefined)
		outerjoin(GMT.ds2df(D1), GMT.ds2df(D2), on=on, makeunique=makeunique, validate=validate, renamecols=renamecols, matchmissing=matchmissing, order=order)
	end
	function GMT.Gleftjoin(D1::GMTdataset, D2::GMTdataset;
	                  on::Union{<:DataFrames.OnType, AbstractVector} = Symbol[], makeunique::Bool=false,
	                  source::Union{Nothing, Symbol, AbstractString}=nothing,
	                  indicator::Union{Nothing, Symbol, AbstractString}=nothing,
	                  validate::Union{Pair{Bool, Bool}, Tuple{Bool, Bool}}=(false, false),
	                  renamecols::Pair=identity => identity, matchmissing::Symbol=:error,
	                  order::Symbol=:undefined)
		leftjoin(GMT.ds2df(D1), GMT.ds2df(D2), on=on, makeunique=makeunique, source=source, indicator=indicator, validate=validate, renamecols=renamecols, matchmissing=matchmissing, order=order)
	end
	"""
	  Gsemijoin(D1::GMTdataset, D2::GMTdataset; on, makeunique=false, validate=(false, false), matchmissing=:error)

	See help on DataFrames `? semijoin`
	"""
	function Gsemijoin(D1::GMTdataset, D2::GMTdataset;
	                   on::Union{<:DataFrames.OnType, AbstractVector} = Symbol[], makeunique::Bool=false,
	                   validate::Union{Pair{Bool, Bool}, Tuple{Bool, Bool}}=(false, false),
	                   matchmissing::Symbol=:error)
		semijoin(GMT.ds2df(D1), GMT.ds2df(D2), on=on, makeunique=makeunique, validate=validate, matchmissing=matchmissing)
	end

	"""
	  Gantijoin(D1::GMTdataset, D2::GMTdataset; on, makeunique=false, validate=(false, false), matchmissing=:error)

	See help on DataFrames `? antijoin`
	"""
	function Gantijoin(D1::GMTdataset, D2::GMTdataset;
	                   on::Union{<:DataFrames.OnType, AbstractVector} = Symbol[], makeunique::Bool=false,
	                   validate::Union{Pair{Bool, Bool}, Tuple{Bool, Bool}}=(false, false),
	                   matchmissing::Symbol=:error)
		antijoin(GMT.ds2df(D1), GMT.ds2df(D2), on=on, makeunique=makeunique, validate=validate, matchmissing=matchmissing)
	end

	"""
	  Gcrossjoin(D1::GMTdataset, D2::GMTdataset; makeunique::Bool=false, renamecols=identity => identity)

	See help on DataFrames `? crossjoin`
	"""
	function Gcrossjoin(D1::GMTdataset, D2::GMTdataset; makeunique::Bool=false, renamecols::Pair=identity => identity)
		crossjoin(GMT.ds2df(D1), GMT.ds2df(D2), makeunique=makeunique, renamecols=renamecols)
	end
end