function intersecting_boundary(p::Point{2}, r::Rectangle)
    (; origin, h, l) = r
    ox, oy = origin
    px, py = p.p
    # Make sure the point is within the rectangle
    # @assert ox ≤ px ≤ ox + h
    # @assert oy ≤ py ≤ oy + l

    # Check if the point is on any boundary
    intersect = intersecting_boundary(px, py, r)
    # If the point is inside the rectangle, we throw an error
    intersect === :inside && throw("Point is inside the rectangle, no intersection")
    # Otherwise, return the boundary
    return intersect
end

function intersecting_boundary(px, py, r::Rectangle)
    (; origin, h, l) = r
    ox, oy = origin
    if oy ≤ py ≤ oy + l
        px ≈ ox     && return 1 # :left
        px ≈ ox + l && return 2 # :right
    end
    py ≤ oy     && return 3 # :bottom
    py ≥ oy + h && return 4 # :top
    return 0 # :inside
end
