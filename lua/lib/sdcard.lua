local cjson = require("cjson")

local Sdcard = {}
Sdcard.__index = Sdcard

function Sdcard:new()
    return setmetatable({ data = nil }, self)
end

-- Run lsblk and parse JSON
function Sdcard:scan()
    local cmd = "lsblk --json -o TYPE,NAME,PATH,MODEL,TRAN,UUID,MOUNTPOINT,SIZE,PARTTYPENAME,LABEL"
    local p = io.popen(cmd, "r")
    if not p then
        self.data = nil
        return
    end

    local data = p:read("*a")
    p:close()

    if data and #data > 0 then
        self.data = cjson.decode(data)
    else
        self.data = nil
    end
end

-- Static method
function Sdcard.do_match(name)
    if not name or name == "None" then
        return false
    end

    local bad =
        name:find("ata") or
        name:find("nvme") or
        name:find("scsi") or
        name:find("wwn")

    local good =
        name:find("mmc") or
        name:find("usb")

    if bad and not good then
        return false
    end

    return true
end

function Sdcard:select_all()
    if not self.data then
        return nil
    end

    local list = {}
    local bds = self.data.blockdevices or {}

    for _, bd in ipairs(bds) do
        local name = tostring(bd.tran)
        local size = bd.size

        if Sdcard.do_match(name) and size and size ~= "0B" then
            table.insert(list, bd)
        end
    end

    if #list == 0 then
        return nil
    end

    return list
end

function Sdcard:get_selection_list()
    local list = self:select_all()
    if not list then
        return nil
    end

    local selects = {}

    for _, bd in ipairs(list) do
        local name = bd.name or ""
        local tran = bd.tran or ""
        local parttypename = bd.parttypename or ""
        local model = bd.model or ""

        table.insert(selects, string.format("%s: %s, %s (%s)", name, tran, parttypename, model))
    end

    return selects
end

function Sdcard:is_unique()
    local list = self:select_all()
    if not list then
        return true
    end
    return #list == 1
end

function Sdcard:select_unique()
    local list = self:select_all()
    if not list then
        return nil
    end

    if #list > 1 then
        print("ERROR: select_unique is not unique: " .. cjson.encode(list))
        return nil
    end

    if #list == 0 then
        return nil
    end

    local user = os.getenv("USER") or "unknown_user"
    local bd = list[1]
    local childs = bd.children

    local partitions = {}

    if not childs then
        local mp = "/media/" .. user .. "/"
        if bd.label then
            table.insert(partitions, bd.path)
            table.insert(partitions, mp .. bd.label)
        elseif bd.uuid then
            table.insert(partitions, bd.path)
            table.insert(partitions, mp .. bd.uuid)
        end
    else
        for _, child in ipairs(childs) do
            local mp = "/media/" .. user .. "/"
            if child.label then
                table.insert(partitions, child.path)
                table.insert(partitions, mp .. child.label)
            elseif child.uuid then
                table.insert(partitions, child.path)
                table.insert(partitions, mp .. child.uuid)
            end
        end
    end

    return partitions
end

function Sdcard:select_chosen(index)
    local list = self:select_all()
    if not list or #list == 0 then
        return nil
    end

    local user = os.getenv("USER") or "unknown_user"
    local bd = list[index]
    local childs = bd.children
    if not childs then
        return nil
    end

    local partitions = {}
    for _, child in ipairs(childs) do
        local mp = "/media/" .. user .. "/"
        table.insert(partitions, child.path)
        table.insert(partitions, mp .. (child.uuid or ""))
    end

    return partitions
end

function Sdcard:select_device(index)
    local list = self:select_all()
    if not list or #list == 0 then
        return nil
    end

    return tostring(list[index].path)
end

return Sdcard

