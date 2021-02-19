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
    obj.pos              = pos or Vector4.new(0.0, 0.0, 0.0, 1.0)
    obj.rot              = rot or Quaternion.new(0.0, 0.0, 0.0, 1.0)
    obj.camSwitch        = camSwitch or false
    obj.freeform         = freeform or false
    ----------VARIABLES-------------

   return obj
end

registerForEvent("onInit", function()
    Observe("vehicleCarBaseObject", "OnVehicleFinishedMounting", function (self)
        if Game['GetMountedVehicle;GameObject'](Game.GetPlayer()) ~= nil then
            JB.inCar = Game['GetMountedVehicle;GameObject'](Game.GetPlayer()):IsPlayerDriver()
        else
            JB.inCar = false
        end
	end)
    
	for row in db:rows("SELECT * FROM cameras") do
		local vec4 = Vector4.new(tonumber(row[2]), tonumber(row[3]), tonumber(row[4]), 1.0)
		local quat = Quaternion.new(tonumber(row[6]), tonumber(row[7]), tonumber(row[8]), 1.0)
		local camSwitch = false
        local freeform = false
		
		if row[10] == 1 then
			camSwitch = true
        end

        if row[11] == 1 then
            freeform = true
        end

		local cam  = CamView:new(vec4, quat, camSwitch, freeform)

		table.insert(JB.camViews, cam)
	end

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
					JB:SetEnableTPPValue(false)
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

registerHotkey("jb_optional_cam_left", "Optional: Move cam left", function()
	JB:MoveHorizontal(-0.20)
end)

registerHotkey("jb_optional_cam_right", "Optional: Move cam right", function()
	JB:MoveHorizontal(0.20)
end)

registerHotkey("jb_optional_cam_up", "Optional: Move cam up", function()
	JB:MoveVertical(0.20)
end)

registerHotkey("jb_optional_cam_down", "Optional: Move cam down", function()
	JB:MoveVertical(-0.20)
end)

registerHotkey("jb_optional_cam_rot_x", "Optional: Move cam rotation i", function()
	JB:MoveRotX(0.05)
end)

registerHotkey("jb_optional_cam_rot_y", "Optional: Move cam rotation j", function()
	JB:MoveRotY(0.05)
end)

registerHotkey("jb_optional_cam_rot_z", "Optional: Move cam rotation k", function()
	JB:MoveRotZ(0.05)
end)

registerHotkey("jb_optional_cam_rot_x_back", "Optional: Move cam rotation i back", function()
	JB:MoveRotX(-0.05)
end)

registerHotkey("jb_optional_cam_rot_y_back", "Optional: Move cam rotation j back", function()
	JB:MoveRotY(-0.05)
end)

registerHotkey("jb_optional_cam_rot_z_back", "Optional: Move cam rotation k back", function()
	JB:MoveRotZ(-0.05)
end)


-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)
    if Game.GetPlayer() then
        JB:CarTimer(deltaTime)
        JB.timerCheckClothes = JB.timerCheckClothes + deltaTime

        JB:CheckForRestoration(deltaTime)

        if JB.carActivated then
            if JB.inCar then
                local PlayerSystem = Game.GetPlayerSystem()
                local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
                local fppCam       = PlayerPuppet:GetFPPCameraComponent()

                carCam = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))
                carCam:Activate(2.0, true)
                --Gender.AddTppHead()
                JB.tppHeadActivated = true
                JB.carActivated     = false
            end
        end

        if JB.isTppEnabled and not JB.inCar then
            local PlayerSystem = Game.GetPlayerSystem()
            local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
            local ts = Game.GetTransactionSystem()
        
            local slotID = TweakDBID.new('AttachmentSlots.TppHead')
            local item = ts:GetItemInSlot(PlayerPuppet, slotID)
        
            if Gender:IsFemale() then
                seamfix = PlayerPuppet:FindComponentByName(CName.new("t0_000_pwa_base__full_seamfix"))
            else
                seamfix = PlayerPuppet:FindComponentByName(CName.new("t0_000_pma_base__full_seamfix"))
            end
            
            seamfix:Toggle(false)
        end
    end
