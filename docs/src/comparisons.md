```@meta
CurrentModule = GridGeometryUtils
```

# Tolerant comparisons

Grid geometry is full of points that ought to sit exactly on a boundary and, in floating
point, do not. Every predicate in this package therefore compares up to a relative tolerance
of about `1000 * eps`, rather than exactly.

```jldoctest
julia> using GridGeometryUtils

julia> inside(Point(1.0, 0.0), Circle((0.0, 0.0), 1.0))   # exactly on the boundary
true
```

## The tolerance

[`GridGeometryUtils.isequal_r`](@ref) is the primitive the rest is built on. Two properties
matter:

- It is **symmetric**: `isequal_r(a, b) == isequal_r(b, a)` for all `a` and `b`. A relative
  difference taken against just one operand is not.
- Its tolerance is **relative to the larger operand**, so it means the same thing whatever
  the scale of the geometry, rather than being tuned for coordinates near 1.

Near zero there is no meaningful relative scale, so operands that are both within an
absolute `1000 * eps` of zero compare equal; [`GridGeometryUtils.isquasizero`](@ref) is that
test on its own.

The ordering comparisons [`GridGeometryUtils.lt_r`](@ref) and its siblings follow from it:
values that compare equal are neither strictly less nor strictly greater, and are both `≤`
and `≥`.

## The `@comp` macro

[`GridGeometryUtils.@comp`](@ref) rewrites every comparison operator in an expression into
its tolerant counterpart, which is how the predicates stay readable:

```jldoctest
julia> using GridGeometryUtils: @comp

julia> x = 0.1 + 0.2;

julia> x == 0.3
false

julia> @comp x == 0.3
true

julia> @comp 0.0 ≤ x ≤ 0.3     # chained comparisons work too
true
```

The rewrite covers `==`, `!=`, `≠`, `<`, `>`, `<=`, `≤`, `>=` and `≥`, in both their ASCII
and Unicode spellings. `===` and `!==` are deliberately left alone: they test identity, not
numeric value.

The rewrite is purely syntactic and reaches every level of the expression, so an operator
used as a value — `filter(==(x), v)` — is rewritten as well. It expands to fully qualified
references, so `@comp` works from any module without importing the comparison functions it
produces.

## Reference

```@docs
GridGeometryUtils.isequal_r
GridGeometryUtils.isquasizero
GridGeometryUtils.neq_r
GridGeometryUtils.lt_r
GridGeometryUtils.@comp
GridGeometryUtils.cross2
GridGeometryUtils.areparallel
GridGeometryUtils.coords
GridGeometryUtils.QueryPoint
GridGeometryUtils.rotation_matrix
```
