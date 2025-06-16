@inline function isequal_r(a::T, b::T) where {T}
    a == b && return true
    δ = abs((a - b + eps(T)) / (a + eps(T)))
    return δ < 50 * eps(T) || isone(δ)
end

@inline isequal_r(a::T1, b::T2) where {T1, T2} = isequal_r(promote(a, b)...)

@inline function le_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a < b
end

@inline function ge_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a > b
end

@inline leq_r(a::Number, b::Number) = isequal_r(a, b) || a < b
@inline geq_r(a::Number, b::Number) = isequal_r(a, b) || a > b
