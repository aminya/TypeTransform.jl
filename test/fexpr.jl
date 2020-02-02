@testset "fexpr" begin

    fexpr = :( function foo(a, b::T1, c::T2) where {T1<:A} where {T2<:Int64}
           print("vector method")
     end)
    f, args, wherestack, body = unwrap_fun(fexpr, true, true)
    fexpr1 = wrap_fun(f, args, wherestack, body)

end
