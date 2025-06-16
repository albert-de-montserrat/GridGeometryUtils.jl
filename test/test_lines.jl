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
end

@testset "Segment" begin
    s1 = Segment(Point(0, 0), Point(1, 1))
    s2 = Segment(Point(0, 1), Point(1, 0))
    s3 = Segment(Point(3, 1), Point(4, 0))

    @test intersection(s1, s2) == Point((0.5, 0.5))
    @test intersection(s1, s3) == Point((2.0, 2.0))

    @test dointersect(s1, s2)
    @test !(dointersect(s1, s3))
end