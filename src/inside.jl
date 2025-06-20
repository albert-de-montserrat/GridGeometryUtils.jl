@inline inside(p::Union{Point, SArray}, object::AbstractGeometryObject) = inside(p, object.box) ? _inside(p, object) : false

@inline function inside(p::Union{Point, SArray}, box::BBox{2})
    (; origin, h, l) = box
    px, py = p[1], p[2]
    ox, oy = origin[1], origin[2]
    # assumes origin is the SW vertex!
    px < ox     && return false
    py < oy     && return false
    px > ox + l && return false
    py > oy + h && return false
    return true
end

@inline function inside(p::Union{Point, SArray}, box::BBox{3})
    (; origin, h, l, d) = box
    px, py, pz = p[1], p[2], p[3]
    ox, oy, oz = origin[1], origin[2], origin[3]
    # assumes origin is the SW vertex!
    px < ox     && return false
    py < oy     && return false
    px > ox + l && return false
    py > oy + d && return false
    pz > oz + h && return false
    return true
end

function inside(p::Union{Point, SArray}, lay::Layering)
    (; center, thickness, ratio, sinθ, cosθ, perturb_amp, perturb_width) = lay

    iswithin = false

    # Shift layering
    𝐱 = p - center
    # Rotate geometry
    𝐑 = rotation_matrix(sinθ, cosθ)
    𝐱′ = 𝐑 * 𝐱

    # Gaussian perturbation
    δy = perturb_amp * exp(-𝐱′[1]^2 / (2 * perturb_width^2))

    # Compute local vertical position in periodic layers
    y_mod = mod(𝐱′[2] - δy, thickness)

    # Determine if within Layer A or Layer B
    iswithin = y_mod < ratio * thickness

    return iswithin
end

@inline function _inside(p::Union{Point, SArray}, rect::Rectangle)
    (; origin, h, l, cosθ, sinθ) = rect

    iszero(sinθ) && return true # No rotation, just check bounding box

    # Shift
    𝐱 = p - origin
    # Rotation matrix
    𝐑 = rotation_matrix(sinθ, cosθ)
    # Rotate geometry
    𝐱′ = 𝐑 * 𝐱
    # Check if inside
    return leq_r(abs(𝐱′[1]), l / 2) && leq_r(abs(𝐱′[2]), h / 2)
end

@inline function _inside(p::Union{Point, SArray}, ellipse::Ellipse)
    (; center, a, b, cosθ, sinθ) = ellipse

    @inline inside_ellipse(p) = leq_r(((p[1] - center[1]) / a)^2 + ((p[2] - center[2]) / b)^2, 1)

    iswithin = if iszero(sinθ) # No rotation, just check bounding box
        inside_ellipse(p)

    else
        # Shift
        𝐱 = p - center
        # Rotation matrix
        𝐑 = rotation_matrix(sinθ, cosθ)
        # Rotate geometry
        𝐱′ = 𝐑 * 𝐱 + center
        # Check if inside
        inside_ellipse(Point(𝐱′))
    end

    return iswithin
end

@inline function _inside(p::Union{Point, SArray}, circle::Circle)
    (; center, radius) = circle

    iswithin = leq_r(sum(@. ((p.p - center.p) / radius)^2), 1)
    return iswithin
end

@inline function _inside(p::Union{Point, SArray}, hex::Hexagon)
    (; vertices) = hex

    # Ray-casting algorithm
    n = 6
    iswithin = false

    j = n
    for i in 1:n
        xi, yi = vertices[:, i]
        xj, yj = vertices[:, j]
        if ((yi > p[2]) != (yj > p[2])) &&
                (p[1] < (xj - xi) * (p[2] - yi) / (yj - yi + 1.0e-10) + xi)  # add small number to avoid divide-by-zero
            iswithin = !iswithin
        end
        j = i
    end

    return iswithin
end
