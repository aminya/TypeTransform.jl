abstract type A end
abstract type B <:A end
abstract type C <:B end

@testset "subtypes" begin

    @specific function foo(a, b::subtypes(A), c::T) where {T<:Int64}
        println("a new method")
    end

    @test length(methods(foo)) == 1

end

@testset "allsubtypes" begin
    @specific function foo_all(a, b::allsubtypes(A), c::T) where {T<:Int64}
        println("a new method")
    end

    @test length(methods(foo_all)) == 3

end
