using Documenter

# Doctests are checked on Julia 1.11–1.13: printed output, and error messages in
# particular, can differ between releases.
#
# Both the docstrings and the manual pages are checked here rather than during the docs
# build, so `Pkg.test()` on its own catches an example that has drifted from what the code
# actually prints.
if VERSION ≥ v"1.11" && VERSION < v"1.14"
    DocMeta.setdocmeta!(
        GridGeometryUtils, :DocTestSetup, :(using GridGeometryUtils); recursive = true
    )
    @testset "Doctests" begin
        doctest(GridGeometryUtils; manual = joinpath(@__DIR__, "..", "docs", "src"))
    end
end
