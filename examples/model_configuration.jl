using GridGeometryUtils, Plots, StaticArrays

function main()
    show_bounding_box = true

    x = (min = -1.5, max = 1.5)
    y = (min = -1, max = 2.0)
    nc = (x = 2000, y = 2000)
    Δ = (x = (x.max - x.min) / nc.x, y = (y.max - y.min) / nc.y)
    xc = LinRange(x.min + Δ.x / 2, x.max - Δ.x / 2, nc.x)
    yc = LinRange(y.min + Δ.y / 2, y.max - Δ.y / 2, nc.y)
    phase = ones(Int64, nc...)

    rects = (
        Rectangle((0, 0), 0.1, 0.4; θ = 0),
        Rectangle((1.0, 0.6), 0.1, 0.4; θ = π / 3),
        Rectangle((-1.0, -0.3), 0.6, 0.4; θ = π / 6),
        Rectangle((-0.8, 0.3), 0.2, 0.2; θ = π / 10),
    )
    hexs = (
        Hexagon((0.8, -0.3), 0.2; θ = π / 10),
        Hexagon((0.1, 0.5), 0.2; θ = 6π / 10),
    )

    ells = (
        Ellipse((-1.1, 0.7), 0.2, 0.1; θ = 1 * π / 4),
        Ellipse((-0.4, -0.7), 0.2, 0.1; θ = 3 * π / 4),
    )

    lays = (
        Layering((-1.1, 0.7), 0.2, 0.1, 0.1; θ = 1 * π / 4),
        Layering((-0.0, 0.7), 0.14, 0.2, 0.5; θ = 0.0, perturb_amp = 0.1, perturb_width = 1.5),
    )

    @time for I in CartesianIndices(phase)

        𝐱 = @SVector([xc[I[1]], yc[I[2]]])

        if show_bounding_box
            # check if inside bounding box
            for igeom in eachindex(rects)
                if inside(𝐱, rects[igeom].box)
                    phase[I] = 3
                end
            end
            for igeom in eachindex(hexs)
                if inside(𝐱, hexs[igeom].box)
                    phase[I] = 3
                end
            end
            for igeom in eachindex(ells)
                if inside(𝐱, ells[igeom].box)
                    phase[I] = 3
                end
            end
        end

        # Check if inside geometry
        for igeom in eachindex(rects)
            if inside(𝐱, rects[igeom])
                phase[I] = 2
            end
        end
        for igeom in eachindex(hexs)
            if inside(𝐱, hexs[igeom])
                phase[I] = 2
            end
        end
        for igeom in eachindex(ells)
            if inside(𝐱, ells[igeom])
                phase[I] = 2
            end
        end
        if 1.0 < 𝐱[2] < 1.5
            for igeom in eachindex(lays)
                if inside(𝐱, lays[1])
                    phase[I] = 2
                end
            end
        end
        if 𝐱[2] > 1.5
            for igeom in eachindex(lays)
                if inside(𝐱, lays[2])
                    phase[I] = 2
                end
            end
        end
    end

    # Visualise
    p = plot()
    p = heatmap!(xc, yc, phase', aspect_ratio = 1)
    for igeom in eachindex(rects)
        p = scatter!(rects[igeom].vertices[1, :], rects[igeom].vertices[2, :], label = :none)
    end
    for igeom in eachindex(hexs)
        p = scatter!(hexs[igeom].vertices[1, :], hexs[igeom].vertices[2, :], label = :none)
    end
    for igeom in eachindex(ells)
        p = scatter!(ells[igeom].vertices[1, :], ells[igeom].vertices[2, :], label = :none)
    end

    return display(p)

end

main()
