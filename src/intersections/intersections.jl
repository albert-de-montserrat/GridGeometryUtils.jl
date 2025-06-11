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
    ox, oy = origin
    if leq_r(oy, py) && leq_r(py, oy + l)
        isequal_r(px, ox)     && return 1 # :left
        isequal_r(px, ox + l) && return 2 # :right
    end
    leq_r(py, oy)     && return 3 # :bottom
    geq_r(py, oy + h) && return 4 # :top
    return 0 # :inside
end
