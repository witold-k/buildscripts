local path = require("pl.path")

local M = {}


--- requires call:
--- local my_dir = script_path.from_debug(debug.getinfo(1, "S"), n)
--- where n 0 .. go directory level up
function M.from_debug(info, n)
    n = n or 0

    if not info or not info.source then
        return nil
    end

    local src = info.source

    -- Only handle file paths (Lua marks them with '@')
    if src:sub(1,1) ~= "@" then
        return nil
    end

    -- Strip '@'
    local full = src:sub(2)

    -- Normalize
    full = path.normpath(full)

    -- Convert to absolute path
    if not path.isabs(full) then
        full = path.abspath(full)
    end

    -- Start with the directory of the script
    local dir = path.dirname(full)

    -- Climb up n directories
    for _ = 1, n do
        local parent = path.dirname(dir)
        if parent == dir then
            break -- reached root
        end
        dir = parent
    end

    return dir
end

function M.current(n)
    return M.from_debug(debug.getinfo(2, "S"), n)
        or M.from_debug(debug.getinfo(1, "S"), n)
end

return M

