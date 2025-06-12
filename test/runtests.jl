using Test, StaticArrays
using GridGeometryUtils

function main()
    test_files = filter(x -> contains(x, "test_"), readdir("."))

    for f in test_files
        include(f)
    end
    return
end

main()
