#!/usr/bin/lua5.4
-- #!/usr/bin/env lua

------------------------------------------------------------------------------

local path = require("pl.path")
local raw = debug.getinfo(1, "S").source
local script_dir

if raw:sub(1, 1) == "@" then
    local full = raw:sub(2)

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
package.path = package.path .. ";" .. my_dir .. "/lib/?.lua"

------------------------------------------------------------------------------

-- Dependencies
-- Install via luarocks:
--     luarocks install luafilesystem
local lfs = require("lfs")

------------------------------------------------------------------------------

-- Arguments
local dirs = {}
local explicit_files = {}
local exec = ""

------------------------------------------------------------------------------

-- Expand a wildcard argument using the shell.
--
-- This handles quoted wildcards such as:
--
--     "*.lua"
--     "src/*.cpp"
--
-- Unquoted wildcards are normally already expanded by the shell.
--
local function expand_glob(pattern)

    -- No wildcard: return unchanged.
    if not pattern:find("[%*%?%[]") then
        return { pattern }
    end

    local results = {}

    -- printf performs shell glob expansion.
    --
    -- %q quotes the original argument safely for the shell.
    local cmd = "printf '%s\\n' " .. string.format("%q", pattern)

    local handle = io.popen(cmd, "r")

    if not handle then
        return results
    end

    for line in handle:lines() do
        if line ~= "" then
            table.insert(results, line)
        end
    end

    handle:close()

    return results
end

------------------------------------------------------------------------------

-- Avoid duplicate directories.
local dirs_seen = {}

local function add_dir(dir)
    if not dirs_seen[dir] then
        dirs_seen[dir] = true
        table.insert(dirs, dir)
    end
end

------------------------------------------------------------------------------

-- --- Argument autodetection ---

for _, argument in ipairs(arg) do

    local expanded = expand_glob(argument)

    for _, item in ipairs(expanded) do

        local attr = lfs.attributes(item)

        if attr then

            if attr.mode == "directory" then

                add_dir(item)

            elseif attr.mode == "file" then

                local permissions = attr.permissions or ""

                if permissions:match("x") then
                    -- Executable file.
                    exec = item
                else
                    -- Explicit non-executable file.
                    table.insert(explicit_files, item)
                end
            end
        end
    end
end

------------------------------------------------------------------------------

-- If no directories were supplied, scan current directory.
if #dirs == 0 then
    dirs[1] = "."
end

------------------------------------------------------------------------------

-- --- Helper function for file extensions ---

local function get_extension(filename)
    return filename:match("^.+(%..+)$") or ""
end

------------------------------------------------------------------------------

-- Define target extension groups.

local group1 = {
    [".md"] = true,
}

local group2 = {
    [".txt"] = true,
}

local group3 = {
    [".bb"] = true,
    [".bbclass"] = true,
    [".c"] = true,
    [".cc"] = true,
    [".cpp"] = true,
    [".h"] = true,
    [".hh"] = true,
    [".hpp"] = true,
    [".i"] = true,
    [".ii"] = true,
    [".inc"] = true,
    [".java"] = true,
    [".jl"] = true,
    [".lua"] = true,
    [".py"] = true,
    [".rs"] = true,
}

------------------------------------------------------------------------------

-- File collections.
--
-- Every file belongs to exactly ONE of these groups.

local files_g1 = {}
local files_g2 = {}
local files_g3 = {}
local files_nonexec = {}

------------------------------------------------------------------------------

