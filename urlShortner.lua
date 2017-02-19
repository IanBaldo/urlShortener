--[[ 
    URL Shortner Project
    Author: Ian Baldo
--]]

local lunajson = require("lunajson")
require("lsqlite3complete")
-- Cria o BD caso não exista
myDb = sqlite3.open('urlshortenerDB')
-- Cria a tablea 'url' caso não exista
myDb:exec "CREATE TABLE url (id TEXT PRIMARY KEY, url TEXT, shortUrl TEXT, alias TEXT)"
myDb:close()

-- Variáveis Globais
defaultURL = "www.shortener/u/"
BASE = "lyT3q2Zh_6CnfWxgzPYGrNvLHK145DwJ0tB8XbdR7MSsjpmQkcVF09" -- BASE 54


-- DB functions
function db_addURL (id,url,pShortURL,alias)
    local shortURL = pShortURL
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "INSERT INTO url VALUES('"..id.."','"..url.."','"..shortURL.."','"..alias.."')"
    myDb:exec(sql)

    if myDb:errcode() == 0 then
        myDb:close()
        return 0
    else
        local err = myDb:errcode()
        print("DB ERROR ["..myDb:errcode().."]: "..myDb:errmsg())
        myDb:close()
        return err
    end
end

function db_getDataById (id)
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "SELECT * FROM url WHERE id='"..id.."'"
    myDb:exec(sql)
    for data in myDb:nrows(sql) do
        if myDb:errcode() == 0 then
            myDb:close()
            return data
        else
            local err = myDb:errcode()
            print("DB ERROR ["..myDb:errcode().."]: "..myDb:errmsg())
            myDb:close()
            return nil
        end 
    end
end

function db_getDataByAlias (alias)
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "SELECT * FROM url WHERE alias='".. alias .."' or shortURL='"..alias.."'"
    for data in myDb:nrows(sql) do
        if data ~= nil then
            myDb:close()
            return data.url
        else
            myDb:close()
            local response ={}
            response.ERR_CODE = '002'
            response.Description = "SHORTENED URL NOT FOUND"
            return lunajson.encode(response)
        end 
    end
end

function db_getAll ()
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "SELECT * FROM url"
    local dump = {}
    for data in myDb:nrows(sql) do
        table.insert( dump, data )
    end

    return lunajson.encode(dump)
end

function db_clear ()
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "DELETE FROM url"
    myDb:exec(sql)
end



function storeURL( url, alias )
    local start = os.clock()
    local id = generateId()

    local data = db_getDataById(id)
    if data ~= nil then
        return storeURL(url, alias)
    else
        if alias == "" then
            alias = encodeURL(id)
            id = tostring(id)
        else
            id = aliasToId(alias)
            if id == nil then
                return
            elseif db_getDataByAlias(alias) ~= nil then
                local response ={}
                response.ERR_CODE = '001'
                response.Description = "CUSTOM ALIAS ALREADY EXISTS"
                return lunajson.encode(response)
            end
        end
        
        local shortURL = defaultURL .. alias
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
    Gera um Id aleatório
]]
function generateId ()
    math.randomseed(os.time())
    local id
    for i=1,math.random(1,10) do
        id = math.random(100000000,999999999) -- random 6 digit Id
    end
    return id
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