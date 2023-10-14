struct GroTopToken
    type::Symbol
    value::SubString{String}
end

function lexer(source::String)
    i = 1
    j = 1
    n = length(source)
    tokens = Vector{GroTopToken}()
    while i ≤ n
        if source[i] == ' '
            # Do nothing
        elseif source[i] == '['
            push!(tokens, GroTopToken(:LBRACKET, SubString(source, i:j)))
        elseif source[i] == ']'
            push!(tokens, GroTopToken(:RBRACKET, SubString(source, i:j)))
        elseif source[i] == '\n'
            push!(tokens, GroTopToken(:NEW_LINE, SubString(source, i:j)))
        elseif source[i] == '#'
            while j+1 ≤ n && !isspace(source[j+1])
                j += 1
            end
            push!(tokens, GroTopToken(:PREPROCESSOR, SubString(source, i:j)))
        elseif source[i] == ';'
            while j+1 ≤ n && source[j+1] ≠ '\n'
                j += 1
            end
            push!(tokens, GroTopToken(:COMMENT, SubString(source, i:j)))
        else
            while j+1 ≤ n && !isspace(source[j+1])
                j += 1
            end
            push!(tokens, GroTopToken(:ITEM, SubString(source, i:j)))
        end
        i = j += 1
    end
    
    return tokens
end