JSON = require("cjson")
JSONEncode = JSON.encode
JSONDecode = JSON.decode

Postgres = require("pgmoon")

-- ошибки
ERROR_UNKNOWN = "UNKNOWN"  -- неизвестная ошибка

-- NEW_USER ошибки
ERROR_NEW_USER_LOGIN_PARAMETER_NOT_FOUND = "ERROR_NEW_USER_LOGIN_PARAMETER_NOT_FOUND" -- пропущен обязательный параметр login
ERROR_NEW_USER_PASSWORD_PARAMETER_NOT_FOUND = "ERROR_NEW_USER_PASSWORD_PARAMETER_NOT_FOUND" -- пропущен обязательный параметр password
ERROR_NEW_USER_LOGIN_NOT_UNIQUE = "ERROR_NEW_USER_LOGIN_NOT_UNIQUE" --login не уникален
ERROR_NEW_USER_1 = "ERROR_NEW_USER_1"
ERROR_NEW_USER_2 = "ERROR_NEW_USER_2"
ERROR_NEW_USER_3 = "ERROR_NEW_USER_3"

-- LOGIN ошибки

ERROR_LOGIN_LOGIN_PARAMETER_NOT_FOUND = "ERROR_LOGIN_LOGIN_PARAMETER_NOT_FOUND" -- пропущен обязательный параметр login
ERROR_LOGIN_PASSWORD_PARAMETER_NOT_FOUND = "ERROR_LOGIN_PASSWORD_PARAMETER_NOT_FOUND" -- пропущен обязательный параметр password
ERROR_LOGIN_LOGIN_OR_PASSWORD_IS_INCORRECT = "ERROR_LOGIN_LOGIN_OR_PASSWORD_IS_INCORRECT" -- не коректная пара логин пароль
ERROR_LOGIN_CAN_NOT_SAVE_COOKIE_STRING_IN_DATABASE = "ERROR_LOGIN_CAN_NOT_SAVE_COOKIE_STRING_IN_DATABASE" -- не смог сохранить куку в базу данных

-- LOGOUT ошибки
ERROR_LOGOUT_CAN_NOT_REMOVE_COOKIE_STRING_IN_DATABASE = "ERROR_LOGOUT_CAN_NOT_REMOVE_COOKIE_STRING_IN_DATABASE" --  не смог удалить куку из базы данных

AUTH_COOKIE_NAME = "auth_cookie"
AUTH_COOKIE_EXPIRES = 3600 * 24

utils = {}

function utils:guid()
    local seed = { 'e', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' }
    local tb = {}
    for i = 1, 32 do
        table.insert(tb, seed[math.random(1, 16)])
    end
    local sid = table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
            string.sub(sid, 1, 8),
            string.sub(sid, 9, 12),
            string.sub(sid, 13, 16),
            string.sub(sid, 17, 20),
            string.sub(sid, 21, 32)
    )
end

Console = {}

function Console:error(...)
    ngx.log(ngx.ERR, debug.traceback(), " ", ...)
end

function Console:error_json(...)
    local new_arg = {}
    local arg = table.pack(...)
    for i = 1, #arg do
        local typ = type(arg[i])
        if typ == "nil" or typ == "number" or typ == "string" or typ == "boolean" then
            new_arg[i] = arg[i]
        else
            new_arg[i] = JSONEncode(arg[i])
        end
    end
    ngx.log(ngx.ERR, debug.traceback(), " ", unpack(new_arg))
end

function Console:log(...)
    ngx.log(ngx.INFO, debug.traceback(), " ", ...)
end

function Console:warn(...)
    ngx.log(ngx.WARN, debug.traceback(), " ", ...)
end

databaseConfig = {
    host = os.getenv("DB_HOST"),
    port = os.getenv("DB_PORT"),
    database = os.getenv("DB_NAME"),
    user = os.getenv("DB_USER"),
    password = os.getenv("DB_PASS"),
    --pool_size = 100,
    ssl = "false",
    ssl_verify = "false"
}

function database(say)
    local postgres = Postgres.new(databaseConfig)
    local ok, err = postgres:connect()
    postgres.connected = ok == true
    if ok ~= true then
        say:error(err, "ошибка связи с сервером базы данных")
        return nil
    end
    return postgres
end

function ReadWriter()
    local obj = {
        ok = false,
        res = nil,
        err_string = nil,
        err_number = nil,
        done = nil,
        uri_params = {},
        text = "",
        text_read = false,
    }

    local uri_args = ngx.req.get_uri_args()
    for k, v in pairs(uri_args) do
        obj.uri_params[k] = v
    end

    function obj:read_body()
        if self.text_read ~= true then
            ngx.req.read_body()
            self.text = ngx.req.get_body_data()
            self.text_read = true
        end
        return self.text
    end

    function obj:json_body()
        local text = self:read_body()
        if text == nil then
            return {}
        end
        return JSONDecode(text)
    end

    function obj:string_param_nil(key)
        local data = self.uri_params[key]
        if data and type(data) == "string" then
            return data
        end
        return nil
    end

    function obj:string_param(key)
        data = self:string_param_nil(key)
        if data ~= nil then
            return data
        end
        return ""
    end

    function obj:error(err_string, err_number)
        self.ok = false
        self.res = nil
        self.err_string = err_string
        self.err_number = err_number or ERROR_UNKNOWN
        return self:write()
    end

    function obj:result(res)
        self.ok = true
        self.res = res
        self.err_string = nil
        self.err_number = nil
        return self:write()
    end

    function obj:write()
        if self.done ~= true then
            ngx.say(JSONEncode({
                ok = self.ok,
                res = self.res,
                err_string = self.err_string,
                err_number = self.err_number,
            }))
            self.done = true
        end
        return self
    end

    return obj
end

function findUserByCookie(postgres, rw)
    local var_name = "cookie_" .. AUTH_COOKIE_NAME
    local cookie_value = ngx.var[var_name]
    if not cookie_value or cookie_value == '' then
        rw:result("не обнаружена кука")
        return nil
    end
    local sql = "SELECT id, created_at, updated_at, deleted_at, cookie_str, user_id FROM auth.cookies where cookie_str = " .. postgres:escape_literal(cookie_value) .. " limit 1"
    local res = postgres:query(sql)
    if not res or #res == 0 then
        rw:result("кука не валидна")
        return nil
    end
    return res[1]
end

