local data = require("modules/data")

nd = {
    runtimeData = {
        cetOpen = false,
        inMenu = false,
        inGame = false,
        inWorkSpot = false
    },

    defaultSettings = {},
    settings = {},

    utils = require("modules/utils"),
    input = require("modules/input"),
    Cron = require("modules/Cron"),
    GameUI = require("modules/GameUI")
}

function nd:new()
    registerForEvent("onInit", function()
        nd.drone = require("modules/drone"):new(nd)
        nd.drone.ui.init(nd.drone)

        nd.input.startInputObserver(nd)
        nd.input.startListeners(Game.GetPlayer())

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            nd.runtimeData.inMenu = isInMenu
        end)

        nd.GameUI.OnSessionStart(function()
            nd.runtimeData.inGame = true
            nd.drone:init()
            if not Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer()) and data.getTier() ~= 0 then
                nd.Cron.After(1.0, function ()
                    nd.utils.showInputHint("QuickMelee", "Activate NanoDrone", 1, true)
                end)
                nd.utils.showInputHint("QuickMelee", "Activate NanoDrone", 1, true)
            end
        end)

        nd.GameUI.OnSessionEnd(function()
            nd.runtimeData.inGame = false
            nd.drone:despawn()
            nd.utils.hideCustomHints()
        end)

        nd.runtimeData.inGame = not nd.GameUI.IsDetached() -- Required to check if ingame after reloading all mods

        if nd.runtimeData.inGame and not Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer()) and data.getTier() ~= 0 then
            nd.utils.showInputHint("QuickMelee", "Activate NanoDrone", 1, true)
        end
    end)

    registerForEvent("onUpdate", function(deltaTime)
        if (not nd.runtimeData.inMenu) and nd.runtimeData.inGame then
            if nd.drone.batteryPercent == nil then nd.drone:init() end
            nd.drone:update(deltaTime)
            nd.Cron.Update(deltaTime)
            if Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer()) and not nd.runtimeData.inWorkSpot then
                nd.utils.hideCustomHints()
                nd.runtimeData.inWorkSpot = true
            elseif not Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer()) and nd.runtimeData.inWorkSpot and data.getTier() ~= 0 then
                nd.utils.showInputHint("QuickMelee", "Activate NanoDrone", 1, true)
                nd.runtimeData.inWorkSpot = false
            end
        end

        if nd.drone.ui.runCron then
            nd.Cron.Update(deltaTime)
        end
    end)

    registerForEvent("onShutdown", function ()
        nd.utils.hideCustomHints()
        nd.drone:despawn()
    end)

    registerForEvent("onOverlayOpen", function()
        nd.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        nd.runtimeData.cetOpen = false
    end)

    registerHotkey("nanoDroneSpawn", "Optional spawn key", function()
        if (not nd.runtimeData.inMenu) and nd.runtimeData.inGame then
            nd.drone:spawn()
        end
    end)

    registerInput('nanoDroneW', 'Fly Forward', function(down)
        nd.input.forward = down
        if down then
            nd.input.analogForward = 1
        else
            nd.input.analogForward = 0
        end
    end)

    registerInput('nanoDroneS', 'Fly Backwards', function(down)
        nd.input.backwards = down
        if down then
            nd.input.analogBackwards = 1
        else
            nd.input.analogBackwards = 0
        end
    end)

    registerInput('nanoDroneA', 'Fly Left', function(down)
        nd.input.left = down
        if down then
            nd.input.analogLeft = 1
        else
            nd.input.analogLeft = 0
        end
    end)

    registerInput('nanoDroneD', 'Fly Right', function(down)
        nd.input.right = down
        if down then
            nd.input.analogRight = 1
        else
            nd.input.analogRight = 0
        end
    end)

    registerInput('nanoDroneSpace', 'Fly Up', function(down)
        nd.input.up = down
        if down then
            nd.input.analogUp = 1
        else
            nd.input.analogUp = 0
        end
    end)

    registerInput('nanoDroneShift', 'Fly Down', function(down)
        nd.input.down = down
        if down then
            nd.input.analogDown = 1
        else
            nd.input.analogDown = 0
        end
    end)

    return nd

end

return nd:new()