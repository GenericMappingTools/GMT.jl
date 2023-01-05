function _precompile_()
	#ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
	@assert Base.precompile(Tuple{typeof(plot),Matrix{Float64}})   # time: 11.283913
	@assert Base.precompile(Tuple{typeof(helper_multi_cols),Dict{Symbol, Any},Matrix{Float64},Bool,String,String,String,String,Bool,Vector{Bool},Vector{String},String,Vector{String},Bool,Bool})   # time: 0.2952042
	@assert Base.precompile(Tuple{typeof(finish_PS_module),Dict{Symbol, Any},Vector{String},String,Bool,Bool,Bool,Matrix{Float64},Vararg{Any, N} where N})   # time: 0.1380821
	@assert Base.precompile(Tuple{typeof(make_color_column),Dict{Symbol, Any},String,String,Int64,Int64,Int64,Bool,Bool,Bool,Vector{String},Matrix{Float64}, Nothing})   # time: 0.1258531
	@assert Base.precompile(Tuple{typeof(make_color_column),Dict{Symbol, Any},String,String,Int64,Int64,Int64,Bool,Bool,Bool,Vector{String},Matrix{Float64}, GMT.GMTcpt})
	@assert Base.precompile(Tuple{typeof(make_color_column_),Dict{Symbol, Any},String,Int64,Int64,Int64,Bool,Bool,Matrix{Float64}, GMTcpt, Vector{Float64},Int64})
	@assert Base.precompile(Tuple{typeof(make_color_column_),Dict{Symbol, Any},String,Int64,Int64,Int64,Bool,Bool,Matrix{Float64},Nothing,Vector{Int64},Int64})

	@assert Base.precompile(Tuple{typeof(get_sizes),Matrix{Float64}})
	@assert Base.precompile(Tuple{typeof(get_sizes),GMTdataset{Float64, 2}})
	@assert Base.precompile(Tuple{typeof(parse_bar_cmd),Dict{Symbol, Any},Symbol, String, String, Bool})
	@assert Base.precompile(Tuple{typeof(check_caller),Dict{Symbol, Any},String, String, String, String, Vector{String}, Bool})
	@assert Base.precompile(Tuple{typeof(seek_custom_symb),String, Bool})
	@assert Base.precompile(Tuple{typeof(recompute_R_4bars!), String, String, GMTdataset{Float64, 2}})
	@assert Base.precompile(Tuple{typeof(recompute_R_4bars!), String, String, Matrix{Float64}})
	@assert Base.precompile(Tuple{typeof(bar_group), Dict{Symbol, Any}, String, String, Vector{String}, Bool, Bool, Matrix{Float64}})
	@assert Base.precompile(Tuple{typeof(helper_gbar_fill),Dict{Symbol, Any}})
	@assert Base.precompile(Tuple{typeof(parse_markerline), Dict{Symbol, Any},String,String})
	@assert Base.precompile(Tuple{typeof(parse_opt_S), Dict{Symbol, Any},Matrix{Float64}, Bool})
	@assert Base.precompile(Tuple{typeof(fish_bg), Dict{Symbol, Any},Vector{String}})
	@assert Base.precompile(Tuple{typeof(with_xyvar), Dict{Symbol, Any},GMTdataset{Float64, 2}, Bool})
	@assert Base.precompile(Tuple{typeof(helper_arrows), Dict{Symbol, Any}, Bool})
	@assert Base.precompile(Tuple{typeof(append_figsize), Dict{Symbol, Any}, String, String, Bool})

	@assert Base.precompile(Tuple{typeof(get_marker_name),Dict{Symbol, Any}, GMTdataset{Float64, 2}, Vector{Symbol}, Bool, Bool})
	@assert Base.precompile(Tuple{typeof(get_marker_name),Dict{Symbol, Any},Matrix{Float64},Vector{Symbol},Bool,Bool}) 
	@assert Base.precompile(Tuple{typeof(add_opt_cpt),Dict{Symbol, Any},String,Matrix{Symbol},Char,Int64,Matrix{Float64},Nothing,Bool,Bool,String,Bool})
	@assert Base.precompile(Tuple{typeof(put_in_legend_bag),Dict{Symbol, Any},Vector{String},Matrix{Float64}})   # time: 0.0101455
	@assert Base.precompile(Tuple{typeof(add_opt_module),Dict{Symbol, Any}})   # time: 0.365098
	@assert Base.precompile(Tuple{typeof(read_data), Dict{Symbol, Any}, String, String, Nothing, String, Bool, Bool})
	@assert Base.precompile(Tuple{typeof(read_data), Dict{Symbol, Any}, String, String, Matrix{Float64}, String, Bool, Bool})
	@assert Base.precompile(Tuple{typeof(read_data), Dict{Symbol, Any}, String, String, GMTdataset{Float64,2}, String, Bool, Bool})

	@assert Base.precompile(Tuple{typeof(imshow),GMTgrid{Float32, 2}})   # time: 12.84012
	@assert Base.precompile(Tuple{typeof(finish_PS_module),Dict{Symbol, Any},Vector{String},String,Bool,Bool,Bool,GMTgrid{Float32, 2},Vararg{Any, N} where N})   # time: 0.1452611
	@assert Base.precompile(Tuple{Core.kwftype(typeof(grdimage)),NamedTuple{(:show,), Tuple{Bool}},typeof(grdimage),String,GMTgrid{Float32, 2}})   # time: 0.043773
	@assert Base.precompile(Tuple{Core.kwftype(typeof(grdview)),NamedTuple{(:show,), Tuple{Bool}},typeof(grdview),String,GMTgrid{Float32, 2}})   # time:
	@assert Base.precompile(Tuple{typeof(common_get_R_cpt),Dict{Symbol, Any},String,String,String,Int64,GMTgrid{Float32, 2},Nothing,Nothing,String})   # time: 0.0355232
	@assert Base.precompile(Tuple{typeof(common_shade),Dict{Symbol, Any},String,GMTgrid{Float32, 2},GMTcpt,Nothing,Nothing,String})   # time: 0.0226077
	@assert Base.precompile(Tuple{typeof(show),IOBuffer,GMTdataset{Float64, 2}})

	@assert Base.precompile(Tuple{typeof(mat2ds),String})
	@assert Base.precompile(Tuple{typeof(mat2ds),Matrix{Float64}})

	@assert Base.precompile(Tuple{typeof(parse_B),Dict{Symbol, Any}, String})
	@assert Base.precompile(Tuple{typeof(parse_R),Dict{Symbol, Any}, String})
	@assert Base.precompile(Tuple{typeof(parse_J),Dict{Symbol, Any}, String, String})

	@assert Base.precompile(Tuple{typeof(violin),Vector{Float64}})
	@assert Base.precompile(Tuple{typeof(boxplot),Vector{Float64}})
	@assert Base.precompile(Tuple{typeof(qqplot),Vector{Float64},Vector{Float64}})
	@assert Base.precompile(Tuple{typeof(feather), String, Matrix{Float64}})
	@assert Base.precompile(Tuple{typeof(ecdfplot), Vector{Float64}})
	@assert Base.precompile(Tuple{typeof(parallelplot), String, Matrix{Float64}})
	@assert Base.precompile(Tuple{typeof(cornerplot),Matrix{Float64}})
	@assert Base.precompile(Tuple{typeof(marginalhist), Matrix{Float64}})

end
