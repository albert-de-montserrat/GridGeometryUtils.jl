using StaticArrays
using GridGeometryUtils: isequal_r

@testset "Point" begin
    @test Point(1, 2.0f0) isa Point{2, Float32}
    @test Point(1, 2.0e0) isa Point{2, Float64}
    @test Point(1.0f0, 2.0e0) isa Point{2, Float64}
    @test Point(1, 2.0f0) isa Point{2, Float32}
    @test Point(1, 2.0e0) isa Point{2, Float64}
    @test Point(1.0f0, 2.0e0) isa Point{2, Float64}

    @test Point(1, 2.0f0, 3) isa Point{3, Float32}
    @test Point(1, 2.0f0, 3.0e0) isa Point{3, Float64}
    @test Point(1, 2.0f0, 3) isa Point{3, Float32}
    @test Point(1, 2.0f0, 3.0e0) isa Point{3, Float64}

    p1 = Point(1, 2)

    @test p1 == Point((1, 2))
    @test p1 isa Point{2, Int}
    @test p1.p == SA[1, 2]
    @test length(p1) == 2
    @test p1[1] == 1
    @test p1[2] == 2

    p2 = Point(1, 2, 3)

    @test p2 isa Point{3, Int}
    @test p2 == Point((1, 2, 3))
    @test p2.p == SA[1, 2, 3]
    @test length(p2) == 3
    @test p2[1] == 1
    @test p2[2] == 2
    @test p2[3] == 3

    @test p1 + 1 == Point(2, 3)
    @test p1 - 1 == Point(0, 1)
    @test p1 * 1 == p1
    @test p1 / 1 == Point(1.0e0, 2.0e0)
    @test p1^1 == p1

    @test p2 + 1 == Point(2, 3, 4)
    @test p2 - 1 == Point(0, 1, 2)
    @test p2 * 1 == p2
    @test p2 / 1 == Point(1.0e0, 2.0e0, 3.0e0)
    @test p2^1 == p2

    @test p1 + p1 == Point(2, 4)
    @test p1 - p1 == Point(0, 0)
    @test p1 * p1 == Point(1, 4)
    @test p1 / p1 == Point(1.0e0, 1.0e0)
    @test p1^p1 == Point(1, 4)

    @test p2 + p2 == Point(2, 4, 6)
    @test p2 - p2 == Point(0, 0, 0)
    @test p2 * p2 == Point(1, 4, 9)
    @test p2 / p2 == Point(1.0e0, 1.0e0, 1.0e0)
    @test p2^p2 == Point(1, 4, 27)


    p1 = Point(1.0e0, 2.0e0)
    p2 = Point(2.0e0, 3.0e0)
    p3 = SA[3.0e0, 4.0e0]
    M = SA[
        1.0e0 0.0e0;
        0.0e0 1.0e0
    ]

    @test p1 + p2 == Point(3.0e0, 5.0e0)
    @test p1 + p3 == SA[4.0e0, 6.0e0]
    @test p1 - p2 == Point(-1.0e0, -1.0e0)
    @test p1 - p3 == SA[-2.0e0, -2.0e0]
    @test p1' == SA[1.0e0, 2.0e0]'
    @test M * p1 == SA[
        1.0
        2.0
    ]
    @test p1' * M == SA[
        1.0
        2.0
    ]'

    @test -p1 == Point(-1.0e0, -2.0e0)
end

@testset "Point equality" begin
    # Points holding the same coordinates are equal regardless of how they are stored.
    @test Point(1, 2) == Point(1.0, 2.0)
    @test hash(Point(1, 2)) == hash(Point(1.0, 2.0))
    @test Point(1, 2) != Point(1, 3)
    @test isequal_r(Point(1.0, 2.0), Point(1.0 + eps(), 2.0))
    @test isequal_r(Point(1.0, 2.0, 3.0), Point(1.0, 2.0, 3.0))
end

@testset "Point dimensions must match" begin
    # Mixing dimensions is a bug, not something to silently truncate or pad.
    @test_throws MethodError Point(1, 2) + Point(1, 2, 3)
    @test_throws MethodError Point(1, 2) - Point(1, 2, 3)
    @test_throws MethodError Point(1, 2) * Point(1, 2, 3)
    @test_throws MethodError isequal_r(Point(1, 2), Point(1, 2, 3))
    @test_throws MethodError Point(1, 2) + SA[1, 2, 3]
    @test_throws MethodError distance(Point(1, 2), Point(1, 2, 3))
end

@testset "Point construction" begin
    # Every entry point coerces identically.
    @test Point{2, Float64}(SA[1, 2]) === Point(1.0, 2.0)
    @test Point(SA[1.0, 2.0]) === Point(1.0, 2.0)
    @test Point((1.0, 2.0)) === Point(1.0, 2.0)
    @test Point(Point(1.0, 2.0)) === Point(1.0, 2.0)
    @test Point(1, 2.0f0) isa Point{2, Float32}
    @test GridGeometryUtils.totuple(Point(1.0, 2.0)) === (1.0, 2.0)
end
