@testset "In Rectangle?" begin

    o    = @SVector([0., 0.])
    p    = @SVector([0., 0.])
    rect = Rectangle(o, 2, 4, 0)
    @test inside(p, rect) ≈ true

    # p    = Point(-0.99, 0)
    # rect = Rectangle((0, 0), 2, 4, 0)
    # @test inside(p, rect) ≈ true

    # p    = Point(-1.001, 0)
    # rect = Rectangle((0, 0), 2, 4, 0)
    # @test inside(p, rect) ≈ false

    # p    = Point(0, 1.6)
    # rect = Rectangle((0, 0), 2, 4, 0)
    # @test inside(p, rect) ≈ true

    # p    = Point(0, 2.001)
    # rect = Rectangle((0, 0), 2, 4, 0)
    # @test inside(p, rect) ≈ false

end




