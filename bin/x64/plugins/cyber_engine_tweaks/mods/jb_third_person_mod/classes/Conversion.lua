Unpack = table.unpack or unpack

local Conversion         = {}
      Conversion.__index = Conversion

function Conversion:new()
    local class = {}

    ----------VARIABLES-------------

    ----------VARIABLES-------------

    setmetatable( class, Conversion )
    return class
end

function Conversion:CNameToNameString(name)
    local conName = tostring(name)
          conName = self:StringSplit(conName, "--[[ ")[2]
          conName = self:StringSplit(conName, " --]]")[1]

    return conName
end

function Conversion:StringSplit(source, separator, limit)
    if limit == nil then
       limit   = 4294967295
    end
    if limit == 0 then
        return {}
    end
    local out   = {}
    local index = 0
    local count = 0
    if (separator == nil) or (separator == "") then
        while (index < (#source - 1)) and (count < limit) do
            out[count + 1] = self:StringAccess(source, index)
                count      = count + 1
                index      = index + 1
        end
    else
        local separatorLength = #separator
        local nextIndex       = (string.find(source, separator, nil, true) or 0) - 1
        while (nextIndex >= 0) and (count < limit) do
            out[count + 1] = self:StringSubstring(source, index, nextIndex)
                count      = count + 1
                index      = nextIndex + separatorLength
                nextIndex  = (string.find(
                source,
                separator,
                math.max(index + 1, 1),
                true
            ) or 0) - 1
        end
    end
    if count < limit then
        out[count + 1] = self:StringSubstring(source, index)
    end
    return out
end

function Conversion: StringSubstring(self, start, ____end)
    if ____end ~= ____end then
       ____end   = 0
    end
    if (____end ~= nil) and (start > ____end) then
        start, ____end = Unpack({____end, start})
    end
    if start >= 0 then
       start   = start + 1
    else
        start = 1
    end
    if (____end ~= nil) and (____end < 0) then
        ____end = 0
    end
    return string.sub(self, start, ____end)
end

function Conversion:StringAccess(self, index)
    if (index >= 0) and (index < #self) then
        return string.sub(self, index + 1, index + 1)
    end
end

return Conversion:new()