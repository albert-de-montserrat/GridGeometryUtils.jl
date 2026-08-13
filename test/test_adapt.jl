using Adapt

# Stands in for a GPU array type: adapting to it rebuilds a shape with its fields converted,
# which is what `Adapt.@adapt_structure` on each type is for. Reaching a real device is not
# needed to check that every field survives and the shape is reconstructible.
struct Float32Adaptor end
Adapt.adapt_storage(::Float32Adaptor, x::AbstractArray) = convert(AbstractArray{Float32}, x)
Adapt.adapt_storage(::Float32Adaptor, x::Float64) = Float32(x)

# Structural, precision-tolerant comparison, so a shape can be checked against its adapted
# counterpart field by field however deeply the shapes nest.
approxequal(a::Number, b::Number) = a ≈ b
approxequal(a::AbstractArray, b::AbstractArray) = size(a) == size(b) && all(splat(≈), zip(a, b))
function approxequal(a, b)
    fields = fieldnames(typeof(a))
    fields === fieldnames(typeof(b)) || return false
    return all(approxequal(getfield(a, f), getfield(b, f)) for f in fields)
end

@testset "Adapt" begin
    shapes = (
        Point(1.0, 2.0),
        Point(1.0, 2.0, 3.0),
        Line(2.0, 1.0),
        Segment(Point(0.0, 0.0), Point(1.0, 1.0)),
        BBox((0.0, 0.0), 2.0, 4.0),
        BBox((0.0, 0.0, 0.0), 2.0, 4.0, 3.0),
        Triangle((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        Rectangle((0.0, 0.0), 2.0, 4.0),
        Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 6),
        Hexagon((0.0, 0.0), 2.0),
        Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0),
        Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0),
        Circle((0.0, 0.0), 1.0),
        Sphere((0.0, 0.0, 0.0), 1.0),
        Ellipse((0.0, 0.0), 1.0, 2.0; θ = 0.3),
        Layering((0.0, 0.0), 1.0, 0.5; θ = 0.3, perturb_amp = 0.1, perturb_width = 2.0),
    )

    @testset "$(nameof(typeof(shape)))" for shape in shapes
        adapted = adapt(Float32Adaptor(), shape)

        @test nameof(typeof(adapted)) === nameof(typeof(shape))
        @test approxequal(adapted, shape)

        # Adapting to an adaptor that converts nothing leaves the shape untouched.
        @test adapt(nothing, shape) == shape
    end

    @testset "adapted shapes still answer queries" begin
        circle = adapt(Float32Adaptor(), Circle((0.0, 0.0), 1.0))
        @test circle isa Circle{Float32}
        @test inside(Point(0.5f0, 0.5f0), circle)
        @test !inside(Point(1.0f0, 1.0f0), circle)
        @test area(circle) ≈ π

        rect = adapt(Float32Adaptor(), Rectangle((0.0, 0.0), 2.0, 4.0))
        @test rect isa Rectangle{Float32}
        @test area(rect) ≈ 8
        @test intersecting_area(Point(-1.0f0, 0.0f0), Point(1.0f0, 0.0f0), rect) ≈ 4
    end
end
