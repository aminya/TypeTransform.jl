# Specific

[![Build Status](https://github.com/aminya/Specific.jl/workflows/CI/badge.svg)](https://github.com/aminya/Specific.jl/actions)

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
