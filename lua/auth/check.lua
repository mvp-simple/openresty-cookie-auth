local rw = ReadWriter()
local postgres = database(rw)

local user = findUserByCookie(postgres,rw)
if not user or user == nil or not user.id or user.id == nil or user.id < 1 then
    user = findUserByToken(postgres,rw)
end
if not user or user == nil or not user.id or user.id == nil or user.id < 1 then
    rw:result("not auth")
    ngx.exit(ngx.HTTP_FORBIDDEN)
    return
end

local uri = postgres:escape_literal(string.gsub(ngx.var.request_uri, "?.*", ""))
local sql = [[
with ids as (
    select id from auth.urls u where uri = ]]..uri..[[
)
select ru.url_id from auth.roles_urls ru where ru.role_id in (
    select role_id from auth.role_groups_roles rgr where rgr.role_group_id in (
        select role_group_id from auth.users_role_groups urg where urg.user_id = ]]..user.id..[[
    )
) and ru.url_id in (select id from ids)
union all
select url_id from auth.users_custom_urls ucu where ucu.user_id = ]]..user.id..[[ and ucu.url_id in (select * from ids)
limit 1]]
local res, unknown = postgres:query(sql)

ngx.req.set_header("X-AUTH-USER-ID", user.id)
ngx.header["X-AUTH-USER-ID"] = user.id
ngx.ctx.user_id = user.id
if #res ~= 1 then
    ngx.exit(ngx.HTTP_FORBIDDEN)
    return
end