abstract type AbstractLayering{T} end

"""
    Layering{T} <: AbstractLayering{T}

A parametric type representing a rectangle with elements of type `T`. 

# Type Parameters
- `T`: The numeric type used for the layering's properties (e.g., `Float64`, `Int`).

"""
struct Layering{T} <: AbstractLayering{T}
    center::Point{2, T}
    thickness::T
    ratio::T
    sinθ::T
    cosθ::T
    perturb_amp::T
    perturb_width::T

    function Layering(center::NTuple{2, T1}, thickness::T2, ratio::T3; θ::T4 = 0.0, perturb_amp::T5 = 0.0, perturb_width::T6 = 1.0) where {T1, T2, T3, T4, T5, T6}
        T = promote_type(T1, T2, T3, T4, T5, T6)
        center_promoted = Point(ntuple(ix -> T(center[ix]), Val(2))...)

        sinθ, cosθ = if iszero(θ)
            zero(T), one(T)
        else
            sincos(θ)
        end

        return new{T}(center_promoted, promote(thickness, ratio, sinθ, cosθ, perturb_amp, perturb_width)...)
    end
end

Layering(origin::Point{2}, thickness::Number, ratio::Number; θ::T = 0.0, perturb_amp = 0.0, perturb_width = 1.0) where {T} = Layering(totuple(origin), t, r; θ = θ, p_amp, p_width)
Layering(origin::SVector{2}, thickness::Number, ratio::Number; θ::T = 0.0, perturb_amp = 0.0, perturb_width = 1.0) where {T} = Layering(origin.data, t, r; θ = θ, p_amp, p_width)

Adapt.@adapt_structure Layering
