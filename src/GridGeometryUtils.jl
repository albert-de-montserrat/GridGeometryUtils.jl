module GridGeometryUtils

include("points.jl")
public AbstractPoint
export Point, distance

include("polygons.jl")
public AbstractPolygon
export Triangle, Rectangle, Prism, Trapezoid
export area, volume, perimeter

include("intersections/intersections.jl")

include("intersections/areas.jl")
export intersecting_area

end # module GridGeometryUtils
