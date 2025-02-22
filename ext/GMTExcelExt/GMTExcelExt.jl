module GMTExcelExt
	using GMT, XLSX

	function GMT.read_xls(fname::String; kwargs...)
		x1 = XLSX.readxlsx(fname)
		shitas = XLSX.sheetnames(x1)
		xf = XLSX.readtable(fname, shitas[1])		# All fAnys
		x_cols = xf.data							# Vector of fAnys
		colnames = string.(xf.column_labels)
		c = zeros(Bool, length(x_cols))
		for k = 1:length(x_cols)  c[k] = isa(x_cols[k][1], String)  end
		inds_r, inds_s = findall(.!c), findall(c)	# Indices of the columns with numeric and string fields

		mat::Matrix{Float64} = Matrix{Float64}(undef, length(x_cols[1]), length(inds_r))
		text_col::Vector{String} = (!isempty(inds_s)) ? Vector{String}(undef, length(x_cols[1])) : String[]
		for col = 1:size(mat, 2)
			for row = 1:size(mat, 1)
				mat[row, col] = x_cols[inds_r[col]][row]
			end
		end
		if !isempty(inds_s)
			text_col = x_cols[inds_s[1]]
			for k = 2:GMT.numel(inds_s)
				text_col *= " | " * x_cols[inds_s[k]]
				colnames[inds_s[1]] *= "|" * colnames[inds_s[k]]		# Concatenate all text column names (we have only 1 text column)
			end
		end
		D = GMT.GMTdataset(mat, text_col)
		D.colnames = [colnames[inds_r]; colnames[inds_s[1]]]
		GMT.set_dsBB!(D)
		return D
	end

end
