"""
    center(object) -> Point

Centroid of `object`: the point its area or volume balances about.

Shapes that store a `center` field return it; the rest compute it. A [`Layering`](@ref) is
infinite and has no centroid, so for it `center` gives the point the stack is rotated and
perturbed about. A [`Line`](@ref) has no center at all.

# Examples
```jldoctest
julia> center(BBox((0.0, 0.0), 2.0, 4.0))
Point{2, Float64}([1.0, 2.0])

julia> center(Triangle((0.0, 0.0), (3.0, 0.0), (0.0, 3.0)))
Point{2, Float64}([1.0, 1.0])
```

See also [`boundingbox`](@ref).
"""
function center end

"""
    boundingbox(object) -> BBox

Smallest axis-aligned box containing `object`.

Shapes carrying a `box` field return it; the rest compute it. Since a [`BBox`](@ref) is
anchored at its minimum-coordinate corner, `boundingbox(object).origin` is that corner for
any bounded shape, whatever the shape itself is anchored at. A [`Line`](@ref) and a
[`Layering`](@ref) are unbounded and have no bounding box.

# Examples
```jldoctest
julia> boundingbox(Hexagon((0.0, 0.0), 2.0)).origin
Point{2, Float64}([-2.0, -1.7320508075688772])

julia> boundingbox(Segment(Point(1.0, 5.0), Point(4.0, 2.0)))
BBox{2, Float64}(Point{2, Float64}([1.0, 2.0]), 3.0, 3.0, 0.0)
```

See also [`center`](@ref).
"""
function boundingbox end

@inline center(x::AbstractGeometryObject) = throw(
    ArgumentError("`center` is not defined for $(typeof(x))")
)
@inline boundingbox(x::AbstractGeometryObject) = throw(
    ArgumentError("`boundingbox` is not defined for $(typeof(x))")
)

@inline center(l::Line) = throw(ArgumentError("a Line extends without bound and has no center"))
@inline boundingbox(l::Line) = throw(
    ArgumentError("a Line extends without bound and has no bounding box")
)
@inline center(lay::Layering) = lay.center
@inline boundingbox(lay::Layering) = throw(
    ArgumentError("a Layering extends without bound and has no bounding box")
)

@inline center(x::Union{Rectangle, Hexagon, Circle, Sphere, Ellipse}) = x.center
@inline boundingbox(x::Union{Rectangle, Hexagon, Circle, Sphere, Ellipse}) = x.box

@inline center(p::Point) = p
@inline boundingbox(p::Point{N}) where {N} = _bbox(coords(p), coords(p))

@inline center(s::Segment) = Point((coords(s.p1) + coords(s.p2)) / 2)

@inline function boundingbox(s::Segment)
    𝐚, 𝐛 = coords(s.p1), coords(s.p2)
    return _bbox(min.(𝐚, 𝐛), max.(𝐚, 𝐛))
end

@inline center(t::Triangle) = Point((coords(t.p1) + coords(t.p2) + coords(t.p3)) / 3)

@inline function boundingbox(t::Triangle)
    𝐩 = (coords(t.p1), coords(t.p2), coords(t.p3))
    return _bbox(min.(𝐩...), max.(𝐩...))
end

@inline center(b::BBox{2}) = Point(coords(b.origin) + SVector(b.l, b.h) / 2)
@inline center(b::BBox{3}) = Point(coords(b.origin) + SVector(b.l, b.h, b.d) / 2)
@inline boundingbox(b::BBox) = b

# Centroid of the quadrilateral (0, 0), (l1, 0), (l2, h), (0, h), offset by `origin`. The
# strip at height y spans [0, l1 + (l2 - l1) * y / h], and integrating over y gives both
# coordinates in closed form.
@inline function center(t::Trapezoid)
    (; origin, h, l1, l2) = t
    s = l1 + l2
    iszero(s) && throw(
        ArgumentError("a trapezoid with l1 == l2 == 0 encloses nothing and has no centroid")
    )
    𝐜 = SVector((l1^2 + l1 * l2 + l2^2) / (3 * s), h * (l1 + 2 * l2) / (3 * s))
    return Point(coords(origin) + 𝐜)
end

@inline boundingbox(t::Trapezoid) = BBox(t.origin, max(t.l1, t.l2), t.h)

# A box spanning `lo` to `hi`, in whichever dimension they carry.
@inline _bbox(lo::SVector, hi::SVector) = BBox(lo.data, (hi - lo)...)
