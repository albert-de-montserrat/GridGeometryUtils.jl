"""
    inside(p, object) -> Bool

Test whether the point `p` lies inside `object`, boundary included. `p` may be a
[`Point`](@ref) or an `SVector` of matching dimension.

Comparisons are made with a relative tolerance of about `1000 * eps`, so points within
round-off of the boundary count as inside.

A [`Line`](@ref) and a [`Segment`](@ref) enclose nothing, so for them the test is whether
`p` lies *on* the object.

# Examples
```jldoctest
julia> inside(Point(0.5, 0.5), Circle((0.0, 0.0), 1.0))
true

julia> inside(Point(1.0, 1.0), Circle((0.0, 0.0), 1.0))
false

julia> inside(Point(0.5, 0.5), Segment(Point(0.0, 0.0), Point(1.0, 1.0)))
true
```
"""
function inside end

@inline inside(p, object::AbstractGeometryObject) = throw(
    ArgumentError("`inside` is not defined for a $(typeof(p)) in a $(typeof(object))")
)

# A point lies within a convex polygon iff it stays on the same side of every edge, with the
# vertices taken in order around the boundary. A vanishing cross product puts the point on an
# edge, which counts as inside. The test is blind to the winding direction.
@inline function _inside_convex(p, vertices::Tuple)
    n = length(vertices)
    has_neg = false
    has_pos = false
    for i in eachindex(vertices)
        d = cross2(vertices[i], vertices[i % n + 1], p)
        has_neg |= lt_r(d, zero(d))
        has_pos |= gt_r(d, zero(d))
    end
    return !(has_neg && has_pos)
end

# Objects carrying a bounding box are rejected cheaply before the exact test runs.
@inline function inside(p::QueryPoint{2}, object::Union{Rectangle, Hexagon, Ellipse, Circle})
    return inside(p, object.box) && _inside(p, object)
end

@inline inside(p::QueryPoint{3}, object::Sphere) = inside(p, object.box) && _inside(p, object)

@inline function inside(p::QueryPoint{2}, box::BBox{2})
    (; origin, h, l) = box
    px, py = p[1], p[2]
    ox, oy = origin[1], origin[2]
    @comp px < ox && return false
    @comp py < oy && return false
    @comp px > ox + l && return false
    @comp py > oy + h && return false
    return true
end

@inline function inside(p::QueryPoint{3}, box::BBox{3})
    (; origin, h, l, d) = box
    px, py, pz = p[1], p[2], p[3]
    ox, oy, oz = origin[1], origin[2], origin[3]
    @comp px < ox && return false
    @comp py < oy && return false
    @comp pz < oz && return false
    @comp px > ox + l && return false
    @comp py > oy + h && return false
    @comp pz > oz + d && return false
    return true
end

@inline function inside(p::QueryPoint{3}, prism::Prism)
    (; origin, l, h, d) = prism
    return inside(p, BBox(origin, l, h, d))
end

@inline inside(p::QueryPoint{2}, t::Triangle) = _inside_convex(p, (t.p1, t.p2, t.p3))

@inline function inside(p::QueryPoint{2}, t::Trapezoid)
    (; origin, h, l1, l2) = t
    ox, oy = origin[1], origin[2]
    # The right angle, then along `l1`, along `l2`, and back down the perpendicular leg.
    vertices = (
        SVector(ox, oy),
        SVector(ox + l1, oy),
        SVector(ox + l2, oy + h),
        SVector(ox, oy + h),
    )
    return _inside_convex(p, vertices)
end

@inline function inside(p::QueryPoint{N}, s::Segment{N}) where {N}
    𝐫 = coords(s.p2) - coords(s.p1)
    𝐝 = coords(p) - coords(s.p1)
    r² = sum(abs2, 𝐫)

    # Position along the segment, and the offset from its infinite line measured as a
    # fraction of its length so that the tolerance follows the scale of the geometry.
    t = dot(𝐝, 𝐫) / r²
    isquasizero(norm(𝐝 - t * 𝐫) / √r²) || return false
    return _inunitrange(t)
end

@inline inside(p::QueryPoint{2}, l::Line) = isequal_r(p[2], line(l, p[1]))

function inside(p::QueryPoint{2}, lay::Layering)
    (; center, thickness, ratio, sinθ, cosθ, perturb_amp, perturb_width) = lay

    𝐱 = coords(p) - coords(center)
    𝐑 = rotation_matrix(sinθ, cosθ)
    𝐱′ = 𝐑 * 𝐱

    # Gaussian perturbation of the layer interfaces
    δy = perturb_amp * exp(-𝐱′[1]^2 / (2 * perturb_width^2))

    # Local vertical position within one period of the layering
    y_mod = mod(𝐱′[2] - δy, thickness)

    return leq_r(y_mod, ratio * thickness)
end

@inline function _inside(p::QueryPoint{2}, rect::Rectangle)
    (; origin, h, l, cosθ, sinθ) = rect

    # For an axis-aligned rectangle the bounding box is the rectangle itself, and the
    # caller has already tested it.
    iszero(sinθ) && return true

    𝐱′ = rotation_matrix(sinθ, cosθ) * (coords(p) - coords(origin))
    return leq_r(abs(𝐱′[1]), l / 2) && leq_r(abs(𝐱′[2]), h / 2)
end

@inline function _inside(p::QueryPoint{2}, ellipse::Ellipse)
    (; center, a, b, cosθ, sinθ) = ellipse

    𝐱 = coords(p) - coords(center)
    𝐱′ = iszero(sinθ) ? 𝐱 : rotation_matrix(sinθ, cosθ) * 𝐱

    return leq_r((𝐱′[1] / a)^2 + (𝐱′[2] / b)^2, one(eltype(𝐱′)))
end

@inline function _inside(p::QueryPoint, sphere::Union{Circle, Sphere})
    (; center, radius) = sphere
    𝐱 = coords(p) - coords(center)
    return leq_r(sum(abs2, 𝐱), radius^2)
end

@inline function _inside(p::QueryPoint{2}, hex::Hexagon)
    (; vertices) = hex
    px, py = p[1], p[2]

    # Ray-casting: count the hexagon edges crossed by a ray cast in the -x direction.
    iswithin = false
    j = 6
    for i in 1:6
        xi, yi = vertices[1, i], vertices[2, i]
        xj, yj = vertices[1, j], vertices[2, j]
        # `yj - yi` cannot vanish once the endpoints straddle `py`, so the division is safe.
        if gt_r(yi, py) ⊻ gt_r(yj, py)
            lt_r(px, (xj - xi) * (py - yi) / (yj - yi) + xi) && (iswithin = !iswithin)
        end
        j = i
    end

    return iswithin
end
