abstract type AbstractPolygon{T} <: AbstractGeometryObject{T} end

"""
    BBox{T} <: AbstractPolygon{T}

A parametric type representing a rectangle with elements of type `T`. 

# Type Parameters
- `T`: The numeric type used for the rectangle's coordinates (e.g., `Float64`, `Int`).

"""
struct BBox{N, T} <: AbstractPolygon{T}
    origin::Point{N, T}
    l::T # length
    h::T # height
    d::T # depth
end

Adapt.@adapt_structure BBox

function BBox(origin::NTuple{N, T1}, l::T2, h::T3, d::T4) where {N, T1, T2, T3, T4}
    T = promote_type(T1, T2, T3, T4)
    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(N))...)
    return BBox{N, T}(origin_promoted, promote(l, h, d)...)
end

BBox(origin::NTuple{2, Any}, l::Number, h::Number) = BBox(origin, l, h, 0)
BBox(origin::Point{2}, l::Number, h::Number) = BBox(totuple(origin), l, h, 0)
BBox(origin::Point{3}, l::Number, h::Number, d::Number) = BBox(totuple(origin), l, h, d)
BBox(origin::SVector{2}, l::Number, h::Number) = BBox(origin.data, l, h, 0)
BBox(origin::SVector{2}, l::Number, h::Number, d::Number) = BBox(origin.data, l, h, d)
BBox(origin::SVector{3}, l::Number, h::Number, d::Number) = BBox(origin.data, l, h, d)

"""
    Triangle{T} <: AbstractPolygon{T}

A parametric type representing a triangle with vertices of type `T`. 

# Type Parameters
- `T`: The type used for the coordinates of the triangle's vertices (e.g., `Float64`, `Int`).
"""
struct Triangle{T} <: AbstractPolygon{T}
    p1::Point{2, T}
    p2::Point{2, T}
    p3::Point{2, T}

    function Triangle(p1::Point{2, T1}, p2::Point{2, T2}, p3::Point{2, T3}) where {T1, T2, T3}
        @assert  p1 !== p2 !== p3
        points = p1, p2, p3
        T = promote_type(T1, T2, T3)
        points_promoted = ntuple(i -> Point(T.(points[i].p)...), Val(3))
        return new{T}(points_promoted...)
    end
end

@inline Triangle(p1::NTuple{2}, p2::NTuple{2}, p3::NTuple{2}) = Triangle(Point(p1), Point(p2), Point(p3))
@inline Triangle(p1::SVector{2}, p2::SVector{2}, p3::SVector{2}) = Triangle(Point(p1), Point(p2), Point(p3))

"""
    coordinates(shape) -> Tuple{Point...}

Return the defining vertices (or control points) of a geometry object as a tuple
of `Point` values.

| Type         | Returns                                      |
|--------------|----------------------------------------------|
| `Triangle`   | `(p1, p2, p3)`                               |
| `Rectangle`  | `(SW, NW, NE, SE)` after rotation            |
| `Hexagon`    | 6 corner points after rotation               |
| `Trapezoid`  | `(SW, SE, NE, NW)`                           |
| `Segment`    | `(p1, p2)`                                   |
"""
@inline coordinates(t::Triangle) = (t.p1, t.p2, t.p3)

Adapt.@adapt_structure Triangle

"""
    Rectangle{T} <: AbstractPolygon{T}

A parametric type representing a rectangle with elements of type `T`. 

# Type Parameters
- `T`: The numeric type used for the rectangle's coordinates (e.g., `Float64`, `Int`).

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

function Rectangle(origin::NTuple{2, T1}, l::T2, h::T3; θ::T4 = 0.0) where {T1, T2, T3, T4}
    T = promote_type(T1, T2, T3, T4)
    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    # Vertices
    𝐱SW = origin .+ SA[-l / 2, -h / 2]
    𝐱SE = origin .+ SA[l / 2, -h / 2]
    𝐱NW = origin .+ SA[-l / 2, h / 2]
    𝐱NE = origin .+ SA[l / 2, h / 2]
    𝐱 = SMatrix{2, 4}([ 𝐱SW 𝐱NW 𝐱NE 𝐱SE])

    vertices, box = if iszero(θ)
        origin_bbox = origin .+ SA[-l / 2, -h / 2]
        box = BBox(origin_bbox, l, h)
        vertices = 𝐱
        vertices, box
    else
        # Define bounding box
        𝐑 = rotation_matrix(sinθ, cosθ)

        # Rotate geometry
        𝐱′ = 𝐑' * (𝐱 .- origin) .+ origin

        lbox, hbox = maximum(𝐱′[1, :]) - minimum(𝐱′[1, :]), maximum(𝐱′[2, :]) - minimum(𝐱′[2, :])

        # shift origin to make further computations faster
        origin_bbox = origin .+ SA[-lbox / 2, -hbox / 2]
        box = BBox(origin_bbox, lbox, hbox)

        # Store vertices
        vertices = 𝐱′
        vertices, box
    end

    return Rectangle{T}(origin_promoted, promote(l, h, sinθ, cosθ)..., box, vertices)
end

Rectangle(origin::Point{2}, l::Number, h::Number; θ::T = 0.0) where {T} = Rectangle(totuple(origin), l, h; θ = θ)
Rectangle(origin::SVector{2}, l::Number, h::Number; θ::T = 0.0) where {T} = Rectangle(origin.data, l, h; θ = θ)

@inline coordinates(r::Rectangle) = ntuple(i -> Point(r.vertices[:, i]...), Val(4))

Adapt.@adapt_structure Rectangle

"""
    Hexagon{T} <: AbstractPolygon{T}

