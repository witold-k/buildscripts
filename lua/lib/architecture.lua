-- Architecture "enum"
local Architecture = {
    DEFAULT     = 1,
    UNKNOWN     = 2,
    ALPHA       = 3,
    AMD64       = 4,
    ARM         = 5,
    AARCH64     = 6,
    AVR32       = 7,
    BFIN        = 8,
    CRIS        = 9,
    FRV         = 10,
    IA64        = 11,
    M32R        = 12,
    M68K        = 13,
    METAG       = 14,
    MICORBLAZE  = 15,
    MIPS        = 16,
    MIPS64      = 17,
    MOXIE       = 18,
    PA          = 19,
    POWERPC     = 20,
    S390        = 21,
    SH          = 22,
    SH64        = 23,
    SPARC       = 24,
    TILE        = 25,
    X86         = 26,
    X86_32      = 27,
    X86_64      = 28,
    XTENSA      = 29
}

-- Reverse lookup: number → name
local name_by_value = {}
for k, v in pairs(Architecture) do
    name_by_value[v] = k
end

-- Convert string to enum
function Architecture.from_name(name)
    local ustr = string.upper(name)
    local maxlen = 0
    local hit = Architecture.UNKNOWN

    for arch_name, value in pairs(Architecture) do
        if string.find(ustr, arch_name, 1, true) then
            if arch_name ~= "UNKNOWN" and #arch_name > maxlen then
                hit = value
                maxlen = #arch_name
            end
        end
    end

    return hit
end

-- Detect native architecture using `uname -m`
function Architecture.from_native()
    local handle = io.popen("/usr/bin/uname -m")
    if not handle then
        return Architecture.UNKNOWN
    end

    local result = handle:read("*l")
    handle:close()

    if result then
        return Architecture.from_name(result)
    end

    return Architecture.UNKNOWN
end

-- Select directory matching native architecture
function Architecture.select_native_from_dir(path)
    local native = Architecture.from_native()

    for entry in io.popen('ls -1 "' .. path .. '"'):lines() do
        local fullpath = path .. "/" .. entry
        local attr = io.popen('test -d "' .. fullpath .. '" && echo dir'):read("*l")

        if attr == "dir" then
            local arch = Architecture.from_name(entry)
            if arch == native then
                return entry
            end
        end
    end

    return ""
end

return Architecture

