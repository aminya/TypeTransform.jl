@testset "sepecific" begin
    abstract type A end
    abstract type B <:A end
    abstract type C <:B end

    @specific function foo(a, b::subtypes(A), c::T) where {T<:Int64}
           print("vector method")
    end

    methods(foo)

end
