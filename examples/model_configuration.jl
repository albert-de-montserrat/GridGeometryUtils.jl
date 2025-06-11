using GridGeometryUtils, Plots, StaticArrays

let
    x = (min = -1.5, max = 1.5)
    y = (min = -1, max = 1)
    nc = (x = 1000, y = 1000)
    Δ = (x = (x.max - x.min) / nc.x, y = (y.max - y.min) / nc.y)
    xc = LinRange(x.min + Δ.x / 2, x.max - Δ.x / 2, nc.x)
    yc = LinRange(y.min + Δ.y / 2, y.max - Δ.y / 2, nc.y)
    phase = ones(Int64, nc...)

    geometries = (
        Rectangle((0, 0), 0.1, 0.4; θ = 0),
        Rectangle((1.0, 0.6), 0.1, 0.4; θ = π / 3),
        Rectangle((-1.0, -0.3), 0.6, 0.4; θ = π / 6),
        Rectangle((-0.8, 0.3), 0.2, 0.2; θ = π / 10),
    )

    @time for I in CartesianIndices(phase)

        𝐱 = @SVector([xc[I[1]], yc[I[2]]])

        for igeom in eachindex(geometries)
            if inside(𝐱, geometries[igeom])
                phase[I] = 2
            end
        end
    end

    heatmap(xc, yc, phase')

end
