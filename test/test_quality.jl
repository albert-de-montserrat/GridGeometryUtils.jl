using Aqua, ExplicitImports

@testset "Aqua" begin
    Aqua.test_all(GridGeometryUtils)
end

@testset "ExplicitImports" begin
    @test check_no_implicit_imports(GridGeometryUtils) === nothing
    @test check_all_explicit_imports_via_owners(GridGeometryUtils) === nothing
    @test check_no_stale_explicit_imports(GridGeometryUtils) === nothing
    @test check_all_qualified_accesses_via_owners(GridGeometryUtils) === nothing
end
