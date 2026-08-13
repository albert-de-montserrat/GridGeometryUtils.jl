abstract type AbstractPolygon{T} <: AbstractGeometryObject{T} end

"""
    BBox{N, T} <: AbstractPolygon{T}

An axis-aligned bounding box in `N` dimensions.

`origin` is the corner with the **smallest** coordinate along every axis (the south-west
corner in 2-D), unlike [`Rectangle`](@ref) and [`Hexagon`](@ref), whose origin is their
center. The extents run along the positive axes from there: `l` along ``x``, `h` along
``y``, and `d` along ``z``. `d` is zero for `N == 2`.

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
end

Adapt.@adapt_structure BBox

function BBox(origin::Tuple{Vararg{Number, N}}, l::Number, h::Number, d::Number) where {N}
    T = promote_type(eltype(promote(origin...)), typeof(l), typeof(h), typeof(d))
    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(N))...)
    return BBox{N, T}(origin_promoted, promote(l, h, d)...)
end

BBox(origin::Tuple{Vararg{Number, 2}}, l::Number, h::Number) = BBox(origin, l, h, 0)
BBox(origin::Point{2}, l::Number, h::Number) = BBox(totuple(origin), l, h, 0)
BBox(origin::Point{3}, l::Number, h::Number, d::Number) = BBox(totuple(origin), l, h, d)
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
    Rectangle(origin, l, h; θ = 0)

A rectangle of width `l` and height `h`, optionally rotated counter-clockwise by `θ`
radians about its center.

`origin` is the **center** of the rectangle, unlike [`BBox`](@ref), whose origin is its
minimum-coordinate corner. The enclosing axis-aligned box is available as the `box` field;
`box.origin` is therefore the south-west corner.

# Fields
- `origin::Point{2, T}`: center.
- `l::T`, `h::T`: width and height, measured in the rectangle's own frame.
- `sinθ::T`, `cosθ::T`: sine and cosine of the rotation angle.
- `box::BBox{2, T}`: enclosing axis-aligned bounding box.
- `vertices::SMatrix{2, 4, T, 8}`: corners as columns, ordered SW, NW, NE, SE.

# Examples
```jldoctest
julia> rect = Rectangle((0.0, 0.0), 2.0, 4.0);

julia> rect.box.origin
Point{2, Float64}([-1.0, -2.0])

julia> area(rect)
8.0
```
"""
struct Rectangle{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    l::T # length
    h::T # height
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 4, T, 8}
end

function Rectangle(origin::Tuple{Vararg{Number, 2}}, l::Number, h::Number; θ::Number = 0.0)
    T = promote_type(eltype(promote(origin...)), typeof(l), typeof(h), typeof(θ))

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    # Vertices, ordered SW, NW, NE, SE
    𝐱SW = origin .+ @SVector [-l / 2, -h / 2]
    𝐱SE = origin .+ @SVector [l / 2, -h / 2]
    𝐱NW = origin .+ @SVector [-l / 2, h / 2]
    𝐱NE = origin .+ @SVector [l / 2, h / 2]
    𝐱 = SMatrix{2, 4}([ 𝐱SW 𝐱NW 𝐱NE 𝐱SE])

    vertices, box = if iszero(θ)
        origin_bbox = origin .+ @SVector [-l / 2, -h / 2]
        𝐱, BBox(origin_bbox, l, h)
    else
        𝐑 = rotation_matrix(sinθ, cosθ)

        # Rotate the geometry about the center
        𝐱′ = 𝐑' * (𝐱 .- origin) .+ origin

        lbox = maximum(𝐱′[1, :]) - minimum(𝐱′[1, :])
        hbox = maximum(𝐱′[2, :]) - minimum(𝐱′[2, :])
        origin_bbox = origin .+ @SVector [-lbox / 2, -hbox / 2]

        𝐱′, BBox(origin_bbox, lbox, hbox)
    end

    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)
    return Rectangle{T}(origin_promoted, promote(l, h, sinθ, cosθ)..., box, vertices)
end

Rectangle(origin::Point{2}, l::Number, h::Number; θ::Number = 0.0) = Rectangle(totuple(origin), l, h; θ)
Rectangle(origin::SVector{2}, l::Number, h::Number; θ::Number = 0.0) = Rectangle(origin.data, l, h; θ)

Adapt.@adapt_structure Rectangle

