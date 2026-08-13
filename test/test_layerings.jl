@testset "Layerings" begin
    @testset "construction" begin
        lay = Layering((0, 0), 0.1, 0.5)

        @test lay.center == Point(0.0, 0.0)
        @test lay.thickness == 0.1
        @test lay.ratio == 0.5
        @test iszero(lay.sinθ)
        @test isone(lay.cosθ)
        @test iszero(lay.perturb_amp)
        @test lay.perturb_width == 1.0

        @test Layering(Point(0.0, 0.0), 0.1, 0.5) == lay
        @test Layering(SA[0.0, 0.0], 0.1, 0.5) == lay
        @test Layering((0, 0), 0.1, 0.5; θ = π / 4) isa Layering{Float64}
        @test Layering((0, 0), 0.1, 0.5; perturb_amp = 0.2, perturb_width = 0.5) isa Layering{Float64}
    end

    @testset "invalid parameters" begin
        @test_throws "thickness must be positive" Layering((0.0, 0.0), 0.0, 0.5)
        @test_throws "thickness must be positive" Layering((0.0, 0.0), -1.0, 0.5)
        @test_throws "ratio must lie in [0, 1]" Layering((0.0, 0.0), 1.0, 2.0)
        @test_throws "ratio must lie in [0, 1]" Layering((0.0, 0.0), 1.0, -0.5)
        @test_throws "width must be positive" Layering((0.0, 0.0), 1.0, 0.5; perturb_width = 0.0)
    end

    @testset "alternating layers" begin
        lay = Layering((0.0, 0.0), 1.0, 0.5)

        # Layer A occupies the lower half of each period, layer B the upper half.
        @test inside(Point(0.0, 0.25), lay)
        @test !inside(Point(0.0, 0.75), lay)
        # ... repeating with period `thickness`, upwards and downwards alike.
        @test inside(Point(0.0, 3.25), lay)
        @test !inside(Point(0.0, 3.75), lay)
        @test inside(Point(0.0, -2.75), lay)
        @test !inside(Point(0.0, -2.25), lay)

        # Layers are infinite in x when unrotated.
        @test inside(Point(100.0, 0.25), lay)
        @test inside(SA[-100.0, 0.25], lay)

        # A thin layer A shrinks the fraction of space it occupies.
        thin = Layering((0.0, 0.0), 1.0, 0.1)
        @test inside(Point(0.0, 0.05), thin)
        @test !inside(Point(0.0, 0.5), thin)
    end

    @testset "rotation" begin
        # A quarter turn makes the layering vary along x instead of y.
        lay = Layering((0.0, 0.0), 1.0, 0.5; θ = π / 2)
        @test inside(Point(0.0, 100.0), lay) == inside(Point(0.0, 0.0), lay)
        @test inside(Point(0.25, 0.0), lay) != inside(Point(0.75, 0.0), lay)
    end

    @testset "perturbation" begin
        # The Gaussian bump displaces the interfaces near the center only.
        lay = Layering((0.0, 0.0), 1.0, 0.5; perturb_amp = 0.4, perturb_width = 1.0)
        @test inside(Point(0.0, 0.6), lay)                 # lifted into layer A
        @test !inside(Point(50.0, 0.6), lay)               # far away, unperturbed
        @test inside(Point(50.0, 0.25), lay)
    end
end
