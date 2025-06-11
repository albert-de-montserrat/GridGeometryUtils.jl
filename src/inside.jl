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
        # Shift
        𝐱 = p - origin
        # Rotation matrix
        𝐑 = @SMatrix([ cosθ -sinθ; sinθ cosθ])
        # Rotate geometry
        𝐱′ = 𝐑 * 𝐱
        # Check if inside
        return abs(𝐱′[1]) ≤ l / 2 && abs(𝐱′[2]) ≤ h / 2
    else
        return false
    end
end
