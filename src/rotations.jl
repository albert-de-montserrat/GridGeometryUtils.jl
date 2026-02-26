@inline rotation_matrix(θ::Real) = rotation_matrix(sincos(θ)...)
@inline rotation_matrix(sinθ, cosθ) = @SMatrix [cosθ sinθ; -sinθ cosθ]

@inline rotate(p::Point{2}, origin::Point{2}, θ::Real) = Point((rotation_matrix(θ) * (p - origin) + origin)...)

@inline function rotate(p::NTuple{N,Point{2}}, origin::Point{2}, θ::Real) where N
    points = mapreduce(x->x.p, hcat, p)
    rotated = rotation_matrix(θ) * (points .- origin.p) .+ origin.p
    ntuple(i -> Point(rotated[:,i]...), Val(N))
end

@inline function rotate(s::Segment, origin::Point{2}, θ::Real)
    p1, p2 = coordinates(s)
    return Segment(rotate(p1, origin, θ), rotate(p2, origin, θ))
end

@inline function rotate(t::Triangle, origin::Point{2}, θ::Real)
    p1, p2, p3 = coordinates(t)
    return Triangle(rotate(p1, origin, θ), rotate(p2, origin, θ), rotate(p3, origin, θ))
end

@inline function rotate(s::T, origin::Point{2}, θ::Real) where {T <: AbstractPolygon}
    p1, p2 = coordinates(s)
    return T(rotate(p1, origin, θ), rotate(p2, origin, θ))
end
