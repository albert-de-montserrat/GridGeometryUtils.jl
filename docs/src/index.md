```@meta
CurrentModule = GridGeometryUtils
```

# GridGeometryUtils.jl

Geometric primitives and predicates for working with shapes on rectangular grids: point
containment, areas and volumes, and segment/rectangle intersection.

Shapes are immutable, stack-allocated `StaticArrays`-backed structs, and `Adapt`-compatible
so they can be moved to a GPU.

## Installation

```julia-repl
julia> using Pkg; Pkg.add("GridGeometryUtils")
```

## A first look

```jldoctest
julia> using GridGeometryUtils

julia> circle = Circle((0.0, 0.0), 1.0);

julia> area(circle)
3.141592653589793

julia> inside(Point(0.5, 0.5), circle)
true

julia> inside(Point(1.0, 1.0), circle)
false
```

## Where to go next

- [Shapes](@ref) — what each type represents, and where it is anchored.
- [Predicates and measures](@ref) — `inside`, `area`, `perimeter` and `volume`.
- [Intersections](@ref) — segment crossings and rectangle chords.
- [Tolerant comparisons](@ref) — the floating-point tolerance every predicate is built on.
- [API reference](@ref) — every exported name.

## Two conventions worth knowing up front

**Anchors are named for what they are.** A field called `origin` is always the corner with
the smallest coordinate on every axis, and a field called `center` is always the center.
[`BBox`](@ref), also spelled [`Prism`](@ref) in 3-D, and [`Trapezoid`](@ref) carry an
`origin`; every other shape carries a `center`. Either can be given by name when building a
shape, and [`center`](@ref) and [`boundingbox`](@ref) read them back from any shape at all:

```jldoctest
julia> using GridGeometryUtils

julia> rect = Rectangle(; origin = (-1.0, -2.0), l = 2.0, h = 4.0);

julia> center(rect), boundingbox(rect).origin
(Point{2, Float64}([0.0, 0.0]), Point{2, Float64}([-1.0, -2.0]))
```

**Comparisons are tolerant.** Every predicate compares up to a relative tolerance of about
`1000 * eps`, so a point within round-off of a boundary counts as lying on it. See
[Tolerant comparisons](@ref).
