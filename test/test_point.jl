using StaticArrays

@testset "Point" begin
    @test Point(1, 2.0f0) isa Point{2, Float32}
    @test Point(1, 2.0e0) isa Point{2, Float64}
    @test Point(1.0f0, 2.0e0) isa Point{2, Float64}

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
end
