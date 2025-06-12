isequal_r(a::T, b::T) where {T} = abs((a - b) / a) < 50 * eps(a)
isequal_r(a::T1, b::T2) where {T1, T2} = isequal_r(promote(a, b)...)

function le_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a < b
end

function ge_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a > b
end

leq_r(a::Number, b::Number) = isequal_r(a, b) || a < b
geq_r(a::Number, b::Number) = isequal_r(a, b) || a > b
