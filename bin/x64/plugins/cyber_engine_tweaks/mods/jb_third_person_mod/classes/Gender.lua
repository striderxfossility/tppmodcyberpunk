local Item = require("classes/Item.lua")

local Gender         = {}
      Gender.__index = Gender

function Gender:new()
    local class = {}

    ----------VARIABLES-------------

    ----------VARIABLES-------------

    setmetatable( class, Gender )
    return class
end

function Gender:IsFemale()
    return not Gender:IsMale()
end

function Gender:RemoveHead()
    local ts     = Game.GetTransactionSystem()
    local player = Game.GetPlayer()
    ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
end

function Gender:AddTppHead()
    Gender:RemoveHead()

    if Gender:IsMale() then
        Item:Equip("Items.PlayerMaTppHead", "TppHead")
    else
        Item:Equip("Items.PlayerWaTppHead", "TppHead")
    end
end

function Gender:AddFppHead()
    Gender:RemoveHead()
    Item:Equip("Items.PlayerFppHead", "TppHead")
end

function Gender:AddHead(animated, model)
    model = model or false

    if not model then
        Gender:RemoveHead()
        
        if Gender:IsMale() then
            Item:Equip("Items.CharacterCustomizationMaHead", "TppHead")
        else
            Item:Equip("Items.CharacterCustomizationWaHead", "TppHead")
        end
    end
end

function Gender:IsMale()
    local player   = Game.GetPlayer()
    local gender   = tostring(player:GetResolvedGenderName())
    local strfound = string.find(gender, "Female")

    if strfound == nil then
        return true
    end
    
    return false
end

return Gender:new()