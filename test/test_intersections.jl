using GridGeometryUtils: boundary_param, intersecting_boundary

# x ∈ [-1, 1], y ∈ [-2, 2]; `origin` is the center, `box.origin` the south-west corner.
const RECT = Rectangle((0.0, 0.0), 2.0, 4.0)

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
    @test_throws "only axis-aligned" boundary_param(Point(-1.0, 0.0), Rectangle((0.0, 0.0), 2.0, 4.0; θ = 0.3))
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
        onboundary(s) = let e = floor(Int, s), t = s - floor(s)
            e == 0 ? Point(-1 + 2t, -2.0) :
                e == 1 ? Point(1.0, -2 + 4t) :
                e == 2 ? Point(1 - 2t, 2.0) : Point(-1.0, 2 - 4t)
        end
        @test all(1:2000) do _
            p1, p2 = onboundary(4 * rand()), onboundary(4 * rand())
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
        @test_throws "only axis-aligned" intersecting_area(
            Point(-1.0, 0.0), Point(1.0, 0.0), Rectangle((0.0, 0.0), 2.0, 4.0; θ = 0.3)
        )
    end

    @testset "off-center rectangle" begin
        # Nothing may assume the rectangle sits at the origin.
        r = Rectangle((10.0, -5.0), 2.0, 4.0)   # x ∈ [9,11], y ∈ [-7,-3]
        @test intersecting_area(Point(9.0, -5.0), Point(11.0, -5.0), r) == 4.0
        @test intersecting_area(Point(10.0, -7.0), Point(10.0, -3.0), r) == 4.0
        @test intersecting_area(Point(9.0, -6.0), Point(10.0, -7.0), r) == 0.5
    end
end
