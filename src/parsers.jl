struct GroTopToken
    type::Symbol
    value::SubString{String}
end

GroTopToken(type::Symbol, value::String) = GroTopToken(type, SubString(value))

function lexer(source::String)
    i = 1
    j = 1
    n = length(source)
    tokens = Vector{GroTopToken}()
    while i ≤ n
        if source[i] == ' '
            # Do nothing
        elseif source[i] == '['
            push!(tokens, GroTopToken(:LBRACKET, source[i:j]))
        elseif source[i] == ']'
            push!(tokens, GroTopToken(:RBRACKET, source[i:j]))
        elseif source[i] == '\n'
            push!(tokens, GroTopToken(:NEW_LINE, source[i:j]))
        elseif source[i] == '#'
            while j+1 ≤ n && !(source[j+1] in ['\n', ' '])
                j += 1
            end
            push!(tokens, GroTopToken(:PREPROCESSOR, source[i:j]))
        elseif source[i] == ';'
            while j+1 ≤ n && !(source[j+1] in ['\n'])
                j += 1
            end
            push!(tokens, GroTopToken(:COMMENT, source[i:j]))
        else
            while j+1 ≤ n && !(source[j+1] in ['\n', ' '])
                j += 1
            end
            push!(tokens, GroTopToken(:ITEM, source[i:j]))
        end
        i = j += 1
    end
    
    return tokens
end