end)

onOpenDebug = false

registerForEvent("onDraw", function()
	if(onOpenDebug) then
		ImGui.SetNextWindowPos(300, 300, ImGuiCond.FirstUseEver)

		if (ImGui.Begin("JB Third Person Mod")) then

            clicked = ImGui.Button("Toggle (front) player light on/of")
	    	if (clicked) then
				local PlayerSystem = Game.GetPlayerSystem()
				local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
                local light = PlayerPuppet:FindComponentByName(CName.new("TEMP_flashlight"))

                if light:IsEnabled() then
                    light:Toggle(false)
                else
                    light:Toggle(true)
                end
			end

            clicked = ImGui.Button("DEBUG")
	    	if (clicked) then
                local PlayerSystem = Game.GetPlayerSystem()
				local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
				local fppTorso = PlayerPuppet:FindComponentByName(CName.new("t0_000_pwa_fpp__torso"))
                local tppTorso = PlayerPuppet:FindComponentByName(CName.new("body"))

                if fppTorso.isEnabled then
                    fppTorso:Toggle(false)
                    tppTorso:Toggle(true)
                else
                    fppTorso:Toggle(true)
                    tppTorso:Toggle(false)
                end
			end

	    	clicked = ImGui.Button("Cam to player")
	    	if (clicked) then
				local PlayerSystem = Game.GetPlayerSystem()
				local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
				local fppCam       = PlayerPuppet:GetFPPCameraComponent()
				local carCam       = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))
				carCam:Deactivate(2.0, true)
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
				db:exec("UPDATE settings SET value = " .. tostring(JB.weaponOverride) .. " WHERE name = 'weaponOverride'")
			end

			clicked = ImGui.Button("animatedFace true/false")
	    	if (clicked) then
	    		JB.animatedFace = not JB.animatedFace
				db:exec("UPDATE settings SET value = " .. tostring(JB.animatedFace) .. " WHERE name = 'animatedFace'")
			end

			clicked = ImGui.Button("allowCameraBobbing true/false")
	    	if (clicked) then
	    		JB.allowCameraBobbing = not JB.allowCameraBobbing
				db:exec("UPDATE settings SET value = " .. tostring(JB.allowCameraBobbing) .. " WHERE name = 'allowCameraBobbing'")
			end

			ImGui.Text("weaponOverride: " .. tostring(JB.weaponOverride))
	      	ImGui.Text("animatedFace: " .. tostring(JB.animatedFace))
	      	ImGui.Text("allowCameraBobbing: " .. tostring(JB.allowCameraBobbing))
	      	ImGui.Text("---------------------------------------")
	      	ImGui.Text("isTppEnabled: " .. tostring(JB.isTppEnabled))
	      	ImGui.Text("timerCheckClothes: " .. tostring(JB.timerCheckClothes))
	      	ImGui.Text("inCar: " .. tostring(JB.inCar))
		ImGui.Text("inScene: " .. tostring(JB.inScene))
	      	ImGui.Text("waitTimer: " .. tostring(JB.waitTimer))
	      	ImGui.Text("waitForCar: " .. tostring(JB.waitForCar))
	      	ImGui.Text("Head " .. tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')))
	      	ImGui.Text("carCheckOnce: " .. tostring(JB.carCheckOnce))
	      	--ImGui.Text("HasWeaponEquipped: " .. tostring(JB:HasWeaponEquipped()))
	      	ImGui.Text("switchBackToTpp: " .. tostring(JB.switchBackToTpp))
	      	ImGui.Text("camActive: " .. tostring(JB.camActive))
	      	ImGui.Text("timeStamp: " .. tostring(JB.timeStamp))
        end
	    ImGui.End()
	end
end)