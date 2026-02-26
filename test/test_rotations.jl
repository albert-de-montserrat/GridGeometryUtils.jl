using LinearAlgebra: det

const _rm = GridGeometryUtils.rotation_matrix
approx_pt(a::Point, b::Point; kw...) = isapprox(a.p, b.p; kw...)

@testset "rotation_matrix" begin
    # θ = 0 → identity
    R0 = _rm(0.0)
    @test R0 ≈ [1.0 0.0; 0.0 1.0]

    # θ = π/2 → clockwise 90°: [0 1; -1 0]
    R90 = _rm(π / 2)
    @test R90 ≈ [0.0 1.0; -1.0 0.0]

    # θ = π → 180°
    R180 = _rm(π)
    @test R180 ≈ [-1.0 0.0; 0.0 -1.0] atol=1e-15

    # det = 1 (orthogonal matrix) and R * Rᵀ = I for arbitrary θ
    for θ in (π/6, π/4, π/3, π/2, π, 4π/3)
        R = _rm(θ)
        @test det(R) ≈ 1.0 atol=1e-14
        @test R * R' ≈ [1.0 0.0; 0.0 1.0] atol=1e-14
    end
end

@testset "rotate – single Point" begin
    origin = Point(0.0, 0.0)

    # θ = 0 → no change
    p = Point(1.0, 2.0)
    @test approx_pt(rotate(p, origin, 0.0), p)

    # Full rotation → back to original
    @test approx_pt(rotate(p, origin, 2π), p)

    # (1,0) rotated 90° clockwise around origin → (0,-1)
    @test approx_pt(rotate(Point(1.0, 0.0), origin, π / 2), Point(0.0, -1.0); atol=1e-14)

    # (1,0) rotated 180° → (-1, 0)
    @test approx_pt(rotate(Point(1.0, 0.0), origin, π), Point(-1.0, 0.0); atol=1e-14)

    # (0,1) rotated 90° clockwise → (1, 0)
    @test approx_pt(rotate(Point(0.0, 1.0), origin, π / 2), Point(1.0, 0.0); atol=1e-14)

    # Non-origin center: rotate (2,1) by 90° around (1,1)
    # shift: (1,0), rotate: (0,-1), shift back: (1,0)
    @test approx_pt(rotate(Point(2.0, 1.0), Point(1.0, 1.0), π / 2), Point(1.0, 0.0); atol=1e-14)
end

@testset "rotate – tuple of Points" begin
    origin = Point(0.0, 0.0)
    p1, p2 = Point(1.0, 0.0), Point(0.0, 1.0)

    pts_rot = rotate((p1, p2), origin, π / 2)
    @test approx_pt(pts_rot[1], Point( 0.0, -1.0); atol=1e-14)
    @test approx_pt(pts_rot[2], Point( 1.0,  0.0); atol=1e-14)

    # θ = 0 → unchanged
    pts_id = rotate((p1, p2), origin, 0.0)
    @test approx_pt(pts_id[1], p1)
    @test approx_pt(pts_id[2], p2)
end

@testset "rotate – Segment" begin
    origin = Point(0.0, 0.0)
    s = Segment(Point(1.0, 0.0), Point(0.0, 1.0))

    # θ = 0 → segment unchanged
    s0 = rotate(s, origin, 0.0)
    @test approx_pt(s0.p1, s.p1)
    @test approx_pt(s0.p2, s.p2)

    # 90° clockwise: (1,0)→(0,-1), (0,1)→(1,0)
    s90 = rotate(s, origin, π / 2)
    @test approx_pt(s90.p1, Point( 0.0, -1.0); atol=1e-14)
    @test approx_pt(s90.p2, Point( 1.0,  0.0); atol=1e-14)

    # Two successive 90° rotations = 180°
    s180a = rotate(rotate(s, origin, π / 2), origin, π / 2)
    s180b = rotate(s, origin, π)
    @test approx_pt(s180a.p1, s180b.p1; atol=1e-14)
    @test approx_pt(s180a.p2, s180b.p2; atol=1e-14)
end

@testset "rotate – Triangle" begin
    origin = Point(0.0, 0.0)

    # Right triangle with legs along the axes
    p1 = Point(0.0, 0.0)
    p2 = Point(1.0, 0.0)
    p3 = Point(0.0, 1.0)
    t  = Triangle(p1, p2, p3)

    # θ = 0 → vertices unchanged
    t0 = rotate(t, origin, 0.0)
    @test approx_pt(t0.p1, p1)
    @test approx_pt(t0.p2, p2)
    @test approx_pt(t0.p3, p3)

    # Full rotation (2π) → back to original
    t2π = rotate(t, origin, 2π)
    @test approx_pt(t2π.p1, p1; atol=1e-14)
    @test approx_pt(t2π.p2, p2; atol=1e-14)
    @test approx_pt(t2π.p3, p3; atol=1e-14)

    # 90° clockwise: (1,0) → (0,-1) and (0,1) → (1,0)
    t90 = rotate(t, origin, π / 2)
    @test approx_pt(t90.p1, Point( 0.0,  0.0); atol=1e-14)  # origin stays
    @test approx_pt(t90.p2, Point( 0.0, -1.0); atol=1e-14)
    @test approx_pt(t90.p3, Point( 1.0,  0.0); atol=1e-14)

    # 180°: (1,0) → (-1,0), (0,1) → (0,-1)
    t180 = rotate(t, origin, π)
    @test approx_pt(t180.p1, Point( 0.0,  0.0); atol=1e-14)
    @test approx_pt(t180.p2, Point(-1.0,  0.0); atol=1e-14)
    @test approx_pt(t180.p3, Point( 0.0, -1.0); atol=1e-14)

    # Two successive 90° rotations = one 180° rotation
    t180a = rotate(rotate(t, origin, π / 2), origin, π / 2)
    t180b = rotate(t, origin, π)
    @test approx_pt(t180a.p1, t180b.p1; atol=1e-14)
    @test approx_pt(t180a.p2, t180b.p2; atol=1e-14)
    @test approx_pt(t180a.p3, t180b.p3; atol=1e-14)

    # Rotation around non-origin center: rotate triangle by 90° CW around (1,1)
    # p1=(1,0): shift=( 0,-1) → R·[0,-1]=[-1, 0] → +center=(0,1)
    # p2=(2,1): shift=( 1, 0) → R·[1, 0]=[ 0,-1] → +center=(1,0)
    # p3=(1,1)=center → stays in place
    center = Point(1.0, 1.0)
    t_nc = rotate(Triangle(Point(1.0, 0.0), Point(2.0, 1.0), Point(1.0, 1.0)), center, π / 2)
    @test approx_pt(t_nc.p1, Point(0.0, 1.0); atol=1e-14)
    @test approx_pt(t_nc.p2, Point(1.0, 0.0); atol=1e-14)
    @test approx_pt(t_nc.p3, center;           atol=1e-14)  # center maps to itself
end

