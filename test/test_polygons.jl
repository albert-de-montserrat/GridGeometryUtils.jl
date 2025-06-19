@testset "Triangle" begin
    p1 = Point(1, 2)
    p2 = Point(1, 3)
    p3 = Point(2, 2)

    @test_throws AssertionError Triangle(p1, p1, p1)

    t = Triangle(p1, p2, p3)
    @test t.p1 == p1
    @test t.p2 == p2
    @test t.p3 == p3

    t = Triangle(p1, p2, p3)
    @test t.p1 == p1
    @test t.p2 == p2
    @test t.p3 == p3

    @test area(t) ≈ 0.5
    @test perimeter(t) == 3.414213562373095
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
    end
end

@testset "Rectangle" begin
    origin = (0, 0)
    rect = Rectangle(origin, 2, 4; θ = π / 3)
    rect = Rectangle(origin, 2, 4; θ = π / 3)

    @test rect.origin == Point(Float64.(origin))
    @test rect.l == 2
    @test rect.h == 4
    @test area(rect) == 8
    @test rect.origin == Point(Float64.(origin))
    @test rect.l == 2
    @test rect.h == 4
    @test area(rect) == 8
    @test perimeter(rect) == 12
end

@testset "Hexagon" begin
    origin = (-1, 1)
    hex = Hexagon(origin, 2; θ = π / 3)

    @test hex.origin == Point(Float64.(origin))
    @test hex.radius == 2
    @test area(hex) == 12.0
    @test perimeter(hex) == 10.392304845413264
end

@testset "Prism" begin
    origin = (0, 0)
    rect = Rectangle(origin, 2, 4)

    @test rect.origin == Point(Float64.(origin))
    @test rect.h == 4
    @test rect.l == 2
    @test area(rect) == 8
    @test perimeter(rect) == 12
end

@testset "Trapezoid" begin
    origin = (0, 0)
    trap = Trapezoid(origin, 2, 3, 4)

    @test trap.origin == Point(origin)
    @test trap.l == 2
    @test trap.h1 == 3
    @test trap.h2 == 4
    @test area(trap) == 7.0
    @test perimeter(trap) == 11.23606797749979
end

@testset "Ellipsoids" begin

    center = 0.0e0, 0.0e0
    a, b = 1.0e0, 2.0e0

    ellipse1 = Ellipse(center, a, b)

    @test area(ellipse1) == π * a * b
    @test perimeter(ellipse1) == π * (3 * (a + b) - √((3 * a + b) * (a + 3 * b)))

    p1 = Point(0.0e0, 0.0e0)
    p2 = Point(2.0e0, 0.0e0)
    p3 = Point(1.0e0, 0.0e0)
    p4 = Point(0.0e0, 2.0e0)

    @test  inside(p1, ellipse1) # true
    @test !inside(p2, ellipse1) # false
    @test  inside(p3, ellipse1) # true
    @test  inside(p4, ellipse1) # true

    ellipse2 = Ellipse(center, a, b; θ = π / 2)

    @test  inside(p1, ellipse2) # true
    @test  inside(p2, ellipse2) # true
    @test  inside(p3, ellipse2) # true
    @test !inside(p4, ellipse2) # false
end
