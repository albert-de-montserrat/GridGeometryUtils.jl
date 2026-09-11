abstract type AbstractPolygon{T} <: AbstractGeometryObject{T} end

"""
    BBox{N, T} <: AbstractPolygon{T}
    BBox(origin, l, h[, d])
    BBox(; origin, l, h[, d])
    BBox(; center, l, h[, d])

An axis-aligned bounding box in `N` dimensions.

`origin` is the corner with the **smallest** coordinate along every axis, the south-west
corner in 2-D. The extents run along the positive axes from there: `l` along ``x``, `h`
along ``y``, and `d` along ``z``. `d` is zero for `N == 2`. No extent may be negative.

The keyword forms name the anchor: `origin` is the minimum-coordinate corner and
`center` the centroid. Exactly one of the two is accepted.

# Fields
- `origin::Point{N, T}`: minimum-coordinate corner.
- `l::T`: extent along ``x``.
- `h::T`: extent along ``y``.
- `d::T`: extent along ``z``, zero in 2-D.

# Examples
```jldoctest
julia> box = BBox((0.0, 0.0), 2.0, 4.0);

julia> area(box)
8.0

julia> inside(Point(1.0, 3.0), box)
true
```
"""
struct BBox{N, T} <: AbstractPolygon{T}
    origin::Point{N, T}
    l::T # length
    h::T # height
    d::T # depth

    function BBox{N, T}(origin, l, h, d) where {N, T}
        # A negative extent would put `origin` somewhere other than the minimum corner,
        # which every containment and intersection query here relies on.
        (l < 0 || h < 0 || d < 0) && throw(
            ArgumentError("BBox extents must be non-negative, got l = $l, h = $h, d = $d")
        )
        N == 2 && !iszero(d) && throw(
            ArgumentError("a 2-D BBox has no depth, got d = $d")
        )
        return new{N, T}(origin, l, h, d)
    end
end

Adapt.@adapt_structure BBox

function BBox(origin::Tuple{Vararg{Number, N}}, l::Number, h::Number, d::Number) where {N}
    T = promote_type(eltype(promote(origin...)), typeof(l), typeof(h), typeof(d))
    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(N))...)
    return BBox{N, T}(origin_promoted, promote(l, h, d)...)
end

BBox(origin::Tuple{Vararg{Number, 2}}, l::Number, h::Number) = BBox(origin, l, h, 0)
BBox(origin::Point{2}, l::Number, h::Number) = BBox(totuple(origin), l, h, 0)
BBox(origin::Point{N}, l::Number, h::Number, d::Number) where {N} = BBox(totuple(origin), l, h, d)
BBox(origin::SVector{2}, l::Number, h::Number) = BBox(origin.data, l, h, 0)
BBox(origin::SVector{3}, l::Number, h::Number, d::Number) = BBox(origin.data, l, h, d)

"""
    Triangle{T} <: AbstractPolygon{T}

A triangle in 2-D, given by its three vertices.

The vertices must be distinct; collinear vertices are permitted but give an
[`area`](@ref) of zero.

# Fields
- `p1::Point{2, T}`, `p2::Point{2, T}`, `p3::Point{2, T}`: the vertices.

# Examples
```jldoctest
julia> t = Triangle((0, 0), (1, 0), (0, 1));

julia> area(t)
0.5
```
"""
struct Triangle{T} <: AbstractPolygon{T}
    p1::Point{2, T}
    p2::Point{2, T}
    p3::Point{2, T}

    function Triangle(p1::Point{2, T1}, p2::Point{2, T2}, p3::Point{2, T3}) where {T1, T2, T3}
        (p1 == p2 || p2 == p3 || p1 == p3) &&
            throw(ArgumentError("the three vertices of a Triangle must be distinct, got $p1, $p2, $p3"))
        T = promote_type(T1, T2, T3)
        points = p1, p2, p3
        points_promoted = ntuple(i -> Point(SVector{2, T}(points[i].p)), Val(3))
        return new{T}(points_promoted...)
    end
end

@inline Triangle(p1::NTuple{2}, p2::NTuple{2}, p3::NTuple{2}) = Triangle(Point(p1), Point(p2), Point(p3))
@inline Triangle(p1::SVector{2}, p2::SVector{2}, p3::SVector{2}) = Triangle(Point(p1), Point(p2), Point(p3))

Adapt.@adapt_structure Triangle

