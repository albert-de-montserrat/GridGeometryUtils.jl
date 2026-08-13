@testset "Line" begin
    p1 = Point(0, 0)
    p2 = Point(1, 1)

    l = Line(p1, p2)

    @test l isa Line{Float64}
    @test l.slope == 1
    @test l.intercept == 0

    for i in 0:10
        @test line(l, i) == i
    end

    @test Line(2, 3.0) isa Line{Float64}
    @test Line(Segment(p1, p2)) == l

    # Slope-intercept form cannot represent a vertical line, so say so rather than
    # returning an infinite slope and a NaN intercept.
    @test_throws "no slope-intercept form" Line(Point(0, 0), Point(0, 1))
    @test_throws "no slope-intercept form" Line(Point(1.0, -3.0), Point(1.0, 5.0))
end

@testset "Segment" begin
    s1 = Segment(Point(0, 0), Point(1, 1))
    s2 = Segment(Point(0, 1), Point(1, 0))
    s3 = Segment(Point(3, 1), Point(4, 0))

    @test intersection(s1, s2) == Point((0.5, 0.5))
    # The infinite lines cross outside both segments.
    @test intersection(s1, s3) == Point((2.0, 2.0))

    @test dointersect(s1, s2)
    @test !dointersect(s1, s3)

    # Endpoints count as touching.
    @test dointersect(s1, Segment(Point(1, 1), Point(2, 0)))

    @testset "vertical segments" begin
        # Handled through the parametric form, which never divides by a zero Δx.
        vertical = Segment(Point(0.0, -1.0), Point(0.0, 1.0))
        horizontal = Segment(Point(-1.0, 0.0), Point(1.0, 0.0))
        @test dointersect(vertical, horizontal)
        @test intersection(vertical, horizontal) ≈ Point(0.0, 0.0)
        @test !dointersect(vertical, Segment(Point(2.0, -1.0), Point(3.0, 1.0)))
    end

    @testset "parallel segments" begin
        a = Segment(Point(0, 0), Point(1, 1))
        b = Segment(Point(0, 1), Point(1, 2))
        @test_throws "parallel" intersection(a, b)
        @test !dointersect(a, b)

        # Collinear and overlapping still counts as parallel.
        c = Segment(Point(0.5, 0.5), Point(2.0, 2.0))
        @test !dointersect(a, c)

        # Parallelism is judged by angle, so it holds at any scale.
        tiny = Segment(Point(0.0, 0.0), Point(1.0e-9, 1.0e-9))
        @test !dointersect(tiny, Segment(Point(0.0, 1.0e-9), Point(1.0e-9, 2.0e-9)))
    end

    @testset "construction" begin
        @test Segment(Point(0, 0), Point(1.0, 1.0)) isa Segment{2, Float64}
        @test Segment(Point(0, 0, 0), Point(1, 1, 1)) isa Segment{3, Int}
        @test_throws "two distinct endpoints" Segment(Point(1, 2), Point(1, 2))
        @test_throws MethodError Segment(Point(0, 0), Point(1, 1, 1))
    end
end
