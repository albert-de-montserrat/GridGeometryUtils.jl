"""
    intersection(l::Line, r::Rectangle) -> Vector{Point{2,T}}

Return the 0, 1, or 2 points where infinite line `l` crosses the boundary of
rectangle `r`. Works for both axis-aligned and rotated rectangles by iterating
over the four sides of `r`.

Corner points that would be returned twice are deduplicated.
"""
# Returns a Vector of 0, 1, or 2 Point{2,T} where the line crosses the rectangle boundary.
# Works for both axis-aligned and rotated rectangles (vertices are already transformed).
function intersection(l::Line, r::Rectangle{T}) where {T}
    v = r.vertices  # 2×4 SMatrix, columns: SW, NW, NE, SE
    p_SW = Point(v[1, 1], v[2, 1])
    p_NW = Point(v[1, 2], v[2, 2])
    p_NE = Point(v[1, 3], v[2, 3])
    p_SE = Point(v[1, 4], v[2, 4])

    sides = (
        Segment(p_SW, p_NW),  # left
        Segment(p_NW, p_NE),  # top
        Segment(p_NE, p_SE),  # right
        Segment(p_SE, p_SW),  # bottom
    )

    points = Point{2, T}[]
    for s in sides
        p, hits = intersection(l, s)
        # accept the point only if it lies on the segment and is not a duplicate (corner)
        if hits && !any(isequal_r(p, q) for q in points)
            push!(points, p)
        end
    end

    return points
end

(∩)(l::Line, r::Rectangle) = intersection(l, r)

"""
    intersecting_boundary(p::Point{2}, r::Rectangle) -> Int
    intersecting_boundary(px, py, r::Rectangle) -> Int

Return an integer code indicating which boundary of the axis-aligned rectangle
`r` the point `(px, py)` lies on:

| Code | Meaning  |
|------|----------|
| `1`  | Left     |
| `2`  | Right    |
| `3`  | Bottom   |
| `4`  | Top      |
| `0`  | Interior |

The `Point` overload throws when the point is interior to `r`.
"""
function intersecting_boundary(p::Point{2}, r::Rectangle)
    # Check if the point is on any boundary
    intersect = intersecting_boundary(p[1], p[2], r)
    # If the point is inside the rectangle, we throw an error
    iszero(intersect) && throw("Point is inside the rectangle, no intersection")
    # Otherwise, return the boundary
    return intersect
end

function intersecting_boundary(px, py, r::Rectangle)
    (; origin, h, l) = r
    ox, oy = origin[1], origin[2]
    if @comp oy ≤ py && py ≤ oy + h
        @comp px == ox     && return 1 # :left
        @comp px == ox + l && return 2 # :right
    end
    @comp py ≤ oy     && return 3 # :bottom
    @comp py ≥ oy + h && return 4 # :top
    return 0 # :inside
end
