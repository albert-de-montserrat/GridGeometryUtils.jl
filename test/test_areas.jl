# Measures cross-checked against `inside` by sampling: any disagreement between a closed
# form and the containment predicate shows up here, whichever of the two is wrong.
function mc_area(obj, box; n = 200_000)
    (; origin, l, h) = box
    ox, oy = origin[1], origin[2]
    hits = count(_ -> inside(SA[ox + l * rand(), oy + h * rand()], obj), 1:n)
    return hits / n * l * h
end

function mc_volume(obj, box; n = 200_000)
    (; origin, l, h, d) = box
    ox, oy, oz = origin[1], origin[2], origin[3]
    hits = count(_ -> inside(SA[ox + l * rand(), oy + h * rand(), oz + d * rand()], obj), 1:n)
    return hits / n * l * h * d
end

@testset "measures agree with `inside`" begin
    @testset "2D" begin
        shapes = (
            Rectangle((0.3, -0.2), 2.0, 4.0),
            Rectangle((0.3, -0.2), 2.0, 4.0; θ = π / 7),
            Hexagon((-1.0, 1.0), 2.0),
            Hexagon((-1.0, 1.0), 2.0; θ = 0.4),
            Circle((1.0, 2.0), 1.5),
            Ellipse((1.0, 2.0), 1.5, 0.5),
            Ellipse((1.0, 2.0), 1.5, 0.5; θ = 0.9),
        )
        for shape in shapes
            @test area(shape) ≈ mc_area(shape, shape.box) rtol = 0.02
        end

        t = Triangle((0.0, 0.0), (3.0, 0.5), (1.0, 2.0))
        @test area(t) ≈ mc_area(t, BBox((0.0, 0.0), 3.0, 2.0)) rtol = 0.02
    end

    @testset "3D" begin
        sphere = Sphere((0.0, 1.0, -1.0), 1.2)
        @test volume(sphere) ≈ mc_volume(sphere, sphere.box) rtol = 0.02

        prism = Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0)
        @test volume(prism) ≈ mc_volume(prism, BBox((0.0, 0.0, 0.0), 2.0, 4.0, 3.0)) rtol = 0.02
    end
end

@testset "measures are scale-consistent" begin
    # Area scales as the square of a length, volume as its cube, perimeter linearly.
    for k in (0.5, 2.0, 10.0)
        @test area(Circle((0.0, 0.0), k * 1.5)) ≈ k^2 * area(Circle((0.0, 0.0), 1.5))
        @test perimeter(Circle((0.0, 0.0), k * 1.5)) ≈ k * perimeter(Circle((0.0, 0.0), 1.5))
        @test area(Hexagon((0.0, 0.0), k * 2.0)) ≈ k^2 * area(Hexagon((0.0, 0.0), 2.0))
        @test perimeter(Hexagon((0.0, 0.0), k * 2.0)) ≈ k * perimeter(Hexagon((0.0, 0.0), 2.0))
        @test volume(Sphere((0.0, 0.0, 0.0), k * 1.2)) ≈ k^3 * volume(Sphere((0.0, 0.0, 0.0), 1.2))
        @test area(Sphere((0.0, 0.0, 0.0), k * 1.2)) ≈ k^2 * area(Sphere((0.0, 0.0, 0.0), 1.2))
        @test area(Prism((0.0, 0.0, 0.0), k * 2, k * 4, k * 3)) ≈ k^2 * area(Prism((0.0, 0.0, 0.0), 2, 4, 3))
        @test volume(Prism((0.0, 0.0, 0.0), k * 2, k * 4, k * 3)) ≈ k^3 * volume(Prism((0.0, 0.0, 0.0), 2, 4, 3))
    end
end

@testset "measures are dimensionally sane" begin
    # A shape's perimeter and area are not interchangeable: for a regular hexagon of
    # circumradius 2 the area is 10.39 and the perimeter 12, and they were once swapped.
    hex = Hexagon((0.0, 0.0), 2.0)
    @test area(hex) ≈ 3 * √3 / 2 * 2.0^2
    @test perimeter(hex) ≈ 6 * 2.0

    # A prism's `area` is its surface area, not the sum of its edge lengths.
    prism = Prism((0.0, 0.0, 0.0), 2.0, 4.0, 3.0)
    @test area(prism) ≈ 2 * (2 * 4 + 2 * 3 + 4 * 3)
    @test area(prism) == area(BBox((0.0, 0.0, 0.0), 2.0, 4.0, 3.0))

    # A bounding box and the shape it bounds agree only when the shape fills it.
    rect = Rectangle((0.0, 0.0), 2.0, 4.0)
    @test area(rect) == area(rect.box)
    @test area(Circle((0.0, 0.0), 1.0)) < area(Circle((0.0, 0.0), 1.0).box)
end
