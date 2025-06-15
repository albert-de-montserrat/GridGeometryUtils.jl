@testset "Layerings" begin
    center = (0, 0)

    l = Layering(center, 0.1, 0.5, 0.1)

    @test l.thickness == 0.1
    @test l.ratio == 0.5
    @test l.period == 0.1

  
end