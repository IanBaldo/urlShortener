require("lsqlite3complete")
-- Cria o BD caso não exista
myDb = sqlite3.open('urlshortenerDB')
-- Cria a tablea 'url' caso não exista
myDb:exec "CREATE TABLE url (id TEXT PRIMARY KEY, url TEXT, shortUrl TEXT, alias TEXT)"
myDb:close()


-- DB functions

--[[
    Adiciona uma nova entrada
]]
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

--[[
    Busca dados a partir do Id
]]
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

--[[
    Busca dados a partir do alias
    (Funciona tanto com apenas o alias como também com a url encurtada)
]]
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

--[[
    Busca todos os dados
]]
function db_getAll ()
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "SELECT * FROM url"
    local dump = {}
    for data in myDb:nrows(sql) do
        table.insert( dump, data )
    end

    return lunajson.encode(dump)
end

--[[
    Apaga todos os dados
]]
function db_clear ()
    local myDb = sqlite3.open('urlshortenerDB')
    local sql = "DELETE FROM url"
    myDb:exec(sql)
end