module Specific

export @specific

include("fexpr.jl")
include("subtypes.jl")

"""
    @specific

Define specific methods for all of subtypes of type.
```julia
abstract type A end
abstract type B <:A end
abstract type C <:B end

@specific function foo(a, b::allsubtypes(A))
    println("a new method")
end
```


Supports functions that have `where`

```julia
@specific function foo(a, b::allsubtypes(A), c::T) where {T<:Int64}
    println("a new method")
end
```

You can use just `subtypes` instead of `allsubtypes`, and in this situation only method for direct subtypes are defined.

"""
macro specific(fexpr::Expr)
    macroexpand(__module__, fexpr)

    f, args, wherestack, body = unwrap_fun(fexpr, true, true)

    fmethods = Vector{Expr}(undef, 0)

    for (i, arg) in enumerate(args)
        if (arg isa Expr &&
           arg.head == :(::) &&
           arg.args[2] isa Expr &&
           arg.args[2].head == :call &&
           arg.args[2].args[1] in [:subtypes, :allsubtypes])

            subtype_function = arg.args[2].args[1]
            target_type = arg.args[2].args[2]
            target_type_escape = :($(esc(target_type)))

            target_subtypes = Core.eval(__module__, Expr(:call, subtype_function,target_type))

            for T in target_subtypes
                args[i].args[2] = T # replacing with actual subtype

                fmethod = wrap_fun(f, args, wherestack, body)
                push!(fmethods, fmethod)
            end
        end
    end

    out = quote
        $ ((esc.(fmethods))...)
    end

    return out
end

end
