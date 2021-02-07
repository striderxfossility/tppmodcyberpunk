local Item = require("classes/Item.lua")
local Conversion = require("classes/Conversion.lua")

local Attachment = {}
Attachment.__index = Attachment

function Attachment:new()
    local class = {}

    ----------VARIABLES-------------

    ----------VARIABLES-------------

    setmetatable( class, Attachment )
    return class
end

function Attachment:TurnArrayToPerspective(arr, perspective)
    for index, value in ipairs(arr) do
        self:TurnToPerspective(value, perspective)
    end
end

function Attachment:TurnToPerspective(slot, perspective)
    if Item:IsEquipped(slot) then
        local pl = Game.GetPlayer()
        local ts = Game.GetTransactionSystem()
        local slotID = TweakDBID.new(slot)
		local item = ts:GetItemInSlot(pl, slotID)
        local itemName = Conversion:CNameToNameString(tostring(ts:GetItemAppearance(pl, ts:GetItemInSlot(pl, TweakDBID.new(slot)):GetItemID())))
        local other = "FPP"

        if perspective == "FPP" then
            other = "TPP"
        end

        if (string.find(itemName, "&" .. other, nil, true) or 0) - 1 then
            local prefixes = Conversion:StringSplit(itemName, "&")
            local newItemName = ""
            local first = true

            for key, element in pairs(prefixes) do
                if element == other then
                    newItemName = tostring(newItemName) .. ("&" .. perspective)
                else
                    if first then
                        first = false
                        newItemName = tostring(newItemName) .. tostring(element)
                    else
                        newItemName = tostring(newItemName) .. ("&" .. element)
                    end
                end
            end

            spdlog.info("ATTACHMENT: Trying to change " .. slot .. " to " .. perspective .. " with item " .. itemName)
            ts:ChangeItemAppearance(pl,item:GetItemID(),CName.new(newItemName),false)

        else
            spdlog.warning("ATTACHMENT: Attachment is already TPP OR could not find slot " .. slot)
        end
    else
        spdlog.warning("ATTACHMENT: Attachment " .. slot .. " is not equipped")
    end
end

return Attachment:new()