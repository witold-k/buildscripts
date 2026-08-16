-- symlink_manager.lua
local uv = require("luv")

local SymlinkManager = {}
SymlinkManager.__index = SymlinkManager

-- Constructor
function SymlinkManager:new(base_dir)
    local obj = {
        base_dir = self:expand_user(base_dir)
    }
    setmetatable(obj, self)
    return obj
end

-- Expand ~ to home directory
function SymlinkManager:expand_user(path)
    local home = uv.os_homedir()
    return path:gsub("^~", home)
end

-- Canonicalize a path
function SymlinkManager:canonicalize(path)
    local real, err = uv.fs_realpath(path)
    if not real then
        error("Failed to canonicalize path: " .. err)
    end
    return real
end

-- Extract filename from path
function SymlinkManager:get_basename(path)
    return path:match("([^/\\]+)$")
end

-- Create symlink inside base_dir
function SymlinkManager:create_link(target_path)
    local expanded = self:expand_user(target_path)
    local canonical = self:canonicalize(expanded)
    local basename = self:get_basename(canonical)

    local link_path = self.base_dir .. "/" .. basename

    -- Remove existing link if present
    uv.fs_unlink(link_path)

    local ok, err = uv.fs_symlink(canonical, link_path)
    if not ok then
        error("Failed to create symlink: " .. err)
    end

    return {
        target = canonical,
        link = link_path
    }
end

return SymlinkManager

