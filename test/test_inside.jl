@testset "In BBox?" begin
    @testset "2D" begin
        box = BBox(SA[0.0, 0.0], 2, 4)   # x ∈ [0,2], y ∈ [0,4]

        @test inside(SA[0.0, 0.0], box)   # corner
        @test inside(SA[1.0, 2.0], box)
        @test inside(SA[2.0, 4.0], box)   # far corner
        @test inside(Point(1.0, 2.0), box)

        @test !inside(SA[-0.1, 2.0], box)
        @test !inside(SA[2.1, 2.0], box)
        @test !inside(SA[1.0, -0.1], box)
        @test !inside(SA[1.0, 4.1], box)
    end

    @testset "3D" begin
        # `l`, `h` and `d` are the extents along x, y and z respectively.
        box = BBox(SA[0.0, 0.0, 0.0], 2, 4, 3)   # x ∈ [0,2], y ∈ [0,4], z ∈ [0,3]

        @test inside(SA[1.0, 1.0, 1.0], box)
        @test inside(SA[2.0, 4.0, 3.0], box)     # far corner
        @test inside(SA[1.0, 3.5, 1.0], box)     # y is bounded by h, not by d
        @test inside(SA[1.0, 1.0, 2.5], box)     # z is bounded by d, not by h

        @test !inside(SA[1.0, 4.5, 1.0], box)
        @test !inside(SA[1.0, 1.0, 3.5], box)
        # Every axis is bounded from below as well as from above.
        @test !inside(SA[-1.0, 1.0, 1.0], box)
        @test !inside(SA[1.0, -1.0, 1.0], box)
        @test !inside(SA[1.0, 1.0, -5.0], box)
    end
end

@testset "In Prism?" begin
    prism = Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0)

    @test inside(Point(1.0, 1.0, 1.0), prism)
    @test inside(SA[0.0, 0.0, 0.0], prism)
    @test !inside(Point(1.0, 1.0, -1.0), prism)
    @test !inside(Point(3.0, 1.0, 1.0), prism)
end

@testset "In Triangle?" begin
    t = Triangle(Point(0.0, 0.0), Point(1.0, 0.0), Point(0.0, 1.0))

    @test inside(Point(0.1, 0.1), t)
    @test inside(Point(0.0, 0.0), t)      # vertex
    @test inside(Point(0.5, 0.5), t)      # on the hypotenuse
    @test inside(SA[0.25, 0.25], t)
    @test !inside(Point(0.9, 0.9), t)
    @test !inside(Point(-0.1, 0.5), t)

    # Winding order must not matter.
    reversed = Triangle(Point(0.0, 0.0), Point(0.0, 1.0), Point(1.0, 0.0))
    @test inside(Point(0.1, 0.1), reversed)
    @test !inside(Point(0.9, 0.9), reversed)
end

@testset "In Trapezoid?" begin
    # Right angle at the origin, `l1 = 3` along x at y = 0, `l2 = 4` at y = 2.
    trap = Trapezoid((0.0, 0.0), 2.0, 3.0, 4.0)

    @test inside(Point(1.0, 1.0), trap)
    @test inside(Point(0.0, 0.0), trap)     # the right-angle vertex
    @test inside(Point(3.0, 0.0), trap)     # far end of l1
    @test inside(Point(4.0, 2.0), trap)     # far end of l2
    @test inside(Point(3.5, 1.0), trap)     # on the slanted leg
    @test inside(SA[0.0, 2.0], trap)        # top of the perpendicular leg

    @test !inside(Point(3.6, 1.0), trap)    # just beyond the slanted leg
    @test !inside(Point(-0.1, 1.0), trap)   # left of the perpendicular leg
    @test !inside(Point(1.0, -0.1), trap)
    @test !inside(Point(1.0, 2.1), trap)

    # The parallel sides may narrow rather than widen, and equal sides give a rectangle.
    narrowing = Trapezoid((0.0, 0.0), 2.0, 4.0, 3.0)
    @test inside(Point(3.5, 1.0), narrowing)
    @test !inside(Point(3.6, 1.0), narrowing)

    rect = Trapezoid((0.0, 0.0), 2.0, 3.0, 3.0)
    @test inside(Point(3.0, 2.0), rect)
    @test !inside(Point(3.1, 2.0), rect)
end

