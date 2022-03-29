function _precompile_()
	#ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
	@assert Base.precompile(Tuple{typeof(plot),Matrix{Float64}})   # time: 11.283913
	@assert Base.precompile(Tuple{typeof(helper_multi_cols),Dict{Symbol, Any},Matrix{Float64},Bool,String,String,String,String,Bool,Vector{Bool},Vector{String},String,Vector{String},Bool,Bool})   # time: 0.2952042
	@assert Base.precompile(Tuple{typeof(finish_PS_module),Dict{Symbol, Any},Vector{String},String,Bool,Bool,Bool,Matrix{Float64},Vararg{Any, N} where N})   # time: 0.1380821
	@assert Base.precompile(Tuple{typeof(make_color_column),Dict{Symbol, Any},String,String,Int64,Int64,Int64,Bool,Bool,Bool,Vector{String},Matrix{Float64}, Nothing})   # time: 0.1258531
	@assert Base.precompile(Tuple{typeof(make_color_column),Dict{Symbol, Any},String,String,Int64,Int64,Int64,Bool,Bool,Bool,Vector{String},Matrix{Float64}, GMT.GMTcpt})
	@assert Base.precompile(Tuple{typeof(get_marker_name),Dict{Symbol, Any},Matrix{Float64},Vector{Symbol},Bool,Bool})   # time: 0.0417101
	@assert Base.precompile(Tuple{typeof(add_opt_cpt),Dict{Symbol, Any},String,Matrix{Symbol},Char,Int64,Matrix{Float64},Nothing,Bool,Bool,String,Bool})   # time: 0.0158795
	@assert Base.precompile(Tuple{typeof(put_in_legend_bag),Dict{Symbol, Any},Vector{String},Matrix{Float64}})   # time: 0.0101455
	@assert Base.precompile(Tuple{typeof(add_opt_module),Dict{Symbol, Any}})   # time: 0.365098

	@assert Base.precompile(Tuple{typeof(imshow),GMTgrid{Float32, 2}})   # time: 12.84012
	@assert Base.precompile(Tuple{typeof(finish_PS_module),Dict{Symbol, Any},Vector{String},String,Bool,Bool,Bool,GMTgrid{Float32, 2},Vararg{Any, N} where N})   # time: 0.1452611
	@assert Base.precompile(Tuple{Core.kwftype(typeof(grdimage)),NamedTuple{(:show,), Tuple{Bool}},typeof(grdimage),String,GMTgrid{Float32, 2}})   # time: 0.043773
	@assert Base.precompile(Tuple{typeof(common_get_R_cpt),Dict{Symbol, Any},String,String,String,Int64,GMTgrid{Float32, 2},Nothing,Nothing,String})   # time: 0.0355232
	@assert Base.precompile(Tuple{typeof(common_shade),Dict{Symbol, Any},String,GMTgrid{Float32, 2},GMTcpt,Nothing,Nothing,String})   # time: 0.0226077
end
