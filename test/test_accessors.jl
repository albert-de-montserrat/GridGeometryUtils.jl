# Bounded shapes in every flavour, used for the properties that must hold of all of them.
const BOUNDED = (
    Segment(Point(1.0, 5.0), Point(4.0, 2.0)),
    Segment(Point(1.0, 5.0, 0.0), Point(4.0, 2.0, 3.0)),
    BBox((0.0, 0.0), 2.0, 4.0),
    BBox((-1.0, 2.0, 0.5), 2.0, 4.0, 3.0),
    Triangle((0.0, 0.0), (3.0, 0.0), (0.0, 3.0)),
    Rectangle((0.0, 0.0), 2.0, 4.0),
    Rectangle((1.0, -2.0), 2.0, 4.0; θ = π / 6),
    Hexagon((0.5, 0.5), 2.0),
    Hexagon((0.5, 0.5), 2.0; θ = 0.4),
    Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0),
    Trapezoid((1.0, -2.0), 3.0, 5.0, 1.0),
    Circle((0.0, 0.0), 1.0),
    Sphere((1.0, 2.0, 3.0), 1.0),
    Ellipse((0.0, 0.0), 1.0, 2.0),
    Ellipse((0.0, 0.0), 1.0, 2.0; θ = 0.3),
)

# Corner opposite `origin`, which for a tight box is the componentwise maximum of the shape.
maxcorner(b::BBox{2}) = Point(b.origin[1] + b.l, b.origin[2] + b.h)
maxcorner(b::BBox{3}) = Point(b.origin[1] + b.l, b.origin[2] + b.h, b.origin[3] + b.d)

@testset "center" begin
    @testset "against the closed forms" begin
        @test center(BBox((0.0, 0.0), 2.0, 4.0)) == Point(1.0, 2.0)
        @test center(BBox((-1.0, 2.0, 0.5), 2.0, 4.0, 3.0)) == Point(0.0, 4.0, 2.0)
        @test center(Triangle((0.0, 0.0), (3.0, 0.0), (0.0, 3.0))) == Point(1.0, 1.0)
        @test center(Segment(Point(1.0, 5.0), Point(4.0, 2.0))) == Point(2.5, 3.5)
        @test center(Point(1.0, 2.0)) == Point(1.0, 2.0)

        # ȳ = h(l1 + 2 l2) / 3(l1 + l2) and x̄ = (l1² + l1 l2 + l2²) / 3(l1 + l2).
        @test center(Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0)) == Point(37 / 21, 22 / 21)

        # Shapes that store a center hand it back untouched.
        for shape in (Rectangle((1.0, -2.0), 2.0, 4.0; θ = π / 6), Hexagon((0.5, 0.5), 2.0),
                      Circle((0.0, 0.0), 1.0), Sphere((1.0, 2.0, 3.0), 1.0),
                      Ellipse((0.0, 0.0), 1.0, 2.0; θ = 0.3))
            @test center(shape) === shape.center
        end
        @test center(Layering((1.0, 2.0), 1.0, 0.5)) === Point(1.0, 2.0)
    end

    # An integer shape still has a fractional centroid.
    @test center(BBox((0, 0), 3, 3)) == Point(1.5, 1.5)
    @test center(Trapezoid((0, 0), 2, 3, 4)) == Point(37 / 21, 22 / 21)

    @testset "lies within its shape" begin
        # True of every convex shape, which all of these are.
        @testset "$(nameof(typeof(shape)))" for shape in BOUNDED
            @test inside(center(shape), shape)
        end
    end

    @test_throws "no center" center(Line(2.0, 1.0))
    @test_throws MethodError center("not a shape")
end

@testset "boundingbox" begin
    @testset "against the closed forms" begin
        @test boundingbox(Segment(Point(1.0, 5.0), Point(4.0, 2.0))) == BBox((1.0, 2.0), 3.0, 3.0)
        @test boundingbox(Triangle((0.0, 0.0), (3.0, 0.0), (0.0, 3.0))) == BBox((0.0, 0.0), 3.0, 3.0)
        @test boundingbox(Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0)) == BBox((0.0, 0.0), 4.0, 2.0)
        @test boundingbox(Hexagon((0.0, 0.0), 2.0)).origin == Point(-2.0, -√3)

        # A point is its own degenerate box.
        @test boundingbox(Point(1.0, 2.0)) == BBox((1.0, 2.0), 0.0, 0.0)
        @test boundingbox(Point(1.0, 2.0, 3.0)) == BBox((1.0, 2.0, 3.0), 0.0, 0.0, 0.0)

        # A box bounds itself, and a shape that stores one hands back that very field.
        box = BBox((0.0, 0.0), 2.0, 4.0)
        @test boundingbox(box) === box
        circle = Circle((0.0, 0.0), 1.0)
        @test boundingbox(circle) === circle.box
    end

    @testset "encloses its shape" begin
        @testset "$(nameof(typeof(shape)))" for shape in BOUNDED
            b = boundingbox(shape)
            @test inside(center(shape), b)

            # Sampled on a grid spanning the box: every point of the shape lies in the
            # box, and the box is tight, each of its faces being approached to within a
            # cell along every axis.
            lo, hi = b.origin, maxcorner(b)
            N = length(lo)
            n = 40
            step = ntuple(i -> (hi[i] - lo[i]) / n, N)
            encloses = true
            reached_lo = ntuple(_ -> false, N)
            reached_hi = ntuple(_ -> false, N)
            for idx in CartesianIndices(ntuple(_ -> 0:n, N))
                p = Point(ntuple(i -> lo[i] + step[i] * idx[i], N)...)
                inside(p, shape) || continue
                encloses &= inside(p, b)
                reached_lo = ntuple(i -> reached_lo[i] || p[i] - lo[i] ≤ 1.001 * step[i], N)
                reached_hi = ntuple(i -> reached_hi[i] || hi[i] - p[i] ≤ 1.001 * step[i], N)
            end
            @test encloses
            @test all(reached_lo)
            @test all(reached_hi)
        end
    end

    @test_throws "no bounding box" boundingbox(Line(2.0, 1.0))
    @test_throws "no bounding box" boundingbox(Layering((0.0, 0.0), 1.0, 0.5))
end

@testset "degenerate trapezoid has no centroid" begin
    @test_throws "encloses nothing" center(Trapezoid((0.0, 0.0), 2.0, 0.0, 0.0))
end
