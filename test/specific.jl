abstract type A end
abstract type B <:A end
abstract type C <:B end

@testset "subtypes" begin

    @transform function foo(a, b::subtypes(A), c::T) where {T<:Int64}
        println("a new method")
    end

    @test length(methods(foo)) == 1

end

@testset "allsubtypes" begin
    @transform function foo_all(a, b::allsubtypes(A), c::T) where {T<:Int64}
        println("a new method")
    end

    @test length(methods(foo_all)) == 3

end

@testset "curly" begin
    @transform function foo_curly(a, b::Type{allsubtypes(A)}, c::T) where {T<:Int64}
        println("a new method")
    end

    @test length(methods(foo_curly)) == 3

    @transform function foo_curly2(a, b::Union{T,allsubtypes(A)}, c::T) where {T<:Int64}
        println("a new method")
    end

    @test length(methods(foo_curly2)) == 3

end

@testset "array of functions" begin
    @transform [:subtypes, :allsubtypes], function foo_array(a, b::allsubtypes(A))
        println("a new method")
    end

    @test length(methods(foo_array)) == 3
end
