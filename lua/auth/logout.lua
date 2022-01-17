local rw = ReadWriter()
local postgres = database(rw)

local user = findUserByCookie(postgres,rw)
if user == nil then
    ngx.exit(ngx.HTTP_OK)
    return
end

local sql = "UPDATE auth.cookies SET deleted_at=now() WHERE id=" .. user.id
local res = postgres:query(sql)

if not res or not res.affected_rows or res.affected_rows < 1 then
    rw:error(ERROR_LOGOUT_CAN_NOT_REMOVE_COOKIE_STRING_IN_DATABASE, "не смог удалить куку из базы данных")
    ngx.exit(ngx.HTTP_OK)
    return
end
ngx.header["Set-Cookie"] = AUTH_COOKIE_NAME .. "=; Path=/; Expires=" .. ngx.cookie_time(ngx.time() - AUTH_COOKIE_EXPIRES)
rw:result("успешно")
