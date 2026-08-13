@testset "Ellipse" begin
    center = 0.0e0, 0.0e0
    a, b = 1.0e0, 2.0e0

    ellipse = Ellipse(center, a, b)

    @test ellipse.center == Point(center)
    @test ellipse.a == a
    @test ellipse.b == b
    @test area(ellipse) == π * a * b
    @test perimeter(ellipse) == π * (3 * (a + b) - √((3 * a + b) * (a + 3 * b)))
    # Ramanujan's approximation is exact for a circle.
    @test perimeter(Ellipse(center, 1.0, 1.0)) ≈ 2π

    # Semi-axes lie along x and y; the bounding box is snug against them.
    @test ellipse.box.origin == Point(-a, -b)
    @test ellipse.box.l == 2a
    @test ellipse.box.h == 2b

    # A quarter turn swaps the extents of the bounding box.
    rotated = Ellipse(center, a, b; θ = π / 2)
    @test rotated.box.l ≈ 2b
    @test rotated.box.h ≈ 2a
    @test area(rotated) == area(ellipse)

    @test Ellipse(Point(0.0, 0.0), a, b) == ellipse
    @test Ellipse(SA[0.0, 0.0], a, b) == ellipse
end

@testset "Circle" begin
    center = 0.0, 0.0
    r = 2.0

    circle = Circle(center, r)

    @test circle.center == Point(center)
    @test circle.radius == r
    @test area(circle) == π * r^2
    @test perimeter(circle) == 2π * r
    @test circle.box.origin == Point(-r, -r)
    @test circle.box.l == 2r
    @test circle.box.h == 2r
    @test iszero(circle.box.d)

    @test Circle(Point(0.0, 0.0), r) == circle
    @test Circle(SA[0.0, 0.0], r) == circle
    @test Circle((0, 0), 2) isa Circle{Int}
end

@testset "Sphere" begin
    center = (0.0, 0.0, 0.0)
    r = 2.0

    sphere = Sphere(center, r)

    @test sphere.center == Point(center)
    @test sphere.radius == r
    @test volume(sphere) == (4 / 3) * π * r^3
    @test area(sphere) == 4 * π * r^2
    @test sphere.box.origin == Point(-r, -r, -r)
    @test sphere.box.l == sphere.box.h == sphere.box.d == 2r

    @test Sphere(Point(0.0, 0.0, 0.0), r) == sphere
    @test Sphere(SA[0.0, 0.0, 0.0], r) == sphere
end
