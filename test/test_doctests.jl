using Documenter

# Doctests are checked on a single Julia version: printed output, and error messages in
# particular, differ between releases and would fail spuriously elsewhere.
if VERSION ≥ v"1.11" && VERSION < v"1.13"
    DocMeta.setdocmeta!(
        GridGeometryUtils, :DocTestSetup, :(using GridGeometryUtils); recursive = true
    )
    @testset "Doctests" begin
        doctest(GridGeometryUtils; manual = false)
    end
end
