#!/usr/bin/lua5.4
-- #!/usr/bin/env lua

------------------------------------------------------------------------------

local path = require("pl.path")
local raw = debug.getinfo(1, "S").source
local script_dir

if raw:sub(1,1) == "@" then
    local full = raw:sub(2)  -- strip '@'

    -- Normalize relative paths
    full = path.normpath(full)

    -- Convert to absolute path
    if not path.isabs(full) then
        full = path.abspath(full)
    end

    script_dir = path.dirname(full)
end
if not script_dir then
    error("script_dir could not be determined!")
end
package.path = package.path .. ";" .. script_dir .. "/?.lua"

------------------------------------------------------------------------------

local script_path = require("script_path_from_debug")
local my_dir = script_path.from_debug(debug.getinfo(1, "S"), 1)
package.path = package.path .. ';' .. my_dir .. '/lib/?.lua'

------------------------------------------------------------------------------

-- Dependencies
-- Install via luarocks: luarocks install luafilesystem
local lfs = require("lfs")

local exec = ""
local dir = "."

-- --- Argument autodetection ---
for _, arg in ipairs(arg) do
    local attr = lfs.attributes(arg)
    if attr then
        if attr.mode == "directory" then
            dir = arg
        elseif attr.mode == "file" then
            -- Check execution permission (Unix specific check)
            local permissions = attr.permissions or ""
            if permissions:match("x") then
                exec = arg
            end
        end
    end
end

-- --- Helper function for file extensions ---
local function get_extension(filename)
    return filename:match("^.+(%..+)$") or ""
end

-- Define target extension groups to replicate the Bash logic
local group1 = { [".md"] = true }
local group2 = { [".txt"] = true }
local group3 = {
    [".java"] = true, [".cpp"] = true, [".hpp"] = true,
    [".cc"] = true,   [".hh"] = true,  [".h"] = true,
    [".c"] = true,    [".i"] = true,   [".ii"] = true,
    [".rs"] = true,   [".py"] = true,  [".lua"] = true
}

-- Collect files matching criteria in the target directory
local files_g1, files_g2, files_g3 = {}, {}, {}

-- --- Recursive directory traversal function ---
local function scan_directory(current_rel_path)
    for file in lfs.dir(current_rel_path) do
        if file ~= "." and file ~= ".." then
            local full_item_path = current_rel_path .. "/" .. file

            -- Replicate ignoring build/ and target/ strictly at the root directory
            if current_rel_path == "." and (file == "build" or file == "target" or file == ".git" or file == ".svn") then
                -- Skip this entry completely
                goto continue
            end

            local attr = lfs.attributes(full_item_path)

            if attr then
                if attr.mode == "directory" then
                    -- Recurse into subdirectory
                    scan_directory(full_item_path)
                elseif attr.mode == "file" then
                    local ext = get_extension(file):lower()

                    if group1[ext] then
                        table.insert(files_g1, full_item_path)
                    elseif group2[ext] then
                        table.insert(files_g2, full_item_path)
                    elseif group3[ext] or not file:find("%.") then
                        -- Matches specific extensions or files without extensions
                        table.insert(files_g3, full_item_path)
                    end
                end
            end
        end
        ::continue::
    end
end

-- Start scanning from the target directory
local current_dir = lfs.currentdir()
local success, err = lfs.chdir(dir)
if not success then
    io.stderr:write("Could not change directory to: " .. dir .. "\n")
    os.exit(1)
end

-- Scan dynamically starting at "." so path strings remain cleanly built
scan_directory(".")

-- Replicate sort -z (sorts the paths alphabetially)
table.sort(files_g1)
table.sort(files_g2)
table.sort(files_g3)

-- --- Collect file contents ---
local output_parts = {}

-- Helper to clean path string for the header format
local clean_dir = dir:gsub("/+$", "") -- strip trailing slashes if present

local function append_file_contents(file_list)
    for _, file_path in ipairs(file_list) do
        local f = io.open(file_path, "r")
        if f then
            local content = f:read("*a")
            f:close()

            -- Replaces the leading "./" from the scan loop with the user-defined base dir
            local display_path = file_path:gsub("^%./", "")
            table.insert(output_parts, string.format("===== %s/%s =====\n%s", clean_dir, display_path, content))
        end
    end
end

append_file_contents(files_g1)
append_file_contents(files_g2)
append_file_contents(files_g3)

-- Return to original directory (replicates popd)
lfs.chdir(current_dir)

local output = table.concat(output_parts)

-- --- Append executable output if provided ---
if exec ~= "" then
    -- Run executable and capture stderr + stdout
    local handle = io.popen(exec .. " 2>&1")
    if handle then
        local exec_output = handle:read("*a")
        handle:close()

        output = output .. string.format("\n\n===== EXECUTABLE OUTPUT: %s =====\n%s", exec, exec_output)
    end
end

-- --- Copy to clipboard ---
-- Uses io.popen to pipe the final string into xclip
local xclip = io.popen("xclip -selection clipboard", "w")
if xclip then
    xclip:write(output)
    xclip:close()
else
    io.stderr:write("Error: xclip is not installed or available.\n")
end

