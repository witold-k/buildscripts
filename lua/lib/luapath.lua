local function add(path)
  if not string.find(package.path, path, 1, true) then
    package.path = package.path .. ";" .. path
  end
end

local function add_c(path)
  if not string.find(package.cpath, path, 1, true) then
    package.cpath = package.cpath .. ";" .. path
  end
end

local function get_current_file_path()
    local info = debug.getinfo(2, "S")
    if info then
        return info.source:match("@(.*)$")
    else
        return nil
    end
end

M = {
    add = add,
    add_c = add_c,
    get_current_file_path = get_current_file_path
}

return M
