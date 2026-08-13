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

@testset "documentation of exported names" begin
    exported = filter(!=(:GridGeometryUtils), names(GridGeometryUtils))

    docstring(s) = string(Base.Docs.doc(Base.Docs.Binding(GridGeometryUtils, s)))
    isdocumented(s) = !occursin("No documentation found", docstring(s))
    hasexample(s) = occursin("jldoctest", docstring(s))

    @test !isempty(exported)
    # Every name the package exports carries a docstring, and that docstring shows a
    # runnable example, which `test_doctests.jl` then checks against real output.
    @test filter(!isdocumented, exported) == Symbol[]
    @test filter(!hasexample, exported) == Symbol[]
end
