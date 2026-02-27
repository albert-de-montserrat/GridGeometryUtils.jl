@testset "intersection(Line, Rectangle)" begin
    # Rectangle centered at origin, 2×2 (vertices at (±1, ±1))
    r = Rectangle((0.0, 0.0), 2.0, 2.0)

    # ── 1. Horizontal line through the center ─────────────────────────────────
    # y = 0  →  should hit the left (x=-1) and right (x=1) sides
    l = Line(0.0, 0.0)
    pts = intersection(l, r)
    @test length(pts) == 2
    @test Point(-1.0, 0.0) ∈ pts
    @test Point(1.0, 0.0) ∈ pts

    # ── 2. Line that misses the rectangle entirely ────────────────────────────
    # y = 5  →  well above the top edge (y = 1)
    l_miss = Line(0.0, 5.0)
    @test isempty(intersection(l_miss, r))

    # ── 3. Diagonal through opposite corners ─────────────────────────────────
    # y = x  →  passes through (-1,-1) and (1,1); tests corner deduplication
    l_diag = Line(1.0, 0.0)
    pts_diag = intersection(l_diag, r)
    @test length(pts_diag) == 2
    @test Point(-1.0, -1.0) ∈ pts_diag
    @test Point(1.0, 1.0) ∈ pts_diag

    # ── 4. Line crossing top and bottom edges ────────────────────────────────
    # y = 4x  →  steep line; hits bottom (y=-1 at x=-0.25) and top (y=1 at x=0.25)
    l_steep = Line(4.0, 0.0)
    pts_steep = intersection(l_steep, r)
    @test length(pts_steep) == 2
    @test Point(-0.25, -1.0) ∈ pts_steep
    @test Point(0.25, 1.0) ∈ pts_steep

    # ── 5. Rotated rectangle (45°) ────────────────────────────────────────────
    # After a 45° rotation the 2×2 rectangle becomes a diamond with
    # vertices at (0,±√2) and (±√2,0); the horizontal line y=0 should
    # hit exactly the left and right tips.
    r_rot = Rectangle((0.0, 0.0), 2.0, 2.0; θ = π / 4)
    l_horiz = Line(0.0, 0.0)
    pts_rot = intersection(l_horiz, r_rot)
    @test length(pts_rot) == 2
    s2 = sqrt(2.0)
    @test any(p -> p[1] ≈ -s2 && p[2] ≈ 0.0, pts_rot)
    @test any(p -> p[1] ≈ s2 && p[2] ≈ 0.0, pts_rot)
end
