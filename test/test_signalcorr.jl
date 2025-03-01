# The reference results are generated from R.

@testset "SIGNALCORR" begin

	println("	SIGNALCORR")

    conv(reshape(1:9,3,3), reshape(1:16,4,4))
    conv(reshape(1:16,4,4), reshape(1:9,3,3))
    conv([-1, 2, 3, -2, 0, 1, 2], [2, 4, -1, 1], shape=:same)

# random data for testing
x = [-2.133252557240862    -.7445937365828654;
       .1775816414485478   -.5834801838041446;
      -.6264517920318317   -.68444205333293;
      -.8809042583216906    .9071671734302398;
       .09251017186697393 -1.0404476733379926;
      -.9271887119115569   -.620728578941385;
      3.355819743178915    -.8325051361909978;
      -.2834039258495755   -.22394811874731657;
       .5354280026977677    .7481337671592626;
       .39182285417742585   .3085762550821047]

x1 = view(x, :, 1)
x2 = view(x, :, 2)
realx = convert(AbstractMatrix{Real}, x)
realx1 = convert(AbstractVector{Real}, x1)
realx2 = convert(AbstractVector{Real}, x2)

# autocov & autocorr

@test GMT.autocov([1:5;])          ≈ [2.0, 0.8, -0.2, -0.8, -0.8]
@test GMT.autocor([1, 2, 3, 4, 5]) ≈ [1.0, 0.4, -0.1, -0.4, -0.4]

racovx1 =  [1.839214242630635709475,
           -0.406784553146903871124,
            0.421772254824993531042,
            0.035874943792884653182,
           -0.255679775928512320604,
            0.231154400105831353551,
           -0.787016960267425180753,
            0.039909287349160660341,
           -0.110149697877911914579,
           -0.088687020167434751916]

@test GMT.autocov(x1) ≈ racovx1
@test GMT.autocov(realx1) ≈ racovx1
@test GMT.autocov(x)  ≈ [GMT.autocov(x1) GMT.autocov(x2)]
@test GMT.autocov(realx)  ≈ [GMT.autocov(realx1) GMT.autocov(realx2)]
@test xcov(x1) ≈ racovx1
@test xcov(realx1) ≈ racovx1
@test xcov(x)  ≈ [GMT.autocov(x1) GMT.autocov(x2)]
@test xcov(realx)  ≈ [GMT.autocov(realx1) GMT.autocov(realx2)]

racorx1 = [0.999999999999999888978,
          -0.221173011668873431557,
           0.229321981664153962122,
           0.019505581764945757045,
          -0.139015765538446717242,
           0.125681062460244019618,
          -0.427909344123907742219,
           0.021699096507690283225,
          -0.059889541590524189574,
          -0.048220059475281865091]

@test GMT.autocor(x1) ≈ racorx1
@test GMT.autocor(realx1) ≈ racorx1
@test GMT.autocor(x)  ≈ [GMT.autocor(x1) GMT.autocor(x2)]
@test GMT.autocor(realx)  ≈ [GMT.autocor(realx1) GMT.autocor(realx2)]
@test xcorr(x1)     ≈ racorx1
@test xcorr(realx1) ≈ racorx1
@test xcorr(x)      ≈ [GMT.autocor(x1) GMT.autocor(x2)]
@test xcorr(realx)  ≈ [GMT.autocor(realx1) GMT.autocor(realx2)]


# crosscov & crosscor

rcov0 = [0.320000000000000006661,
        -0.319999999999999951150,
         0.080000000000000029421,
        -0.479999999999999982236,
         0.000000000000000000000,
         0.479999999999999982236,
        -0.080000000000000029421,
         0.319999999999999951150,
        -0.320000000000000006661]

@test GMT.crosscov([1, 2, 3, 4, 5], [1, -1, 1, -1, 1]) ≈ rcov0
@test GMT.crosscov([1:5;], [1:5;]) ≈ [-0.8, -0.8, -0.2, 0.8, 2.0, 0.8, -0.2, -0.8, -0.8]

