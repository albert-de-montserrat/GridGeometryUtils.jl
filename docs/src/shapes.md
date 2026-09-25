```@meta
CurrentModule = GridGeometryUtils
```

# Shapes

| Dimension | Types |
| --- | --- |
| 2-D | [`Point`](@ref), [`Line`](@ref), [`Segment`](@ref), [`Triangle`](@ref), [`Rectangle`](@ref), [`Trapezoid`](@ref), [`Hexagon`](@ref), [`BBox`](@ref), [`Circle`](@ref), [`Ellipse`](@ref), [`Layering`](@ref) |
| 3-D | [`Point`](@ref), [`Segment`](@ref), [`BBox`](@ref) (also spelled [`Prism`](@ref)), [`Sphere`](@ref) |

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

Every bounded, anchored shape also has a keyword form. Exactly one of `center` and `origin`
must be given. [`Layering`](@ref) accepts only `center`, since it has no minimum corner:

```jldoctest
julia> using GridGeometryUtils

julia> Rectangle(; origin = (-1.0, -2.0), l = 2.0, h = 4.0) == Rectangle((0.0, 0.0), 2.0, 4.0)
true

julia> BBox(; center = (1.0, 2.0), l = 2.0, h = 4.0) == BBox((0.0, 0.0), 2.0, 4.0)
true
```

For a rotated shape, `origin` is the minimum corner of the bounding box at the requested
angle, not necessarily a point on the shape:

```jldoctest
julia> using GridGeometryUtils

julia> rect = Rectangle(; origin = (1.0, 2.0), l = 2.0, h = 4.0, θ = π / 4);

julia> boundingbox(rect).origin ≈ Point(1.0, 2.0)
true
```

`BBox` extents must be non-negative; a 2-D box requires zero depth, and a 3-D keyword
constructor requires `d`. `Trapezoid` requires positive `h` and non-negative `l1` and `l2`.

## Anchors

Anchor fields are named for what they hold, and the two names never swap meaning:

- A field called **`origin`** is the corner with the smallest coordinate on every axis, the
  south-west corner in 2-D. [`BBox`](@ref), and hence [`Prism`](@ref), carries one, with its
  extents running along the positive axes from there, and so does [`Trapezoid`](@ref), whose
  right-angled vertex is exactly that corner.
- A field called **`center`** is the center of the shape. [`Rectangle`](@ref),
  [`Hexagon`](@ref), [`Circle`](@ref), [`Ellipse`](@ref), [`Sphere`](@ref) and
  [`Layering`](@ref) carry one.

[`Triangle`](@ref), [`Segment`](@ref) and [`Line`](@ref) have no anchor of their own: each
is given directly by the points or coefficients that define it.

For bounded shapes, [`center`](@ref) gives the centroid and
[`boundingbox`](@ref) gives the enclosing axis-aligned box, whether or not the shape stores
these as fields. `boundingbox(shape).origin` gives the minimum corner:

```jldoctest
julia> using GridGeometryUtils

julia> hex = Hexagon((0.0, 0.0), 2.0);

julia> center(hex)
Point{2, Float64}([0.0, 0.0])

julia> boundingbox(hex).origin
Point{2, Float64}([-2.0, -1.7320508075688772])

julia> center(Triangle((0.0, 0.0), (3.0, 0.0), (0.0, 3.0)))   # no anchor field at all
Point{2, Float64}([1.0, 1.0])
```

A [`Line`](@ref) has neither: both queries throw `ArgumentError`. A [`Layering`](@ref) has
no bounding box, so `boundingbox` throws, but `center` returns its reference point for
rotation and perturbation. This point is not a centroid of the infinite stack.

A [`Trapezoid`](@ref) with `l1 == l2 == 0` has a bounding box but no centroid: `center`
and construction with the `center` keyword throw `ArgumentError`. Either side alone may
be zero, giving a triangle with a defined centroid.

### Migrating from v0.2

`Rectangle.origin` and `Hexagon.origin` are now named `center`. Their positional
constructors keep the same meaning. Replace reads of the old field with `shape.center`
or `center(shape)`; use `boundingbox(shape).origin` for the minimum corner. Reading the old
field throws an `ArgumentError` explaining the replacement.

Negative `BBox` extents, non-zero depth on a 2-D box, non-positive `Trapezoid` height and
negative parallel sides now throw `ArgumentError`. The new exports `center` and
`boundingbox` may need qualification, such as `GridGeometryUtils.center`, if another
package exports the same names.

## Axis names in 3-D

`BBox{3}` names its extents `l`, `h` and `d`, running along ``x``, ``y`` and ``z``
respectively. [`inside`](@ref) bounds each axis from below as well as from above.

[`Prism`](@ref) is an alias for `BBox{3}` rather than a type of its own, so the two share
every method and a 3-D box prints under the name `Prism` however it was built:

```jldoctest
julia> using GridGeometryUtils

julia> Prism{Float64} === BBox{3, Float64}
true

julia> Sphere((0.0, 0.0, 0.0), 1.0).box
Prism{Float64}(Point{3, Float64}([-1.0, -1.0, -1.0]), 2.0, 2.0, 2.0)
```

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
center
boundingbox
```
