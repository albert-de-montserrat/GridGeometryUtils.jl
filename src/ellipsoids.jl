abstract type AbstractEllipsoid{T} <: AbstractGeometryObject{T} end

"""
    Circle{T} <: AbstractEllipsoid{T}
    Circle(center, radius)
    Circle(; center, radius)
    Circle(; origin, radius)

A circle of radius `radius` centered on `center`.

The keyword forms name the anchor: `center` is the center and `origin` the
minimum-coordinate corner of the enclosing box. Exactly one of the two is accepted.

# Fields
- `center::Point{2, T}`: center.
- `radius::T`: radius.
- `box::BBox{2, T}`: enclosing axis-aligned bounding box.

# Examples
```jldoctest
julia> c = Circle((0.0, 0.0), 1.0);

julia> inside(Point(0.5, 0.5), c)
true
```
"""
struct Circle{T} <: AbstractEllipsoid{T}
    center::Point{2, T}
    radius::T
    box::BBox{2, T}
end

function Circle(center::Tuple{Vararg{Number, 2}}, r::Number)
    T = promote_type(eltype(promote(center...)), typeof(r))
    center_promoted = Point(ntuple(i -> T(center[i]), Val(2))...)
    origin = center .+ @SVector([-r, -r])
    return Circle{T}(center_promoted, convert(T, r), BBox(origin, 2 * r, 2 * r))
end

Circle(center::Point{2}, radius::Number) = Circle(totuple(center), radius)
Circle(center::SVector{2}, radius::Number) = Circle(center.data, radius)

Adapt.@adapt_structure Circle

"""
    Sphere{T} <: AbstractEllipsoid{T}
    Sphere(center, radius)
    Sphere(; center, radius)
    Sphere(; origin, radius)

A sphere of radius `radius` centered on `center`.

The keyword forms name the anchor: `center` is the center and `origin` the
minimum-coordinate corner of the enclosing box. Exactly one of the two is accepted.

# Fields
- `center::Point{3, T}`: center.
- `radius::T`: radius.
- `box::BBox{3, T}`: enclosing axis-aligned bounding box.

# Examples
```jldoctest
julia> volume(Sphere((0.0, 0.0, 0.0), 1.0))
4.1887902047863905
```
"""
struct Sphere{T} <: AbstractEllipsoid{T}
    center::Point{3, T}
    radius::T
    box::BBox{3, T}
end

function Sphere(center::Tuple{Vararg{Number, 3}}, r::Number)
    T = promote_type(eltype(promote(center...)), typeof(r))
    center_promoted = Point(ntuple(i -> T(center[i]), Val(3))...)
    origin = center .+ @SVector([-r, -r, -r])
    return Sphere{T}(center_promoted, convert(T, r), BBox(origin, 2 * r, 2 * r, 2 * r))
end

Sphere(center::Point{3}, radius::Number) = Sphere(totuple(center), radius)
Sphere(center::SVector{3}, radius::Number) = Sphere(center.data, radius)

Adapt.@adapt_structure Sphere

"""
    Ellipse{T} <: AbstractEllipsoid{T}
    Ellipse(center, a, b; θ = 0)
    Ellipse(; center, a, b, θ = 0)
    Ellipse(; origin, a, b, θ = 0)

An ellipse with semi-axes `a` and `b`, optionally rotated counter-clockwise by `θ` radians
about its center. At `θ == 0`, `a` lies along ``x`` and `b` along ``y``.

The keyword forms name the anchor: `center` is the center and `origin` the
minimum-coordinate corner of the enclosing box. Exactly one of the two is accepted.

# Fields
- `center::Point{2, T}`: center.
- `a::T`, `b::T`: semi-axes.
- `sinθ::T`, `cosθ::T`: sine and cosine of the rotation angle.
- `box::BBox{2, T}`: enclosing axis-aligned bounding box.
- `vertices::SMatrix{2, 4, T, 8}`: semi-axis endpoints as columns, ordered W, N, E, S.

# Examples
```jldoctest
julia> e = Ellipse((0.0, 0.0), 1.0, 2.0);

julia> area(e)
6.283185307179586
```
"""
struct Ellipse{T} <: AbstractEllipsoid{T}
    center::Point{2, T}
    a::T # semi-axis 1
    b::T # semi-axis 2
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 4, T, 8}
end

function Ellipse(center::Tuple{Vararg{Number, 2}}, a::Number, b::Number; θ::Number = 0.0e0)
    T = promote_type(eltype(promote(center...)), typeof(a), typeof(b), typeof(θ))

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    # Semi-axis endpoints relative to the center, ordered W, N, E, S
    𝐱 = SMatrix{2, 4}([(@SVector [-a, 0]) (@SVector [0, b]) (@SVector [a, 0]) (@SVector [0, -b])])

    vertices, box = if iszero(θ)
        origin = center .+ @SVector([-a, -b])
        (𝐱 .+ center), BBox(origin, 2 * a, 2 * b)
    else
        𝐑 = rotation_matrix(sinθ, cosθ)
        𝐱′ = 𝐑' * 𝐱 .+ center

        # Extent of a rotated ellipse along each axis
        lbox = 2 * √(a^2 * cosθ^2 + b^2 * sinθ^2)
        hbox = 2 * √(a^2 * sinθ^2 + b^2 * cosθ^2)
        origin_bbox = center .+ @SVector [-lbox / 2, -hbox / 2]

        𝐱′, BBox(origin_bbox, lbox, hbox)
    end

    center_promoted = Point(ntuple(i -> T(center[i]), Val(2))...)
    return Ellipse{T}(center_promoted, promote(a, b, sinθ, cosθ)..., box, vertices)
end

Ellipse(center::Point{2}, a::Number, b::Number; θ::Number = 0.0e0) = Ellipse(totuple(center), a, b; θ)
Ellipse(center::SVector{2}, a::Number, b::Number; θ::Number = 0.0e0) = Ellipse(center.data, a, b; θ)

Adapt.@adapt_structure Ellipse
