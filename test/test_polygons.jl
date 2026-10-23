@testset "Triangle" begin
    p1 = Point(1, 2)
    p2 = Point(1, 3)
    p3 = Point(2, 2)

    @test_throws "must be distinct" Triangle(p1, p1, p1)
    @test_throws "must be distinct" Triangle(p1, p2, p1)   # the p1/p3 pair counts too
    @test_throws "must be distinct" Triangle(p1, p1, p3)

    t = Triangle(p1, p2, p3)
    @test t.p1 == p1
    @test t.p2 == p2
    @test t.p3 == p3

    @test Triangle((1, 2), (1, 3), (2, 2)) == t
    @test Triangle(SA[1, 2], SA[1, 3], SA[2, 2]) == t

    @test area(t) ≈ 0.5
    @test perimeter(t) ≈ 2 + √2

    # Vertex order does not change the area.
    @test area(Triangle(p1, p3, p2)) ≈ area(t)

    # Collinear vertices are a valid, zero-area triangle.
    @test area(Triangle(Point(0, 0), Point(1, 1), Point(2, 2))) == 0

    # A sliver triangle, where Heron's formula loses every significant digit to
    # cancellation in the semiperimeter and returns exactly zero.
    y3 = 1.0e8 + 1.0e-8
    needle = Triangle(Point(0.0, 0.0), Point(1.0, 1.0), Point(1.0e8, y3))
    @test area(needle) > 0
    @test area(needle) ≈ (y3 - 1.0e8) / 2
end

@testset "BBox" begin
    @testset "2D" begin
        origin = (0, 0)
        bbox = BBox(origin, 2, 4)

        @test bbox.origin == Point(origin)
        @test bbox.l == 2
        @test bbox.h == 4
        @test iszero(bbox.d)
        @test area(bbox) == 8
        @test perimeter(bbox) == 12
    end

    @testset "3D" begin
        origin = (0, 0, 0)
        bbox = BBox(origin, 2, 4, 3)

        @test bbox.origin == Point(origin)
        @test bbox.l == 2
        @test bbox.h == 4
        @test bbox.d == 3
        @test volume(bbox) == 24
        @test area(bbox) == 2 * (2 * 4 + 2 * 3 + 4 * 3)
    end

    @testset "constructors" begin
        @test BBox((0, 0.0), 2, 4) isa BBox{2, Float64}       # heterogeneous tuple
        @test BBox(Point(0, 0), 2, 4) == BBox((0, 0), 2, 4)
        @test BBox(SA[0, 0], 2, 4) == BBox((0, 0), 2, 4)
        @test BBox(Point(0, 0, 0), 2, 4, 3) == BBox((0, 0, 0), 2, 4, 3)
        @test BBox(SA[0, 0, 0], 2, 4, 3) == BBox((0, 0, 0), 2, 4, 3)
        @test BBox((0, 0), 2.0f0, 4.0f0) isa BBox{2, Float32}

        # The typed form coerces its arguments like every other call form.
        @test BBox{2, Float64}(Point(0, 0), 1, 2, 0) == BBox((0.0, 0.0), 1.0, 2.0)
    end

    @testset "extents" begin
        # `origin` is the minimum corner only while every extent is non-negative.
        @test_throws "extents must be non-negative" BBox((0, 0), -2, 4)
        @test_throws "extents must be non-negative" BBox((0, 0), 2, -4)
        @test_throws "extents must be non-negative" BBox((0, 0, 0), 2, 4, -3)
        @test_throws "2-D BBox has no depth" BBox((0, 0), 2, 4, 3)

        # A degenerate box is legitimate: a zero-radius circle bounds itself.
        @test BBox((0, 0), 0, 0) isa BBox{2, Int}
    end
end

@testset "Rectangle" begin
    center = (0, 0)
    rect = Rectangle(center, 2, 4; θ = π / 3)

    @test rect.center == Point(Float64.(center))
    @test rect.l == 2
    @test rect.h == 4
    @test area(rect) == 8
    @test perimeter(rect) == 12

    # A rectangle is anchored at its center; the bounding box carries the south-west corner.
    unrotated = Rectangle(center, 2, 4)
    @test unrotated.center == Point(0.0, 0.0)
    @test unrotated.box.origin == Point(-1.0, -2.0)

    @test_throws "anchored at its `center`" unrotated.origin
    @test unrotated.box.l == 2
    @test unrotated.box.h == 4

    # Rotating enlarges the axis-aligned box (though not necessarily along both axes at
    # once) while leaving the rectangle's own area untouched.
    @test area(rect.box) > area(unrotated.box)
    @test area(rect) == area(unrotated)
    @test all(inside(Point(rect.vertices[1, i], rect.vertices[2, i]), rect.box) for i in 1:4)

    # Vertices are the corners, ordered SW, NW, NE, SE.
    @test unrotated.vertices ≈ SA[-1.0 -1.0 1.0 1.0; -2.0 2.0 2.0 -2.0]

    @test Rectangle(Point(0, 0), 2, 4) == unrotated
    @test Rectangle(SA[0, 0], 2, 4) == unrotated
