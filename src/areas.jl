area(::T) where {T <: AbstractPolygon} = throw("Area not defined for the AbstractPolygon of type $T")
area(::T) where {T} = throw("$T is not an AbstractPolygon")

@inline area(r::BBox) = r.h * r.l

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

@inline area(r::Rectangle) = r.h * r.l
@inline area(r::Prism) = 2 * ((r.h + r.l) + (r.h + r.d) + (r.d + r.l))
@inline area(t::Trapezoid) = (t.h1 + t.h2) * t.l / 2
@inline area(h::Hexagon) = 6 * h.radius
@inline area(circle::Circle) = π * circle.radius^2
@inline area(ellipse::Ellipse) = π * ellipse.a * ellipse.b

perimeter(::T) where {T <: AbstractPolygon} = throw("Perimeter not defined for the AbstractPolygon of type $T")
perimeter(::T) where {T} = throw("$T is not an AbstractPolygon")

@inline perimeter(r::BBox) = 2 * (r.h + r.l)
@inline perimeter(t::Triangle{T}) where {T} = distance(t.p1, t.p2) + distance(t.p2, t.p3) + distance(t.p3, t.p1)
@inline perimeter(r::Rectangle) = 2 * (r.h + r.l)
@inline perimeter(h::Hexagon) = 3 / 2 * √3 * h.radius^2
@inline perimeter(t::Trapezoid) = t.l + t.h1 + t.h2 + √(t.l^2 + (t.h1 - t.h2)^2)
@inline perimeter(circle::Circle) = 2 * π * circle.radius

@inline function perimeter(ellipse::Ellipse)
    (; a, b) = ellipse
    # Approximation of the perimeter of an ellipse using Ramanujan's formula
    P = π * (3 * (a + b) - √((3 * a + b) * (a + 3 * b)))
    return P
end

volume(::T) where {T <: AbstractPolygon} = throw("Volume not defined for the AbstractPolygon of type $T")
volume(::T) where {T} = throw("$T is not an AbstractPolygon")
@inline volume(r::Prism) = r.h * r.l * r.d
