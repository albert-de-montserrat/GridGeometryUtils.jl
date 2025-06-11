using GridGeometryUtils

function inside(p::Point, rect::Rectangle)
    (; origin, h, l,  cosθ, sinθ) = rect

    # Shift
    𝐱 = p - origin
    # Rotation matrix
    𝐑  = @SMatrix([ cosθ -sinθ; sinθ cosθ])
    # Rotate geometry
    𝐱′ = 𝐑*𝐱
    # Check if inside
    return abs(𝐱′[1]) ≤ l/2 && abs(𝐱′[2]) ≤ h/2
end