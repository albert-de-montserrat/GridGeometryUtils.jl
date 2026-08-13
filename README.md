# GridGeometryUtils.jl

[![Unit tests](https://github.com/albert-de-montserrat/GridGeometryUtils.jl/actions/workflows/UnitTests.yml/badge.svg)](https://github.com/albert-de-montserrat/GridGeometryUtils.jl/actions/workflows/UnitTests.yml)

Geometric primitives and predicates for working with shapes on rectangular grids: point
containment, areas and volumes, and segment/rectangle intersection. Shapes are immutable,
stack-allocated `StaticArrays`-backed structs, and `Adapt`-compatible so they can be moved
to a GPU.

## Installation

```julia
julia> using Pkg; Pkg.add("GridGeometryUtils")
```

## Shapes

| 2-D | 3-D |
| --- | --- |
| `Point`, `Segment`, `Line` | `Point`, `Segment` |
| `Triangle`, `Rectangle`, `Trapezoid`, `Hexagon`, `BBox` | `BBox`, also spelled `Prism` |
| `Circle`, `Ellipse` | `Sphere` |
| `Layering` | |

Every shape is built from a tuple, a `Point` or an `SVector`, and its scalar arguments are
promoted to a common element type:

```julia-repl
julia> using GridGeometryUtils

julia> Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 6)   # rotated counter-clockwise
```

### Where is the origin?

The two conventions differ by shape, and mixing them up is a common source of off-by-half
errors:

- `BBox`, and hence `Prism`, takes the corner with the **smallest** coordinate on every axis.
- `Rectangle`, `Hexagon`, `Circle`, `Ellipse`, `Sphere` and `Layering` take the **center**.

Shapes that carry a `box` field expose their axis-aligned bounding box, whose `origin` is
always the minimum corner:

```julia-repl
julia> rect = Rectangle((0.0, 0.0), 2.0, 4.0);

julia> rect.origin, rect.box.origin
(Point{2, Float64}([0.0, 0.0]), Point{2, Float64}([-1.0, -2.0]))
```

## Measures

`area` returns the enclosed area of a 2-D shape and the total surface area of a 3-D one;
`volume` and `perimeter` do what their names say.

```julia-repl
julia> area(Circle((0.0, 0.0), 1.0))
3.141592653589793

julia> volume(Sphere((0.0, 0.0, 0.0), 1.0))
4.1887902047863905

julia> perimeter(Hexagon((0.0, 0.0), 2.0))
12.0
```

## Point containment

```julia-repl
julia> inside(Point(0.5, 0.5), Circle((0.0, 0.0), 1.0))
true

julia> inside(Point(1.0, 0.0), Circle((0.0, 0.0), 1.0))   # boundaries count as inside
true
```

`inside` accepts a `Point` or a bare `SVector`, and covers every shape in the package. A
`Line` and a `Segment` enclose nothing, so for those it tests whether the point lies *on*
the object.

## Segment intersection

```julia-repl
julia> s1 = Segment(Point(0, 0), Point(1, 1))
Segment{2, Int64}(Point{2, Int64}([0, 0]), Point{2, Int64}([1, 1]))

julia> s2 = Segment(Point(0, 1), Point(1, 0))
Segment{2, Int64}(Point{2, Int64}([0, 1]), Point{2, Int64}([1, 0]))

julia> intersection(s1, s2)      # where the infinite lines cross
Point{2, Float64}([0.5, 0.5])

julia> dointersect(s1, s2)       # whether the segments themselves cross
true
```

`boundary_param` locates a point on the boundary of an axis-aligned rectangle, as a
parameter running counter-clockwise from the south-west corner and covering one unit per
edge; `intersecting_boundary` reduces that to which edge the point is on:

```julia-repl
julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> boundary_param(Point(1.0, 0.0), r)     # halfway up the right edge
1.5

julia> intersecting_boundary(Point(1.0, 0.0), r)   # 1 left, 2 right, 3 bottom, 4 top
2
```

`intersecting_area` splits the rectangle along a chord between two points on its boundary,
returning the area of the piece to the **right** of the directed chord:

```julia-repl
julia> r = Rectangle((0.0, 0.0), 2.0, 4.0);   # spans x ∈ [-1, 1], y ∈ [-2, 2]

julia> intersecting_area(Point(-1.0, 0.0), Point(1.0, 0.0), r)   # the lower half
4.0

julia> intersecting_area(Point(1.0, 0.0), Point(-1.0, 0.0), r)   # the upper half
4.0
```

## Floating-point tolerance

Comparisons throughout are made up to a relative tolerance of about `1000 * eps`, so a
point within round-off of a boundary counts as lying on it. The rewriting macro behind
this, `GridGeometryUtils.@comp`, turns every comparison in an expression into its tolerant
counterpart:

```julia-repl
julia> using GridGeometryUtils: @comp

julia> 0.1 + 0.2 == 0.3
false

julia> @comp 0.1 + 0.2 == 0.3
true
```
