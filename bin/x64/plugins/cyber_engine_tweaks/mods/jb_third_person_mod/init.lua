local JB = require("classes/JB.lua")
local Attachment = require("classes/Attachment.lua")
local Gender = require("classes/Gender.lua")

CamView         = {}
CamView.__index = CamView

function CamView:new (pos, rot, camSwitch, freeform)
    local obj = {}
    setmetatable(obj, CamView)

    ----------VARIABLES-------------
    obj.defaultZoomLevel = pos.y
    obj.pos              = pos or Vector4:new(0.0, 0.0, 0.0, 1.0)
    obj.rot              = rot or Quaternion:new(0.0, 0.0, 0.0, 1.0)
    obj.camSwitch        = camSwitch or false
    obj.freeform         = freeform or false
    ----------VARIABLES-------------

   return obj
end

registerForEvent("onInit", function()
	JB.camViews = { -- JUST REMOVE OR ADD CAMS TO YOUR LIKING!
		CamView:new(Vector4:new(0.0, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false, false),   -- Front Camera
		CamView:new(Vector4:new(0.5, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false, false),   -- Left Shoulder Camera
		CamView:new(Vector4:new(-0.5, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false, false),  -- Right Shoulder Camera
		CamView:new(Vector4:new(0.0, 4.0, 0.0, 1.0), Quaternion:new(50.0, 0.0, 4000.0, 1.0), true, false), -- Read Camera
		CamView:new(Vector4:new(0.0, 4.0, 0.0, 1.0), Quaternion:new(50.0, 0.0, 4000.0, 1.0), true, true) -- FreeForm Camera
    }

    print('Jb Third Person Mod Loaded')
end)


registerHotkey("jb_activate_tpp", "Activate/Deactivate Third Person", function()
    if not JB.inCar then
        local PlayerSystem = Game.GetPlayerSystem()
        local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
        local fppCam       = PlayerPuppet:GetFPPCameraComponent()

		fppCam:Activate(2.0, true)
		if(JB.isTppEnabled) then
			JB:DeactivateTPP()
		else
			if(JB.weaponOverride) then
				if(Attachment:HasWeaponActive()) then
					JB.player:SetWarningMessage("Cant go into Third person when holding a weapon, change weaponOverride to false!")
					JB.isTppEnabled = false
					JB:RestoreFPPView()
				else
					JB:ActivateTPP()
				end
			else
				JB:ActivateTPP()
			end
		end
	end
end)

registerHotkey("jb_zoom_in", "Zoom in (no continues press)", function()
	JB:Zoom(0.50)
end)

registerHotkey("jb_zoom_out", "Zoom out (no continues press)", function()
	JB:Zoom(-0.50)
end)
	
registerHotkey("jb_switch_cam", "To next Camera view", function()
	JB:NextCam()
end)

registerHotkey("jb_open_debug", "Open Debug menu", function()
	onOpenDebug = not onOpenDebug
end)

registerHotkey("jb_activate_car_cam", "Activate Car Camera", function()
	if JB.inCar then
		JB.carActivated = true
	end
end)


-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)
    if Game.GetPlayer() then
        JB:CarTimer(deltaTime)
        JB.timerCheckClothes = JB.timerCheckClothes + deltaTime

        JB:CheckForRestoration()

        if JB.carActivated then
            if JB.inCar then
                local PlayerSystem = Game.GetPlayerSystem()
                local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
                local fppCam       = PlayerPuppet:GetFPPCameraComponent()

                carCam = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))
                carCam:Activate(2.0, true)
                Gender.AddTppHead()
                JB.tppHeadActivated = true
                JB.carActivated     = false
            end
        end

        if(JB.switchBackToTpp and not Attachment:HasWeaponActive()) then
            JB:ActivateTPP()
            JB.switchBackToTpp = false
        end
    end
end)

onOpenDebug = false

registerForEvent("onDraw", function()
	if(onOpenDebug) then
		ImGui.SetNextWindowPos(300, 300, ImGuiCond.FirstUseEver)

		if (ImGui.Begin("JB Third Person Mod")) then

	    	clicked = ImGui.Button("Cam to player")
	    	if (clicked) then
				local PlayerSystem = Game.GetPlayerSystem()
				local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
				local fppCam       = PlayerPuppet:GetFPPCameraComponent()
				local carCam       = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))
				carCam:Deactivate(2.0, true)

                print(Dump(fppCam, false))
			end

			clicked = ImGui.Button("Cam to car")
	    	if (clicked) then
	    		local PlayerSystem = Game.GetPlayerSystem()
	    		local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
	    		local fppCam       = PlayerPuppet:GetFPPCameraComponent()
	    		local carCam       = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))
				carCam:Activate(2.0, true)
			end

	    	clicked = ImGui.Button("Reset zoom")
	    	if (clicked) then
	    		JB:ResetZoom()
			end

			clicked = ImGui.Button("weaponOverride true/false")
	    	if (clicked) then
	    		JB.weaponOverride = not JB.weaponOverride
			end

			clicked = ImGui.Button("animatedFace true/false")
	    	if (clicked) then
	    		JB.animatedFace = not JB.animatedFace
			end

			clicked = ImGui.Button("allowCameraBobbing true/false")
	    	if (clicked) then
	    		JB.allowCameraBobbing = not JB.allowCameraBobbing
			end

			ImGui.Text("weaponOverride: " .. tostring(JB.weaponOverride))
	      	ImGui.Text("animatedFace: " .. tostring(JB.animatedFace))
	      	ImGui.Text("allowCameraBobbing: " .. tostring(JB.allowCameraBobbing))
	      	ImGui.Text("---------------------------------------")
	      	ImGui.Text("isTppEnabled: " .. tostring(JB.isTppEnabled))
	      	ImGui.Text("timerCheckClothes: " .. tostring(JB.timerCheckClothes))
	      	ImGui.Text("inCar: " .. tostring(JB.inCar))
	      	ImGui.Text("waitTimer: " .. tostring(JB.waitTimer))
	      	ImGui.Text("waitForCar: " .. tostring(JB.waitForCar))
	      	ImGui.Text("isHeadOn " .. tostring(tostring(JB:GetNameOfObject('TppHead')) == tostring(CName.new('player_fpp_head'))))
	      	ImGui.Text("carCheckOnce: " .. tostring(JB.carCheckOnce))
	      	ImGui.Text("HasWeaponEquipped: " .. tostring(JB.HasWeaponEquipped()))
	      	ImGui.Text("switchBackToTpp: " .. tostring(JB.switchBackToTpp))
	      	ImGui.Text("camActive: " .. tostring(JB.camActive))
	      	ImGui.Text("timeStamp: " .. tostring(JB.timeStamp))
        end
	    ImGui.End()
	end
end)