c11 = GMT.crosscov(x1, x1)
c12 = GMT.crosscov(x1, x2)
c21 = GMT.crosscov(x2, x1)
c22 = GMT.crosscov(x2, x2)
@test GMT.crosscov(realx1, realx2) ≈ c12
@test xcov(realx1, realx2) ≈ c12

@test GMT.crosscov(x,  x1) ≈ [c11 c21]
@test GMT.crosscov(realx, realx1) ≈ [c11 c21]
#@test GMT.crosscov(x1, x)  ≈ [c11 c12]
#@test GMT.crosscov(realx1, realx)  ≈ [c11 c12]
@test GMT.crosscov(x,  x)  ≈ cat([c11 c21], [c12 c22], dims=3)
@test GMT.crosscov(realx,  realx)  ≈ cat([c11 c21], [c12 c22], dims=3)
@test xcov(x,  x1) ≈ [c11 c21]
@test xcov(realx, realx1) ≈ [c11 c21]
@test xcov(x,  x)  ≈ cat([c11 c21], [c12 c22], dims=3)
@test xcov(realx,  realx)  ≈ cat([c11 c21], [c12 c22], dims=3)

# issue #805: avoid converting one input to the other's eltype
@test GMT.crosscov([34566.5345, 3466.4566], Float16[1, 10]) ≈
    GMT.crosscov(Float16[1, 10], [34566.5345, 3466.4566]) ≈
    GMT.crosscov([34566.5345, 3466.4566], Float16[1, 10])

rcor0 = [0.230940107675850,
        -0.230940107675850,
         0.057735026918963,
        -0.346410161513775,
         0.000000000000000,
         0.346410161513775,
        -0.057735026918963,
         0.230940107675850,
        -0.230940107675850]

@test GMT.crosscor([1, 2, 3, 4, 5], [1, -1, 1, -1, 1]) ≈ rcor0
@test GMT.crosscor([1:5;], [1:5;]) ≈ [-0.4, -0.4, -0.1, 0.4, 1.0, 0.4, -0.1, -0.4, -0.4]
@test xcorr([1, 2, 3, 4, 5], [1, -1, 1, -1, 1]) ≈ rcor0
@test xcorr([1:5;], [1:5;]) ≈ [-0.4, -0.4, -0.1, 0.4, 1.0, 0.4, -0.1, -0.4, -0.4]

c11 = GMT.crosscor(x1, x1)
c12 = GMT.crosscor(x1, x2)
c21 = GMT.crosscor(x2, x1)
c22 = GMT.crosscor(x2, x2)
@test GMT.crosscor(realx1, realx2) ≈ c12
@test xcorr(realx1, realx2) ≈ c12

@test GMT.crosscor(x,  x1) ≈ [c11 c21]
@test xcorr(x,  x1) ≈ [c11 c21]
@test GMT.crosscor(realx, realx1) ≈ [c11 c21]
@test xcorr(realx, realx1) ≈ [c11 c21]
@test GMT.crosscor(x1, x)  ≈ [c11 c12]
@test xcorr(x1, x)  ≈ [c11 c12]
@test GMT.crosscor(realx1, realx)  ≈ [c11 c12]
@test xcorr(realx1, realx)  ≈ [c11 c12]
@test GMT.crosscor(x,  x)  ≈ cat([c11 c21], [c12 c22], dims=3)
@test xcorr(x,  x)  ≈ cat([c11 c21], [c12 c22], dims=3)
@test GMT.crosscor(realx, realx)  ≈ cat([c11 c21], [c12 c22], dims=3)
@test xcorr(realx, realx)  ≈ cat([c11 c21], [c12 c22], dims=3)

# issue #805: avoid converting one input to the other's eltype
@test GMT.crosscor([34566.5345, 3466.4566], Float16[1, 10]) ≈
    GMT.crosscor(Float16[1, 10], [34566.5345, 3466.4566]) ≈
    GMT.crosscor([34566.5345, 3466.4566], Float16[1, 10])

end