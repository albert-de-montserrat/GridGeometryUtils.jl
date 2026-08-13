abstract type AbstractLine{T} <: AbstractGeometryObject{T} end

"""
    Line{T} <: AbstractLine{T}
    Line(slope, intercept)
    Line(p1::Point{2}, p2::Point{2})
    Line(s::Segment{2})

An infinite line in slope-intercept form, ``y = slope \\cdot x + intercept``.

This form cannot represent a vertical line, so constructing one from two points sharing an
``x`` coordinate throws an `ArgumentError` instead of returning an infinite slope. Segment
intersection ([`intersection`](@ref), [`dointersect`](@ref)) does not go through `Line` and
handles vertical segments.

# Fields
- `slope::T`, `intercept::T`

# Examples
```jldoctest
julia> l = Line(Point(0, 0), Point(1, 1))
Line{Float64}(1.0, 0.0)

julia> line(l, 3)
3.0
```
"""
struct Line{T} <: AbstractLine{T}
    slope::T
    intercept::T

    Line{T}(slope, intercept) where {T} = new{T}(slope, intercept)
end

Line(slope::T1, intercept::T2) where {T1, T2} = Line{promote_type(T1, T2)}(slope, intercept)

function Line(p1::Point{2}, p2::Point{2})
    p1x, p1y = p1[1], p1[2]
    p2x, p2y = p2[1], p2[2]
    isequal_r(p1x, p2x) && throw(
        ArgumentError("the vertical line through $p1 and $p2 has no slope-intercept form")
    )
    slope = (p2y - p1y) / (p2x - p1x)
    return Line(slope, muladd(-slope, p1x, p1y))
end

Adapt.@adapt_structure Line

"""
    line(l::Line, x::Number) -> Number

Evaluate `l` at `x`, i.e. the ``y`` of the point on `l` with that ``x``.

# Examples
```jldoctest
julia> l = Line(2, 1);   # y = 2x + 1

julia> line(l, 3)
7

julia> line(l, 0.5)
2.0
```
"""
@inline line(l::Line, x::Number) = muladd(l.slope, x, l.intercept)

"""
    Segment{N, T} <: AbstractLine{T}
    Segment(p1::Point{N}, p2::Point{N})

The straight segment bounded by the two distinct endpoints `p1` and `p2`.

# Fields
- `p1::Point{N, T}`, `p2::Point{N, T}`: the endpoints.

# Examples
```jldoctest
julia> s = Segment(Point(0, 0), Point(1, 1));

julia> intersection(s, Segment(Point(0, 1), Point(1, 0)))
Point{2, Float64}([0.5, 0.5])
```
"""
struct Segment{N, T} <: AbstractLine{T}
    p1::Point{N, T}
    p2::Point{N, T}

    function Segment{N, T}(p1, p2) where {N, T}
        p1 == p2 && throw(ArgumentError("a Segment needs two distinct endpoints, got $p1 twice"))
        return new{N, T}(p1, p2)
    end
end

function Segment(p1::Point{N, T1}, p2::Point{N, T2}) where {N, T1, T2}
    T = promote_type(T1, T2)
    return Segment{N, T}(Point(SVector{N, T}(p1.p)), Point(SVector{N, T}(p2.p)))
end

Adapt.@adapt_structure Segment

Line(s::Segment{2}) = Line(s.p1, s.p2)

# Position of the crossing of the infinite lines through `s1` and `s2`, as the parameter
# pair `(t, u)` with the crossing at `s1.p1 + t * (s1.p2 - s1.p1)` and likewise for `u` on
# `s2`; `nothing` when the segments are parallel. Solving in this parametric form, rather
# than through slope and intercept, keeps vertical segments finite.
@inline function _crossing(s1::Segment{2}, s2::Segment{2})
    𝐫 = coords(s1.p2) - coords(s1.p1)
    𝐬 = coords(s2.p2) - coords(s2.p1)
    areparallel(𝐫, 𝐬) && return nothing

    denom = cross2(𝐫, 𝐬)
    𝐝 = coords(s2.p1) - coords(s1.p1)
    return cross2(𝐝, 𝐬) / denom, cross2(𝐝, 𝐫) / denom
end

"""
    intersection(s1::Segment{2}, s2::Segment{2}) -> Point{2}

Point at which the infinite lines through `s1` and `s2` cross.

The result need not lie on either segment; use [`dointersect`](@ref) to test that. Parallel
segments, including collinear ones, throw an `ArgumentError`.

# Examples
```jldoctest
julia> intersection(Segment(Point(0, 0), Point(1, 1)), Segment(Point(3, 1), Point(4, 0)))
Point{2, Float64}([2.0, 2.0])
```
"""
function intersection(s1::Segment{2}, s2::Segment{2})
    tu = _crossing(s1, s2)
    isnothing(tu) && throw(ArgumentError("segments $s1 and $s2 are parallel and do not cross"))
    t = first(tu)
    return Point(coords(s1.p1) + t * (coords(s1.p2) - coords(s1.p1)))
end

"""
    dointersect(s1::Segment{2}, s2::Segment{2}) -> Bool

Test whether `s1` and `s2` cross, i.e. whether their [`intersection`](@ref) falls within
the bounds of both segments. Endpoints count as touching. Parallel segments — including
collinear, overlapping ones — return `false`.

# Examples
```jldoctest
julia> dointersect(Segment(Point(0, 0), Point(1, 1)), Segment(Point(0, 1), Point(1, 0)))
true

julia> dointersect(Segment(Point(0, 0), Point(1, 1)), Segment(Point(3, 1), Point(4, 0)))
false
```
"""
function dointersect(s1::Segment{2}, s2::Segment{2})
    tu = _crossing(s1, s2)
    isnothing(tu) && return false
    t, u = tu
    return _inunitrange(t) && _inunitrange(u)
end

@inline _inunitrange(x) = leq_r(zero(x), x) && leq_r(x, one(x))
