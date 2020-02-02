# Specific

[![Build Status](https://github.com/aminya/Specific.jl/workflows/CI/badge.svg)](https://github.com/aminya/Specific.jl/actions)

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
