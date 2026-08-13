abstract type AbstractPoint{N, T} end

"""
    Point{N, T} <: AbstractPoint{N, T}

A point in `N`-dimensional space with coordinates of type `T`.

# Fields
- `p::SVector{N, T}`: the coordinates.

# Examples
```jldoctest
julia> Point(1, 2)
Point{2, Int64}([1, 2])

julia> Point(1, 2.0)          # coordinates are promoted to a common type
Point{2, Float64}([1.0, 2.0])

julia> Point((1.0, 2.0, 3.0)) # tuples work too
Point{3, Float64}([1.0, 2.0, 3.0])
```

See also [`distance`](@ref).
"""
struct Point{N, T} <: AbstractPoint{N, T}
    p::SVector{N, T}

    Point{N, T}(p) where {N, T} = new{N, T}(p)
end

Point{N}(p::AbstractVector{T}) where {N, T} = Point{N, T}(p)
Point(p::SVector{N, T}) where {N, T} = Point{N, T}(p)

function Point(pᵢ::Vararg{Number, N}) where {N}
    T = promote_type(typeof.(pᵢ)...)
    return Point{N, T}(SVector{N, T}(pᵢ))
end

Adapt.@adapt_structure Point

@inline Point(p::Point) = p
@inline Point(p::NTuple) = Point(p...)

@inline totuple(p::Point) = p.p.data

Base.length(::Point{N}) where {N} = N

Base.getindex(p::Point, i::Integer) = p.p[i]

Base.:(==)(p1::Point{N}, p2::Point{N}) where {N} = p1.p == p2.p
Base.hash(p::Point, h::UInt) = hash(p.p, h)
Base.isapprox(p1::Point{N}, p2::Point{N}; kwargs...) where {N} = isapprox(p1.p, p2.p; kwargs...)

for op in (:+, :-, :*, :/, :^)
    @eval begin
        Base.$op(p::Point, x::Number) = Point(broadcast($op, p.p, x))
        Base.$op(x::Number, p::Point) = Point(broadcast($op, x, p.p))
    end
end

for op in (:*, :/, :^)
    @eval begin
        Base.$op(p1::Point{N}, p2::Point{N}) where {N} = Point(broadcast($op, p1.p, p2.p))
    end
end

for op in (:+, :-)
    @eval begin
        Base.$op(p1::Point{N}, p2::Point{N}) where {N} = Point(Base.$op(p1.p, p2.p))
        Base.$op(p1::Point{N}, p2::SVector{N}) where {N} = Base.$op(p1.p, p2)
        Base.$op(p1::SVector{N}, p2::Point{N}) where {N} = Base.$op(p1, p2.p)
    end
end

Base.:-(p::Point) = Point(-p.p)

Base.:*(A::SMatrix{M, N}, p::Point{N}) where {M, N} = A * p.p

Base.adjoint(p::Point) = adjoint(p.p)

"""
    distance(p1::Point{N}, p2::Point{N}) -> Real

Euclidean distance between `p1` and `p2`.

# Examples
```jldoctest
julia> distance(Point(0, 0), Point(3, 4))
5.0
```
"""
@inline distance(p1::Point{N}, p2::Point{N}) where {N} = norm(p1.p - p2.p)

@inline function isequal_r(a::Point{N}, b::Point{N}) where {N}
    return all(ntuple(i -> isequal_r(a[i], b[i]), Val(N)))
end