"""
    Rectangle{T} <: AbstractPolygon{T}
    Rectangle(center, l, h; θ = 0)
    Rectangle(; center, l, h, θ = 0)
    Rectangle(; origin, l, h, θ = 0)

A rectangle of width `l` and height `h`, optionally rotated counter-clockwise by `θ`
radians about its center.

The enclosing axis-aligned box is available as the `box` field, so `box.origin` is the
south-west corner.

The keyword forms name the anchor: `center` is the center and `origin` the
minimum-coordinate corner of the enclosing box. Exactly one of the two is accepted.

# Fields
- `center::Point{2, T}`: center.
- `l::T`, `h::T`: width and height, measured in the rectangle's own frame.
- `sinθ::T`, `cosθ::T`: sine and cosine of the rotation angle.
- `box::BBox{2, T}`: enclosing axis-aligned bounding box.
- `vertices::SMatrix{2, 4, T, 8}`: corners as columns, ordered SW, NW, NE, SE.

# Examples
```jldoctest
julia> rect = Rectangle((0.0, 0.0), 2.0, 4.0);

julia> rect.box.origin
Point{2, Float64}([-1.0, -2.0])

julia> Rectangle(; origin = (-1.0, -2.0), l = 2.0, h = 4.0) == rect
true

julia> area(rect)
8.0
```
"""
struct Rectangle{T} <: AbstractPolygon{T}
    center::Point{2, T}
    l::T # length
    h::T # height
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 4, T, 8}
end

function Rectangle(center::Tuple{Vararg{Number, 2}}, l::Number, h::Number; θ::Number = 0.0)
    T = promote_type(eltype(promote(center...)), typeof(l), typeof(h), typeof(θ))

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    # Vertices, ordered SW, NW, NE, SE
    𝐱SW = center .+ @SVector [-l / 2, -h / 2]
    𝐱SE = center .+ @SVector [l / 2, -h / 2]
    𝐱NW = center .+ @SVector [-l / 2, h / 2]
    𝐱NE = center .+ @SVector [l / 2, h / 2]
    𝐱 = SMatrix{2, 4}([ 𝐱SW 𝐱NW 𝐱NE 𝐱SE])

    vertices, box = if iszero(θ)
        origin_bbox = center .+ @SVector [-l / 2, -h / 2]
        𝐱, BBox(origin_bbox, l, h)
    else
        𝐑 = rotation_matrix(sinθ, cosθ)

        # Rotate the geometry about the center
        𝐱′ = 𝐑' * (𝐱 .- center) .+ center

        lbox = maximum(𝐱′[1, :]) - minimum(𝐱′[1, :])
        hbox = maximum(𝐱′[2, :]) - minimum(𝐱′[2, :])
        origin_bbox = center .+ @SVector [-lbox / 2, -hbox / 2]

        𝐱′, BBox(origin_bbox, lbox, hbox)
    end

    center_promoted = Point(ntuple(ix -> T(center[ix]), Val(2))...)
    return Rectangle{T}(center_promoted, promote(l, h, sinθ, cosθ)..., box, vertices)
end

Rectangle(center::Point{2}, l::Number, h::Number; θ::Number = 0.0) = Rectangle(totuple(center), l, h; θ)
Rectangle(center::SVector{2}, l::Number, h::Number; θ::Number = 0.0) = Rectangle(center.data, l, h; θ)

Adapt.@adapt_structure Rectangle

"""
    Hexagon{T} <: AbstractPolygon{T}
    Hexagon(center, radius; θ = 0)
    Hexagon(; center, radius, θ = 0)
    Hexagon(; origin, radius, θ = 0)

A regular hexagon of circumradius `radius`, optionally rotated counter-clockwise by `θ`
radians about its center. At `θ == 0` a vertex lies at `center + (radius, 0)`.

The keyword forms name the anchor: `center` is the center and `origin` the
minimum-coordinate corner of the enclosing box. Exactly one of the two is accepted.

# Fields
- `center::Point{2, T}`: center.
- `radius::T`: circumradius, i.e. the center-to-vertex distance.
- `sinθ::T`, `cosθ::T`: sine and cosine of the rotation angle.
- `box::BBox{2, T}`: enclosing axis-aligned bounding box.
- `vertices::SMatrix{2, 6, T, 12}`: corners as columns, counter-clockwise from `θ`.

# Examples
```jldoctest
julia> hex = Hexagon((0.0, 0.0), 2.0);

julia> perimeter(hex)
12.0
```
"""
struct Hexagon{T} <: AbstractPolygon{T}
    center::Point{2, T}
    radius::T
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 6, T, 12}
end

function Hexagon(center::Tuple{Vararg{Number, 2}}, radius::Number; θ::Number = 0.0)
    T = promote_type(eltype(promote(center...)), typeof(radius), typeof(θ))

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    α = ntuple(i -> (i - 1) * π / 3 + θ, Val(6))
    vertices = hcat(
        ntuple(i -> SVector(center[1] + radius * cos(α[i]), center[2] + radius * sin(α[i])), Val(6))...
    )

    lbox = maximum(vertices[1, :]) - minimum(vertices[1, :])
    hbox = maximum(vertices[2, :]) - minimum(vertices[2, :])
    origin_bbox = center .+ @SVector [-lbox / 2, -hbox / 2]
    box = BBox(origin_bbox, lbox, hbox)

    center_promoted = Point(ntuple(ix -> T(center[ix]), Val(2))...)
    return Hexagon{T}(center_promoted, promote(radius, sinθ, cosθ)..., box, vertices)
