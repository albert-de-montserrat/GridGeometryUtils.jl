abstract type AbstractLineOrPlane{T} end

struct Line{T} <: AbstractLineOrPlane{T}
    slope::T
    intercept::T

    function Line(slope::T1, intercept::T2) where {T1, T2}
        T = promote_type(T1, T2)
        new{T}(slope, intercept)
    end
end

function Line(p1::Point{2}, p2::Point{2})
    p1x, p1y  = p1.p
    p2x, p2y  = p2.p
    Δx        = p2x - p1x
    Δy        = p2y - p1y
    slope     = Δy / Δx
    intercept = p1y - slope * p1x
    
    return Line(slope, intercept)
end

@inline line(l::Line, x::Number) = muladd(l.slope, x, l.intercept)

# TODO
# - `intersect(::Line,::Line)::Bool`
# - `intersect(::Line,::Rectangle)::Bool`
# - `intersection(::Line,::Line)::Point{2,T}`
# - `intersection(::Line,::Rectangle)::NTuple{2,Point{2,T}`
