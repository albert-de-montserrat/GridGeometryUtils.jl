@testset "In BBox?    " begin

    o2 = @SVector([0.0, 0.0])

    p = @SVector([0.0, 0.0])
    box = BBox(o2, 2, 4)
    @test inside(p, box)
end

@testset "In Hexagon? " begin

    o2 = @SVector([0.0, 0.0])

    p = @SVector([0.0, 0.0])
    hex = Hexagon(o2, 2; θ = 10)
    @test inside(p, hex) === true

    p = @SVector([-14, 0.0])
    hex = Hexagon(o2, 2; θ = 10)
    @test inside(p, hex) === false
end

@testset "In Rectangle?" begin

    o2 = @SVector([0.0, 0.0])

    p = @SVector([0.0, 0.0])
    rect = Rectangle(o2, 2, 4; θ = 0)
    @test inside(p, rect)

    p = @SVector([-0.99, 0.0])
    rect = Rectangle(o2, 2, 4; θ = 0)
    @test inside(p, rect)

    p = @SVector([-1.001, 0.0])
    rect = Rectangle(o2, 2, 4; θ = 0)
    @test !inside(p, rect)

    p = @SVector([0, 1.6])
    rect = Rectangle(o2, 2, 4; θ = 0)
    @test inside(p, rect)

    p = @SVector([0, 2.001])
    rect = Rectangle(o2, 2, 4; θ = 0)
    @test !inside(p, rect)

end

@testset "In Ellipse?" begin

    center = 0.0e0, 0.0e0
    a, b = 1.0e0, 2.0e0

    ellipse1 = Ellipse(center, a, b)

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

@testset "In circle?" begin
    center = 0.0e0, 0.0e0
    r = 1.0e0

    circle = Circle(center, r)

    p1 = Point(0.0e0, 0.0e0)
    p2 = Point(2.0e0, 0.0e0)
    p3 = Point(0.5, 0.5)

    @test  inside(p1, circle) # true
    @test !inside(p2, circle) # false
    @test  inside(p3, circle) # true
end

# @b inside($p, $hex)
# @edit inside(p, hex)