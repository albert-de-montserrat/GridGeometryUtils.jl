abstract type AbstractLine{T} end

"""
    Line{T} <: AbstractLine{T}

Represents an infinite 2-D line in slope-intercept form `y = slope * x + intercept`.

# Fields
- `slope::T`: The gradient of the line.
- `intercept::T`: The y-intercept of the line.

# Constructors
    Line(slope, intercept)
    Line(p1::Point{2}, p2::Point{2})

The two-point constructor derives slope and intercept from two distinct points.
"""
struct Line{T} <: AbstractLine{T}
    slope::T
    intercept::T

    function Line(slope::T1, intercept::T2) where {T1, T2}
        T = promote_type(T1, T2)
        return new{T}(slope, intercept)
    end
end

function Line(p1::Point{2}, p2::Point{2})
    p1x, p1y = p1.p
    p2x, p2y = p2.p
    Δx = p2x - p1x
    Δy = p2y - p1y
    slope = Δy / Δx
    intercept = muladd(-slope, p1x, p1y)

    return Line(slope, intercept)
end

Adapt.@adapt_structure Line

"""
    line(l::Line, x)

Evaluate the line equation at abscissa `x`, returning `l.slope * x + l.intercept`.
"""
@inline line(l::Line, x::Number) = muladd(l.slope, x, l.intercept)

"""
    Segment{N, T} <: AbstractLine{T}

Represents a finite 2-D or 3-D line segment defined by two endpoints.

# Fields
- `p1::Point{N, T}`: The start point.
- `p2::Point{N, T}`: The end point.
"""
struct Segment{N, T} <: AbstractLine{T}
    p1::Point{N, T}
    p2::Point{N, T}

    function Segment(p1::Point{N, T}, p2::Point{N, T}) where {N, T}
        return new{N, T}(p1, p2)
    end
end

Adapt.@adapt_structure Segment

@inline coordinates(s::Segment) = (s.p1, s.p2)

Line(s::Segment) = Line(s.p1, s.p2)

"""
    dointersect(s1::Segment, s2::Segment) -> Bool

Return `true` when segments `s1` and `s2` intersect within the x-range of `s1`.
"""
function dointersect(s1::Segment, s2::Segment)
    (; p1, p2) = s1
    p = intersection(s1, s2)

    # Check if intersect
    return @comp  p1[1] ≤ p[1] && p[1] ≤ p2[1]
end

"""
    intersection(s1::Segment, s2::Segment) -> Point

Return the intersection point of two infinite lines that extend through `s1` and `s2`.
"""
function intersection(s1::Segment, s2::Segment)
    l1, l2 = Line(s1), Line(s2)
    x = (l2.intercept - l1.intercept) / (l1.slope - l2.slope)
    y = muladd(l1.slope, x, l1.intercept)

    return Point(x, y)
end

"""
    intersection(l::Line, s::Segment{2}) -> (Point, Bool)

Return the candidate intersection point of line `l` with finite segment `s`, and a
`Bool` indicating whether the point lies within the segment's extent.
Returns `(Point(0, 0), false)` for segments parallel (or coincident) to `l`.
"""
# Returns (Point, Bool) — the candidate intersection and whether it lies within the segment.
function intersection(l::Line, s::Segment{2, T}) where {T}
    x1, y1 = s.p1[1], s.p1[2]
    x2, y2 = s.p2[1], s.p2[2]

    # Vertical segment: x coordinate is fixed
    if @comp x1 == x2
        x   = x1
        y   = muladd(l.slope, x, l.intercept)
        ylo, yhi = minmax(y1, y2)
        return Point(x, y), (@comp ylo ≤ y && y ≤ yhi)
    end

    ls = Line(s)
    # Parallel (or coincident) lines — no unique intersection
    @comp l.slope == ls.slope && return Point(zero(T), zero(T)), false

    x   = (ls.intercept - l.intercept) / (l.slope - ls.slope)
    y   = muladd(l.slope, x, l.intercept)
    xlo, xhi = minmax(x1, x2)
    return Point(x, y), (@comp xlo ≤ x && x ≤ xhi)
end
