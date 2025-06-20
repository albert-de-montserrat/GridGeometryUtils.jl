abstract type AbstractEllipsoid{T} <: AbstractGeometryObject{T} end

struct Circle{T} <: AbstractEllipsoid{T}
    center::Point{2, T}
    radius::T
    box::BBox{2, T}

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

struct Sphere{T} <: AbstractEllipsoid{T}
    center::Point{3, T}
    radius::T
    box::BBox{3, T}

    function Sphere(center::NTuple{3, T1}, r::T2) where {T1, T2}
        T = promote_type(T1, T2)
        center_promoted = Point(ntuple(i -> T(center[i]), Val(3))...)
        # Create bounding box
        origin = center .+ @SVector([-r, -r, -r])
        box = BBox(Point(origin), 2 * r, 2 * r, 2 * r)
        return new{T}(center_promoted, convert(T, r), box)
    end
end

Sphere(center::Point{3}, radius::Number) = Sphere(totuple(center), radius)
Sphere(center::SVector{3}, radius::Number) = Sphere(center.data, radius)

Adapt.@adapt_structure Sphere

struct Ellipse{T} <: AbstractEllipsoid{T}
    center::Point{2, T}
    a::T # semi-axis 1
    b::T # semi-axis 2
    sinθ::T
    cosθ::T
    box::BBox{2, T}
    vertices::SMatrix{2, 4, T, 8}

    function Ellipse(center::NTuple{2, T1}, a::T2, b::T3; θ::T4 = 0.0e0) where {T1, T2, T3, T4}
        T = promote_type(T1, T2, T3, T4)
        center_promoted = Point(ntuple(i -> T(center[i]), Val(2))...)

        sinθ, cosθ = if iszero(θ)
            zero(T), one(T)
        else
            sincos(θ)
        end

        𝐱W = center .+ @SVector([-a, 0])
        𝐱N = center .+ @SVector([0, b])
        𝐱E = center .+ @SVector([a, 0])
        𝐱S = center .+ @SVector([0, -b])
        𝐱 = SMatrix{2, 4}([ 𝐱W 𝐱N 𝐱E 𝐱S])

        vertices, box = if iszero(θ)
            origin = center .+ @SVector([-a, -b])
            box = BBox(origin, 2 * a, 2 * b)
            vertices = 𝐱
            vertices, box
        else
            # Define bounding box
            𝐑 = rotation_matrix(sinθ, cosθ)
            𝐱W = @SVector([-a, 0])
            𝐱N = @SVector([0, b])
            𝐱E = @SVector([a, 0])
            𝐱S = @SVector([0, -b])

            # Rotate geometry
            𝐱 = SMatrix{2, 4}([ 𝐱W 𝐱N 𝐱E 𝐱S])
            𝐱′ = 𝐑' * 𝐱 .+ center

            # Define bounding box
            lbox = 2 * sqrt(a^2 * cosθ^2 + b^2 * sinθ^2)
            hbox = 2 * sqrt(a^2 * sinθ^2 + b^2 * cosθ^2)
            origin_bbox = center .+ @SVector([-lbox / 2, -hbox / 2])
            box = BBox(origin_bbox, lbox, hbox)
            vertices = 𝐱′
            vertices, box
        end

        return new{T}(center_promoted, promote(a, b, sinθ, cosθ)..., box, vertices)
    end
end

Ellipse(center::Point{2}, a::Number, b::Number; θ::T = 0.0e0) where {T} = Ellipse(totuple(center), a, b; θ = θ)
Ellipse(center::SVector{2}, a::Number, b::Number; θ::T = 0.0e0) where {T} = Ellipse(center.data, a, b; θ = θ)

Adapt.@adapt_structure Ellipse
