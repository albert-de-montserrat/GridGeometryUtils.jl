@testset "In Rectangle?" begin

    o2   = @SVector([0., 0.])

    p    = @SVector([0., 0.])
    rect = Rectangle(o2, 2, 4; θ=0)
    @test inside(p, rect) ≈ true

    p    = @SVector([-0.99, 0.])
    rect = Rectangle(o2, 2, 4; θ=0)
    @test inside(p, rect) ≈ true

    p    = @SVector([-1.001, 0.])
    rect = Rectangle(o2, 2, 4; θ=0)
    @test inside(p, rect) ≈ false

    p    = @SVector([0, 1.6])
    rect = Rectangle(o2, 2, 4; θ=0)
    @test inside(p, rect) ≈ true

    p    = @SVector([0, 2.001])
    rect = Rectangle(o2, 2, 4; θ=0)
    @test inside(p, rect) ≈ false

end




