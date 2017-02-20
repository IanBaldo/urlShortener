--[[ 
    URL Shortner Project
    Author: Ian Baldo
--]]


lunajson = require("lunajson")
require("db_funcs")


-- Variáveis Globais
defaultURL = "www.shortener/u/"
BASE = "lyT3q2Zh_6CnfWxgzPYGrNvLHK145DwJ0tB8XbdR7MSsjpmQkcVF09" -- BASE 54



--[[
    Função que trata a conversão e inserção no BD de uma nova URL
]]
function storeURL( url, alias )
    local start = os.clock() -- Benchmark
    local id = generateId() -- Gera Id aleatório

    -- Checa se o Id já existe
    local data = db_getDataById(id)
    if data ~= nil then
        -- Id já está ocupado, faz chamada recursiva para tentar um novo Id
        return storeURL(url, alias)
    else
        -- Checa se o usuário definiu um CUSTOM_ALIAS
        if alias == "" then
            -- Gera um alias a partir do Id aleatório
            alias = encodeURL(id)
            id = tostring(id)
        else
            -- Transforma o alias em um Id
            id = aliasToId(alias)
            if id == nil then
                -- Alias Inválido (caractere inválido)
                return
            -- Checa se o alias já existe
            elseif db_getDataByAlias(alias) ~= nil then
                local response ={}
                response.ERR_CODE = '001'
                response.Description = "CUSTOM ALIAS ALREADY EXISTS"
                return lunajson.encode(response)
            end
        end
        
        -- Gera a nova url
        local shortURL = defaultURL .. alias

        -- Adiciona a nova entrada no BD
        if db_addURL(id,url,shortURL,alias) == 0 then
            -- Sucesso!
            local result = {}
            result.statistics = {}

            result.url = shortURL
            result.alias = alias
            result.statistics.time_taken = (os.clock() - start) * 1000
            return lunajson.encode(result)
        else
            -- Erro na inserção
            local response ={}
            response.ERR_CODE = '003'
            response.Description = "FAILED TO GENERATE URL"
            return lunajson.encode(response)
        end 
    end 
end


--[[
    aliasToId:
        Param:
        alias -> Recebe o alias que o usuário digitou

    Faz a conversão do alias(base 54) para o id(base 10)
    Nota: na base de caracteres para o alias não existem vogais
    (tentativa de evitar que o alias seja uma palavra "ruim")
]]
function aliasToId (alias)
    alias = string.reverse( alias )
    local id = 0
    for i=1,string.len(alias) do
        local pos = string.find(BASE, alias:sub(i,i))
        
        if pos == nil then
            print("Alias Inválido (vogais não são permitidas)")
            return nil
        else
            id = id + (54^(i-1)) * tonumber(pos)
        end
    end
    return id
end



--[[
    Gera um Id aleatório
]]
function generateId ()
    math.randomseed(os.time())
    local id
    for i=1,math.random(1,10) do
        id = math.random(100000000,999999999) -- Número grande para gerar um alias de no mínimo 6 caracteres
    end
    return id
end

--[[
    Gera um alias a partir do Id aleatório
]]
function encodeURL(Id)
    local newURL = ""
    local id = tonumber(Id)
    while id/54 > 0 do
        newURL = newURL .. BASE:sub(id%54,id%54)
        id = id / 54
    end
    newURL = newURL .. BASE:sub(id%54,id%54)
    newURL = string.reverse( newURL )
    return newURL
end


--[[
    Main
    Ponto de entrada do programa
]] 
while 1 do
    -- Menu Principal
    print('\n\n Main Menu')
    print('1: Convert URL')
    print('2: Retrieve URL')
    print('3: DataBase Menu')
    print('5: Exit')
    io.write("Escolha: ")
    local opcao = io.read()

    if opcao == '1' then
        io.write('\nEntre com a URL:')
        local url = io.read()

        if url ~= "" then
            io.write('Entre com o alias:')
            local alias = io.read()
            
            print(storeURL(url,alias))
        end
    elseif opcao == '2' then
        io.write('Entre com o Alias:')
        local input = io.read()
        
        print(db_getDataByAlias(input))
    elseif opcao == '3' then
        while 1 do
            -- Menu do BD
            print('\n\nDataBase Menu')
            print('1: Dump')
            print('2: Clear')
            print('3: Main Menu ')
            io.write("Escolha: ")
            local opcao2 = io.read()
            if opcao2 == '1' then
                local dbData = db_getAll()
                dbData = lunajson.decode(dbData)
                for i=1,table.getn(dbData) do
                    print(lunajson.encode(dbData[i]))
                end
                break
            elseif opcao2 == '2' then
                db_clear()
                break
            elseif opcao2 == '3' then
                break
            end
        end
    elseif opcao == '5' then
        print("Bye Bye")
        break
    end
end