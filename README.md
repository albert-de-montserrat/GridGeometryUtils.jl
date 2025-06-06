# GridGeometryUtils.jl

This package utility functions to do geometry operations on rectangular grids, such as intersections between different geometric objects.

## Example: segment-segment intersection

```julia-repl
julia> using GridGeometryUtils

julia> s1 = Segment(Point(0, 0), Point(1, 1))
Segment{2, Int64}(Point{2, Int64}((0, 0)), Point{2, Int64}((1, 1)))

julia> s2 = Segment(Point(0, 1), Point(1, 0))
Segment{2, Int64}(Point{2, Int64}((0, 1)), Point{2, Int64}((1, 0)))

julia> intersection(s1, s2)
Point{2, Float64}((0.5, 0.5))
```
