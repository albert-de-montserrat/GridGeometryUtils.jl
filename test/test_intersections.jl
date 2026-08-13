# x ∈ [-1, 1], y ∈ [-2, 2]; `origin` is the center, `box.origin` the south-west corner.
const RECT = Rectangle((0.0, 0.0), 2.0, 4.0)

# The point of `RECT` at boundary parameter `s`, built independently of `boundary_param` so
# that the two can be checked against each other.
function boundary_point(s)
    e, t = floor(Int, s), s - floor(s)
    return e == 0 ? Point(-1 + 2t, -2.0) :
        e == 1 ? Point(1.0, -2 + 4t) :
        e == 2 ? Point(1 - 2t, 2.0) : Point(-1.0, 2 - 4t)
end

@testset "boundary_param" begin
    # Runs counter-clockwise from the south-west corner, one unit per edge.
    @test boundary_param(Point(-1.0, -2.0), RECT) == 0     # SW corner
    @test boundary_param(Point(0.0, -2.0), RECT) == 0.5    # bottom edge
    @test boundary_param(Point(1.0, -2.0), RECT) == 1      # SE corner
    @test boundary_param(Point(1.0, 0.0), RECT) == 1.5     # right edge
    @test boundary_param(Point(1.0, 2.0), RECT) == 2       # NE corner
    @test boundary_param(Point(0.0, 2.0), RECT) == 2.5     # top edge
    @test boundary_param(Point(-1.0, 2.0), RECT) == 3      # NW corner
    @test boundary_param(Point(-1.0, 0.0), RECT) == 3.5    # left edge

    @test_throws "does not lie on the boundary" boundary_param(Point(0.0, 0.0), RECT)
    @test_throws "does not lie on the boundary" boundary_param(Point(-5.0, 0.0), RECT)

    @testset "rotated" begin
        # The parameter is attached to the rectangle's own edges, so rotating the rectangle
        # and its boundary points together leaves every parameter unchanged.
        θ = 0.7
        rot = Rectangle((0.0, 0.0), 2.0, 4.0; θ)
        turn(p) = Point(p[1] * cos(θ) - p[2] * sin(θ), p[1] * sin(θ) + p[2] * cos(θ))

        for s in (0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5)
            p = boundary_point(s)
            @test boundary_param(turn(p), rot) ≈ s atol = 1.0e-12
            @test intersecting_boundary(turn(p), rot) == intersecting_boundary(p, RECT)
        end

        @test_throws "does not lie on the boundary" boundary_param(Point(0.0, 0.0), rot)
        # A point on the bounding box of a rotated rectangle is not on the rectangle.
        @test_throws "does not lie on the boundary" boundary_param(rot.box.origin, rot)
    end
end

@testset "intersecting_boundary" begin
    # A point on the left edge is on the left edge, not the bottom one.
    @test intersecting_boundary(Point(-1.0, 0.0), RECT) == 1
    @test intersecting_boundary(Point(1.0, 0.0), RECT) == 2
    @test intersecting_boundary(Point(0.0, -2.0), RECT) == 3
    @test intersecting_boundary(Point(0.0, 2.0), RECT) == 4

    @test_throws "does not lie on the boundary" intersecting_boundary(Point(0.0, 0.0), RECT)
end

