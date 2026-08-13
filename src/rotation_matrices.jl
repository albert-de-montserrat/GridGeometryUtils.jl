# Clockwise rotation by the angle whose sine and cosine are given; its transpose rotates
# counter-clockwise. Shapes store their vertices already rotated counter-clockwise by θ, so
# containment tests apply this matrix to bring a query point back into the shape's frame.
@inline rotation_matrix(sinθ, cosθ) = @SMatrix [cosθ sinθ; -sinθ cosθ]
