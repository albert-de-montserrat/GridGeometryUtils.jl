```@meta
CurrentModule = GridGeometryUtils
```

# Shapes

| Dimension | Types |
| --- | --- |
| 2-D | [`Point`](@ref), [`Line`](@ref), [`Segment`](@ref), [`Triangle`](@ref), [`Rectangle`](@ref), [`Trapezoid`](@ref), [`Hexagon`](@ref), [`BBox`](@ref), [`Circle`](@ref), [`Ellipse`](@ref), [`Layering`](@ref) |
| 3-D | [`Point`](@ref), [`Segment`](@ref), [`Prism`](@ref), [`BBox`](@ref), [`Sphere`](@ref) |

## Construction

Every shape accepts its anchor point as a tuple, a [`Point`](@ref) or an `SVector`, and
promotes all of its arguments to a common element type:

```jldoctest
julia> using GridGeometryUtils, StaticArrays

julia> Circle((0, 0), 1.0) == Circle(Point(0.0, 0.0), 1.0) == Circle(SA[0.0, 0.0], 1.0)
true

julia> Circle((0, 0), 1)          # an all-integer circle stays integer
Circle{Int64}(Point{2, Int64}([0, 0]), 1, BBox{2, Int64}(Point{2, Int64}([-1, -1]), 2, 2, 0))
```

Shapes that can be rotated take a `θ` keyword, in radians, counter-clockwise about their
center:

```jldoctest
julia> using GridGeometryUtils

julia> rect = Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 2);

julia> inside(Point(1.9, 0.0), rect)   # the long side now runs along x
true
```

## Origins

This is the single most common source of off-by-half errors, so it is worth stating plainly:

- [`BBox`](@ref) and [`Prism`](@ref) are anchored at the **minimum-coordinate corner** — the
  south-west corner in 2-D — with their extents running along the positive axes from there.
- [`Rectangle`](@ref), [`Hexagon`](@ref), [`Circle`](@ref), [`Ellipse`](@ref),
  [`Sphere`](@ref) and [`Layering`](@ref) are anchored at their **center**.
- [`Trapezoid`](@ref) is anchored at the vertex holding its right angle.

Shapes that carry a `box` field expose their axis-aligned bounding box, and a `BBox` origin
is always the minimum corner, whatever the shape it bounds:

```jldoctest
julia> using GridGeometryUtils

julia> hex = Hexagon((0.0, 0.0), 2.0);

julia> hex.origin
Point{2, Float64}([0.0, 0.0])

julia> hex.box.origin
Point{2, Float64}([-2.0, -1.7320508075688772])
```

## Axis names in 3-D

`BBox{3}` and `Prism` name their extents `l`, `h` and `d`, running along ``x``, ``y`` and
``z`` respectively. [`inside`](@ref) bounds each axis from below as well as from above.

```jldoctest
julia> using GridGeometryUtils

julia> box = BBox((0.0, 0.0, 0.0), 2.0, 4.0, 3.0);   # x ∈ [0,2], y ∈ [0,4], z ∈ [0,3]

julia> inside(Point(1.0, 3.5, 1.0), box)
true

julia> inside(Point(1.0, 1.0, 3.5), box)
false
```

## Moving shapes to a GPU

Every shape is registered with `Adapt`, so `adapt` rebuilds it with converted storage:

```julia
using Adapt, CUDA
gpu_circle = adapt(CuArray, Circle((0.0, 0.0), 1.0))
```

## Reference

```@docs
Point
distance
Line
line
Segment
Triangle
Rectangle
Trapezoid
Hexagon
BBox
Prism
Circle
Ellipse
Sphere
Layering
```