A parametric type representing a hexagon with elements of type `T`. 

# Type Parameters
- `T`: The numeric type used for the hexagon's coordinates (e.g., `Float64`, `Int`).

"""
struct Hexagon{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    radius::T
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 6, T, 12}
end

function Hexagon(origin::NTuple{2, T1}, radius::T2; θ::T3 = 0.0) where {T1, T2, T3}
    T = promote_type(T1, T2, T3)
    origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    # Compute vertices of the hexagon
    α = @SVector([i * π / 3 + θ for i in 0:5])  # 6 corners

    vertices = hcat(
        (@SVector [origin[1] + radius * cos(α[i]) for i in 1:6]),
        (@SVector [origin[2] + radius * sin(α[i]) for i in 1:6]),
    )
    vertices = vertices'

    # Define bounding box
    lbox, hbox = maximum(vertices[1, :]) - minimum(vertices[1, :]), maximum(vertices[2, :]) - minimum(vertices[2, :])

    # shift origin to make further computations faster
    origin_bbox = origin .+ @SVector [-lbox / 2, -hbox / 2]
    box = BBox(origin_bbox, lbox, hbox)

    return Hexagon{T}(origin_promoted, promote(radius, sinθ, cosθ)..., box, vertices)
end

Hexagon(origin::Point{2}, radius::Number; θ::T = 0.0) where {T} = Hexagon(totuple(origin), radius; θ = θ)
Hexagon(origin::SVector{2}, radius::Number; θ::T = 0.0) where {T} = Hexagon(origin.data, radius; θ = θ)

Adapt.@adapt_structure Hexagon

@inline coordinates(hex::Hexagon) = ntuple(i -> Point(hex.vertices[:, i]...), Val(6))

"""
    Prism{T} <: AbstractPolygon{T}

A parametric type representing a 3-D rectangular prism (box) with elements of
type `T`.

# Fields
- `origin::Point{3, T}`: The origin (SW-bottom) corner of the prism.
- `l::T`: Length along the x-axis.
- `h::T`: Height along the z-axis.
- `d::T`: Depth along the y-axis.

# Type Parameters
- `T`: The numeric type used for the prism's coordinates (e.g., `Float64`, `Int`).
"""
struct Prism{T} <: AbstractPolygon{T}
    origin::Point{3, T}
    l::T # length
    h::T # height
    d::T # depth
end

function Prism(origin::NTuple{3, T1}, l::T2, h::T3, d::T4) where {T1, T2, T3, T4}
    T = promote_type(T1, T2, T3, T4)
    origin_promoted = Point(ntuple(i -> T(origin[i]), Val(3))...)
    return Prism{T}(origin_promoted, promote(l, h, d)...)
end

Prism(origin::Point{2}, l::Number, h::Number, d::Number) = Prism(totuple(origin), l, h, d)
Prism(origin::SVector{2}, l::Number, h::Number, d::Number) = Prism(origin.data, l, h, d)

Adapt.@adapt_structure Prism

"""
    Trapezoid{T} <: AbstractPolygon{T}

A parametric type representing a right trapezoid lying in the 2-D plane.

# Fields
- `origin::Point{2, T}`: The bottom-left vertex.
- `l::T`: Width (horizontal extent).
- `h1::T`: Height of the right side.
- `h2::T`: Height of the left side.

The four vertices (SW, SE, NE, NW) are returned by `coordinates(trap)`.

# Type Parameters
- `T`: The numeric type used for the trapezoid's coordinates.
"""
struct Trapezoid{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    l::T
    h1::T
    h2::T
end

function Trapezoid(origin::NTuple{2, T1}, h::T2, l1::T3, l2::T4) where {T1, T2, T3, T4}
    T = promote_type(T1, T2, T3, T4)
    origin_promoted = Point(ntuple(i -> T(origin[i]), Val(2))...)
    return Trapezoid{T}(origin_promoted, promote(h, l1, l2)...)
end

Trapezoid(origin::Point{2}, h::Number, l1::Number, l2::Number) = Trapezoid(totuple(origin), h, l1, l2)
Trapezoid(origin::SVector{2}, h::Number, l1::Number, l2::Number) = Trapezoid(origin.data, h, l1, l2)

Adapt.@adapt_structure Trapezoid

@inline coordinates(trap::Trapezoid) = (trap.origin, Point(trap.origin.x + trap.l, trap.origin.y), Point(trap.origin.x + trap.l, trap.origin.y + trap.h1), Point(trap.origin.x, trap.origin.y + trap.h2))
