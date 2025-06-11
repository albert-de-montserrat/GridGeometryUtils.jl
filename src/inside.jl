using GridGeometryUtils

function inside(p::Point, rect::Rectangle)

    (; origin, h, l,  cosθ, sinθ) = rect

    x_temp = [p[1]-origin[1], p[2]-origin[2]] # TODO: remove once all inputs are SArrays

    # Shift
    𝐱 = SVector{2}(x_temp)

    # Rotation matrix
    𝐑  = @SMatrix([ cosθ -sinθ; sinθ cosθ])

    # Rotate geometry
    𝐱′ = 𝐑*𝐱

    # Check if inside
    return abs(𝐱′[1]) ≤ l/2 && abs(𝐱′[2]) ≤ h/2
end