end

@testset "Hexagon" begin
    center = (-1, 1)
    radius = 2
    hex = Hexagon(center, radius; θ = π / 3)

    @test hex.center == Point(Float64.(center))
    @test_throws "anchored at its `center`" hex.origin
    @test hex.radius == radius
    # Regular hexagon of circumradius r: area 3√3/2 r², perimeter 6r.
    @test area(hex) ≈ 3 * √3 / 2 * radius^2
    @test perimeter(hex) ≈ 6 * radius
    @test area(hex) < perimeter(hex)   # 10.39 < 12; the two were once swapped

    # A sixth-turn maps a regular hexagon onto itself.
    @test area(Hexagon(center, radius)) ≈ area(hex)
    @test sort(Hexagon(center, radius).vertices[1, :]) ≈ sort(hex.vertices[1, :])

    @test Hexagon(Point(-1, 1), 2) == Hexagon(center, radius)
    @test Hexagon(SA[-1, 1], 2) == Hexagon(center, radius)
end

@testset "Prism" begin
    origin = (0, 0, 0)
    prism = Prism(origin, 2, 4, 3)

    @test prism.origin == Point(origin)
    @test prism.l == 2
    @test prism.h == 4
    @test prism.d == 3
    @test volume(prism) == 24
    # Surface area, not the sum of the edge lengths.
    @test area(prism) == 2 * (2 * 4 + 2 * 3 + 4 * 3)

    @test Prism(Point(0, 0, 0), 2, 4, 3) == prism
    @test Prism(SA[0, 0, 0], 2, 4, 3) == prism
    @test_throws MethodError Prism(Point(0, 0), 2, 4, 3)
    @test_throws MethodError Prism((0, 0), 2, 4)

    @testset "is BBox{3}" begin
        # One type under two names, so a method written for either applies to both and the
        # two can never drift apart.
        @test Prism{Float64} === BBox{3, Float64}
        @test prism === BBox(origin, 2, 4, 3)
        @test prism isa BBox
        @test prism isa GridGeometryUtils.AbstractPolygon
    end
end

@testset "Trapezoid" begin
    origin = (0, 0)
    # h is the separation of the parallel sides; l1 and l2 are their lengths.
    trap = Trapezoid(origin, 2, 3, 4)

    @test trap.origin == Point(origin)
    @test trap.h == 2
    @test trap.l1 == 3
    @test trap.l2 == 4
    @test area(trap) == 7.0
    @test perimeter(trap) == 11.23606797749979

    # A trapezoid with equal parallel sides is a rectangle.
    @test area(Trapezoid(origin, 2, 3, 3)) == area(Rectangle(origin, 3, 2))
    @test perimeter(Trapezoid(origin, 2, 3, 3)) == perimeter(Rectangle(origin, 3, 2))

    @test Trapezoid(Point(0, 0), 2, 3, 4) == trap
    @test Trapezoid(SA[0, 0], 2, 3, 4) == trap

    # `origin` is the right-angled vertex, and hence the minimum corner, only while both
    # parallel sides run in the positive x direction.
    @test_throws "side lengths must be non-negative" Trapezoid(origin, 2, -3, 4)
    @test_throws "side lengths must be non-negative" Trapezoid(origin, 2, 3, -4)
    @test_throws "height must be positive" Trapezoid(origin, 0, 3, 4)
    @test_throws "height must be positive" Trapezoid(origin, -2, 3, 4)
end

@testset "unsupported measures" begin
    s = Segment(Point(0, 0), Point(1, 1))
    @test_throws "`area` is not defined" area(s)
    @test_throws "`perimeter` is not defined" perimeter(s)
    @test_throws "`volume` is not defined" volume(s)
    @test_throws "`volume` is not defined" volume(Triangle((0, 0), (1, 0), (0, 1)))
    @test_throws MethodError area("not a shape")
end
