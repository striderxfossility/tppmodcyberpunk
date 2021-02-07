local Item = {}
Item.__index = Item

function Item:new()
    local class = {}
    print("test")

    ----------VARIABLES-------------


    ----------VARIABLES-------------

    setmetatable( class, Item )
    return class
end

function Item:AddToInventory(name)
    local gameItemID = GetSingleton('gameItemID')
    local tdbid = TweakDBID.new(name)
    local itemID = gameItemID:FromTDBID(tdbid)
    local player = Game.GetPlayer()
    local ts = Game.GetTransactionSystem()

    if(ts:HasItem(player, itemID) == false) then
        spdlog.info("ITEM: added item to inventory " .. name)
        Game.AddToInventory(name, 1)
    end
end

function Item:Equip(name, slot)
    Item:AddToInventory(name)
    Game.EquipItemOnPlayer(name, slot)
end

return Item:new()