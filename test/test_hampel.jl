
println("	HAMPEL")
	
@testset "HAMPEL - Identification" begin
	x = rand(100)
	k = [1,2,20,50,70,90]
	x[k] .= 7
	@test all(findall(hampel(x)).==k)
end

@testset "HAMPEL - Filtering" begin
	t = range(0, 10, length=200)
	x = @. cos(t) + 0.1sin(4t)
	k = [1,5,100,101,102,103,199]
	x[k] .= 2

	y = hampel(x, 3)
	@test findall(y.!=x) == [1, 5, 199]
	y = hampel(x, 5)
	@test findall(y.!=x) == k
	z = hampel(x, fill(1, 11))
	@test all(y.==z)
	y = hampel(x, 5, threshold=3)
	@test findall(y.!=x) == [1, 5, 199]
	
	u = hampel(x,[1,1,1,3,1,1,1])
	v = hampel(x[[94,95,96,97,97,97,98,99,100]], 4)
	@test u[97] ≈ v[5]
end
