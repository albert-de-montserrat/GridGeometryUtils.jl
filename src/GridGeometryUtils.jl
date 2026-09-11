"""
    GridGeometryUtils

Geometric primitives and predicates for working with shapes on rectangular grids: point
containment ([`inside`](@ref)), measures ([`area`](@ref), [`perimeter`](@ref),
[`volume`](@ref)), and segment/rectangle intersection ([`intersection`](@ref),
[`boundary_param`](@ref), [`intersecting_area`](@ref)).

Comparisons throughout are made up to a relative tolerance of about `1000 * eps`, so points
within round-off of a boundary are treated as lying on it.
"""
module GridGeometryUtils

using Adapt: Adapt
using LinearAlgebra: dot, norm
using StaticArrays: SMatrix, SVector, @SMatrix, @SVector

abstract type AbstractGeometryObject{T} end

include("comparisons.jl")

include("points.jl")
export Point, distance

include("utils.jl")

include("rotation_matrices.jl")

include("lines.jl")
export Line, Segment, line, dointersect, intersection

include("polygons.jl")
export Triangle, Rectangle, Prism, Trapezoid, Hexagon, BBox

include("ellipsoids.jl")
export Ellipse, Circle, Sphere

include("layering.jl")
export Layering

include("accessors.jl")
export center, boundingbox

include("constructors.jl")

include("areas.jl")
export area, volume, perimeter

include("intersections/intersections.jl")
export boundary_param, intersecting_boundary

include("intersections/areas.jl")
export intersecting_area

include("inside.jl")
export inside

end # module GridGeometryUtils
