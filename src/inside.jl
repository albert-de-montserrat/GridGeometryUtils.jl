using GridGeometryUtils, UnPack

function inside(p::Point, rect::Rectangle)

    @unpack origin, h, l, θ = rect

    # Shift
    Δx = p[1] - origin[1]      # This could be a static vector - should we do that?
    Δy = p[2] - origin[2]

    # Rotate 
    cosθ, sinθ = cos(-θ), sin(-θ) 
    x′ = Δx * cosθ - Δy * sinθ # This could be a static mat-vec product - should we do that?
    y′ = Δx * sinθ + Δy * cosθ

    # Check if inside
    return abs(x′) ≤ l/2 && abs(y′) ≤ h/2
end