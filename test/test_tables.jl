@testset "TABLES" begin
	println("	TABLES")
	D = mat2ds(rand(3,2));
	GMT.Tables.getcolumn(D, 1);
	GMT.Tables.getcolumn(D, :X)
	@test_throws ErrorException("Column name - XX - not found in this dataset") GMT.Tables.getcolumn(D, :XX)
	GMT.Tables.columnnames(D)
	GMT.Tables.schema(D)
	GMT.Tables.istable(D)
	GMT.Tables.rowaccess(D)
	GMT.Tables.columnaccess(D)
	GMT.Tables.columns(D)
	GMT.Tables.rows(D)

	Ds = gmt2gd(mat2ds([-8. 37.0; -8.1 37.5; -8.5 38.0]));
	Df = GMT.Gdal.unsafe_getfeature(GMT.Gdal.getlayer(Ds, 0),0);
	GMT.Tables.getcolumn(Df, 1)
end