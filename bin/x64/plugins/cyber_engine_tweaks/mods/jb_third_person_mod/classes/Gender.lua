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

function Gender:AddTppHead()
    if Gender:IsMale() then
         Item:Equip("Items.PlayerMaTppHead", "TppHead")
    else
        Item:Equip("Items.PlayerWaTppHead", "TppHead")
    end
end

function Gender:AddHead(animated)
    if Gender:IsMale() then
        if animated then
            Item:Equip("Items.CharacterCustomizationMaHead", "TppHead")
        else
            Item:Equip("Items.PlayerMaPhotomodeHead", "TppHead")
        end
    else
        if animated then
            Item:Equip("Items.CharacterCustomizationWaHead", "TppHead")
        else
            Item:Equip("Items.PlayerWaPhotomodeHead", "TppHead")
        end
    end
end

function Gender:IsMale()
    local player   = Game.GetPlayer()
    local gender   = tostring(player:GetResolvedGenderName())
    local strfound = string.find(gender, "Female")

    spdlog.info("Gender: found gender string = " .. gender .. " RESULTS = " .. strfound)

    if strfound == nil then
        return true
    end
    
    return false
end

return Gender:new()