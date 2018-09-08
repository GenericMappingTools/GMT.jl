# Functions that desapeared on v0.7 for certainly good reasons but for a smell of Edipo's complex as well
function ind2sub(a, i::Integer...)
    i2s = CartesianIndices(a)
    i2s[i...]
end

function eye(A)
    using LinearAlgebra
    copyto!(similar(A, size(A,1), size(A,1)), I)
end