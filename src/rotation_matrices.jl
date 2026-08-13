"""
    rotation_matrix(sinθ, cosθ) -> SMatrix{2, 2}

Matrix rotating a 2-D vector **clockwise** by the angle whose sine and cosine are given;
its transpose rotates counter-clockwise.

Shapes store their vertices already rotated counter-clockwise by `θ`, so a containment test
applies this matrix to bring a query point back into the shape's own frame.
"""
@inline rotation_matrix(sinθ, cosθ) = @SMatrix [cosθ sinθ; -sinθ cosθ]
