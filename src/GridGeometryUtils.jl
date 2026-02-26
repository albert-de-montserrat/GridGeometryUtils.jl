module GridGeometryUtils

using Adapt, StaticArrays, LinearAlgebra

import Base.∩

abstract type AbstractGeometryObject{T} end

include("comparisons.jl")

include("points.jl")
export Point, distance

include("lines.jl")
export Line, Segment, line, dointersect, intersection

include("polygons.jl")
export Triangle, Rectangle, Prism, Trapezoid, Hexagon, BBox

include("ellipsoids.jl")
export Ellipse, Circle, Sphere

include("layering.jl")
export Layering

include("areas.jl")
export area, perimeter

include("volumes.jl")
export volume

include("intersections/intersections.jl")

include("intersections/areas.jl")
export intersecting_area

include("inside.jl")
export inside

include("rotations.jl")
export rotate

end # module GridGeometryUtils
