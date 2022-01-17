local rw = ReadWriter()
local login, password = rw:string_param_nil("login"), rw:string_param_nil("password");

if login == nil then
    rw:error(ERROR_NEW_USER_LOGIN_PARAMETER_NOT_FOUND, "пропущен обязательный параметр login")
    ngx.exit(ngx.HTTP_OK)
    return
end

if password == nil then
    rw:error(ERROR_NEW_USER_PASSWORD_PARAMETER_NOT_FOUND, "пропущен обязательный параметр password")
    ngx.exit(ngx.HTTP_OK)
    return
end

local postgres = database(rw)
if postgres == nil then
    ngx.exit(ngx.HTTP_OK)
    return
end

local login = postgres:escape_literal(login)
local password = postgres:escape_literal(password)

local res, unknown = postgres:query("SELECT * FROM auth.users where login = " .. login.."limit 1")

if res == nil then
    rw:error(unknown, ERROR_NEW_USER_1)
    ngx.exit(ngx.HTTP_OK)
    return
end

if #res == 1 then
    rw:error("login не уникален", ERROR_NEW_USER_LOGIN_NOT_UNIQUE)
    ngx.exit(ngx.HTTP_OK)
    return
end

local res, unknown = postgres:query("INSERT INTO auth.users (created_at, updated_at, login, \"password\",fio) VALUES(now(), now(), " .. login .. ", md5(" .. password .. "), '')")

if res == nil then
    rw:error(unknown, ERROR_NEW_USER_2)
    ngx.exit(ngx.HTTP_OK)
    return
elseif res.affected_rows ~= 1 then
    rw:error("не смог создать пользователя", ERROR_NEW_USER_3)
    ngx.exit(ngx.HTTP_OK)
    return
end

rw:result("успешно")
