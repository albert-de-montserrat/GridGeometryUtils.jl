# Coordinates of a point, which may be given either as a `Point` or as a raw vector.
@inline coords(p::Point) = p.p
@inline coords(p::SVector) = p

# A point supplied to a predicate or query, in either accepted form.
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

# Parallelism test for two 2-D direction vectors. `cross2(u, v) == norm(u) * norm(v) * sinθ`,
# so dividing by the norms gives a scale-free (angular) tolerance; an absolute threshold on
# `cross2` alone would call any sufficiently small geometry parallel.
@inline function areparallel(u, v)
    scale = norm(u) * norm(v)
    iszero(scale) && throw(ArgumentError("parallelism is undefined for a zero-length vector"))
    return isquasizero(cross2(u, v) / scale)
end
