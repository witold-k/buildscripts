-- data tools

KeyValue = {}
KeyValue.__index = KeyValue

function KeyValue:new(key, value, delimitter, keystring)
    local obj = {
        key   = key,
        value = value
    }

    if keystring == nil then
        if key == nil then
            obj.keystring = nil
        else
            if delimitter == nil then
                obj.keystring = key .. " "
            else
                obj.keystring = key .. " " .. delimitter .. " "
            end
        end
    else
        obj.keystring = keystring
    end

    setmetatable(obj, KeyValue)
    return obj
end

function KeyValue:valid()
    return self.key ~= nil
end

function KeyValue:has_var()
    return self.value and self.value:find("${", 1, true) ~= nil
end

function KeyValue.from_assign(linestr, delimitter)
    delimitter = delimitter or "="
    local key, value = linestr:match("^(.-)" .. delimitter .. "(.*)$")
    if key then
        key   = key:match("^%s*(.-)%s*$")
        value = value:match("^%s*(.-)%s*$")
        return KeyValue:new(key, value, delimitter)
    end
    return KeyValue:new(nil, nil)
end

function KeyValue.from_assign_string(linestr, delimitter)
    delimitter = delimitter or "="
    local key, rest = linestr:match("^(.-)" .. delimitter .. "(.*)$")
    if key then
        key = key:match("^%s*(.-)%s*$")
        local value = rest:match('"%s*(.-)%s*"')
        return KeyValue:new(key, value, delimitter)
    end
    return KeyValue:new(nil, nil)
end

function KeyValue.from_assign_char_array(linestr, delimitter)
    delimitter = delimitter or "="
    local key, rest = linestr:match("^(.-)" .. delimitter .. "(.*)$")
    if key then
        key = key:match("^%s*(.-)%s*$")
        local value = rest:match("'(.-)'")
        return KeyValue:new(key, value, delimitter)
    end
    return KeyValue:new(nil, nil)
end

function KeyValue.from_assign_or_char_array(linestr, delimitter)
    delimitter = delimitter or "="
    local key, rest = linestr:match("^(.-)" .. delimitter .. "(.*)$")
    if key then
        key = key:match("^%s*(.-)%s*$")
        local value = rest:match("'(.-)'") or rest:match("^%s*(.-)%s*$")
        return KeyValue:new(key, value, delimitter)
    end
    return KeyValue:new(nil, nil)
end

function KeyValue.append(list, key, value)
    if value ~= nil then
        table.insert(list, key .. value)
    end
end

function KeyValue:__tostring()
    return (self.keystring or "") .. (self.value or "")
end



-- KeyValueMap

KeyValueMap = {}
KeyValueMap.__index = KeyValueMap

function KeyValueMap:new(delimitter)
    local obj = {
        map = {},
        delimitter = delimitter or "="
    }
    setmetatable(obj, KeyValueMap)
    return obj
end

function KeyValueMap:read_assign(filename)
    for line in io.lines(filename) do
        local kv = KeyValue.fromAssign(line, self.delimitter)
        self.map[kv.key] = kv
    end
end

function KeyValueMap:read_assign_string(filename)
    for line in io.lines(filename) do
        local kv = KeyValue.fromAssignString(line, self.delimitter)
        self.map[kv.key] = kv
    end
end

function KeyValueMap:read_string_array(arr)
    for _, part in ipairs(arr) do
        local kv = KeyValue.fromAssign(part, self.delimitter)
        self.map[kv.key] = kv
    end
end

function KeyValueMap:get(key)
    local kv = self.map[key]
    return kv and kv.value or nil
end

function KeyValueMap:__tostring()
    local out = "{"
    for k, v in pairs(self.map) do
        out = out .. k .. "=" .. tostring(v) .. ", "
    end
    return out .. "}"
end

