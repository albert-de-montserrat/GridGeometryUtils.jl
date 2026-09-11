```@meta
CurrentModule = GridGeometryUtils
```

# Intersections

## Segments

[`intersection`](@ref) returns the point where the infinite lines through two segments
cross, whether or not that point falls on either segment. [`dointersect`](@ref) answers the
narrower question of whether the segments themselves meet.

```jldoctest
julia> using GridGeometryUtils

julia> s1 = Segment(Point(0, 0), Point(1, 1));

julia> s2 = Segment(Point(3, 1), Point(4, 0));

julia> intersection(s1, s2)     # the lines cross, well past both segments
Point{2, Float64}([2.0, 2.0])

julia> dointersect(s1, s2)      # the segments themselves do not
false
```

Both are solved in parametric form rather than through slope and intercept, so vertical
segments are handled exactly:

```jldoctest
julia> using GridGeometryUtils

julia> dointersect(Segment(Point(0.0, -1.0), Point(0.0, 1.0)), Segment(Point(-1.0, 0.0), Point(1.0, 0.0)))
true
```

Parallel segments have no crossing. [`dointersect`](@ref) reports `false` for them —
including collinear, overlapping ones — while [`intersection`](@ref) raises an
`ArgumentError` rather than returning an infinite point. Parallelism is judged by the angle
between the segments, so the test behaves the same at any scale.

[`Line`](@ref), being in slope-intercept form, cannot represent a vertical line at all and
says so:

```jldoctest
julia> using GridGeometryUtils

julia> Line(Point(0, 0), Point(0, 1))
ERROR: ArgumentError: the vertical line through Point{2, Int64}([0, 0]) and Point{2, Int64}([0, 1]) has no slope-intercept form
[...]
```

## Rectangle chords

A chord between two points on the boundary of a [`Rectangle`](@ref) cuts it in two.
[`intersecting_area`](@ref) returns the area of the piece to the **right** of the directed
chord `p1 → p2`, so swapping the arguments gives the other piece and the two sum to
`area(r)`.

```jldoctest
julia> using GridGeometryUtils

julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> intersecting_area(Point(-1.0, 0.0), Point(1.0, 0.0), r)
4.0

julia> intersecting_area(Point(1.0, 0.0), Point(-1.0, 0.0), r)
4.0

julia> intersecting_area(Point(-1.0, -2.0), Point(1.0, 2.0), r)   # corner to corner
4.0
```

Both endpoints must lie on the boundary; a point elsewhere raises an `ArgumentError`.

A rotated rectangle works the same way. The chord and the corners are taken into the
rectangle's own frame, where it is axis-aligned by construction, and a rotation leaves area
alone:

```jldoctest
julia> using GridGeometryUtils

julia> rot = Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 2);   # now spans x ∈ [-2, 2], y ∈ [-1, 1]

julia> intersecting_area(Point(0.0, -1.0), Point(0.0, 1.0), rot) ≈ 4.0
true
```

## Locating a point on the boundary

[`boundary_param`](@ref) gives a point's position along the boundary as a parameter running
counter-clockwise from the corner the rectangle was built from, one unit per edge.
[`intersecting_boundary`](@ref) reduces that to an edge index. Both name the edges in the
rectangle's own frame, so they turn along with a rotated rectangle.

```jldoctest
julia> using GridGeometryUtils

julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);

julia> boundary_param.([Point(-1.0, -2.0), Point(1.0, -2.0), Point(1.0, 0.0), Point(-1.0, 0.0)], Ref(r))
4-element Vector{Float64}:
 0.0
 1.0
 1.5
 3.5

julia> intersecting_boundary(Point(-1.0, 0.0), r)   # 1 left, 2 right, 3 bottom, 4 top
1
```

Note that these work in the frame of `r.box`, whose `origin` is the south-west corner; a
[`Rectangle`](@ref) itself is anchored at its `center`.

## Reference

```@docs
intersection
dointersect
boundary_param
intersecting_boundary
intersecting_area
```
