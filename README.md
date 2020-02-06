# TypeTransform

[![Build Status](https://github.com/aminya/TypeTransform.jl/workflows/CI/badge.svg)](https://github.com/aminya/TypeTransform.jl/actions)

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

It is possible to use the function names inside curly expressions like `Union{A, subtypes{B}}` or `Type{allsubtypes{A}}`
```julia
@transform function foo_curly(a, b::Union{T,allsubtypes(A)}, c::T) where {T<:Int64}
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
