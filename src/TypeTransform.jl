module TypeTransform

export @transform, transform

include("fexpr.jl")
include("subtypes.jl")

"""
    @transform

Transform the given type to another type during defining a method.

Use `@transform` and the function that transforms the type to another type. The function should return an `Array` of types that you want the method to be defined for.

For example, we use `allsubtypes()` type transform function to define specific methods for all of subtypes of a given type (fix ambiguity error!).
```julia
using TypeTransform
abstract type A end
abstract type B <:A end
abstract type C <:B end

@transform function foo(a, b::allsubtypes(A))
    println("a new method")
end
```
Since `allsubtypes(A)` returns the array of types `[A, B, C]`, three methods are defined
```julia
julia> methods(foo)
# 3 methods for generic function "foo":
[1] foo(a, b::C) in Main at none:2
[2] foo(a, b::B) in Main at none:2
[3] foo(a, b::A) in Main at none:2
```
Note that you could use `subtypes()` instead of `allsubtypes()`, which defines methods only for the direct subtypes (`[B]` in this case).

If you want that only specific functions to be considered in transformation by `@transform`, give an `Array` of `Symbol`s that contains the function names you want to be transformed.

```julia
@transform [:subtypes, :allsubtypes], function foo_array(a, b::allsubtypes(A))
    println("a new method")
end
```

It is possible to use the function names inside curly expressions like `Union{A, subtypes{B}}` or `Type{allsubtypes{A}}` or use arguments without a name:
```julia
@transform function foo_curly(a, ::Union{T,allsubtypes(A)}, c::T) where {T<:Int64}
    println("a new method")
end
```

# Motivation
The first motivation for this package was to fix ambiguity error by defining specific methods.

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
@transform foo(a::Vector, b::allsubtypes(A)) = print("vector method")
```
"""
macro transform(expr::Expr)
    #TODO: support for multiple function transforms in a @transform
    modul = __module__
    macroexpand(modul, expr)
    out = transform(modul, expr)

    return out
end

function transform(modul::Module, expr)
    if expr.head == :block
        expr = expr.args[2]
    end

    if expr.head == :tuple # some functions are specified
        funclist = eval(expr.args[1])
        isfunclist = true

        fexpr = expr.args[2]
    else
        fexpr = expr
        isfunclist = false
    end

    f, args, wherestack, body = unwrap_fun(fexpr, true, true)

    fmethods = Expr[]
    for (iArg, arg) in enumerate(args)
        if arg isa Expr && arg.head == :(::) &&
            arg.args[end] isa Expr

            if arg.args[end].head == :call

                # skip this function if it is not in funclist
                if isfunclist && !(arg.args[end].args[1] in funclist)
                    continue
                end

                funcname = arg.args[end].args[1]
                intype = arg.args[end].args[2]

                isCurly =false

            elseif arg.args[end].head == :curly

                # string match is faster
                strarg = string(arg.args[end])

                # match any function name
                m = match(r"([a-zA-Z\_][a-zA-Z0-9\_]*)\((.*)\)", strarg)
                if m === nothing
                    continue
                end

                funcname = Meta.parse(m.captures[1])

                 # skip this function if it is not in funclist
                if isfunclist && !(funcname in funclist)
                    continue
                end

                intype = Meta.parse(m.captures[2])

                isCurly =true

            else
                continue
            end

            outtypes =Core.eval(modul,
                quote
                    $funcname($intype)
                end)

            outtypes_len = length(outtypes)
            fmethod = Vector{Expr}(undef, outtypes_len)
            for (iouttype, outtypeI) in enumerate(outtypes)
                # replacing with actual trasformed type
                if !isCurly
                    args[iArg].args[end] = outtypeI
                else
                    args[iArg].args[end] = Meta.parse(replace(strarg, m.match=>string(outtypeI)))
                end
                fmethod[iouttype] = copy(wrap_fun(f, args, wherestack, body))
            end
            append!(fmethods, fmethod)
        end
    end
    if isempty(fmethods)
        error("No method defined")
    end
    # print(fmethods)

    out = quote
        Base.@__doc__(function $f end) # supports docuementation
        $(esc.(fmethods)...)
    end
    return out
end

end
