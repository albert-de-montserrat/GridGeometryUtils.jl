# Keyword constructors that name the anchor they are given, so that a call site reading
# `Rectangle(; origin = (0, 0), l = 2, h = 4)` needs no knowledge of which point the
# positional form expects. Exactly one of `center` and `origin` is accepted.

@inline _astuple(x::Tuple) = x
@inline _astuple(p::Point) = totuple(p)
@inline _astuple(v::SVector) = v.data

@inline function _checkanchor(::Type{S}, center, origin) where {S}
    center === nothing && origin === nothing && throw(
        ArgumentError("$(nameof(S)) needs an anchor: pass either `center` or `origin`")
    )
    center === nothing || origin === nothing || throw(
        ArgumentError("$(nameof(S)) takes one anchor: pass `center` or `origin`, not both")
    )
    return nothing
end

# `build` anchors the shape at its center, and the caller gave the minimum corner. A
# shape's extents do not depend on where it sits, so one provisional build measures the
# offset between the two anchors exactly, whatever the shape and however it is rotated.
@inline function _build_at_origin(build, origin::Tuple)
    half = origin .- _astuple(boundingbox(build(origin)).origin)
    return build(origin .+ half)
end

# The mirror image: `build` anchors the shape at its minimum corner, and the caller gave
# the centroid.
@inline function _build_at_center(build, centroid::Tuple)
    offset = _astuple(center(build(centroid))) .- centroid
    return build(centroid .- offset)
end

function BBox(; center = nothing, origin = nothing, l::Number, h::Number, d = nothing)
    _checkanchor(BBox, center, origin)
    anchor = _astuple(center === nothing ? origin : center)
    length(anchor) == 3 && d === nothing && throw(
        ArgumentError("a 3-D BBox needs a depth: pass `d`")
    )
    build = x -> d === nothing ? BBox(x, l, h) : BBox(x, l, h, d)
    return center === nothing ? build(anchor) : _build_at_center(build, anchor)
end

function Prism(; kwargs...)
    box = BBox(; kwargs...)
    box isa Prism || throw(
        ArgumentError("a Prism is 3-D, but the anchor given has $(length(box.origin)) coordinates")
    )
    return box
end

function Trapezoid(; center = nothing, origin = nothing, h::Number, l1::Number, l2::Number)
    _checkanchor(Trapezoid, center, origin)
    build = x -> Trapezoid(x, h, l1, l2)
    return center === nothing ? build(_astuple(origin)) : _build_at_center(build, _astuple(center))
end

function Rectangle(; center = nothing, origin = nothing, l::Number, h::Number, θ::Number = 0.0)
    _checkanchor(Rectangle, center, origin)
    build = x -> Rectangle(x, l, h; θ)
    return origin === nothing ? build(_astuple(center)) : _build_at_origin(build, _astuple(origin))
end

function Hexagon(; center = nothing, origin = nothing, radius::Number, θ::Number = 0.0)
    _checkanchor(Hexagon, center, origin)
    build = x -> Hexagon(x, radius; θ)
    return origin === nothing ? build(_astuple(center)) : _build_at_origin(build, _astuple(origin))
end

function Circle(; center = nothing, origin = nothing, radius::Number)
    _checkanchor(Circle, center, origin)
    build = x -> Circle(x, radius)
    return origin === nothing ? build(_astuple(center)) : _build_at_origin(build, _astuple(origin))
end

function Sphere(; center = nothing, origin = nothing, radius::Number)
    _checkanchor(Sphere, center, origin)
    build = x -> Sphere(x, radius)
    return origin === nothing ? build(_astuple(center)) : _build_at_origin(build, _astuple(origin))
end

function Ellipse(; center = nothing, origin = nothing, a::Number, b::Number, θ::Number = 0.0)
    _checkanchor(Ellipse, center, origin)
    build = x -> Ellipse(x, a, b; θ)
    return origin === nothing ? build(_astuple(center)) : _build_at_origin(build, _astuple(origin))
end

# A layering fills the plane, so its `center` is the point it turns and is perturbed about
# rather than a centroid, and there is no minimum corner to offer as an alternative.
function Layering(;
        center, thickness::Number, ratio::Number,
        θ::Number = 0.0, perturb_amp::Number = 0.0, perturb_width::Number = 1.0
    )
    return Layering(_astuple(center), thickness, ratio; θ, perturb_amp, perturb_width)
end
