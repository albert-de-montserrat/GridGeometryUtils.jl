module GridGeometryUtils

include("points.jl")
export Point, distance

include("lines.jl")
export Line, Segment, line, dointersect, intersection

include("polygons.jl")
public AbstractPolygon
export Triangle, Rectangle, Prism, Trapezoid
export area, volume, perimeter

include("intersections/intersections.jl")

include("intersections/areas.jl")
export intersecting_area

end # module GridGeometryUtils
