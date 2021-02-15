local Attachment = require("classes/Attachment.lua")
local timerCheckClothes = 0.0

-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)
    if Game.GetPlayer() then
        timerCheckClothes = timerCheckClothes + deltaTime

        if(timerCheckClothes > 2.0) then

            local script       = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
            local photoMode    = script:GetPhotoModeSystem(script)

            if not photoMode:IsPhotoModeActive() then
                Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
            end 
            
            timerCheckClothes = 0.0
        end

    end
end)