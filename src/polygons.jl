abstract type AbstractPolygon{T} end

"""
    BBox{T} <: AbstractPolygon{T}

A parametric type representing a rectangle with elements of type `T`. 

# Type Parameters
- `T`: The numeric type used for the rectangle's coordinates (e.g., `Float64`, `Int`).

"""
struct BBox{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    l::T # length
    h::T # height
    function BBox(origin::NTuple{2, T1}, l::T2, h::T3) where {T1, T2, T3}
        T = promote_type(T1, T2, T3)
        origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)
        return new{T}(origin_promoted, promote(l, h)...)
    end
end

BBox(origin::Point{2}, l::Number, h::Number) = BBox(totuple(origin), l, h)
BBox(origin::SVector{2}, l::Number, h::Number) = BBox(origin.data, l, h)

Adapt.@adapt_structure BBox

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
    box::BBox{T}

    function Rectangle(origin::NTuple{2, T1}, l::T2, h::T3; θ::T4 = 0.0) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)

        sinθ, cosθ = if iszero(θ)
            zero(T), one(T)
        else
            sincos(θ)
        end

        box = if iszero(θ)
            origin_bbox = origin .+ @SVector([-l / 2, -h / 2])
            BBox(origin_bbox, l, h)

        else
            # Define bounding box
            𝐑 = rotation_matrix(sinθ, cosθ) 
            𝐱SW = origin .+ @SVector([-l / 2, -h / 2])
            𝐱SE = origin .+ @SVector([l / 2, -h / 2])
            𝐱NW = origin .+ @SVector([-l / 2, h / 2])
            𝐱NE = origin .+ @SVector([l / 2, h / 2])

            # Rotate geometry
            𝐱 = SMatrix{2, 4}([ 𝐱SW 𝐱SE 𝐱NW 𝐱NE])
            𝐱′ = 𝐑 * 𝐱
            lbox, hbox = maximum(𝐱′[1, :]) - minimum(𝐱′[1, :]), maximum(𝐱′[2, :]) - minimum(𝐱′[2, :])

            # shift origin to make further computations faster
            origin_bbox = origin .+ @SVector([-lbox / 2, -hbox / 2])
            BBox(origin_bbox, lbox, hbox)
        end

        return new{T}(origin_promoted, promote(l, h, sinθ, cosθ)..., box)
    end
end

Rectangle(origin::Point{2}, l::Number, h::Number; θ::T = 0.0) where {T} = Rectangle(totuple(origin), l, h; θ = θ)
Rectangle(origin::SVector{2}, l::Number, h::Number; θ::T = 0.0) where {T} = Rectangle(origin.data, l, h; θ = θ)

Adapt.@adapt_structure Rectangle

"""
    Prism{T} <: AbstractPolygon{T}

A parametric type representing a rectangle with elements of type `T`. 

# Type Parameters
- `T`: The numeric type used for the rectangle's coordinates (e.g., `Float64`, `Int`).

"""
struct Prism{T} <: AbstractPolygon{T}
    origin::Point{3, T}
    l::T # length
    h::T # height
    d::T # depth
    function Prism(origin::NTuple{3, T1}, l::T2, h::T3, d::T4) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = Point(ntuple(i -> T(origin[i]), Val(3))...)
        return new{T}(origin_promoted, promote(l, h, d)...)
    end
end

Prism(origin::Point{2}, l::Number, h::Number, d::Number) = Prism(totuple(origin), l, h, d)
Prism(origin::SVector{2}, l::Number, h::Number, d::Number) = Prism(origin.data, l, h, d)

Adapt.@adapt_structure Prism

struct Trapezoid{T} <: AbstractPolygon{T}
    origin::Point{2, T}
    l::T
    h1::T
    h2::T
    function Trapezoid(origin::NTuple{2, T1}, h::T2, l1::T3, l2::T4) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = Point(ntuple(i -> T(origin[i]), Val(2))...)
        return new{T}(origin_promoted, promote(h, l1, l2)...)
    end
end

Trapezoid(origin::Point{2}, h::Number, l1::Number, l2::Number) = Trapezoid(totuple(origin), h, l1, l2)
Trapezoid(origin::SVector{2}, h::Number, l1::Number, l2::Number) = Trapezoid(origin.data, h, l1, l2)

Adapt.@adapt_structure Trapezoid
