local json = require("json")        -- any JSON lib (dkjson, cjson, etc.)
local lfs  = require("lfs")         -- for path resolution if needed
local KeyValue = KeyValue           -- your earlier module
local pathutils = pathutils         -- your own module

JsonEnvironment = {}
JsonEnvironment.__index = JsonEnvironment


------------------------------------------------------------
-- Constructors
------------------------------------------------------------

function JsonEnvironment.from_json(basedir, json_data)
    local private_env = JsonEnvironment.resolve_variables_self(basedir, json_data["private"])
    local public_env_prepend = JsonEnvironment.resolve_variables_other(json_data, "env:prepend", private_env)
    local public_env_append  = JsonEnvironment.resolve_variables_other(json_data, "env:append", private_env)
    local public_env_set     = JsonEnvironment.resolve_variables_other(json_data, "env:set", private_env)

    return JsonEnvironment:new(basedir, private_env, public_env_prepend, public_env_append, public_env_set)
end

function JsonEnvironment.new_empty()
    return JsonEnvironment:new(".", {}, {}, {}, {})
end

function JsonEnvironment.with_env(private_env, public_env_set)
    private_env    = JsonEnvironment.resolve_variables_self(".", private_env)
    public_env_set = JsonEnvironment.resolve_variables_section(public_env_set, private_env)
    return JsonEnvironment:new(".", private_env, {}, {}, public_env_set)
end

function JsonEnvironment.load(filename)
    local basedir = filename:match("(.+)/[^/]+$") or "."
    local file = assert(io.open(filename, "r"))
    local text = file:read("*a")
    file:close()
    return JsonEnvironment.from_json(basedir, json.decode(text))
end

function JsonEnvironment.load_upper_from(dirname, filename)
    local envname = pathutils.find_subdir(dirname, filename)
    return JsonEnvironment.load(envname)
end

function JsonEnvironment.from_string(basedir, text)
    return JsonEnvironment.from_json(basedir, json.decode(text))
end


------------------------------------------------------------
-- Variable resolution
------------------------------------------------------------

function JsonEnvironment.resolve_variables_self(basedir, data)
    local decoded = {}
    local dir_keys = {}

    -- First pass: detect DIR/FILE types
    for key, value in pairs(data) do
        local name, type_ = key:match("([^:]+):?(.*)")
        if type_ == "DIR" or type_ == "FILE" then
            table.insert(dir_keys, name)
        end
        decoded[name] = value
    end

    -- Resolve variables repeatedly until stable
    local replaced = true
    while replaced do
        replaced = false

        -- Replace ${var} inside values
        for key, value in pairs(decoded) do
            local kv = KeyValue:new(key, value, "=")
            if kv:has_var() then
                for var_key, var_value in pairs(decoded) do
                    local pattern = "${" .. var_key .. "}"
                    if value:find(pattern, 1, true) then
                        value = value:gsub(pattern, var_value)
                        decoded[key] = value
                        replaced = true
                    end
                end
            end
        end

        -- Resolve DIR/FILE to absolute paths
        for _, dir_key in ipairs(dir_keys) do
            local dir_name = decoded[dir_key]
            if dir_name ~= "" then
                if not dir_name:match("^/") then
                    dir_name = basedir .. "/" .. dir_name
                end
                decoded[dir_key] = dir_name
            end
        end
    end

    return decoded
end


function JsonEnvironment.resolve_variables_section(data, map_data)
    local decoded = {}

    for key, value in pairs(data) do
        if value:find("${", 1, true) then
            for var_key, var_value in pairs(map_data) do
                local pattern = "${" .. var_key .. "}"
                if value:find(pattern, 1, true) then
                    value = value:gsub(pattern, var_value)
                end
            end
        end
        decoded[key] = value
    end

    return decoded
end


function JsonEnvironment.resolve_variables_other(data_all, key, map_data)
    return JsonEnvironment.resolve_variables_section(data_all[key], map_data)
end


------------------------------------------------------------
-- Instance
------------------------------------------------------------

function JsonEnvironment:new(basedir, private_env, public_env_prepend, public_env_append, public_env_set)
    local obj = {
        basedir            = basedir,
        private_env        = private_env,
        public_env_prepend = public_env_prepend,
        public_env_append  = public_env_append,
        public_env_set     = public_env_set
    }
    setmetatable(obj, JsonEnvironment)
    return obj
end


------------------------------------------------------------
-- Apply environment variables
------------------------------------------------------------

function JsonEnvironment:apply_env()
    local map = {}

    -- private env
    for name, val in pairs(self.private_env) do
        map[name] = val
    end

    -- prepend
    for name, val in pairs(self.public_env_prepend) do
        local old = os.getenv(name)
        local new_val = old and (val .. old) or val
        os.setenv(name, new_val)
        map[name] = new_val
    end

    -- append
    for name, val in pairs(self.public_env_append) do
        local old = os.getenv(name)
        local new_val = old and (old .. val) or val
        os.setenv(name, new_val)
        map[name] = new_val
    end

    -- set
    for name, val in pairs(self.public_env_set) do
        os.setenv(name, val)
        map[name] = val
    end

    return map
end


------------------------------------------------------------
-- Formatting
------------------------------------------------------------

function JsonEnvironment.map_to_str(map)
    local out = ""
    for key, value in pairs(map) do
        out = out .. '    { "' .. key .. '": "' .. value .. '"},\n'
    end
    if #out > 0 then
        return out:sub(1, -2) .. "\n"
    end
    return out
end

function JsonEnvironment:__tostring()
    return
        '"private": {\n'      .. JsonEnvironment.map_to_str(self.private_env)        .. '},\n' ..
        '"env:prepend": {\n'  .. JsonEnvironment.map_to_str(self.public_env_prepend) .. '},\n' ..
        '"env:append": {\n'   .. JsonEnvironment.map_to_str(self.public_env_append)  .. '},\n' ..
        '"env:set": {\n'      .. JsonEnvironment.map_to_str(self.public_env_set)     .. '}\n'
end

