function inside(p::Union{Point, SArray}, rect::Rectangle)
    (; origin, h, l, cosθ, sinθ) = rect

    return inside(p, rect.box) ? _inside(p, rect) : false
end

function inside(p::Union{Point, SArray}, ellipse::Ellipse)
    (; center, a, b, cosθ, sinθ) = ellipse

    return inside(p, ellipse.box) ? _inside(p, ellipse) : false
end

function inside(p::Union{Point, SArray}, circle::Circle)
    (; center, radius) = circle

    return inside(p, circle.box) ? _inside(p, circle) : false
end

function inside(p::Union{Point, SArray}, hex::Hexagon)
    (; origin, radius) = hex

    return inside(p, hex.box) ? _inside(p, hex) : false
end

function inside(p::Union{Point, SArray}, box::BBox)
    (; origin, h, l) = box
    # assumes origin is the SW vertex!
    p[1] < origin[1]     && return false
    p[2] < origin[2]     && return false
    p[1] > origin[1] + l && return false
    p[2] > origin[2] + h && return false
    return true
end

function _inside(p::Union{Point, SArray}, rect::Rectangle)
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

function _inside(p::Union{Point, SArray}, ellipse::Ellipse)
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

function _inside(p::Union{Point, SArray}, circle::Circle)
    (; center, radius) = circle

    iswithin = leq_r(sum(@. ((p.p - center.p) / radius)^2), 1)
    return iswithin
end

function _inside(p::Union{Point, SArray}, hex::Hexagon)
    (; origin, radius, cosθ, sinθ, box, vertices) = hex

    # Ray-casting algorithm
    n = size(vertices, 2)
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