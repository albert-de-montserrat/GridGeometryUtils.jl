"""
    isequal_r(a, b)

Relative floating-point equality check. Returns `true` when `a` and `b` are equal
up to a tolerance of `1e3 * eps(T)`. Both nearly-zero values and values whose
relative difference is within that tolerance are considered equal.

Falls back to exact integer equality for `Integer` arguments.
"""
@inline function isequal_r(a::T, b::T) where {T}
    a == b && return true
    arequasizero(a, b) && return true
    δ = abs((a - b + eps(T)) / (a + eps(T)))
    return δ < 1.0e3 * eps(T)
end

@inline isequal_r(a::Integer, b::Integer) = a == b

@inline isequal_r(a::T1, b::T2) where {T1, T2} = isequal_r(promote(a, b)...)

"""
    le_r(a, b)

Relative strict less-than comparison. Returns `true` when `a < b` and `a` is
not approximately equal to `b` (using [`isequal_r`](@ref)).
"""
@inline le_r(a::Integer, b::Integer) = a < b
@inline le_r(a::Number, b::Number) = isequal_r(a, b) ? false : a < b

"""
    ge_r(a, b)

Relative strict greater-than comparison. Returns `true` when `a > b` and `a` is
not approximately equal to `b` (using [`isequal_r`](@ref)).
"""
@inline ge_r(a::Number, b::Number) = isequal_r(a, b) ? false : a > b
@inline ge_r(a::Integer, b::Integer) = a > b

"""
    leq_r(a, b)

Relative less-than-or-equal comparison. Returns `true` when `a ≤ b` or `a ≈ b`
(using [`isequal_r`](@ref)).
"""
@inline leq_r(a::Number, b::Number) = isequal_r(a, b) || a < b
@inline leq_r(a::Integer, b::Integer) = a ≤ b

"""
    geq_r(a, b)

Relative greater-than-or-equal comparison. Returns `true` when `a ≥ b` or `a ≈ b`
(using [`isequal_r`](@ref)).
"""
@inline geq_r(a::Number, b::Number) = isequal_r(a, b) || a > b
@inline geq_r(a::Integer, b::Integer) = a ≥ b

"""
    arequasizero(a, b)

Return `true` when both `a` and `b` are quasi-zero, i.e., `|a| < 1e3 * eps(T)`.
"""
@inline arequasizero(a, b) = isquasizero(a) && isquasizero(b)

"""
    isquasizero(a)

Return `true` when `|a| < 1e3 * eps(T)`, i.e., `a` is numerically indistinguishable
from zero at working precision.
"""
@inline isquasizero(a::T) where {T} = abs(a) < 1.0e3 * eps(T)

"""
    @comp expr

Rewrite floating-point comparison operators in `expr` to their relative-tolerance
equivalents:

| Operator | Replaced by   |
|----------|---------------|
| `==`     | `isequal_r`   |
| `>`      | `ge_r`        |
| `<`      | `le_r`        |
| `≥`      | `geq_r`       |
| `≤`      | `leq_r`       |

This avoids spurious failures in geometric predicates caused by floating-point
rounding near boundaries.
"""
macro comp(ex)
    substitute_comp(ex)
    return esc(:($ex))
end

@inline function substitute_comp(ex::Expr)
    for (i, arg) in enumerate(ex.args)
        new_arg = substitute_comp(arg)
        if !isnothing(new_arg)
            ex.args[i] = new_arg
        end
    end
    return
end

@inline function substitute_comp(sym::Symbol)
    ex = if sym === :(==)
        :(isequal_r)
    elseif sym === :(>)
        :(ge_r)
    elseif sym === :(<)
        :(le_r)
    elseif sym === :(≥)
        :(geq_r)
    elseif sym === :(≤)
        :(leq_r)
    else
        sym
    end
    return ex
end

@inline substitute_comp(x) = x
