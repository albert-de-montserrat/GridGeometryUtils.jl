"""
    area(object) -> Real

Area of a two-dimensional `object`, or the total surface area of a three-dimensional one.

# Examples
```jldoctest
julia> area(Rectangle((0.0, 0.0), 2.0, 4.0))
8.0

julia> area(Circle((0.0, 0.0), 1.0))
3.141592653589793
```

See also [`perimeter`](@ref) and [`volume`](@ref).
"""
function area end

"""
    perimeter(object) -> Real

Length of the boundary of a two-dimensional `object`.

# Examples
```jldoctest
julia> perimeter(Rectangle((0.0, 0.0), 2.0, 4.0))
12.0
```

See also [`area`](@ref).
"""
function perimeter end

"""
    volume(object) -> Real

Volume enclosed by a three-dimensional `object`.

# Examples
```jldoctest
julia> volume(Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0))
24.0
```

See also [`area`](@ref).
"""
function volume end

@inline area(x::AbstractGeometryObject) = throw(ArgumentError("`area` is not defined for $(typeof(x))"))
@inline perimeter(x::AbstractGeometryObject) = throw(ArgumentError("`perimeter` is not defined for $(typeof(x))"))
@inline volume(x::AbstractGeometryObject) = throw(ArgumentError("`volume` is not defined for $(typeof(x))"))

# Shoelace formula. Preferred over Heron's, which loses most of its significant digits on
# needle-shaped triangles through cancellation in the semiperimeter differences.
@inline function area(t::Triangle)
    x1, y1 = t.p1[1], t.p1[2]
    x2, y2 = t.p2[1], t.p2[2]
    x3, y3 = t.p3[1], t.p3[2]
    return abs(muladd(x1, y2 - y3, muladd(x2, y3 - y1, x3 * (y1 - y2)))) / 2
end

@inline area(r::Rectangle) = r.h * r.l
@inline area(r::BBox{2}) = r.h * r.l
@inline area(r::BBox{3}) = 2 * (r.l * r.h + r.l * r.d + r.h * r.d)
@inline area(r::Prism) = 2 * (r.l * r.h + r.l * r.d + r.h * r.d)
@inline area(t::Trapezoid) = (t.l1 + t.l2) * t.h / 2
@inline area(h::Hexagon) = 3 * √3 / 2 * h.radius^2
@inline area(circle::Circle) = π * circle.radius^2
@inline area(ellipse::Ellipse) = π * ellipse.a * ellipse.b
@inline area(s::Sphere) = 4 * π * s.radius^2

@inline perimeter(r::BBox{2}) = 2 * (r.h + r.l)
@inline perimeter(t::Triangle) = distance(t.p1, t.p2) + distance(t.p2, t.p3) + distance(t.p3, t.p1)
@inline perimeter(r::Rectangle) = 2 * (r.h + r.l)
@inline perimeter(h::Hexagon) = 6 * h.radius
@inline perimeter(circle::Circle) = 2 * π * circle.radius

# The right-angled leg is `h`; the slanted one closes the offset between the parallel sides.
@inline perimeter(t::Trapezoid) = t.l1 + t.l2 + t.h + √(t.h^2 + (t.l1 - t.l2)^2)

@inline function perimeter(ellipse::Ellipse)
    (; a, b) = ellipse
    # Ramanujan's approximation; exact only for a circle, and within 1e-5 relative error
    # for eccentricities up to about 0.99.
    return π * (3 * (a + b) - √((3 * a + b) * (a + 3 * b)))
end

@inline volume(r::Prism) = r.h * r.l * r.d
@inline volume(s::Sphere) = (4 * π * s.radius^3) / 3
@inline volume(r::BBox{3}) = r.h * r.l * r.d
