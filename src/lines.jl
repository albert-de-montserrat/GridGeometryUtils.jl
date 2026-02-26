abstract type AbstractLine{T} end

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

@inline line(l::Line, x::Number) = muladd(l.slope, x, l.intercept)

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

function dointersect(s1::Segment, s2::Segment)
    (; p1, p2) = s1
    p = intersection(s1, s2)

    # Check if intersect
    return @comp  p1[1] ≤ p[1] && p[1] ≤ p2[1]
end

function intersection(s1::Segment, s2::Segment)
    l1, l2 = Line(s1), Line(s2)
    x = (l2.intercept - l1.intercept) / (l1.slope - l2.slope)
    y = muladd(l1.slope, x, l1.intercept)

    return Point(x, y)
end

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
