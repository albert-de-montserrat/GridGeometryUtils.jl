using Test

@testset "Triangle" begin
    p1 = Point(1,2)
    p2 = Point(1,3)
    p3 = Point(2,2)

    @test_throws AssertionError Triangle(p1, p1, p1)

    t = Triangle(p1, p2, p3)
    @test t.p1 == p1
    @test t.p2 == p2
    @test t.p3 == p3

    t = Triangle(p1.p, p2.p, p3.p)
    @test t.p1 == p1
    @test t.p2 == p2
    @test t.p3 == p3

    @test area(t) ≈ 0.5
    @test perimeter(t) == 3.414213562373095
end

@testset "Rectangle" begin
    origin = (0, 0)
    rect   = Rectangle(origin, 2, 4)
    
    @test rect.origin     == origin
    @test rect.h          == 2
    @test rect.l          == 4
    @test area(rect)      == 8
    @test perimeter(rect) == 12
end

@testset "Prism" begin
    origin = (0, 0)
    rect   = Rectangle(origin, 2, 4)
    
    @test rect.origin     == origin
    @test rect.h          == 2
    @test rect.l          == 4
    @test area(rect)      == 8
    @test perimeter(rect) == 12
end

@testset "Trapezoid" begin
    origin = (0, 0)
    trap   = Trapezoid(origin, 2, 3, 4)

    @test trap.origin     == origin
    @test trap.l          == 2
    @test trap.h1         == 3
    @test trap.h2         == 4
    @test area(trap)      == 7.0
    @test perimeter(trap) == 11.23606797749979
end