```@meta
CurrentModule = GridGeometryUtils
```

# Predicates and measures

## Containment

[`inside`](@ref) tests whether a point lies within a shape, boundary included. The point may
be a [`Point`](@ref) or a bare `SVector` of matching dimension.

```jldoctest
julia> using GridGeometryUtils, StaticArrays

julia> circle = Circle((0.0, 0.0), 1.0);

julia> inside(Point(0.5, 0.5), circle), inside(SA[0.5, 0.5], circle)
(true, true)

julia> inside(Point(1.0, 0.0), circle)   # exactly on the boundary
true
```

It is implemented for [`BBox`](@ref), [`Prism`](@ref), [`Triangle`](@ref),
[`Rectangle`](@ref), [`Hexagon`](@ref), [`Circle`](@ref), [`Ellipse`](@ref),
[`Sphere`](@ref) and [`Layering`](@ref). Any other shape raises an `ArgumentError` naming
itself rather than failing obscurely.

Shapes that carry a bounding box test it first and only then run the exact predicate, so a
point far outside is rejected cheaply.

## Area, perimeter and volume

[`area`](@ref) gives the enclosed area of a 2-D shape and the **total surface area** of a
3-D one; [`volume`](@ref) gives the enclosed volume and [`perimeter`](@ref) the boundary
length.

```jldoctest
julia> using GridGeometryUtils

julia> hex = Hexagon((0.0, 0.0), 2.0);

julia> area(hex), perimeter(hex)
(10.392304845413264, 12.0)

julia> prism = Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0);

julia> volume(prism), area(prism)
(24.0, 52.0)
```

Not every measure is defined for every shape — a [`Triangle`](@ref) has no volume — and the
undefined combinations raise an `ArgumentError`:

```jldoctest
julia> using GridGeometryUtils

julia> volume(Triangle((0, 0), (1, 0), (0, 1)))
ERROR: ArgumentError: `volume` is not defined for Triangle{Int64}
[...]
```

## Accuracy notes

- Triangle area uses the shoelace formula rather than Heron's, which loses every significant
  digit to cancellation on sliver triangles.
- [`perimeter`](@ref) of an [`Ellipse`](@ref) is Ramanujan's approximation: exact for a
  circle, and within about `1e-5` relative error up to an eccentricity of `0.99`.
- [`Trapezoid`](@ref) is a *right* trapezoid, so its perimeter assumes one leg perpendicular
  to the parallel sides.

## Reference

```@docs
inside
area
perimeter
volume
```
