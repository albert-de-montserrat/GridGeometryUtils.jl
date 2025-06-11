abstract type AbstractPolygon{T} end

area(::T) where {T <: AbstractPolygon} = throw("Area not defined for the AbstractPolygon of type $T")
area(::T) where {T} = throw("$T is not an AbstractPolygon")

volume(::T) where {T <: AbstractPolygon} = throw("Volume not defined for the AbstractPolygon of type $T")
volume(::T) where {T} = throw("$T is not an AbstractPolygon")

perimeter(::T) where {T <: AbstractPolygon} = throw("Perimeter not defined for the AbstractPolygon of type $T")
perimeter(::T) where {T} = throw("$T is not an AbstractPolygon")

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
    function Rectangle(origin::NTuple{2, T1}, l::T2, h::T3, θ::T4) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = Point(ntuple(ix -> T(origin[ix]), Val(2))...)

        sinθ, cosθ = if iszero(θ) 
            zero(T), one(T)
        else
            sincos(θ)
        end
        return new{T}(origin_promoted, promote(l, h, sinθ, cosθ )...)
    end
end

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
    origin::NTuple{3, T}
    h::T # height
    l::T # length
    d::T # depth
    function Prism(origin::NTuple{3, T1}, h::T2, l::T3, d::T4) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = ntuple(i -> T(origin[i]), Val(3))
        return new{T}(origin_promoted, promote(h, l, d)...)
    end
end

Adapt.@adapt_structure Prism

@inline volume(r::Prism) = r.h * r.l * r.d
@inline area(r::Prism) = 2 * ((r.h + r.l) + (r.h + r.d) + (r.d + r.l))

struct Trapezoid{T} <: AbstractPolygon{T}
    origin::NTuple{2, T}
    l::T
    h1::T
    h2::T
    function Trapezoid(origin::NTuple{2, T1}, h::T2, l1::T3, l2::T4) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        origin_promoted = ntuple(i -> T(origin[i]), Val(2))
        return new{T}(origin_promoted, promote(h, l1, l2)...)
    end
end

Adapt.@adapt_structure Trapezoid

@inline area(t::Trapezoid) = (t.h1 + t.h2) * t.l / 2
@inline perimeter(t::Trapezoid) = t.l + t.h1 + t.h2 + √(t.l^2 + (t.h1 - t.h2)^2)
