using GMT
using Base.Test

# write your own tests here
@test 1 == 1
r = gmt("gmtinfo -C",ones(Float32,9,3)*5);
assert(r[1].data == [5.0 5 5 5 5 3])