module Specific

export @specific

include("fexpr.jl")
include("subtypes.jl")

macro specific(fexpr::Expr)
    macroexpand(__module__, fexpr)

    f, args, wherestack, body = unwrap_fun(fexpr, true, true)

    fsymbol = QuoteNode(f)
    bodyexpr = QuoteNode(body)

    argsubtype = Vector{Expr}(undef, 0)
    argsout = Symbol(f, "_argsout")

    for (i, arg) in enumerate(args)
        if (arg isa Expr &&
           arg.head == :(::) &&
           arg.args[2] isa Expr &&
           arg.args[2].head == :call &&
           arg.args[2].args[1] in [:subtypes, :allsubtypes])

            subtype_function = arg.args[2].args[1]

            argsubtypeI = quote
                $argsout = $(args)

                for T in $subtype_function($(arg.args[2].args[2]))
                    $argsout[$i].args[2] = T # replacing with actual subtype

                    eval(wrap_fun($fsymbol, $argsout, $wherestack, $bodyexpr))
                end

            end

            push!(argsubtype, argsubtypeI)
        end
    end
    return :($(esc(argsubtype[1]))) # only one
end

end