-- Global deduplication.
--
-- Use the normalized absolute path as the key.
-- This prevents duplicates when, for example:
--
--     ./src
--     src
--     src/*.lua
--
-- all refer to the same file.

local files_seen = {}

------------------------------------------------------------------------------

local function normalize_file_path(file_path)

    local normalized = path.normpath(file_path)

    if not path.isabs(normalized) then
        normalized = path.abspath(normalized)
    end

    return normalized
end

------------------------------------------------------------------------------

-- Add a file to a group exactly once.
--
-- We store both the absolute path and the display root/path.
-- This avoids having to reconstruct which directory a file came from.

local function add_unique(list, file_path, root_dir)

    local absolute_path = normalize_file_path(file_path)

    if files_seen[absolute_path] then
        return
    end

    files_seen[absolute_path] = true

    table.insert(list, {
        path = absolute_path,
        root = root_dir,
    })
end

------------------------------------------------------------------------------

-- Classify a non-executable file.

local function classify_file(file_path, root_dir)

    local filename = path.basename(file_path)
    local ext = get_extension(filename):lower()

    if group1[ext] then

        add_unique(files_g1, file_path, root_dir)

    elseif group2[ext] then

        add_unique(files_g2, file_path, root_dir)

    elseif group3[ext] or not filename:find("%.") then

        add_unique(files_g3, file_path, root_dir)

    else

        -- Other non-executable files.
        add_unique(files_nonexec, file_path, root_dir)
    end
end

------------------------------------------------------------------------------

-- Classify explicitly supplied files.
--
-- Their root is "." because they were supplied directly rather than
-- discovered recursively below a directory.

for _, file_path in ipairs(explicit_files) do
    classify_file(file_path, ".")
end

------------------------------------------------------------------------------

-- Recursively scan one directory.
--
-- root_dir:
--     The original directory supplied by the user.
--
-- current_path:
--     Directory currently being traversed.

local function scan_directory(root_dir, current_path)

    for file in lfs.dir(current_path) do

        if file ~= "." and file ~= ".." then

            local full_item_path = current_path .. "/" .. file

            ------------------------------------------------------------------
            -- Ignore build/, target/, .git/ and .svn/ at the root
            -- of EACH supplied directory.
            ------------------------------------------------------------------

            if current_path == "." and (
                file == "build"
                or file == "target"
                or file == ".git"
                or file == ".svn"
            ) then

                goto continue
            end

            ------------------------------------------------------------------

            local attr = lfs.attributes(full_item_path)

            if attr then

                if attr.mode == "directory" then

                    -- Recurse.
                    scan_directory(root_dir, full_item_path)

                elseif attr.mode == "file" then

                    local permissions = attr.permissions or ""
                    local is_executable =
                        permissions:match("x") ~= nil

                    -- Executables are NOT copied as file contents.
                    -- They are handled separately via exec.
                    if not is_executable then
                        classify_file(full_item_path, root_dir)
                    end
                end
            end
        end

        ::continue::
    end
end

------------------------------------------------------------------------------

-- Scan all requested directories.

local current_dir = lfs.currentdir()

for _, dir in ipairs(dirs) do

    print("scan: " .. dir)

    local success, err = lfs.chdir(dir)

    if not success then

        io.stderr:write(
            "Could not change directory to: "
            .. dir
            .. "\n"
        )

        os.exit(1)
    end

    -- Scan from ".".
    --
    -- This keeps the traversal paths simple while root_dir retains
    -- the original user supplied directory.

    scan_directory(dir, ".")

    -- Return to original directory.
    lfs.chdir(current_dir)
end

------------------------------------------------------------------------------

-- Sort groups.
--
-- Sort by the final display path.

local function sort_files(a, b)
    return a.path < b.path
end

table.sort(files_g1, sort_files)
table.sort(files_g2, sort_files)
table.sort(files_g3, sort_files)
table.sort(files_nonexec, sort_files)

------------------------------------------------------------------------------

-- --- Collect file contents ---

local output_parts = {}

------------------------------------------------------------------------------

local function clean_dir(dir)

    dir = dir:gsub("/+$", "")

    if dir == "" then
        return "."
    end

    return dir
end

------------------------------------------------------------------------------

local function append_file_contents(file_list)

    for _, entry in ipairs(file_list) do

        local file_path = entry.path
        local root_dir = entry.root

        local f = io.open(file_path, "r")

        if f then

            local content = f:read("*a")

            f:close()

            ------------------------------------------------------------------
            -- Build a clean display path relative to the supplied root.
            ------------------------------------------------------------------

            local display_path

            local absolute_root = normalize_file_path(root_dir)

            if absolute_root == path.dirname(file_path) then

                display_path = path.basename(file_path)

            else

                local prefix = absolute_root .. "/"

                if file_path:sub(1, #prefix) == prefix then
                    display_path =
                        file_path:sub(#prefix + 1)
                else
                    display_path = file_path
                end
            end

            ------------------------------------------------------------------
            -- For explicitly supplied files, show the supplied path.
            ------------------------------------------------------------------

            if root_dir == "." then
                display_path = file_path

                -- Make it relative to cwd where possible.
                local cwd = normalize_file_path(".")

                local prefix = cwd .. "/"

                if display_path:sub(1, #prefix) == prefix then
                    display_path =
                        display_path:sub(#prefix + 1)
                end
            end

            ------------------------------------------------------------------

            local display_root = clean_dir(root_dir)

            table.insert(
                output_parts,
                string.format(
                    "===== %s/%s =====\n%s",
                    display_root,
                    display_path,
                    content
                )
            )
        end
    end
end

------------------------------------------------------------------------------

-- Files are output in this order:
--
--     Markdown
--     Text
--     Source/code
--     Other non-executable files
--
-- Because files_seen is global, each file can appear only once.

append_file_contents(files_g1)
append_file_contents(files_g2)
append_file_contents(files_g3)
append_file_contents(files_nonexec)

------------------------------------------------------------------------------

local output = table.concat(output_parts)

------------------------------------------------------------------------------

-- --- Append executable output if provided ---

if exec ~= "" then
    local handle = io.popen(exec .. " 2>&1")
    if handle then
        local exec_output = handle:read("*a")
        handle:close()
        output = output
            .. string.format(
                "\n\n===== EXECUTABLE OUTPUT: %s =====\n%s",
                exec,
                exec_output
            )
    end
end

------------------------------------------------------------------------------

-- --- Copy to clipboard ---

local xclip = io.popen("xclip -selection clipboard", "w")

if xclip then
    xclip:write(output)
    xclip:close()
else
    io.stderr:write(
        "Error: xclip is not installed or available.\n"
    )
end

