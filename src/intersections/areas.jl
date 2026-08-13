# Corners of an axis-aligned rectangle, counter-clockwise from the south-west one, indexed
# by the integer part of the boundary parameter (see `boundary_param`).
@inline function boundary_corner(r::Rectangle{T}, i::Integer) where {T}
    (; origin, l, h) = r.box
    ox, oy = origin[1], origin[2]
    return if i == 0
        Point(ox, oy)
    elseif i == 1
        Point(ox + l, oy)
    elseif i == 2
        Point(ox + l, oy + h)
    else
        Point(ox, oy + h)
    end
end

"""
    intersecting_area(p1, p2, r::Rectangle) -> Real
    intersecting_area(s::Segment{2}, r::Rectangle) -> Real

Area of the part of the axis-aligned rectangle `r` lying to the **right** of the directed
chord running from `p1` to `p2`. Both points must lie on the boundary of `r`; the two
pieces the chord cuts `r` into are therefore obtained by swapping the arguments, and their
areas sum to `area(r)`.

Rotated rectangles are not supported and throw an `ArgumentError`.

# Examples
```jldoctest
julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> intersecting_area(Point(-1.0, 0.0), Point(1.0, 0.0), r)   # keep the lower half
4.0

julia> intersecting_area(Point(1.0, 0.0), Point(-1.0, 0.0), r)   # keep the upper half
4.0

julia> intersecting_area(Point(-1.0, -2.0), Point(1.0, 2.0), r)  # corner to corner
4.0
```
"""
function intersecting_area(p1, p2, r::Rectangle)
    s1 = boundary_param(p1, r)
    s2 = boundary_param(p2, r)
    # Walking counter-clockwise from `p1` to `p2` traces the piece to the right of the
    # chord; wrapping past the south-west corner keeps that walk in one direction.
    s2 < s1 && (s2 += 4)

    # Shoelace sum over p1 → corners passed on the way → p2 → p1.
    prev = Point(p1[1], p1[2])
    acc = zero(cross2(prev, prev))
    s = floor(s1) + 1
    while s < s2
        corner = boundary_corner(r, Int(s) % 4)
        acc += cross2(prev, corner)
        prev = corner
        s += 1
    end
    acc += cross2(prev, p2)
    acc += cross2(p2, p1)

    return abs(acc) / 2
end

@inline intersecting_area(s::Segment{2}, r::Rectangle) = intersecting_area(s.p1, s.p2, r)
