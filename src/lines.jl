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
    intercept = p1y - slope * p1x

    return Line(slope, intercept)
end

@inline line(l::Line, x::Number) = muladd(l.slope, x, l.intercept)

struct Segment{N, T} <: AbstractLine{T}
    p1::Point{N, T}
    p2::Point{N, T}

    function Segment(p1::Point{N, T}, p2::Point{N, T}) where {N, T}
        return new{N, T}(p1, p2)
    end
end

Line(s::Segment) = Line(s.p1, s.p2)

function dointersect(s1::Segment, s2::Segment)
    (; p1, p2) = s1
    p = intersection(s1, s2)

    # Check if intersect
    return p1[1] ≤ p[1] ≤ p2[1]
end

function intersection(s1::Segment, s2::Segment)
    l1, l2 = Line(s1), Line(s2)
    x = (l2.intercept - l1.intercept) / (l1.slope - l2.slope)
    y = l1.slope * x + l1.intercept

    return Point(x, y)
end
