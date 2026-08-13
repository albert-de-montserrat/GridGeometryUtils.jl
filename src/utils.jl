"""
    coords(p) -> SVector

Coordinates of `p` as a plain vector, whether `p` is a [`Point`](@ref) or already an
`SVector`. Predicates accept both forms ([`QueryPoint`](@ref)), so anything doing vector
arithmetic on a query point goes through this rather than reaching for the `p` field.
"""
@inline coords(p::Point) = p.p
@inline coords(p::SVector) = p

"""
    QueryPoint{N}

A point in `N` dimensions supplied to a predicate or query, in either accepted form: a
[`Point`](@ref) or a bare `SVector`. Use [`coords`](@ref) to get at its coordinates.
"""
const QueryPoint{N} = Union{Point{N}, SVector{N}}

"""
    cross2(u, v) -> Number

``z`` component of the cross product of two 2-D vectors, i.e. the signed area of the
parallelogram they span. It vanishes exactly when `u` and `v` are parallel.
"""
@inline cross2(u, v) = u[1] * v[2] - u[2] * v[1]

"""
    cross2(a, b, c) -> Number

[`cross2`](@ref) of `b - a` and `c - a`; twice the signed area of the triangle `(a, b, c)`.
Its sign gives the direction of the turn `a → b → c`.
"""
@inline cross2(a, b, c) = (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])

"""
    areparallel(u, v) -> Bool

Test whether the 2-D direction vectors `u` and `v` are parallel, up to round-off.

The test is on the angle between them, not on [`cross2`](@ref) directly: since
`cross2(u, v) == norm(u) * norm(v) * sin(θ)`, dividing by the norms gives a scale-free
tolerance, where an absolute threshold on `cross2` would call any sufficiently small
geometry parallel. Throws an `ArgumentError` for a zero-length vector, which has no
direction to compare.
"""
@inline function areparallel(u, v)
    scale = norm(u) * norm(v)
    iszero(scale) && throw(ArgumentError("parallelism is undefined for a zero-length vector"))
    return isquasizero(cross2(u, v) / scale)
end
