@testset "Comparisons" begin
    a = 1.0
    b = 1.0 + eps(a)
    @test  GridGeometryUtils.isequal_r(a, b)
    @test  GridGeometryUtils.leq_r(a, b)
    @test  GridGeometryUtils.geq_r(a, b)
    @test !GridGeometryUtils.le_r(b, a)
    @test !GridGeometryUtils.ge_r(b, a)

    @test GridGeometryUtils.isequal_r(1, 1)
    @test GridGeometryUtils.isequal_r(0, 0)
    @test GridGeometryUtils.isequal_r(0, 0 + eps())
    @test GridGeometryUtils.isequal_r(0 + eps(), 0)
    @test GridGeometryUtils.isequal_r(1, 1.0e0)
    @test GridGeometryUtils.isequal_r(0, 0.0e0)

    b = 2.0
    @test !GridGeometryUtils.isequal_r(a, b) # false
    @test  GridGeometryUtils.leq_r(a, b) # true
    @test !GridGeometryUtils.geq_r(a, b) # false
end
