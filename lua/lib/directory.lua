local lfs = require("lfs")

-- Function to recursively search a directory
local function search_dir(path, search)
    for file in lfs.dir(path) do
        if file == search then
            local full_path = path .. "/" .. file
            return full_path
        end
        if file ~= "." and file ~= ".." then
            local full_path = path .. "/" .. file
            local attr = lfs.attributes(full_path)
            if attr ~= nil and attr.mode == "directory" then
                local found = search_dir(full_path, search)
                if found ~= nil then
                    return found
                end
            end
        end
    end
    return nil
end

local function is_empty(directory)
    local iterator, dir_handle = lfs.dir(directory)
    if not iterator then
        return true  -- Directory does not exist or cannot be read
    end

    for entry in iterator, dir_handle do
        if entry ~= "." and entry ~= ".." then
            return false  -- Found a real file or folder
        end
    end

    return true  -- No real entries found
end

M = {
    search = search_dir,
    is_empty = is_empty
}

return M
