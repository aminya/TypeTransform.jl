export allsubtypes
import InteractiveUtils.subtypes
################################################################
function allsubtypes(T::Type)
    t = Set{Type}()
    push!(t, T) # include itself
    allsubtypes.(subtypes(T), Ref(t))
    t
end
function allsubtypes(T, t)
    # T is an element
    # recursive method
    push!(t, T)
    if isempty(subtypes(T))
        return
    else
        allsubtypes.(subtypes(T), Ref(t))
    end
end

allsubtypes(T::Symbol) = allsubtypes(Core.eval(Main, T))#convert Symbol to Type
