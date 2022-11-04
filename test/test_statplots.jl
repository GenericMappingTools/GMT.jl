@testset "STATPLOTS" begin
	println("	STATPLOTS")
	GMT.density(randn(100), kernel=:uniform, Vd=dbg2)
	GMT._quantile(randn(30), rand(30), [0.25, 0.75])

	y = randn(100,3);
	violin(y, scatter=true)
	boxplot!(y, Vd=dbg2)
	boxplot(randn(100,3), outliers=(size="6p",), hbar=true, Vd=dbg2)

	y = randn(100,3,2);
	violin(y, G=true, split=true)
	violin(y, G=true, split=true, boxplot=true)
end