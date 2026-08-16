local uv = require("luv")

local function realpath(path)
    -- uv.fs_realpath returns absolute, normalized, symlink‑resolved path
    local resolved, err = uv.fs_realpath(path)
    if not resolved then
        return nil, err
    end
    return resolved
end

-- VolumeMapper.lua
local VolumeMapper = {}
VolumeMapper.__index = VolumeMapper

-- Constructor
function VolumeMapper:new(home, user)
    return setmetatable({
        home = home or os.getenv("HOME"),
        user = user or os.getenv("USER")
    }, self)
end

-- Main mapping function
function VolumeMapper:map(paths)
    local volumes = {}
    local index = 0

    for _, arg in ipairs(paths) do
        local abs = realpath(arg)

        -- Skip if resolution failed or path doesn't exist
        if abs and abs ~= "" then
            local f = io.open(abs, "r")
            if f then f:close() else abs = nil end
        end
        if not abs then
            -- skip silently like original script
            goto continue
        end

        -- Check if inside HOME
        if abs:sub(1, #self.home + 1) == self.home .. "/" then
            local rel = abs:sub(#self.home + 2)

            local mode = (index == 0) and "rw" or "ro"
            local mapping = string.format(
                "-v %s/%s:/home/%s/%s:%s",
                self.home, rel, self.user, rel, mode
            )

            table.insert(volumes, mapping)
            index = index + 1
        else
            io.stderr:write(string.format("Skipping (not in HOME): %s\n", arg))
        end

        ::continue::
    end

    return table.concat(volumes, " ")
end

return VolumeMapper

