using Documenter
using GridGeometryUtils

DocMeta.setdocmeta!(
    GridGeometryUtils, :DocTestSetup, :(using GridGeometryUtils); recursive = true
)

makedocs(
    sitename = "GridGeometryUtils.jl",
    modules = [GridGeometryUtils],
    authors = "Albert de Montserrat and contributors",
    format = Documenter.HTML(
        canonical = "https://albert-de-montserrat.github.io/GridGeometryUtils.jl",
        prettyurls = get(ENV, "CI", "false") == "true",
    ),
    pages = [
        "Home" => "index.md",
        "Shapes" => "shapes.md",
        "Predicates and measures" => "measures.md",
        "Intersections" => "intersections.md",
        "Tolerant comparisons" => "comparisons.md",
        "API reference" => "api.md",
    ],
    # Doctests run as part of the test suite, so `Pkg.test()` alone catches doc rot; running
    # them here as well would only repeat that work on every docs build.
    doctest = false,
    checkdocs = :exported,
)

deploydocs(
    repo = "github.com/albert-de-montserrat/GridGeometryUtils.jl",
    devbranch = "main",
    push_preview = true,
)
