function intersecting_boundary(p::Point{2}, r::Rectangle)
    # Check if the point is on any boundary
    intersect = intersecting_boundary(p[1], p[2], r)
    # If the point is inside the rectangle, we throw an error
    iszero(intersect) && throw("Point is inside the rectangle, no intersection")
    # Otherwise, return the boundary
    return intersect
end

function intersecting_boundary(px, py, r::Rectangle)
    (; origin, h, l) = r
    ox, oy = origin[1], origin[2]
    if @comp oy ≤ py && py ≤ oy + h
        @comp px == ox     && return 1 # :left
        @comp px == ox + l && return 2 # :right
    end
    @comp py ≤ oy     && return 3 # :bottom
    @comp py ≥ oy + h && return 4 # :top
    return 0 # :inside
end
