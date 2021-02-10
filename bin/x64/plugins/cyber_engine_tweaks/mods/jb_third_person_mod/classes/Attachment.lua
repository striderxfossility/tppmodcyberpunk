local Item       = require("classes/Item.lua")
local Conversion = require("classes/Conversion.lua")

local Attachment         = {}
      Attachment.__index = Attachment

function Attachment:new()
    local class = {}

    ----------VARIABLES-------------

    ----------VARIABLES-------------

    setmetatable( class, Attachment )
    return class
end

function Attachment:HasWeaponActive()
    return Item:IsEquipped('AttachmentSlots.WeaponRight')
end

function Attachment:TurnArrayToPerspective(arr, perspective)
    for index, value in ipairs(arr) do
        self:TurnToPerspective(value, perspective)
    end
end

function Attachment:TurnToPerspective(slot, perspective)
    if Item:IsEquipped(slot) then
        local pl       = Game.GetPlayer()
        local ts       = Game.GetTransactionSystem()
        local slotID   = TweakDBID.new(slot)
        local item     = ts:GetItemInSlot(pl, slotID)
        local itemName = Conversion:CNameToNameString(tostring(ts:GetItemAppearance(pl, ts:GetItemInSlot(pl, TweakDBID.new(slot)):GetItemID())))
        local other    = "FPP"

        if perspective == "FPP" then
           other = "TPP"
        end

        if (string.find(itemName, "&" .. other, nil, true) or 0) - 1 then
            local prefixes    = Conversion:StringSplit(itemName, "&")
            local newItemName = ""
            local first       = true

            for key, element in pairs(prefixes) do
                if element == other then
                   newItemName = tostring(newItemName) .. ("&" .. perspective)
                else
                    if first then
                        first       = false
                        newItemName = tostring(newItemName) .. tostring(element)
                    else
                        newItemName = tostring(newItemName) .. ("&" .. element)
                    end
                end
            end

            ts:ChangeItemAppearance(pl,item:GetItemID(),CName.new(newItemName),false)
        end
    end
end

function Attachment:GetNameOfObject(slot)
    local pl = Game.GetPlayer()
    local ts = Game.GetTransactionSystem()
    if(Item:IsEquipped(slot)) then
		local slotID = TweakDBID.new(slot)
		local item   = ts:GetItemInSlot(pl, slotID)
		local data   = ts:GetItemData(pl, item:GetItemID())

		return Conversion:CNameToNameString(data:GetName())
	end

	return ''
end

return Attachment:new()