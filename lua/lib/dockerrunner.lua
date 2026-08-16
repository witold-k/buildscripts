local uv = require("luv")

------------------------------------------------------------
-- Utility helpers
------------------------------------------------------------

local function read_process(cmd, args)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local output = {}

    local handle = uv.spawn(cmd, {
        args = args,
        stdio = {nil, stdout, stderr}
    }, function()
        stdout:close()
        stderr:close()
        handle:close()
    end)

    stdout:read_start(function(err, data)
        if data then table.insert(output, data) end
    end)

    stderr:read_start(function(err, data)
        if data then io.stderr:write(data) end
    end)

    uv.run()
    return table.concat(output)
end

local function dir_exists(path)
    local st = uv.fs_stat(path)
    return st and st.type == "directory"
end

local function scandir_match(root, pattern)
    local out = {}
    local req = uv.fs_scandir(root)
    if not req then return out end

    while true do
        local name, t = uv.fs_scandir_next(req)
        if not name then break end
        if t == "directory" and name:match(pattern) then
            table.insert(out, root .. "/" .. name)
        end
    end
    return out
end

------------------------------------------------------------
-- DockerRunner class
------------------------------------------------------------

local DockerRunner = {}
DockerRunner.__index = DockerRunner

function DockerRunner:new(project_dir, script_dir)
    local o = {
        project_dir = project_dir,
        script_dir = script_dir,
        mount_opt = {},
        env = {},
    }
    setmetatable(o, self)
    return o
end

------------------------------------------------------------
-- Environment loading
------------------------------------------------------------

function DockerRunner:load_environment()
    local env_json = self.project_dir .. "/config/environment.json"
    local out = read_process("python3", {
        self.script_dir .. "/get_config_environment.py",
        env_json
    })

    for line in out:gmatch("[^\n]+") do
        local k, v = line:match("export%s+(%S+)=(.*)")
        if k and v then
            os.setenv(k, v)
            self.env[k] = v
        end
    end

    if not self.env.PYTHON_BIN or self.env.PYTHON_BIN == "" then
        self.env.PYTHON_BIN = "/usr/bin/python3"
        os.setenv("PYTHON_BIN", self.env.PYTHON_BIN)
    end
end

------------------------------------------------------------
-- Mount helpers
------------------------------------------------------------

function DockerRunner:add_mount(src, dst)
    table.insert(self.mount_opt, "-v")
    table.insert(self.mount_opt, src .. ":" .. dst)
end

function DockerRunner:map(path)
    if dir_exists("/opt/" .. path) then
        self:add_mount("/opt/" .. path, "/opt/" .. path)
    end
    if dir_exists("/usr/local/" .. path) then
        self:add_mount("/usr/local/" .. path, "/usr/local/" .. path)
    end
end

function DockerRunner:map_find(pattern)
    for _, d in ipairs(scandir_match("/opt", pattern)) do
        self:add_mount(d, d)
    end
    for _, d in ipairs(scandir_match("/usr/local", pattern)) do
        self:add_mount(d, d)
    end
end

------------------------------------------------------------
-- Podman execution (array‑based)
------------------------------------------------------------

function DockerRunner:run_podman(args)
    print("Running podman:", table.concat(args, " "))
    local handle = uv.spawn("podman", { args = args }, function() end)
    uv.run()
end

------------------------------------------------------------
-- Main logic
------------------------------------------------------------

function DockerRunner:prepare_mounts()
    local RUNDOCKER_OPT_COMPILER_ONLY = os.getenv("RUNDOCKER_OPT_COMPILER_ONLY")

    if not RUNDOCKER_OPT_COMPILER_ONLY or RUNDOCKER_OPT_COMPILER_ONLY == "" then
        self:add_mount("/opt", "/opt")
        if dir_exists("/data") then
            self:add_mount("/data", "/data")
        end
    else
        uv.fs_mkdir("/opt/compiler", 493)
        uv.fs_mkdir("/opt/rust", 493)
        self:map("rust")
        self:map("compiler")
        self:map("buildsystems")
        self:map_find("cuda%-.*")
        self:map_find("gcc%-12.*")
        if dir_exists("/data") then
            self:add_mount("/data", "/data")
        end
    end
end

function DockerRunner:run_build(args)
    local HOME = os.getenv("HOME")
    local USER = os.getenv("USER") or read_process("id", {"-un"}):gsub("\n","")
    local UID = os.getenv("UID")
    local DOCKER_IMAGE = os.getenv("DOCKER_IMAGE")

    local podman_args = {
        "run", "--init", "--rm", "-it",
        "--userns=keep-id",
        "-e", "SHELL=bash",
        "-e", "SYSTEM_HOME=" .. HOME,
        "-e", "SYSTEM_NAME=" .. USER,
        "-e", "SYSTEM_UID=" .. UID,
        "--mount", "type=bind,src=" .. HOME .. ",target=/home/" .. USER,
        "-w", self.project_dir
    }

    -- Add mounts
    for _, v in ipairs(self.mount_opt) do
        table.insert(podman_args, v)
    end

    -- Image
    table.insert(podman_args, DOCKER_IMAGE)

    -- Command inside container
    table.insert(podman_args, "cd")
    table.insert(podman_args, self.project_dir)
    table.insert(podman_args, "&&")
    table.insert(podman_args, self.env.PYTHON_BIN)
    table.insert(podman_args, self.script_dir .. "/build.py")

    for _, a in ipairs(args) do
        table.insert(podman_args, a)
    end

    self:run_podman(podman_args)
end

------------------------------------------------------------
-- Example usage
------------------------------------------------------------

local project_dir = arg[1]
local runner = DockerRunner:new(project_dir, project_dir .. "/../python/bin")

runner:load_environment()
runner:prepare_mounts()
runner:run_build({ arg[2], arg[3], arg[4], arg[5], arg[6] })

