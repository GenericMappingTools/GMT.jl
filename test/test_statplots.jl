@testset "STATPLOTS" begin
	println("	STATPLOTS")
	GMT.density(randn(100), kernel=:uniform, Vd=dbg2)
	GMT.Normal(randn(50), 0.5)
	GMT.Normal(randn(50), 0.5, 1.0)
	GMT.Uniform(randn(50), 0.0, 1.0)
	GMT._quantile(randn(30), rand(30), [0.25, 0.75])

	violin(randn(50), Vd=dbg2)
	y = randn(100,3);
	violin(y, scatter=true)
	boxplot(randn(100), Vd=dbg2)
	boxplot!(y, fill=true, separator=(:red,), Vd=dbg2)
	boxplot(randn(100,3), outliers=(size="6p",), hbar=true, Vd=dbg2)
	boxplot!(randn(100,3,2), separator=true, cap="5p", Vd=dbg2)

	y = randn(100,3,2);
	violin(y, G=true, split=true)
	violin(y, G=true, split=true, boxplot=true)
	violin(y, G=true, scatter=true, boxplot=true)

	vv = [round.(randn(50),digits=1), round.(randn(40),digits=3)]
	GMT.kernelDensity(vv)

	vvv = [[randn(50), randn(30)], [randn(40), randn(48), randn(45)], [randn(35), randn(43)]];
	GMT.kernelDensity(vvv)
	boxplot(mat2ds(randn(20)), Vd=dbg2)
	violin(vvv, fill=true, boxplot=true, separator=true, scatter=true)
	boxplot(vvv, fill=true, separator=true)
	violin(randn(50), rand(1:3,50), Vd=dbg2)
	boxplot(randn(50), rand(1:3,50), Vd=dbg2)
end