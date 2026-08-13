# Comparisons that tolerate floating-point round-off. The tolerance is
# `TOL_FACTOR * eps(T)`, relative to the larger operand for `isequal_r` and
# absolute for `isquasizero` (no meaningful relative scale exists near zero).

const TOL_FACTOR = 1000

@inline isquasizero(a::T) where {T <: AbstractFloat} = abs(a) < TOL_FACTOR * eps(T)
@inline isquasizero(a::Integer) = iszero(a)
@inline arequasizero(a, b) = isquasizero(a) && isquasizero(b)

"""
    isequal_r(a, b) -> Bool

Test `a == b` up to a relative tolerance of `$(TOL_FACTOR) * eps`. Operands that are both
within an absolute `$(TOL_FACTOR) * eps` of zero compare equal, since no relative scale is
meaningful there.

Unlike a bare relative difference, this is symmetric: `isequal_r(a, b) == isequal_r(b, a)`
for all `a` and `b`.
"""
@inline function isequal_r(a::T, b::T) where {T <: AbstractFloat}
    a == b && return true
    arequasizero(a, b) && return true
    return abs(a - b) < TOL_FACTOR * eps(T) * max(abs(a), abs(b))
end

@inline isequal_r(a::T, b::T) where {T <: Integer} = a == b

# Mixed types compare at their promotion; identical types that reach here have no `eps`.
@inline isequal_r(a::Number, b::Number) = isequal_r(promote(a, b)...)
@inline isequal_r(::T, ::T) where {T <: Number} = throw(
    ArgumentError("`isequal_r` needs `eps($T)` to size its tolerance, which is not defined")
)

@inline neq_r(a::Number, b::Number) = !isequal_r(a, b)

@inline lt_r(a::Number, b::Number) = !isequal_r(a, b) && a < b
@inline gt_r(a::Number, b::Number) = !isequal_r(a, b) && a > b
@inline leq_r(a::Number, b::Number) = isequal_r(a, b) || a < b
@inline geq_r(a::Number, b::Number) = isequal_r(a, b) || a > b

# Comparison operators rewritten by `@comp`. `===`/`!==` are absent on purpose: they test
# identity, not numeric value, and must survive the rewrite unchanged.
#
# The replacements are `GlobalRef`s rather than bare symbols so that they resolve here
# rather than in the caller's module, which is what lets `@comp` be used from outside the
# package without importing the unexported comparison functions it expands to.
const COMP_SUBSTITUTIONS = Dict(
    :(==) => GlobalRef(@__MODULE__, :isequal_r),
    :(!=) => GlobalRef(@__MODULE__, :neq_r),
    :(≠) => GlobalRef(@__MODULE__, :neq_r),
    :(<) => GlobalRef(@__MODULE__, :lt_r),
    :(>) => GlobalRef(@__MODULE__, :gt_r),
    :(<=) => GlobalRef(@__MODULE__, :leq_r),
    :(≤) => GlobalRef(@__MODULE__, :leq_r),
    :(>=) => GlobalRef(@__MODULE__, :geq_r),
    :(≥) => GlobalRef(@__MODULE__, :geq_r),
)

"""
    @comp expr

Rewrite every comparison operator in `expr` into its round-off-tolerant counterpart, so
`==` becomes [`isequal_r`](@ref), `<` becomes `lt_r`, `≤` becomes `leq_r`, and so on.

The rewrite is purely syntactic and reaches every level of `expr`, so an operator used as a
value (`filter(==(x), v)`) is rewritten too. `===` and `!==` are left alone.

# Examples
```jldoctest
julia> using GridGeometryUtils: @comp

julia> x = 0.1 + 0.2;

julia> x == 0.3
false

julia> @comp x == 0.3
true
```
"""
macro comp(ex)
    return esc(substitute_comp(ex))
end

function substitute_comp(ex::Expr)
    return Expr(ex.head, map(substitute_comp, ex.args)...)
end

substitute_comp(sym::Symbol) = get(COMP_SUBSTITUTIONS, sym, sym)

substitute_comp(x) = x
