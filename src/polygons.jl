abstract type AbstractPolygon{T} end

area(::T) where {T <: AbstractPolygon} = throw("Area not defined for the AbstractPolygon of type $T")
area(::T) where {T} = throw("$T is not an AbstractPolygon")

volume(::T) where {T <: AbstractPolygon} = throw("Volume not defined for the AbstractPolygon of type $T")
volume(::T) where {T} = throw("$T is not an AbstractPolygon")

perimeter(::T) where {T <: AbstractPolygon} = throw("Perimeter not defined for the AbstractPolygon of type $T")
perimeter(::T) where {T} = throw("$T is not an AbstractPolygon")

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
    sinθ::T
    cosθ::T
    function BBox(origin::NTuple{2, T1}, l::T2, h::T3; θ::T4 = 0.0) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)
        # All of this is not needed fo BBox but all attempts to remove breaks the code
        sinθ, cosθ = if iszero(θ)
            zero(T), one(T)
        else
            sincos(θ)
        end
        # All of this is not needed fo BBox but all attempts to remove breaks the code
        return new{T}(origin_promoted, promote(l, h, sinθ, cosθ)...)
    end
end

BBox(origin::Point{2}, l::Number, h::Number; θ::T = 0.0) where {T} = BBox(totuple(origin), l, h; θ = θ)
BBox(origin::SVector{2}, l::Number, h::Number; θ::T = 0.0) where {T} = BBox(origin.data, l, h; θ = θ)

Adapt.@adapt_structure BBox

@inline area(r::BBox) = r.h * r.l
@inline perimeter(r::BBox) = 2 * (r.h + r.l)

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

@inline function area(t::Triangle{T}) where {T}
    a = distance(t.p1, t.p2)
    b = distance(t.p2, t.p3)
    c = distance(t.p3, t.p1)
    # semiperimeter
    s = (a + b + c) / 2
    # Heron's formula for area of triangle
    #      √(s * (s - a) * (s - b) * (s - c))
    return √(muladd(s, muladd(s - a, muladd(s - b, s - c, zero(T)), zero(T)), zero(T)))
end

@inline perimeter(t::Triangle{T}) where {T} = distance(t.p1, t.p2) + distance(t.p2, t.p3) + distance(t.p3, t.p1)

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
    box::BBox
    function Rectangle(origin::NTuple{2, T1}, l::T2, h::T3; θ::T4 = 0.0) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)

        sinθ, cosθ = if iszero(θ)
            zero(T), one(T)
        else
            sincos(θ)
        end

        # Define bounding box
        𝐑   = @SMatrix([ cosθ -sinθ; sinθ cosθ])
        𝐱SW  = origin .+ @SVector([-l/2, -h/2])
        𝐱SE  = origin .+ @SVector([ l/2, -h/2])
        𝐱NW  = origin .+ @SVector([-l/2,  h/2])
        𝐱NE  = origin .+ @SVector([ l/2,  h/2])
        # Rotate geometry
        𝐱SW′ = 𝐑 * 𝐱SW
        𝐱SE′ = 𝐑 * 𝐱SE
        𝐱NW′ = 𝐑 * 𝐱NW
        𝐱NE′ = 𝐑 * 𝐱NE

        # 𝐱  = SMatrix{2,4}([ 𝐱SW 𝐱SE 𝐱NW 𝐱NE])
        # 𝐱′ = 𝐑 * 𝐱
        # lbox, hbox = maximum(𝐱'[1,:]) - minimum(𝐱'[1,:]), maximum(𝐱'[2,:]) - minimum(𝐱'[2,:])
        # lbox, hbox = abs(𝐱SW′[1]-𝐱NE′[1]), abs(𝐱SW′[2]-𝐱NE′[2])
        lbox = max(𝐱SW′[1], 𝐱SE′[1], 𝐱NW′[1], 𝐱NE′[1]) - min(𝐱SW′[1], 𝐱SE′[1], 𝐱NW′[1], 𝐱NE′[1])
        hbox = max(𝐱SW′[2], 𝐱SE′[2], 𝐱NW′[2], 𝐱NE′[2]) - min(𝐱SW′[2], 𝐱SE′[2], 𝐱NW′[2], 𝐱NE′[2])
        box = BBox(origin, lbox, hbox)

        return new{T}(origin_promoted, promote(l, h, sinθ, cosθ)..., box)
    end
end

Rectangle(origin::Point{2}, l::Number, h::Number; θ::T = 0.0) where {T} = Rectangle(totuple(origin), l, h; θ = θ)
Rectangle(origin::SVector{2}, l::Number, h::Number; θ::T = 0.0) where {T} = Rectangle(origin.data, l, h; θ = θ)

Adapt.@adapt_structure Rectangle

@inline area(r::Rectangle) = r.h * r.l
@inline perimeter(r::Rectangle) = 2 * (r.h + r.l)

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

@inline volume(r::Prism) = r.h * r.l * r.d
@inline area(r::Prism) = 2 * ((r.h + r.l) + (r.h + r.d) + (r.d + r.l))

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

@inline area(t::Trapezoid) = (t.h1 + t.h2) * t.l / 2
@inline perimeter(t::Trapezoid) = t.l + t.h1 + t.h2 + √(t.l^2 + (t.h1 - t.h2)^2)
