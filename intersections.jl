
# function intersecting_boundary(x::Number, r::Rectangle)
#     (; origin, h, l) = r
#     x == origin[1] && return :left
#     x == origin[2] && return :bot
#     x == origin[1] + h && return :right
#     x == origin[2] + l && return :top
#     return :inside
# end

function intersecting_boundary(px, py, r::Rectangle)
    (; origin, h, l) = r
    ox, oy = origin
    px == ox     && return :left
    px == ox + h && return :right
    py == oy     && return :bot
    py == oy + l && return :top
    return :inside
end

function intersecting_boundary(p::Point{2}, r::Rectangle)
    (; origin, h, l) = r
    ox, oy = origin
    px, py = p.p 
    # Make sure the point is within the rectangle
    @assert ox ≤ px ≤ ox + h
    @assert oy ≤ py ≤ oy + l

    # Check if the point is on any boundary
    intersect = intersecting_boundary(px, py, r)
    # If the point is inside the rectangle, we throw an error
    intersect === :inside && throw("Point is inside the rectangle, no intersection")
    # Otherwise, return the boundary
    return intersect
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

origin = 0, 0  
h, l = 1e0, 1e0
r = Rectangle(origin, h, l)
p1 = Point(0, 0.5)
p2 = Point(1, 0.5)

@test intersecting_boundary(Point(0, 0.5), r) == :left
@test intersecting_boundary(Point(1, 0.5), r) == :right
@test intersecting_boundary(Point(0.5, 0), r) == :bot
@test intersecting_boundary(Point(0.5, 1), r) == :top
@test_throws "Point is inside the rectangle, no intersection" intersecting_boundary(Point(0.5, 0.5), r) == :top

@code_warntype intersecting_area(p1, p2, r)
@b intersecting_area($(p1, p2, r)...)
intersecting_area(p1, p2, r)