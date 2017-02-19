--[[ 
    URL Shortner Project
    Author: Ian Baldo
--]]

local lunajson = require("lunajson")

-- Variáveis Globais
defaultURL = "www.shortener/u/"
BASE = "lyT3q2Zh_6CnfWxgzPYGrNvLHK145DwJ0tB8XbdR7MSsjpmQkcVF09" -- BASE 54


function storeURL( id, url, alias )
    for key,val in pairs(myStorage) do
        if(tonumber(key) == id) then
            print ('trying again')
            storeURL(generateId(),url, alias)
            return nil
        end
    end

    if alias == "" then
        alias = encodeURL(id)
        id = tostring(id)
    else
        id = aliasToId(alias)
        if id == nil then
            return
        elseif myStorage[id] ~= nil then
            print('Alias ja existe')
            return
        end
    end

    myStorage[id] = {}
    myStorage[id].url = url
    myStorage[id].alias = alias
    myStorage[id].shortURL = defaultURL .. alias
    return id
end


--[[
    aliasToId:
        Param:
        alias -> Recebe o alias que o usuário digito

    Faz a conversão do alias(base 54) para o id(base 10)
]]
function aliasToId (alias)
    alias = string.reverse( alias )
    local id = 0
    for i=1,string.len(alias) do
        local pos = string.find(BASE, alias:sub(i,i))
        
        if pos == nil then
            print("Alias Inválido")
            return nil
        else
            id = id + (54^(i-1)) * tonumber(pos)
        end
    end
    return id
end



--[[

]]
function generateId ()
    return math.random( 100000,999999) -- random 6 digit Id
end


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


-- Main

myStorage = {}
while 1 do
    print ( '1: Store', '2: Retrieve', '4: DB' ,'3: Exit')
    local opcao = io.read()

    if opcao == '1' then
        io.write('Entre com a URL:')
        local url = io.read()

        if url ~= "" then
            io.write('Entre com o alias:')
            local alias = io.read()
            local id = generateId()
            

            local result = {}
            result.statistics = {}

            local start = os.clock()
            id = storeURL(id,url,alias)
            if id ~= nil then
                result.url = myStorage[id].shortURL
                result.alias = myStorage[id].alias
                result.statistics.time_taken = (os.clock() - start) * 1000
                print(lunajson.encode(result))
            end
        end
    elseif opcao == '2' then
        io.write('Entre com o Alias:')
        local input = io.read()
        local result = {}
        result.statistics = {}

        local start = os.clock()
        local id = aliasToId(input)
        if id ~= nil and myStorage[id] ~= nil then
            result.url = myStorage[id].url
            result.alias = myStorage[id].alias
            result.statistics.time_taken = (os.clock() - start) * 1000
            print(lunajson.encode(result))
        end
    elseif opcao == '3' then
        break

    elseif opcao == '4' then
        for key,val in pairs(myStorage) do
            print(key, lunajson.encode(val))
        end
    end
end