# Every anchored shape, paired with a builder taking a `center` and one taking an `origin`,
# so that both keyword forms can be checked against the positional form they must match.
const ANCHORED = (
    (
        Rectangle((1.0, -2.0), 2.0, 4.0), c -> Rectangle(; center = c, l = 2.0, h = 4.0),
        o -> Rectangle(; origin = o, l = 2.0, h = 4.0),
    ),
    (
        Rectangle((1.0, -2.0), 2.0, 4.0; θ = π / 6), c -> Rectangle(; center = c, l = 2.0, h = 4.0, θ = π / 6),
        o -> Rectangle(; origin = o, l = 2.0, h = 4.0, θ = π / 6),
    ),
    (
        Hexagon((0.5, 0.5), 2.0; θ = 0.4), c -> Hexagon(; center = c, radius = 2.0, θ = 0.4),
        o -> Hexagon(; origin = o, radius = 2.0, θ = 0.4),
    ),
    (
        Circle((3.0, 1.0), 2.0), c -> Circle(; center = c, radius = 2.0),
        o -> Circle(; origin = o, radius = 2.0),
    ),
    (
        Sphere((3.0, 1.0, -1.0), 2.0), c -> Sphere(; center = c, radius = 2.0),
        o -> Sphere(; origin = o, radius = 2.0),
    ),
    (
        Ellipse((1.0, 2.0), 1.0, 3.0; θ = 0.3), c -> Ellipse(; center = c, a = 1.0, b = 3.0, θ = 0.3),
        o -> Ellipse(; origin = o, a = 1.0, b = 3.0, θ = 0.3),
    ),
    (
        BBox((1.0, 2.0), 2.0, 4.0), c -> BBox(; center = c, l = 2.0, h = 4.0),
        o -> BBox(; origin = o, l = 2.0, h = 4.0),
    ),
    (
        BBox((1.0, 2.0, 3.0), 2.0, 4.0, 6.0), c -> BBox(; center = c, l = 2.0, h = 4.0, d = 6.0),
        o -> BBox(; origin = o, l = 2.0, h = 4.0, d = 6.0),
    ),
    (
        Trapezoid((1.0, -2.0), 3.0, 5.0, 1.0), c -> Trapezoid(; center = c, h = 3.0, l1 = 5.0, l2 = 1.0),
        o -> Trapezoid(; origin = o, h = 3.0, l1 = 5.0, l2 = 1.0),
    ),
)

@testset "keyword constructors" begin
    @testset "either anchor rebuilds the shape" begin
        @testset "$(nameof(typeof(shape)))" for (shape, bycenter, byorigin) in ANCHORED
            # A rotated shape puts these two points in different places, so agreeing with
            # both is what pins the convention down.
            @test bycenter(center(shape)) == shape
            @test byorigin(boundingbox(shape).origin) == shape
        end
    end

    @testset "anchors accept the same forms as the positional constructors" begin
        rect = Rectangle(; center = (0.0, 0.0), l = 2.0, h = 4.0)
        @test Rectangle(; center = Point(0.0, 0.0), l = 2.0, h = 4.0) == rect
        @test Rectangle(; center = SA[0.0, 0.0], l = 2.0, h = 4.0) == rect
        @test Rectangle(; origin = Point(-1.0, -2.0), l = 2.0, h = 4.0) == rect
    end

    @testset "a Prism is a 3-D box" begin
        @test Prism(; origin = (0.0, 0.0, 0.0), l = 1.0, h = 2.0, d = 3.0) ==
            Prism((0.0, 0.0, 0.0), 1.0, 2.0, 3.0)
        @test Prism(; center = (0.5, 1.0, 1.5), l = 1.0, h = 2.0, d = 3.0) ==
            Prism((0.0, 0.0, 0.0), 1.0, 2.0, 3.0)
        @test_throws "a Prism is 3-D" Prism(; origin = (0.0, 0.0), l = 1.0, h = 2.0)
    end

    @testset "a Layering has only a center" begin
        @test Layering(; center = (1.0, 2.0), thickness = 1.0, ratio = 0.5) ==
            Layering((1.0, 2.0), 1.0, 0.5)
        @test Layering(; center = Point(0.0, 0.0), thickness = 1.0, ratio = 0.5, θ = 0.3) ==
            Layering((0.0, 0.0), 1.0, 0.5; θ = 0.3)
        @test_throws UndefKeywordError Layering(; thickness = 1.0, ratio = 0.5)
    end

    @testset "exactly one anchor" begin
        @test_throws "needs an anchor" Rectangle(; l = 1.0, h = 2.0)
        @test_throws "needs an anchor" Circle(; radius = 1.0)
        @test_throws "takes one anchor" Rectangle(; center = (0.0, 0.0), origin = (0.0, 0.0), l = 1.0, h = 2.0)
        @test_throws "takes one anchor" BBox(; center = (0.0, 0.0), origin = (0.0, 0.0), l = 1.0, h = 2.0)
        @test_throws "needs a depth" BBox(; origin = (0.0, 0.0, 0.0), l = 1.0, h = 2.0)
        @test_throws UndefKeywordError Rectangle(; center = (0.0, 0.0), h = 2.0)
    end

    @testset "validation still applies" begin
        @test_throws "extents must be non-negative" BBox(; origin = (0.0, 0.0), l = -1.0, h = 2.0)
        @test_throws "height must be positive" Trapezoid(; origin = (0.0, 0.0), h = 0.0, l1 = 1.0, l2 = 2.0)
    end
end
