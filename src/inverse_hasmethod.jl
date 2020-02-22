export inverse_hasmethod
"""
    inverse_hasmethod(f::Function)
Returns the types that a function hasmethod for.
```julia
inverse_hasmethod(string)
```
"""
function inverse_hasmethod(f::Function)
    allmethods = methods(f).ms
    out = Type[]
    for method in allmethods
        t = typereturn(method.sig)
        if !(typeof(t) in [NoArg])
            push!(out, t)
        end
    end
    return out
end

struct NoArg end

function typereturn(sig)
    sigparams = sig.parameters
    sigparams_length = length(sigparams)
    if sigparams_length == 1
        return NoArg()
    else
        return sigparams[end]
    end
end