"""
    Hexagon{T} <: AbstractPolygon{T}
    Hexagon(origin, radius; θ = 0)

A regular hexagon of circumradius `radius`, optionally rotated counter-clockwise by `θ`
radians about its center.

`origin` is the **center** of the hexagon. At `θ == 0` a vertex lies at
`origin + (radius, 0)`.

# Fields
- `origin::Point{2, T}`: center.
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
    origin::Point{2, T}
    radius::T
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 6, T, 12}
end

function Hexagon(origin::Tuple{Vararg{Number, 2}}, radius::Number; θ::Number = 0.0)
    T = promote_type(eltype(promote(origin...)), typeof(radius), typeof(θ))

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    α = ntuple(i -> (i - 1) * π / 3 + θ, Val(6))
    vertices = hcat(
        ntuple(i -> SVector(origin[1] + radius * cos(α[i]), origin[2] + radius * sin(α[i])), Val(6))...
    )

    lbox = maximum(vertices[1, :]) - minimum(vertices[1, :])
    hbox = maximum(vertices[2, :]) - minimum(vertices[2, :])
    origin_bbox = origin .+ @SVector [-lbox / 2, -hbox / 2]
    box = BBox(origin_bbox, lbox, hbox)

    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)
    return Hexagon{T}(origin_promoted, promote(radius, sinθ, cosθ)..., box, vertices)
end

Hexagon(origin::Point{2}, radius::Number; θ::Number = 0.0) = Hexagon(totuple(origin), radius; θ)
Hexagon(origin::SVector{2}, radius::Number; θ::Number = 0.0) = Hexagon(origin.data, radius; θ)

Adapt.@adapt_structure Hexagon

"""
    Prism{T} <: AbstractPolygon{T}

An axis-aligned rectangular cuboid.

`origin` is the corner with the smallest coordinate along every axis, and the extents run
along the positive axes from there, matching [`BBox`](@ref).

# Fields
- `origin::Point{3, T}`: minimum-coordinate corner.
- `l::T`, `h::T`, `d::T`: extents along ``x``, ``y`` and ``z``.

# Examples
```jldoctest
julia> volume(Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0))
24.0
```
"""
struct Prism{T} <: AbstractPolygon{T}
    origin::Point{3, T}
    l::T # length
    h::T # height
    d::T # depth
end

function Prism(origin::Tuple{Vararg{Number, 3}}, l::Number, h::Number, d::Number)
    T = promote_type(eltype(promote(origin...)), typeof(l), typeof(h), typeof(d))
    origin_promoted = Point(ntuple(i -> T(origin[i]), Val(3))...)
    return Prism{T}(origin_promoted, promote(l, h, d)...)
end

Prism(origin::Point{3}, l::Number, h::Number, d::Number) = Prism(totuple(origin), l, h, d)
Prism(origin::SVector{3}, l::Number, h::Number, d::Number) = Prism(origin.data, l, h, d)

Adapt.@adapt_structure Prism

"""
    Trapezoid{T} <: AbstractPolygon{T}
    Trapezoid(origin, h, l1, l2)

A right trapezoid: two parallel sides of lengths `l1` and `l2`, separated by `h`, with the
right angle at `origin`.

`l1` runs along the positive ``x`` axis from `origin`; `l2` runs parallel to it from
`origin + (0, h)`.

# Fields
- `origin::Point{2, T}`: vertex at the right angle.
- `h::T`: distance between the two parallel sides.
- `l1::T`, `l2::T`: lengths of the parallel sides, at `origin` and at `origin + (0, h)`.

# Examples
```jldoctest
julia> area(Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0))
7.0
```
"""
struct Trapezoid{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    h::T
    l1::T
    l2::T
end

function Trapezoid(origin::Tuple{Vararg{Number, 2}}, h::Number, l1::Number, l2::Number)
    T = promote_type(eltype(promote(origin...)), typeof(h), typeof(l1), typeof(l2))
    origin_promoted = Point(ntuple(i -> T(origin[i]), Val(2))...)
    return Trapezoid{T}(origin_promoted, promote(h, l1, l2)...)
end

Trapezoid(origin::Point{2}, h::Number, l1::Number, l2::Number) = Trapezoid(totuple(origin), h, l1, l2)
Trapezoid(origin::SVector{2}, h::Number, l1::Number, l2::Number) = Trapezoid(origin.data, h, l1, l2)

Adapt.@adapt_structure Trapezoid
