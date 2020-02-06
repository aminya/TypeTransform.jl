module TypeTransform
macro transform(expr::Expr)
    #TODO: support for multiple function transforms in a @transform

    macroexpand(__module__, expr)
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
        if arg isa Expr && arg.head == :(::) && arg.args[2] isa Expr

            if arg.args[2].head == :call

                if isfunclist # skip this function if it is not in funclist
                    if !(arg.args[2].args[1] in funclist)
                        continue
                    end
                end

                funcname = arg.args[2].args[1]
                intype = arg.args[2].args[2]

                isCurly =false

            elseif arg.args[2].head == :curly

                # string match is faster
                strarg = string(arg.args[2])
                # match any function name
                m = match(r"([a-zA-Z\_][a-zA-Z0-9\_]+)\((.)\)", strarg)

                if m === nothing
                    continue
                end

                funcname = Meta.parse(m.captures[1])

                if isfunclist # skip this function if it is not in funclist
                    if !(funcname in funclist)
                        continue
                    end
                end

                intype = Meta.parse(m.captures[2])

                isCurly =true

            else
                continue
            end

            outtypes =Core.eval(__module__,
                quote
                    $funcname($intype)
                end)

            outtypes_len = length(outtypes)
            fmethod = Vector{Expr}(undef, outtypes_len)
            for (iouttype, outtypeI) in enumerate(outtypes)
                # replacing with actual trasformed type
                if !isCurly
                    args[iArg].args[2] = outtypeI
                else
                    args[iArg].args[2] = Meta.parse(replace(strarg, m.match=>string(outtypeI)))
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
        $(esc.(fmethods)...)
    end

    return out
end
