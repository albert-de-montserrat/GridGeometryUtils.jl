using Test
using GridGeometryUtils

function main()
    test_files = filter(x -> contains(x, "test_"), readdir("."))

    for f in test_files
        include(f)
    end
end

main()