abstract type AbstractPoint{N, T} end

"""
    Point{N, T}

A parametric type representing a point in N-dimensional space, where `N` is the number of dimensions and `T` is the numeric type of the coordinates (e.g., `Float64`, `Int`).

# Fields
- `N`: The number of dimensions.
- `T`: The type of each coordinate.
"""
struct Point{N, T}
    p::SVector{N, T}
end

function Point(pᵢ::Vararg{Number, N}) where {N}
    T = promote_type(typeof.(pᵢ)...)
    return Point{N, T}(SA[T.(pᵢ)...])
end

Adapt.@adapt_structure Point

@inline Point(p::Point) = p
@inline Point(p::NTuple) = Point(p...)

@inline totuple(p::Point) = p.p.data

Base.length(::Point{N}) where {N} = N

Base.getindex(p::Point, i::Int) = p.p[i]

for op in (:+, :-, :*, :/, :^)
    @eval begin
        Base.$op(p::Point, x::Number) = Point(broadcast($op, p.p, x)...)
        Base.$op(x::Number, p::Point) = Point(broadcast($op, x, p.p)...)
    end
end

for op in (:*, :/, :^)
    @eval begin
        Base.$op(p1::Point, p2::Point) = Point(broadcast($op, p1.p, p2.p)...)
    end
end

for op in (:+, :-)
    @eval begin
        Base.$op(p1::Point, p2::Point) = Point(Base.$op(p1.p, p2.p)...)
        Base.$op(p1::Point, p2::SVector) = Base.$op(p1.p, p2)
        Base.$op(p1::SVector, p2::Point) = Base.$op(p1, p2.p)
    end
end

Base.:*(p1::SMatrix, p2::Point) = p1 * p2.p
Base.:*(p1::Point, p2::SMatrix) = p2.p * p1

LinearAlgebra.adjoint(p::Point) = Adjoint(p.p)

@inline distance(p1::Point{N}, p2::Point{N}) where {N} = √sum(((p1.p[i] - p2.p[i])^2) for i in 1:N)

@inline function isequal_r(a::Point{2}, b::Point{2})
    return isequal_r(a[1], b[1]) && isequal_r(a[2], b[2])
end

@inline function isequal_r(a::Point{2}, b::Point{3})
    return isequal_r(a[1], b[1]) && isequal_r(a[2], b[2]) && isequal_r(a[3], b[3])
end
