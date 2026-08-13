using GridGeometryUtils: isequal_r, neq_r, lt_r, gt_r, leq_r, geq_r, isquasizero, @comp

@testset "Comparisons" begin
    @testset "round-off tolerance" begin
        a = 1.0
        b = 1.0 + eps(a)
        @test isequal_r(a, b)
        @test leq_r(a, b)
        @test geq_r(a, b)
        @test !lt_r(b, a)
        @test !gt_r(b, a)
        @test !neq_r(a, b)

        @test isequal_r(1, 1)
        @test isequal_r(0, 0)
        @test isequal_r(0, 0 + eps())
        @test isequal_r(0 + eps(), 0)
        @test isequal_r(1, 1.0e0)
        @test isequal_r(0, 0.0e0)

        b = 2.0
        @test !isequal_r(a, b)
        @test neq_r(a, b)
        @test leq_r(a, b)
        @test !geq_r(a, b)
        @test lt_r(a, b)
        @test !gt_r(a, b)
    end

    @testset "symmetry" begin
        # A relative difference taken against only one operand is not symmetric; the
        # pairs below straddled the threshold in one direction only.
        @test isequal_r(-7.471812957850326e-4, -7.471812957853784e-4) ==
            isequal_r(-7.471812957853784e-4, -7.471812957850326e-4)

        @test all(1:200_000) do _
            x = exp10(12 * rand() - 12) * (rand(Bool) ? 1 : -1)
            y = x * (1 + (2 * rand() - 1) * 1.0e-12)
            isequal_r(x, y) == isequal_r(y, x)
        end
    end

    @testset "tolerance scales with magnitude" begin
        # Absolute tolerances would call these equal at every magnitude, or none.
        @test isequal_r(1.0e10, 1.0e10 + 1.0e-3)
        @test !isequal_r(1.0e-10, 1.0e-10 + 1.0e-3)
        @test isequal_r(1.0e-20, 2.0e-20)   # both within eps of zero
        @test isquasizero(1.0e-20)
        @test !isquasizero(1.0e-10)
        @test isquasizero(0)
        @test !isquasizero(1)
    end

    @testset "unsupported types fail loudly" begin
        @test_throws "needs `eps(" isequal_r(1 // 2, 1 // 3)
    end

    @testset "@comp rewrites every comparison" begin
        x = 0.1 + 0.2
        @test x != 0.3            # exact comparison disagrees ...
        @test @comp x == 0.3      # ... but the tolerant one does not
        @test @comp x ≤ 0.3
        @test @comp x <= 0.3      # ASCII and Unicode forms alike
        @test @comp x ≥ 0.3
        @test @comp x >= 0.3
        @test !(@comp x < 0.3)
        @test !(@comp x > 0.3)
        @test !(@comp x != 0.3)
        @test !(@comp x ≠ 0.3)
        @test @comp 0.0 ≤ x ≤ 0.3 # chained comparisons
        @test !(@comp x === 0.3)  # identity is left alone
    end
end
