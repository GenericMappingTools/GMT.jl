@testset "STATPLOTS" begin
	println("	STATPLOTS")
	v = randn(50);
	GMT.density(randn(100), kernel=:uniform, Vd=dbg2)
	GMT.density!(randn(50), Vd=dbg2)
	GMT.Normal(v, 0.5)
	GMT.Normal(v, 0.5, 1.0)
	GMT.Uniform(v, 0.0, 1.0)
	GMT._quantile(randn(30), rand(30), [0.25, 0.75])
	GMT.parse_candle_outliers_par("")

	violin(v, Vd=dbg2)
	violin!(v, Vd=dbg2)
	y = randn(100,3);
	violin(y, scatter=true)
	violin!(y, Vd=dbg2)
	boxplot(randn(100), Vd=dbg2)
	boxplot!(randn(40), Vd=dbg2)
	boxplot!(y, fill=true, separator=(:red,), Vd=dbg2)
	boxplot(randn(50,10), fill=true, outliers=(size="6p",), hbar=true, Vd=dbg2)
	boxplot!(randn(100,3,2), separator=true, cap="5p", Vd=dbg2)
	boxplot!(y, Vd=dbg2)

	y = randn(100,3,2);
	violin(y, G=true, split=true)
	violin!(y, Vd=dbg2)
	violin(y, G=true, split=true, boxplot=true)
	violin(y, G=true, scatter=true, boxplot=true)

	vv = [round.(randn(50),digits=1), round.(randn(40),digits=3)]
	GMT.kernelDensity(vv)

	vvv = [[randn(50), randn(30)], [randn(40), randn(48), randn(45)], [randn(35), randn(43)]];
	GMT.kernelDensity(vvv)
	boxplot!(vvv, Vd=dbg2)
	boxplot(mat2ds(randn(20)), Vd=dbg2)
	boxplot!(mat2ds(randn(20)), Vd=dbg2)
	violin(mat2ds(randn(20)), Vd=dbg2)
	violin!(mat2ds(randn(20)), Vd=dbg2)
	violin(vvv, fill=true, boxplot=true, separator=true, scatter=true)
	violin!(vvv, ccolor=true, Vd=dbg2)
	boxplot(vvv, ccolor=true, fill=true, Vd=dbg2)
	boxplot(vvv, fill=true, separator=true)
	violin(randn(30), rand(1:3,30), Vd=dbg2)
	violin!(randn(20), rand(1:3,20), Vd=dbg2)
	boxplot(randn(50), rand(1:3,50), Vd=dbg2)

	qqplot(randn(500), randn(50))
	qqplot(randn(100), randn(50), qqline=:fit)
	qqplot!(randn(200), qqline=:none, Vd=dbg2)
	qqplot!(randn(50), randn(50), qqline=:none, Vd=dbg2)
	qqnorm(randn(200), qqline=:fitrobust)
	qqnorm!(randn(200), qqline=:none, Vd=dbg2)

	GMT.gunique(rand(10))
	GMT.gunique([NaN, rand(10)...])
	ecdfplot!(randn(50), Vd=dbg2)

	GMT.erfinv(-1.0)

	parallelplot("iris.dat",  groupvar="text", normalize="")
	parallelplot("iris.dat",  groupvar="text", normalize="zscore")
	parallelplot("iris.dat",  groupvar="text", normalize="scale", quantile=0.25)
	parallelplot("iris.dat",  normalize="", quantile=0.25, band=true, legend=true)
	parallelplot!("iris.dat", normalize="scale")
	parallelplot("iris.dat", groupvar="text", band=true, quantile=0.25, legend=true)
	parallelplot("iris.dat", groupvar="text", std=1.0, legend=true)
	D = gmtread("iris.dat");
	parallelplot!(D, normalize="scale")
	parallelplot(D, normalize="zscore")
	parallelplot(D, normalize="")

	A = rand(10,2);		A[1] = NaN
	GMT.normalizeArray("zscore", A);
	try cornerplot("lixo"); catch end
	try cornerplot!("lixo"); catch end
	cornerplot(randn(50,3), scatter=true)
	cornerplot(randn(500,3), truths=[0.25, 0.5, 0.75])
	cornerplot(randn(500,3), hexbin=(inc=0.2, threshold=1.0))
	cornerplot!(randn(500,3), hexbin=true)

	marginalhist(randn(1000,2), scatter=true, histkw=(annot=true,))
	marginalhist(randn(1000,2), hexbin=true)
	marginalhist!(randn(2001,2), aspect=:equal)
	try marginalhist("lixo", Vd=dbg2); catch end
	try marginalhist!("lixo", Vd=dbg2); catch end
end