local rw = ReadWriter()
local json = rw:json_body()

if not json["login"] then
    rw:error(ERROR_LOGIN_LOGIN_PARAMETER_NOT_FOUND, "пропущен обязательный параметр login")
    ngx.exit(ngx.HTTP_OK)
    return
end

if not json["password"] then
    rw:error(ERROR_LOGIN_PASSWORD_PARAMETER_NOT_FOUND, "пропущен обязательный параметр password")
    return 200
end

local postgres = database(rw)
if postgres == nil then
    ngx.exit(ngx.HTTP_OK)
    return
end

local login = postgres:escape_literal(json["login"])
local password = postgres:escape_literal(json["password"])
local sql = "SELECT * FROM auth.users where login = " .. login .." and password = md5("..password..") limit 1"
local res, unknown = postgres:query(sql)

if #res ~= 1 then
    rw:error(ERROR_LOGIN_LOGIN_OR_PASSWORD_IS_INCORRECT, "не коректная пара логин пароль")
    ngx.exit(ngx.HTTP_OK)
    return
end

local cookie_str = utils:guid()
local sql = "INSERT INTO auth.cookies(created_at, updated_at, cookie_str, user_id) VALUES(now(), now(), '"..cookie_str.."',  "..res[1].id..")"
local res = postgres:query(sql)

if not res or not res.affected_rows or res.affected_rows < 1 then
    rw:error(ERROR_LOGIN_CAN_NOT_SAVE_COOKIE_STRING_IN_DATABASE, "не смог сохранить куку в базу данных")
    ngx.exit(ngx.HTTP_OK)
    return
end
ngx.header["Set-Cookie"] = AUTH_COOKIE_NAME .. "="..cookie_str.."; Path=/; Expires=" .. ngx.cookie_time(ngx.time() + AUTH_COOKIE_EXPIRES)
rw:result("успешно")