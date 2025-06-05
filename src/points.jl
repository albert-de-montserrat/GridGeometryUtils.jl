abstract type AbstractPoint{N, T} end

"""
    Point{N, T}

A parametric type representing a point in N-dimensional space, where `N` is the number of dimensions and `T` is the numeric type of the coordinates (e.g., `Float64`, `Int`).

# Fields
- `N`: The number of dimensions.
- `T`: The type of each coordinate.
"""
struct Point{N, T}
    p::NTuple{N, T}

    function Point(pᵢ::Vararg{Number, N}) where {N}
        T = promote_type(typeof.(pᵢ)...)
        return new{N, T}(T.(pᵢ))
    end
end

@inline Point(pᵢ::NTuple{N, Number}) where {N} = Point(pᵢ...)

Base.length(::Point{N}) where {N} = N

Base.getindex(p::Point{N}, i::Int) where {N} = (@assert i ≤ N; p.p[i])

for op in (:+, :-, :*, :/, :^)
    @eval begin
        @inline Base.$op(p::Point, x::Number) = Point(broadcast($op, p.p, x)...)
        @inline Base.$op(x::Number, p::Point) = Point(broadcast($op, x, p.p)...)
        @inline Base.$op(p1::Point, p2::Point) = Point(broadcast($op, p1.p, p2.p)...)
    end
end

@inline distance(p1::Point{N}, p2::Point{N}) where {N} = √sum(((p1.p[i] - p2.p[i])^2) for i in 1:N)
