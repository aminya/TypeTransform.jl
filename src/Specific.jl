module Specific

export @specific

include("fexpr.jl")
include("subtypes.jl")

"""
    @specific

Define specific methods for all of subtypes of type (fix ambiguity error!).
```julia
using Specific
abstract type A end
abstract type B <:A end
abstract type C <:B end

@specific function foo(a, b::allsubtypes(A))
    println("a new method")
end
```
```julia
julia> methods(foo)
# 3 methods for generic function "foo":
[1] foo(a, b::C) in Main at none:2
[2] foo(a, b::B) in Main at none:2
[3] foo(a, b::A) in Main at none:2
```
You can use `subtypes` instead of `allsubtypes`, which defines methods only for the direct subtypes.

It is possible to use `allsubtypes`/`subtypes` inside curly expressions like `Union{A, subtypes{B}}` or `Type{allsubtypes{A}}`
```julia
@specific function foo_curly2(a, b::Union{T,allsubtypes(A)}, c::T) where {T<:Int64}
    println("a new method")
end
```

# Why? To fix ambiguity error!
If you run the following program
```julia
abstract type A end
abstract type B <:A end

# my general vector method
foo(a::Vector, b::Type{<:A}) = print("vector method")

# my special B mwthod
foo(a, b::Type{B}) = print("B method")
```
`foo([1,2], B)` will give an ambiguity error, while if you use `allsubtypes`, you can fix the issue.

```julia
# my general vector method
@specific foo(a::Vector, b::allsubtypes(A)) = print("vector method")
```

"""
macro specific(fexpr::Expr)
    macroexpand(__module__, fexpr)
    f, args, wherestack, body = unwrap_fun(fexpr, true, true)

    fmethods = Expr[]
    for (iArg, arg) in enumerate(args)
        if arg isa Expr && arg.head == :(::) && arg.args[2] isa Expr

            if arg.args[2].head == :call &&
               arg.args[2].args[1] in [:subtypes, :allsubtypes]

                subtype_function = arg.args[2].args[1]
                target_type = arg.args[2].args[2]

                isCurly =false

            elseif arg.args[2].head == :curly

                # string match is faster
                strarg = string(arg.args[2])
                m = match(r"(subtypes|allsubtypes)\((.)\)", strarg)
                if m === nothing
                    continue
                end

                subtype_function = Meta.parse(m.captures[1])
                target_type = Meta.parse(m.captures[2])

                isCurly =true

            else
                continue
            end

            target_subtypes =__module__.eval(
                quote
                    $subtype_function($target_type)
                end)

            target_subtypes_len = length(target_subtypes)
            fmethod = Vector{Expr}(undef, target_subtypes_len)
            for (iSubType, TSubtype) in enumerate(target_subtypes)
                # replacing with actual subtype
                if !isCurly
                    args[iArg].args[2] = TSubtype
                else
                    args[iArg].args[2] = Meta.parse(replace(strarg, m.match=>string(TSubtype)))
                end
                fmethod[iSubType] = copy(wrap_fun(f, args, wherestack, body))
            end
            append!(fmethods, fmethod)
        end
    end

    out = quote
        $(esc.(fmethods)...)
    end

    return out
end

end
