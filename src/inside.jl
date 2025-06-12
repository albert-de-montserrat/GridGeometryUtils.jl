function inside(p::Union{Point, SArray}, box::BBox)
    (; origin, h, l) = box
    # assumes origin is the SW vertex!
    p[1] < origin[1]     && return false
    p[2] < origin[2]     && return false
    p[1] > origin[1] + l && return false
    p[2] > origin[2] + h && return false
    return true
end

function inside(p::Union{Point, SArray}, rect::Rectangle)
    (; origin, h, l, cosθ, sinθ) = rect

    if inside(p, rect.box)
        iszero(sinθ) && return true # No rotation, just check bounding box

        # Shift
        𝐱 = p - origin
        # Rotation matrix
        𝐑 = @SMatrix([ cosθ sinθ; -sinθ cosθ])
        # Rotate geometry
        𝐱′ = 𝐑 * 𝐱
        # Check if inside
        return leq_r(abs(𝐱′[1]), l / 2) && leq_r(abs(𝐱′[2]), h / 2)
    else
        return false
    end

end


function inside(p::Union{Point, SArray}, hex::Hexagon)
    (; origin, radius, cosθ, sinθ, box, vertices) = hex

    # Ray-casting algorithm
    n = size(vertices, 2)
    inside = false

    j = n
    for i in 1:n
        xi, yi = vertices[:, i]
        xj, yj = vertices[:, j]
        if ((yi > p[2]) != (yj > p[2])) &&
                (p[1] < (xj - xi) * (p[2] - yi) / (yj - yi + 1.0e-10) + xi)  # add small number to avoid divide-by-zero
            inside = !inside
        end
        j = i
    end

    return inside
end
