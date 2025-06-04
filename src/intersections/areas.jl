function intersecting_area(p1, p2, r::Rectangle{T}) where T
    intersect_1 = intersecting_boundary(p1, r)
    intersect_2 = intersecting_boundary(p2, r)
    intersections = intersect_1, intersect_2

    area = if intersections === (:left, :right)
        area_left_right(p1, p2, r)

    elseif intersections === (:top, :bot)
        area_top_bot(p1, p2, r)
    
    elseif intersections === (:left, :bot)
        area_left_bot(p1, p2, r)
    
    elseif intersections === (:bot, :right)
        area_bot_right(p1, p2, r)
    
    elseif intersections === (:bot, :top)
        area_bot_top(p1, p2, r)
    
    else # it should have crashed before anyway
        throw("Unsupported intersection case")
    end
    return area
end

@inline area_left_bot(p1::Point{2}, p2::Point{2}, r::Rectangle)  = area(Triangle(r.origin, p1, p2))
@inline area_bot_right(p1::Point{2}, p2::Point{2}, r::Rectangle) = area(Triangle(r.origin + r.l, p1, p2))

@inline function area_left_right(p1, p2, r::Rectangle)
    polygon = Trapezoid(
        r.origin,
        r.h,
        p1[2] - r.origin[2],  # l1
        p2[2] - r.origin[2],  # l2
    )
    return area(polygon)
end

@inline function area_top_bot(p1, p2, r::Rectangle{T}) where T
    polygon = Trapezoid(
        r.origin .+ (r.h, zero(T)),
        r.h,
        p1[1],  # l1
        p2[1],  # l2
    )
    return area(polygon)
end

@inline function area_bot_top(p1, p2, r::Rectangle{T}) where T
    polygon = Trapezoid(
        r.origin .+ (r.l, zero(T)),
        r.h,
        # origin[1] + r.l - p1[1], # l1
        # origin[1] + r.l - p2[1], # l2
        p1[1],  # l1
        p2[1],  # l2
    )
    return area(polygon)
end
