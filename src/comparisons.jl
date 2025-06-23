@inline function isequal_r(a::T, b::T) where {T}
    a == b && return true
    arequasizero(a, b) && return true
    δ = abs((a - b + eps(T)) / (a + eps(T)))
    return δ < 1.0e3 * eps(T)
end

@inline isequal_r(a::Integer, b::Integer) = a == b

@inline isequal_r(a::T1, b::T2) where {T1, T2} = isequal_r(promote(a, b)...)

@inline function le_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a < b
end

@inline le_r(a::Integer, b::Integer) = a < b

@inline function ge_r(a::Number, b::Number)
    isequal_r(a, b) && return false
    # If a is not equal to b, we can use the standard comparison
    return a > b
end

@inline ge_r(a::Integer, b::Integer) = a > b

@inline leq_r(a::Number, b::Number) = isequal_r(a, b) || a < b
@inline geq_r(a::Number, b::Number) = isequal_r(a, b) || a > b
@inline leq_r(a::Integer, b::Integer) = a ≤ b
@inline geq_r(a::Integer, b::Integer) = a ≥ b

@inline arequasizero(a, b) = isquasizero(a) && isquasizero(b)
@inline isquasizero(a::T) where {T} = abs(a) < 1.0e3 * eps(T)

macro comp(ex)
    substitute_comp(ex)
    return esc(:($ex))
end

@inline function substitute_comp(ex::Expr)
    for (i, arg) in enumerate(ex.args)
        new_arg = substitute_comp(arg)
        if !isnothing(new_arg)
            ex.args[i] = new_arg
        end
    end
    return
end

@inline function substitute_comp(sym::Symbol) 
    if sym === :(==) 
        :(isequal_r)
    elseif sym === :(>) 
        :(ge_r)
    elseif sym === :(<) 
        :(le_r) 
    elseif sym === :(≥) 
        :(geq_r)
    elseif sym === :(≤) 
        :(leq_r) 
    else
        sym
    end

end

@inline substitute_comp(x) = x
