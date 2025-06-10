function intersecting_area(p1, p2, r::Rectangle)
    intersect_1 = intersecting_boundary(p1, r)
    intersect_2 = intersecting_boundary(p2, r)
    intersections = intersect_1, intersect_2

    area = if intersections === (:left, :right)
        area_left_right(p1, p2, r)

    elseif intersections === (:top, :bot)

        s1 = Segment(p1, p2)
        # find intersection with bottom boundary
        s2 = Segment(Point(r.origin), Point(r.origin .+ (r.l, 0)))
        pbot = intersection(s1, s2)
        # find intersection with top boundary
        s2 = Segment(Point(r.origin .+ (0, r.h)), Point(r.origin .+ (r.l, r.h)))
        ptop = intersection(s1, s2)
        # compute area
        area_top_bot(ptop, pbot, r)

    elseif intersections === (:bot, :top)
        
        s1 = Segment(p1, p2)
        # find intersection with bottom boundary
        s2 = Segment(Point(r.origin), Point(r.origin .+ (r.l, 0)))
        pbot = intersection(s1, s2)
        # find intersection with top boundary
        s2 = Segment(
            Point(r.origin .+ (0, r.h)), Point(r.origin .+ (r.l, r.h))
        )
        ptop = intersection(s1, s2)
        # compute area
        area_bot_top(pbot, ptop, r)

    elseif intersections === (:left, :bot)
        # find intersection with bottom boundary
        s1 = Segment(p1, p2)
        s2 = Segment(Point(r.origin), Point(r.origin .+ (r.l, 0)))
        pbot = intersection(s1, s2)
        # compute area
        area_left_bot(p1, pbot, r)

    elseif intersections === (:bot, :right)
        # find intersection with bottom boundary
        s1   = Segment(p1, p2)
        s2   = Segment(Point(r.origin), Point(r.origin .+ (r.l, 0)))
        pbot = intersection(s1, s2)
        # compute area
        area_bot_right(pbot, p2, r)

    elseif intersections === (:left, :top)
        # find intersection with bottom boundary
        s1   = Segment(p1, p2)
        s2   = Segment(Point(r.origin .+ (0, r.h)), Point(r.origin .+ (r.l, r.h)))
        ptop = intersection(s1, s2)
        # compute area
        area_left_top(p1, ptop, r)

    elseif intersections === (:top, :right)
        # find intersection with bottom boundary
        s1   = Segment(p1, p2)
        s2   = Segment(Point(r.origin .+ (0, r.h)), Point(r.origin .+ (r.l, r.h)))
        ptop = intersection(s1, s2)
        # compute area
        area_top_right(ptop, p2, r)

    else # it should have crashed before anyway
        throw("Unsupported intersection case")
    end
    return area
end

@inline intersecting_area(s::Segment, r::Rectangle) = intersecting_area(s.p1, s.p2, r)

@inline area_left_bot(p1::Point{2}, p2::Point{2}, r::Rectangle) = area(Triangle(Point(r.origin), p1, p2))
@inline area_bot_right(p1::Point{2}, p2::Point{2}, r::Rectangle{T}) where T = area(Triangle(Point(r.origin .+ (r.l, zero(T))), p1, p2))

@inline function area_left_right(p1, p2, r::Rectangle)
    polygon = Trapezoid(
        r.origin,
        r.h,
        p1[2] - r.origin[2],  # l1
        p2[2] - r.origin[2],  # l2
    )
    return area(polygon)
end

@inline function area_top_bot(p1, p2, r::Rectangle{T}) where {T}
    polygon = Trapezoid(
        r.origin .+ (r.h, zero(T)),
        r.h,
        p1[1],  # l1
        p2[1],  # l2
    )
    return area(polygon)
end

@inline function area_bot_top(p1, p2, r::Rectangle{T}) where {T}
    polygon = Trapezoid(
        r.origin .+ (r.l, zero(T)),
        r.h,
        p1[1],  # l1
        p2[1],  # l2
    )
    return area(polygon)
end

@inline function area_left_top(p1, p2, r::Rectangle{T}) where {T}
    tr = Triangle(Point(r.origin .+ (0, r.h)), p1, p2)
    return area(r) - area(tr)
end

@inline function area_top_right(p1, p2, r::Rectangle{T}) where {T}
    tr = Triangle(Point(r.origin .+ (r.l, r.h)), p1, p2)
    return area(r) - area(tr)
end