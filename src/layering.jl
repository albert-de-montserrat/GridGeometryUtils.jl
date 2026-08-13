abstract type AbstractLayering{T} end

"""
    Layering{T} <: AbstractLayering{T}
    Layering(center, thickness, ratio; θ = 0, perturb_amp = 0, perturb_width = 1)

An infinite stack of two alternating parallel layers, A and B, of combined period
`thickness`. Layer A takes up the fraction `ratio` of each period and layer B the rest;
[`inside`](@ref) reports whether a point falls in layer A.

The stack is horizontal at `θ == 0` and rotated counter-clockwise by `θ` radians about
`center`. Interfaces are displaced vertically by a Gaussian bump of amplitude
`perturb_amp` and width `perturb_width`, centered on `center`.

# Fields
- `center::Point{2, T}`: origin of the layering, on an interface when unperturbed.
- `thickness::T`: period of the stack; must be positive.
- `ratio::T`: fraction of each period occupied by layer A; must lie in `[0, 1]`.
- `sinθ::T`, `cosθ::T`: sine and cosine of the rotation angle.
- `perturb_amp::T`: amplitude of the Gaussian perturbation.
- `perturb_width::T`: width of the Gaussian perturbation; must be positive.

# Examples
```jldoctest
julia> lay = Layering((0.0, 0.0), 1.0, 0.5);

julia> inside(Point(0.0, 0.25), lay), inside(Point(0.0, 0.75), lay)
(true, false)
```
"""
struct Layering{T} <: AbstractLayering{T}
    center::Point{2, T}
    thickness::T
    ratio::T
    sinθ::T
    cosθ::T
    perturb_amp::T
    perturb_width::T

    function Layering{T}(center, thickness, ratio, sinθ, cosθ, perturb_amp, perturb_width) where {T}
        thickness > 0 || throw(ArgumentError("layer thickness must be positive, got $thickness"))
        0 ≤ ratio ≤ 1 || throw(ArgumentError("layer ratio must lie in [0, 1], got $ratio"))
        perturb_width > 0 || throw(ArgumentError("perturbation width must be positive, got $perturb_width"))
        return new{T}(center, thickness, ratio, sinθ, cosθ, perturb_amp, perturb_width)
    end
end

function Layering(
        center::Tuple{Vararg{Number, 2}}, thickness::Number, ratio::Number;
        θ::Number = 0.0, perturb_amp::Number = 0.0, perturb_width::Number = 1.0
    )
    T = promote_type(
        eltype(promote(center...)), typeof(thickness), typeof(ratio),
        typeof(θ), typeof(perturb_amp), typeof(perturb_width),
    )
    center_promoted = Point(ntuple(ix -> T(center[ix]), Val(2))...)

    sinθ, cosθ = if iszero(θ)
        zero(T), one(T)
    else
        sincos(θ)
    end

    return Layering{T}(center_promoted, promote(thickness, ratio, sinθ, cosθ, perturb_amp, perturb_width)...)
end

function Layering(
        center::Point{2}, thickness::Number, ratio::Number;
        θ::Number = 0.0, perturb_amp::Number = 0.0, perturb_width::Number = 1.0
    )
    return Layering(totuple(center), thickness, ratio; θ, perturb_amp, perturb_width)
end

function Layering(
        center::SVector{2}, thickness::Number, ratio::Number;
        θ::Number = 0.0, perturb_amp::Number = 0.0, perturb_width::Number = 1.0
    )
    return Layering(center.data, thickness, ratio; θ, perturb_amp, perturb_width)
end

Adapt.@adapt_structure Layering