@testset "On a Segment?" begin
    s = Segment(Point(0.0, 0.0), Point(2.0, 4.0))

    @test inside(Point(1.0, 2.0), s)
    @test inside(Point(0.0, 0.0), s)        # endpoint
    @test inside(Point(2.0, 4.0), s)        # endpoint
    @test inside(SA[0.5, 1.0], s)

    @test !inside(Point(1.0, 2.1), s)       # off the line
    @test !inside(Point(3.0, 6.0), s)       # on the line, past the end
    @test !inside(Point(-1.0, -2.0), s)     # on the line, before the start

    # A vertical segment is no different, and works in 3-D too.
    @test inside(Point(1.0, 0.5), Segment(Point(1.0, 0.0), Point(1.0, 1.0)))
    s3 = Segment(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    @test inside(Point(0.5, 0.5, 0.5), s3)
    @test !inside(Point(0.5, 0.5, 0.6), s3)

    # The tolerance follows the length of the segment rather than an absolute threshold.
    tiny = Segment(Point(0.0, 0.0), Point(2.0e-8, 4.0e-8))
    @test inside(Point(1.0e-8, 2.0e-8), tiny)
    @test !inside(Point(1.0e-8, 2.1e-8), tiny)
end

@testset "On a Line?" begin
    l = Line(2, 1)   # y = 2x + 1

    @test inside(Point(0.0, 1.0), l)
    @test inside(Point(3.0, 7.0), l)
    @test inside(SA[-1.0, -1.0], l)
    @test !inside(Point(3.0, 7.1), l)
end

@testset "In Hexagon?" begin
    o2 = @SVector([0.0, 0.0])

    hex = Hexagon(o2, 2; θ = 10)
    @test inside(@SVector([0.0, 0.0]), hex) === true
    @test inside(@SVector([-14.0, 0.0]), hex) === false

    # A regular hexagon of circumradius 2 contains its inradius √3 but not its circumradius
    # in the direction between two vertices.
    hex = Hexagon(o2, 2.0)
    @test inside(Point(1.9, 0.0), hex)    # towards a vertex
    @test !inside(Point(2.1, 0.0), hex)
    @test inside(Point(0.0, 1.7), hex)    # towards an edge midpoint, inradius √3 ≈ 1.732
    @test !inside(Point(0.0, 1.8), hex)
end

@testset "In Rectangle?" begin
    o2 = @SVector([0.0, 0.0])

    rect = Rectangle(o2, 2, 4; θ = 0)   # centered, so x ∈ [-1,1], y ∈ [-2,2]
    @test inside(@SVector([0.0, 0.0]), rect)
    @test inside(@SVector([-0.99, 0.0]), rect)
    @test !inside(@SVector([-1.001, 0.0]), rect)
    @test inside(@SVector([0.0, 1.6]), rect)
    @test !inside(@SVector([0.0, 2.001]), rect)

    # A quarter turn swaps the sides.
    rotated = Rectangle(o2, 2, 4; θ = π / 2)
    @test inside(Point(1.9, 0.0), rotated)
    @test !inside(Point(2.1, 0.0), rotated)
    @test !inside(Point(0.0, 1.1), rotated)
    @test inside(Point(0.0, 0.9), rotated)

    # `Point` and `SVector` queries must agree.
    @test inside(Point(0.5, 0.5), rotated) == inside(SA[0.5, 0.5], rotated)
end

@testset "In Ellipse?" begin
    center = 0.0e0, 0.0e0
    a, b = 1.0e0, 2.0e0

    ellipse1 = Ellipse(center, a, b)

    p1 = Point(0.0e0, 0.0e0)
    p2 = Point(2.0e0, 0.0e0)
    p3 = Point(1.0e0, 0.0e0)
    p4 = Point(0.0e0, 2.0e0)

    @test inside(p1, ellipse1)
    @test !inside(p2, ellipse1)
    @test inside(p3, ellipse1)   # on the boundary
    @test inside(p4, ellipse1)   # on the boundary

    ellipse2 = Ellipse(center, a, b; θ = π / 2)

    @test inside(p1, ellipse2)
    @test inside(p2, ellipse2)
    @test inside(p3, ellipse2)
    @test !inside(p4, ellipse2)

    @test inside(SA[0.0, 0.0], ellipse2) == inside(p1, ellipse2)
end

@testset "In circle?" begin
    circle = Circle((0.0e0, 0.0e0), 1.0e0)

    @test inside(Point(0.0, 0.0), circle)
    @test !inside(Point(2.0, 0.0), circle)
    @test inside(Point(0.5, 0.5), circle)
    @test inside(Point(1.0, 0.0), circle)     # on the boundary
    @test !inside(Point(0.71, 0.71), circle)  # just outside, 0.71√2 > 1
    @test inside(SA[0.5, 0.5], circle)        # raw vectors work too
end

@testset "In sphere?" begin
    sphere = Sphere((0.0, 0.0, 0.0), 2.0)

    @test inside(Point(0.0, 0.0, 0.0), sphere)
    @test inside(Point(2.0, 0.0, 0.0), sphere)   # on the boundary
    @test !inside(Point(1.5, 1.5, 1.5), sphere)
    @test !inside(Point(3.0, 0.0, 0.0), sphere)
    @test inside(SA[0.0, 0.0, 1.0], sphere)
end

@testset "a shape stays within its bounding box" begin
    # The box is only ever used to reject candidates cheaply, so a point inside the shape
    # must always be inside the box; the reverse need not hold.
    shapes = (
        Rectangle((0.3, -0.2), 2.0, 4.0),
        Rectangle((0.3, -0.2), 2.0, 4.0; θ = π / 7),
        Hexagon((-1.0, 1.0), 2.0),
        Hexagon((-1.0, 1.0), 2.0; θ = 0.4),
        Circle((1.0, 2.0), 1.5),
        Ellipse((1.0, 2.0), 1.5, 0.5),
        Ellipse((1.0, 2.0), 1.5, 0.5; θ = 0.9),
    )
    @testset "$(nameof(typeof(shape)))" for shape in shapes
        (; origin, l, h) = shape.box
        # Sample generously beyond the box so points on both sides of it are covered.
        @test all(1:20_000) do _
            p = SA[origin[1] + l * (2.4 * rand() - 0.7), origin[2] + h * (2.4 * rand() - 0.7)]
            !inside(p, shape) || inside(p, shape.box)
        end
    end
end

@testset "inside on mismatched dimensions" begin
    # A query point of the wrong dimension matches no method for the shape, and the
    # fallback names both types rather than failing obscurely.
    @test_throws "`inside` is not defined" inside(Point(0.0, 0.0), Prism((0.0, 0.0, 0.0), 1.0, 1.0, 1.0))
    @test_throws "`inside` is not defined" inside(Point(0.0, 0.0, 0.0), Circle((0.0, 0.0), 1.0))
    @test_throws "`inside` is not defined" inside(Point(0.0, 0.0, 0.0), Segment(Point(0, 0), Point(1, 1)))
end
