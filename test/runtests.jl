using Test, StaticArrays
using GridGeometryUtils

@testset "GridGeometryUtils" begin
    test_files = sort(filter(startswith("test_"), readdir(@__DIR__)))
    for f in test_files
        include(joinpath(@__DIR__, f))
    end
end
