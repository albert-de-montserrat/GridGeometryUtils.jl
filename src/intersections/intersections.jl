# Edges of a rectangle, identified by the code `intersecting_boundary` returns.
const BOUNDARY_NONE = 0
const BOUNDARY_LEFT = 1
const BOUNDARY_RIGHT = 2
const BOUNDARY_BOTTOM = 3
const BOUNDARY_TOP = 4

# Coordinates of `p` in the frame of `r`: centered on the rectangle with the axes along its
# own sides, so that it spans [-l/2, l/2] × [-h/2, h/2] however it is rotated. Every
# boundary query here works in that frame.
@inline function local_coords(p, r::Rectangle)
    𝐱 = SVector(p[1] - r.origin[1], p[2] - r.origin[2])
    return iszero(r.sinθ) ? 𝐱 : rotation_matrix(r.sinθ, r.cosθ) * 𝐱
end

"""
    boundary_param(p, r::Rectangle) -> Real

Position of `p` along the boundary of `r`, as an arc-length-like parameter in `[0, 4)` that
runs counter-clockwise from the corner `r` was built from: `[0, 1]` along the bottom edge,
`[1, 2]` up the right edge, `[2, 3]` back along the top, and `[3, 4]` down the left edge.

Edges are named in the rectangle's own frame, so a rotated rectangle has the same four
edges carrying the same parameters, turned along with it.

A corner takes the parameter given to it by the earlier of the two edges meeting there, so
the starting corner is `0` rather than `4`.

Throws an `ArgumentError` if `p` does not lie on the boundary.

# Examples
```jldoctest
julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> boundary_param(Point(-1.0, -2.0), r)   # south-west corner
0.0

julia> boundary_param(Point(1.0, 0.0), r)     # halfway up the right edge
1.5

julia> rot = Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 2);

julia> boundary_param(Point(2.0, 0.0), rot) ≈ 0.5   # the bottom edge, turned a quarter turn
true
```

See also [`intersecting_boundary`](@ref) and [`intersecting_area`](@ref).
"""
function boundary_param(p, r::Rectangle)
    (; l, h) = r
    px, py = local_coords(p, r)
    ox, oy = -l / 2, -h / 2

    withinx = geq_r(px, ox) && leq_r(px, ox + l)
    withiny = geq_r(py, oy) && leq_r(py, oy + h)

    # Ordered so that each corner is reached by the earlier of the two edges meeting there,
    # which keeps the parameter of a corner single-valued.
    withinx && isequal_r(py, oy) && return (px - ox) / l
    withiny && isequal_r(px, ox + l) && return 1 + (py - oy) / h
    withinx && isequal_r(py, oy + h) && return 2 + (ox + l - px) / l
    withiny && isequal_r(px, ox) && return 3 + (oy + h - py) / h

    throw(ArgumentError("$p does not lie on the boundary of the rectangle"))
end

"""
    intersecting_boundary(p, r::Rectangle) -> Int

Which edge of `r` the point `p` lies on: `1` for left, `2` for right, `3` for bottom and
`4` for top. Corners belong to the horizontal edge that meets them. The edges are named in
the rectangle's own frame, so they turn with a rotated `r`.

Throws an `ArgumentError` if `p` does not lie on the boundary of `r`.

# Examples
```jldoctest
julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> intersecting_boundary(Point(-1.0, 0.0), r)
1

julia> intersecting_boundary(Point(0.0, 2.0), r)
4
```

See also [`boundary_param`](@ref).
"""
function intersecting_boundary(p, r::Rectangle)
    s = boundary_param(p, r)
    s ≤ 1 && return BOUNDARY_BOTTOM
    s ≤ 2 && return BOUNDARY_RIGHT
    s ≤ 3 && return BOUNDARY_TOP
    return BOUNDARY_LEFT
end
