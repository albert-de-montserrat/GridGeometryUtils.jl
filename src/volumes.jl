"""
    volume(shape)

Return the volume of the given 3-D geometry object.

Supported types: `Prism`, `Sphere`, `BBox{3}`.

Throws an informative error when `volume` is not implemented for the given type.
"""
@inline volume(::T) where {T <: AbstractPolygon} = throw("Volume not defined for the AbstractPolygon of type $T")
@inline volume(::T) where {T} = throw("$T is not an AbstractPolygon")
@inline volume(r::Prism) = r.h * r.l * r.d
@inline volume(s::Sphere) = (4 * π * s.radius^3) / 3
@inline volume(r::BBox{3}) = r.h * r.l * r.d
