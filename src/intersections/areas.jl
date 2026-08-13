# Corners of a rectangle in its own frame, counter-clockwise from the one the boundary
# parameter starts at, indexed by the integer part of that parameter (see `boundary_param`).
@inline function boundary_corner(r::Rectangle, i::Integer)
    x, y = r.l / 2, r.h / 2
    return if i == 0
        SVector(-x, -y)
    elseif i == 1
        SVector(x, -y)
    elseif i == 2
        SVector(x, y)
    else
        SVector(-x, y)
    end
end

"""
    intersecting_area(p1, p2, r::Rectangle) -> Real
    intersecting_area(s::Segment{2}, r::Rectangle) -> Real

Area of the part of the rectangle `r` lying to the **right** of the directed chord running
from `p1` to `p2`. Both points must lie on the boundary of `r`; the two pieces the chord
cuts `r` into are therefore obtained by swapping the arguments, and their areas sum to
`area(r)`.

# Examples
```jldoctest
julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> intersecting_area(Point(-1.0, 0.0), Point(1.0, 0.0), r)   # keep the lower half
4.0

julia> intersecting_area(Point(1.0, 0.0), Point(-1.0, 0.0), r)   # keep the upper half
4.0

julia> intersecting_area(Point(-1.0, -2.0), Point(1.0, 2.0), r)  # corner to corner
4.0

julia> rot = Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 2);

julia> intersecting_area(Point(0.0, -1.0), Point(0.0, 1.0), rot) ≈ 4.0
true
```
"""
function intersecting_area(p1, p2, r::Rectangle)
    s1 = boundary_param(p1, r)
    s2 = boundary_param(p2, r)
    # Walking counter-clockwise from `p1` to `p2` traces the piece to the right of the
    # chord; wrapping past the starting corner keeps that walk in one direction.
    s2 < s1 && (s2 += 4)

    # Shoelace sum over p1 → corners passed on the way → p2 → p1, taken in the frame of `r`,
    # which is a rotation away from the world frame and so leaves the area unchanged.
    q1 = local_coords(p1, r)
    q2 = local_coords(p2, r)

    prev = q1
    acc = zero(cross2(prev, prev))
    s = floor(s1) + 1
    while s < s2
        corner = boundary_corner(r, Int(s) % 4)
        acc += cross2(prev, corner)
        prev = corner
        s += 1
    end
    acc += cross2(prev, q2)
    acc += cross2(q2, q1)

    return abs(acc) / 2
end

@inline intersecting_area(s::Segment{2}, r::Rectangle) = intersecting_area(s.p1, s.p2, r)
