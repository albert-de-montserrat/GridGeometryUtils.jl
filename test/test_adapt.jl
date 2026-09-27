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

# Some GPUs (Metal) have no `Float64`, so `Float32` geometry must never promote, whether
# through a default argument, a literal, or an irrational constant.
@testset "Float32 geometry stays Float32" begin
    o2, o3, w = (0.0f0, 0.0f0), (0.0f0, 0.0f0, 0.0f0), 1.0f0
    @test Rectangle(o2, w, w) isa Rectangle{Float32}
    @test Rectangle(; origin = o2, l = w, h = w) isa Rectangle{Float32}
    @test Hexagon(o2, w) isa Hexagon{Float32}
    @test Hexagon(; origin = o2, radius = w) isa Hexagon{Float32}
    @test Ellipse(o2, w, w) isa Ellipse{Float32}
    @test Ellipse(; origin = o2, a = w, b = w) isa Ellipse{Float32}
    @test Layering(o2, w, w / 2) isa Layering{Float32}
    @test Layering(; center = o2, thickness = w, ratio = w / 2) isa Layering{Float32}

    shapes2 = (
        BBox(o2, w, w), Triangle(o2, (w, 0.0f0), (0.0f0, w)), Rectangle(o2, w, w; θ = w),
        Hexagon(o2, w; θ = w), Trapezoid(o2, w, w, 2w), Circle(o2, w), Ellipse(o2, w, 2w; θ = w),
    )
    @testset "$(nameof(typeof(s)))" for s in shapes2
        @test area(s) isa Float32
        @test perimeter(s) isa Float32
    end
    sphere = Sphere(o3, w)
    @test area(sphere) isa Float32
    @test volume(sphere) isa Float32
    @test volume(Prism(o3, w, w, w)) isa Float32

    # Integer input still yields floating-point shapes wherever a rotation is involved.
    @test Rectangle((0, 0), 2, 4) isa Rectangle{Float64}
    @test Hexagon((0, 0), 2) isa Hexagon{Float64}
    @test Ellipse((0, 0), 1, 2) isa Ellipse{Float64}
    @test Layering((0, 0), 1, 0) isa Layering{Float64}
end

# Validation messages are static strings: interpolating runtime values would put string
# construction in every constructor, which GPU kernels cannot compile.
@testset "validation messages" begin
    @test_throws "BBox extents must be non-negative" BBox((0.0f0, 0.0f0), -1.0f0, 1.0f0)
    @test_throws "a 2-D BBox has no depth" BBox{2, Float32}(Point(0.0f0, 0.0f0), 1, 1, 1)
    @test_throws "three vertices of a Triangle must be distinct" Triangle((0, 0), (0, 0), (1, 1))
    @test_throws "trapezoid height must be positive" Trapezoid((0, 0), 0, 1, 1)
    @test_throws "trapezoid side lengths must be non-negative" Trapezoid((0, 0), 1, -1, 1)
    @test_throws "layer thickness must be positive" Layering((0, 0), 0, 0.5)
    @test_throws "layer ratio must lie in [0, 1]" Layering((0, 0), 1, 2)
    @test_throws "perturbation width must be positive" Layering((0, 0), 1, 0.5; perturb_width = 0)
end
