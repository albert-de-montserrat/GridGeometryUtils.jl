abstract type AbstractEllipsoid{T} end


struct Circle{T} <: AbstractEllipsoid{T}
    center::Point{2, T}
    radius::T
    box::BBox{T}

    function Circle(center::NTuple{2, T1}, r::T2) where {T1, T2}
        T = promote_type(T1, T2)
        center_promoted = Point(ntuple(i -> T(center[i]), Val(2))...)
        # Create bounding box
        origin = center .+ @SVector([-r, -r])
        box = BBox(origin, 2 * r, 2 * r)

        return new{T}(center_promoted, convert(T, r), box)
    end
end

Circle(center::Point{2}, radius::Number) = Circle(totuple(center), radius)
Circle(center::SVector{2}, radius::Number) = Circle(center.data, radius)

Adapt.@adapt_structure Circle

struct Ellipse{T} <: AbstractEllipsoid{T}
    center::Point{2, T}
    a::T # semi-axis 1
    b::T # semi-axis 2
    sinθ::T
    cosθ::T
    box::BBox{T}

    function Ellipse(center::NTuple{2, T1}, a::T2, b::T3; θ::T4 = 0.0e0) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        center_promoted = Point(ntuple(i -> T(center[i]), Val(2))...)

        sinθ, cosθ = if iszero(θ)
            zero(T), one(T)
        else
            sincos(θ)
        end

        box = if iszero(θ)
            origin = center .+ @SVector([-a, -b])
            BBox(origin, 2 * a, 2 * b)

        else
            # Define bounding box
            𝐑 = rotation_matrix(sinθ, cosθ)
            𝐱SW = center .+ @SVector([-a, -b])
            𝐱SE = center .+ @SVector([a, -b])
            𝐱NW = center .+ @SVector([-a, b])
            𝐱NE = center .+ @SVector([a, b])

            # Rotate geometry
            𝐱 = SMatrix{2, 4}([ 𝐱SW 𝐱SE 𝐱NW 𝐱NE])
            𝐱′ = 𝐑 * 𝐱
            lbox, hbox = maximum(𝐱′[1, :]) - minimum(𝐱′[1, :]), maximum(𝐱′[2, :]) - minimum(𝐱′[2, :])

            # shift center to make further computations faster
            origin_bbox = center .+ @SVector([-lbox / 2, -hbox / 2])
            BBox(origin_bbox, lbox, hbox)
        end

        return new{T}(center_promoted, promote(a, b, sinθ, cosθ)..., box)
    end
end

Ellipse(center::Point{2}, a::Number, b::Number; θ::T = 0.0e0) where {T} = Ellipse(totuple(center), a, b; θ = θ)
Ellipse(center::SVector{2}, a::Number, b::Number; θ::T = 0.0e0) where {T} = Ellipse(center.data, a, b; θ = θ)

Adapt.@adapt_structure Ellipse