end

Hexagon(center::Point{2}, radius::Number; θ::Number = 0.0) = Hexagon(totuple(center), radius; θ)
Hexagon(center::SVector{2}, radius::Number; θ::Number = 0.0) = Hexagon(center.data, radius; θ)

Adapt.@adapt_structure Hexagon

# `shape.origin` is a mistake these types invite, and a bare `no field origin` error does
# not say where the anchor actually is. Deprecation aid for the field name used up to
# v0.2; remove once v0.2 is out of use.
@inline function Base.getproperty(shape::Union{Rectangle, Hexagon}, name::Symbol)
    name === :origin && throw(
        ArgumentError(
            "a $(nameof(typeof(shape))) is anchored at its `center`, not at an `origin`; " *
            "its minimum-coordinate corner is `boundingbox(shape).origin`"
        )
    )
    return getfield(shape, name)
end

"""
    Prism{T}
    Prism(origin, l, h, d)
    Prism(; origin, l, h, d)
    Prism(; center, l, h, d)

An axis-aligned rectangular cuboid: an alias for `BBox{3, T}`, and hence the very same
type, sharing its fields and every method defined on it. `Prism` is the name a 3-D box
prints under.

`origin` is the corner with the smallest coordinate along every axis, and the extents `l`,
`h` and `d` run along the positive ``x``, ``y`` and ``z`` axes from there.

# Examples
```jldoctest
julia> volume(Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0))
24.0

julia> Prism{Float64} === BBox{3, Float64}
true
```
"""
const Prism{T} = BBox{3, T}

Prism(origin::Tuple{Vararg{Number, 3}}, l::Number, h::Number, d::Number) = BBox(origin, l, h, d)
Prism(origin::Point{3}, l::Number, h::Number, d::Number) = BBox(origin, l, h, d)
Prism(origin::SVector{3}, l::Number, h::Number, d::Number) = BBox(origin, l, h, d)

"""
    Trapezoid{T} <: AbstractPolygon{T}
    Trapezoid(origin, h, l1, l2)
    Trapezoid(; origin, h, l1, l2)
    Trapezoid(; center, h, l1, l2)

A right trapezoid: two parallel sides of lengths `l1` and `l2`, separated by `h`, with the
right angle at `origin`, which is therefore also its minimum-coordinate corner.

`l1` runs along the positive ``x`` axis from `origin`; `l2` runs parallel to it from
`origin + (0, h)`. `h` must be positive and neither parallel side may be negative.

The keyword forms name the anchor: `origin` is the minimum-coordinate corner and
`center` the centroid. Exactly one of the two is accepted.

# Fields
- `origin::Point{2, T}`: vertex at the right angle.
- `h::T`: distance between the two parallel sides.
- `l1::T`, `l2::T`: lengths of the parallel sides, at `origin` and at `origin + (0, h)`.

# Examples
```jldoctest
julia> t = Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0);

julia> area(t)
7.0

julia> inside(Point(3.5, 1.0), t)   # halfway up, on the slanted leg
true
```
"""
struct Trapezoid{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    h::T
    l1::T
    l2::T

    function Trapezoid{T}(origin, h, l1, l2) where {T}
        h > 0 || throw(ArgumentError("trapezoid height must be positive, got $h"))
        # Both parallel sides run along the positive x axis from `origin`, so a negative
        # one would move the minimum corner off it.
        (l1 < 0 || l2 < 0) && throw(
            ArgumentError("trapezoid side lengths must be non-negative, got l1 = $l1, l2 = $l2")
        )
        return new{T}(origin, h, l1, l2)
    end
end

function Trapezoid(origin::Tuple{Vararg{Number, 2}}, h::Number, l1::Number, l2::Number)
    T = promote_type(eltype(promote(origin...)), typeof(h), typeof(l1), typeof(l2))
    origin_promoted = Point(ntuple(i -> T(origin[i]), Val(2))...)
    return Trapezoid{T}(origin_promoted, promote(h, l1, l2)...)
end

Trapezoid(origin::Point{2}, h::Number, l1::Number, l2::Number) = Trapezoid(totuple(origin), h, l1, l2)
Trapezoid(origin::SVector{2}, h::Number, l1::Number, l2::Number) = Trapezoid(origin.data, h, l1, l2)

Adapt.@adapt_structure Trapezoid
