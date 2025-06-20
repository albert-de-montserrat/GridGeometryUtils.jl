@inline function isequal_r(a::T, b::T) where {T}
    a == b && return true
    arequasizero(a, b) && return true
    δ = abs((a - b + eps(T)) / (a + eps(T)))
    return δ < 1.0e3 * eps(T)
end

@inline isequal_r(a::Integer, b::Integer) = a == b

@inline isequal_r(a::T1, b::T2) where {T1, T2} = isequal_r(promote(a, b)...)

@inline function isequal_r(a::Point{2}, b::Point{2})
    return isequal_r(a[1], b[1]) && isequal_r(a[2], b[2])
end

@inline function isequal_r(a::Point{2}, b::Point{3})
    return isequal_r(a[1], b[1]) && isequal_r(a[2], b[2]) && isequal_r(a[3], b[3])
end

@inline function le_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a < b
end

@inline le_r(a::Integer, b::Integer) = a < b

@inline function ge_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a > b
end

@inline ge_r(a::Integer, b::Integer) = a > b

@inline leq_r(a::Number, b::Number) = isequal_r(a, b) || a < b
@inline geq_r(a::Number, b::Number) = isequal_r(a, b) || a > b
@inline leq_r(a::Integer, b::Integer) = a ≤ b
@inline geq_r(a::Integer, b::Integer) = a ≥ b

@inline arequasizero(a, b) = isquasizero(a) && isquasizero(b)
@inline isquasizero(a::T) where {T} = abs(a) < 1.0e3 * eps(T)
