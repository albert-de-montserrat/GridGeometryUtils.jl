"""
    rotation_matrix(θ::Real) -> SMatrix{2,2}
    rotation_matrix(sinθ, cosθ) -> SMatrix{2,2}

Return the 2×2 clockwise rotation matrix for angle `θ` (in radians):

```
[ cosθ   sinθ ]
[-sinθ   cosθ ]
```

The two-argument form avoids recomputing `sincos` when both components are already
available.
"""
@inline rotation_matrix(θ::Real) = rotation_matrix(sincos(θ)...)
@inline rotation_matrix(sinθ, cosθ) = @SMatrix [cosθ sinθ; -sinθ cosθ]

"""
    rotate(p::Point{2}, origin::Point{2}, θ::Real) -> Point{2}
    rotate(pts::NTuple{N,Point{2}}, origin::Point{2}, θ::Real) -> NTuple{N,Point{2}}
    rotate(s::Segment, origin::Point{2}, θ::Real) -> Segment
    rotate(t::Triangle, origin::Point{2}, θ::Real) -> Triangle
    rotate(poly, origin::Point{2}, θ::Real) -> same type

Rotate the geometry object clockwise by angle `θ` (in radians) around `origin`.

All methods delegate to the `Point{2}` method and reconstruct the geometry object
from its rotated vertices.
"""
@inline rotate(p::Point{2}, origin::Point{2}, θ::Real) = Point((rotation_matrix(θ) * (p - origin) + origin)...)

@inline function rotate(p::NTuple{N, Point{2}}, origin::Point{2}, θ::Real) where {N}
    points = mapreduce(x -> x.p, hcat, p)
    rotated = rotation_matrix(θ) * (points .- origin.p) .+ origin.p
    return ntuple(i -> Point(rotated[:, i]...), Val(N))
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
