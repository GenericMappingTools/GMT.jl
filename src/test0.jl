using GMT

API=create_session();

#dim=uint64([2,9,2]);
#V = create_data (API, GMT_IS_VECTOR, GMT_IS_POINT, 0, dim)
#Vb = unsafe_load(V)

dim=uint64([2,6,1]);
M = create_data (API, GMT_IS_MATRIX, GMT_IS_SURFACE, 0, dim)
Mb = unsafe_load(M)
print([Mb.n_rows,Mb.n_columns,Mb.n_layers])

#dim=uint64([1,2,3,4]);
#D = create_data (API, GMT_IS_DATASET, GMT_IS_POINT, 0, dim)
#Db = unsafe_load(D)
#print([Db.n_tables,Db.n_segments,Db.n_records,Db.n_columns])
