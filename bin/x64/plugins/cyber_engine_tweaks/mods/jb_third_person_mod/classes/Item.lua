local Item         = {}
      Item.__index = Item

function Item:new()
    local class = {}

    ----------VARIABLES-------------

    ----------VARIABLES-------------

    setmetatable( class, Item )
    return class
end

function Item:IsEquipped(slot)
    local ts = Game.GetTransactionSystem()
    local pl = Game.GetPlayer()
    
    if(ts:GetItemInSlot(pl, TweakDBID.new(slot)) ~= nil) then
        return true
    end

    return false
end

function Item:AddToInventory(name)
    local gameItemID = GetSingleton('gameItemID')
    local tdbid      = TweakDBID.new(name)
    local itemID     = gameItemID:FromTDBID(tdbid)
    local player     = Game.GetPlayer()
    local ts         = Game.GetTransactionSystem()

    if(ts:HasItem(player, itemID) == false) then
        spdlog.info("ITEM: added item to inventory " .. name)
        Game.AddToInventory(name, 1)
    end
end

function Item:Equip(name, slot)
    spdlog.info("ITEM: item " .. name .. " equipped on " .. slot)
    Item:AddToInventory(name)
    Game.EquipItemOnPlayer(name, slot)
end

return Item:new()