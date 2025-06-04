@testset begin
    p1 = Point(0, 0)
    p2 = Point(1, 1)

    l = Line(p1,p2)

    @test l isa Line{Float64}
    @test l.slope     == 1
    @test l.intercept == 0

    for i in 0:10
        @test line(l, i) == i
    end
end