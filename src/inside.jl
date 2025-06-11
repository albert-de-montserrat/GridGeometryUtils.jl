function inside(p::Union{Point, SArray}, box::BBox)
    (; origin, h, l, cosθ, sinθ) = box
    𝐱SW  = origin - @SVector([l/2, h/2])
    𝐱NE  = origin + @SVector([l/2, h/2])
    return 𝐱SW[1] ≤ p[1] ≤ 𝐱NE[1] && 𝐱SW[2] ≤ p[2] ≤ 𝐱NE[2]
end

function inside(p::Union{Point, SArray}, rect::Rectangle)
    (; origin, h, l, cosθ, sinθ) = rect

    # Shift
    𝐱 = p - origin
    # Rotation matrix
    𝐑 = @SMatrix([ cosθ -sinθ; sinθ cosθ])
    # Rotate geometry
    𝐱′ = 𝐑 * 𝐱
    # Check if inside
    return abs(𝐱′[1]) ≤ l / 2 && abs(𝐱′[2]) ≤ h / 2
end
