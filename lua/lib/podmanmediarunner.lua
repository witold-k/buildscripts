-- PodmanRunner.lua
local PodmanRunner = {}
PodmanRunner.__index = PodmanRunner

local APP_DIR = "/home/gamer/app"

function PodmanRunner:new(volumeMapper, opts)
    if not volumeMapper then
        error("PodmanRunner: volumeMapper must not be nil")
    end

    opts = opts or {}
    return setmetatable({
        volumeMapper = volumeMapper,
        script_entry = opts.script_entry or "bash",
        app_mount_template = opts.app_mount_template or "%s/tmp/%s",
        image = opts.image or "media:latest"
    }, self)
end

function PodmanRunner:build_cmd(opts)
    if not self.volumeMapper then
        error("PodmanRunner: volumeMapper must not be nil")
    end

    opts = opts or {}
    local NAME            = opts.NAME
    local MUID            = opts.MUID
    local MGID            = opts.MGID
    local PACKAGE         = opts.PACKAGE
    local SCRIPT_DIR      = opts.SCRIPT_DIR
    local XDG_RUNTIME_DIR = opts.XDG_RUNTIME_DIR
    local mount_user      = opts.mount_user or ""
    local extra_paths     = opts.extra_paths or {}
    local workdir = opts.workdir and ("--workdir " .. opts.workdir) or ""

    -- Volume mappings
    local volumes = self.volumeMapper:map(extra_paths)
    local volumes_part = (volumes ~= "" and (volumes .. " ")) or ""

    -- App mount
    local app_mount_host = string.format(self.app_mount_template, SCRIPT_DIR, PACKAGE)

    -- Build command
    local cmd = string.format([[
podman run --rm -it \
  --name %s \
  --user %s:%s \
  --userns=keep-id %s \
  --replace \
  --network=host \
  --tz=local \
  -e APP_BIN=./%s \
  -e XDG_RUNTIME_DIR=%s \
  %s\
  -v /opt:/opt:ro \
  -v %s:%s \
  %s %s
]],
        NAME,
        MUID, MGID,
        workdir,
        PACKAGE,
        XDG_RUNTIME_DIR,
        volumes_part,
        XDG_RUNTIME_DIR, XDG_RUNTIME_DIR,
        self.image,
        self.script_entry
    )
    -- print(cmd)
    return cmd:gsub("^%s+", ""):gsub("%s+$", "")
end

-- creates command and executes it
-- returns output of command
function PodmanRunner:run(opts)
    if not self.volumeMapper then
        error("PodmanRunner: volumeMapper must not be nil")
    end

    local cmd = self:build_cmd(opts)
    return os.execute(cmd)
end

return PodmanRunner

