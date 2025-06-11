module GridGeometryUtils

using Adapt, StaticArrays, LinearAlgebra

include("points.jl")
export Point, distance

include("lines.jl")
export Line, Segment, line, dointersect, intersection

include("polygons.jl")
export Triangle, Rectangle, Prism, Trapezoid, BBox
export area, volume, perimeter

include("intersections/intersections.jl")

include("intersections/areas.jl")
export intersecting_area

include("inside.jl")
export inside

end # module GridGeometryUtils