@testset "intersecting_area" begin
    A = area(RECT)

    @testset "straight cuts" begin
        @test intersecting_area(Point(-1.0, 0.0), Point(1.0, 0.0), RECT) == 4.0   # lower half
        @test intersecting_area(Point(1.0, 0.0), Point(-1.0, 0.0), RECT) == 4.0   # upper half
        @test intersecting_area(Point(0.0, -2.0), Point(0.0, 2.0), RECT) == 4.0   # right half
        @test intersecting_area(Point(0.0, 2.0), Point(0.0, -2.0), RECT) == 4.0   # left half
        @test intersecting_area(Point(-1.0, 1.0), Point(1.0, 1.0), RECT) == 6.0
    end

    @testset "corner cuts and their complements" begin
        @test intersecting_area(Point(-1.0, -1.0), Point(0.0, -2.0), RECT) == 0.5
        @test intersecting_area(Point(0.0, -2.0), Point(-1.0, -1.0), RECT) == A - 0.5
        @test intersecting_area(Point(0.0, -2.0), Point(1.0, -1.0), RECT) == 0.5
        @test intersecting_area(Point(-1.0, 1.0), Point(0.0, 2.0), RECT) == A - 0.5
        @test intersecting_area(Point(0.0, 2.0), Point(1.0, 1.0), RECT) == A - 0.5
    end

    @testset "cuts through corners" begin
        @test intersecting_area(Point(-1.0, -2.0), Point(1.0, 2.0), RECT) == 4.0
        @test intersecting_area(Point(1.0, 2.0), Point(-1.0, -2.0), RECT) == 4.0
        @test intersecting_area(Point(-1.0, 2.0), Point(1.0, -2.0), RECT) == 4.0
    end

    @testset "degenerate chords" begin
        # A chord lying along one edge encloses nothing on its right ...
        @test intersecting_area(Point(-1.0, -2.0), Point(1.0, -2.0), RECT) == 0.0
        # ... and everything when traversed the other way.
        @test intersecting_area(Point(1.0, -2.0), Point(-1.0, -2.0), RECT) == A
    end

    @testset "complement identity" begin
        # The two pieces a chord cuts the rectangle into must add up to the whole, for
        # every ordered pair of boundary points and every pair of edges.
        @test all(1:2000) do _
            p1, p2 = boundary_point(4 * rand()), boundary_point(4 * rand())
            intersecting_area(p1, p2, RECT) + intersecting_area(p2, p1, RECT) ≈ A
        end
    end

    @testset "Segment method" begin
        s = Segment(Point(-1.0, 0.0), Point(1.0, 0.0))
        @test intersecting_area(s, RECT) == intersecting_area(s.p1, s.p2, RECT)
    end

    @testset "rejected input" begin
        @test_throws "does not lie on the boundary" intersecting_area(Point(0.0, 0.0), Point(1.0, 0.0), RECT)
        @test_throws "does not lie on the boundary" intersecting_area(Point(-1.0, 0.0), Point(5.0, 0.0), RECT)
    end

    @testset "rotated rectangle" begin
        θ = 0.7
        rot = Rectangle((0.0, 0.0), 2.0, 4.0; θ)
        turn(p) = Point(p[1] * cos(θ) - p[2] * sin(θ), p[1] * sin(θ) + p[2] * cos(θ))

        @test area(rot) == A

        # Rotating a chord along with its rectangle is an isometry, so every chord area is
        # the one the same chord cuts from the unrotated rectangle.
        @test all(1:2000) do _
            s1, s2 = 4 * rand(), 4 * rand()
            p1, p2 = boundary_point(s1), boundary_point(s2)
            isapprox(intersecting_area(turn(p1), turn(p2), rot), intersecting_area(p1, p2, RECT); atol = 1.0e-12)
        end

        # The complement identity has to survive the rotation on its own terms.
        @test all(1:2000) do _
            p1, p2 = turn(boundary_point(4 * rand())), turn(boundary_point(4 * rand()))
            intersecting_area(p1, p2, rot) + intersecting_area(p2, p1, rot) ≈ A
        end

        # A quarter turn is the case where the answer can be read off by eye: the rectangle
        # spans x ∈ [-2, 2], y ∈ [-1, 1], and a vertical chord through the center halves it.
        quarter = Rectangle((0.0, 0.0), 2.0, 4.0; θ = π / 2)
        @test intersecting_area(Point(0.0, -1.0), Point(0.0, 1.0), quarter) ≈ 4.0
        @test intersecting_area(Point(-2.0, 0.0), Point(2.0, 0.0), quarter) ≈ 4.0

        # An off-center rotated rectangle may not be assumed to sit at the origin.
        offset = Rectangle((10.0, -5.0), 2.0, 4.0; θ)
        shifted(p) = Point(turn(p)[1] + 10.0, turn(p)[2] - 5.0)
        @test all(1:500) do _
            p1, p2 = boundary_point(4 * rand()), boundary_point(4 * rand())
            isapprox(
                intersecting_area(shifted(p1), shifted(p2), offset),
                intersecting_area(p1, p2, RECT); atol = 1.0e-11
            )
        end
    end

    @testset "off-center rectangle" begin
        # Nothing may assume the rectangle sits at the origin.
        r = Rectangle((10.0, -5.0), 2.0, 4.0)   # x ∈ [9,11], y ∈ [-7,-3]
        @test intersecting_area(Point(9.0, -5.0), Point(11.0, -5.0), r) == 4.0
        @test intersecting_area(Point(10.0, -7.0), Point(10.0, -3.0), r) == 4.0
        @test intersecting_area(Point(9.0, -6.0), Point(10.0, -7.0), r) == 0.5
    end
end
