local JB 			= require("classes/JB.lua")
local Attachment 	= require("classes/Attachment.lua")
local Gender 		= require("classes/Gender.lua")
local Cron 			= require("classes/Cron.lua")
local GameSession 	= require('classes/GameSession.lua')
local Ref        	= require("classes/Ref.lua")

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
	local speed = 8

	-- FIX CRASH LOAD SAVE
	GameSession.Listen(function(state)
		if state.event == "Clean" then
			JB.isInitialized   = false
			JB.secondCam       = nil
			JB.foundJohnnyEnt  = false
			JB.johnnyEntId     = nil
			exEntitySpawner.Despawn(JB.johnnyEnt)
			JB.johnnyEnt       = nil
		end
    end)

	JB.isInitialized = Game.GetPlayer() and Game.GetPlayer():IsAttached() and not Game.GetSystemRequestsHandler():IsPreGame()

	Observe('QuestTrackerGameController', 'OnInitialize', function()
		if not isLoaded then
			JB.isInitialized = true
		end
	end)

	Observe('QuestTrackerGameController', 'OnUninitialize', function()
		if Game.GetPlayer() == nil then
			JB.isInitialized   = false
		end
	end)

    Observe("vehicleCarBaseObject", "OnVehicleFinishedMounting", function (self)
        if Game['GetMountedVehicle;GameObject'](Game.GetPlayer()) ~= nil then
            JB.inCar = Game['GetMountedVehicle;GameObject'](Game.GetPlayer()):IsPlayerDriver()
			if Game.GetPlayer():FindVehicleCameraManager():IsTPPActive() then
				Gender:AddHead(JB.animatedFace)
			end
        else
            JB.inCar = false
        end
	end)

	Observe('PlayerPuppet', 'OnAction', function(self, action)
		if JB.isInitialized then
			if not IsPlayerInAnyMenu() then
				local actionName  = Game.NameToString(ListenerAction.GetName(action))
				local actionValue = ListenerAction.GetValue(action)
				local actionType  = action:GetType(action).value

				if actionName == "mouse_wheel" then
					JB:Zoom(actionValue)
				end

				if actionName == "Right" or actionName == "Left" or actionName == "Forward" or actionName == "Back" then
					JB.isMoving = true
				end

				if actionName == 'mouse_y' then
					JB.yroll = 0.008 * actionValue
					JB.moveHorizontal = true
				end

				if actionName == 'mouse_x' then
					JB.moveHorizontal = true
					JB.xroll = 0.025 * actionValue
				end

				if actionName == 'world_map_menu_move_vertical' then
					JB.isMoving = true
					if actionValue >= 0 then
						speed = 1 + actionValue * 8
					else
						speed = 1 + actionValue * 8
					end
				end

				if actionName == 'world_map_menu_move_horizontal' and JB.directionalMovement and JB.isTppEnabled and not JB.inCar then
					JB.isMoving = true
					JB.moveHorizontal = true

					if not JB.directionalStaticCamera then
						JB.xroll = -actionValue * 0.87 * -JB.camViews[JB.camActive].pos.y
					end

					if speed < 8 then
						speed = 8
					end

					local moveEuler = EulerAngles.new(0, 0, Game.GetPlayer():GetWorldYaw() - actionValue * -JB.camViews[JB.camActive].pos.y * 2)
					Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), Game.GetPlayer():GetWorldPosition(), moveEuler)
				end
			end
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

	-- FIX CRASH RELOAD ALL MODS
	local arr = JB:GetPlayerObjects()
	for _, v in ipairs(arr) do
		local obj = v:GetComponent(v):GetEntity()

		if obj:GetClassName() == CName.new("PlayerPuppet") then
			if obj.audioResourceName == CName.new("johnnysecondcam") then
				JB.foundJohnnyEnt 	= true
				JB.johnnyEntId 		= obj:GetEntityID()
				JB.johhnyEnt 		= obj
				JB.secondCam 		= Ref.Weak(JB.johhnyEnt:FindComponentByName(CName.new("camera")))
				break
			end
		end
	end

end)

registerInput('jb_hold_360_cam', 'Hold to activate 360 camera', function(isDown)
	if (isDown) then
	  	JB.directionalMovement = true
	else
		JB.directionalMovement = false
	end
  end)

registerHotkey("jb_activate_tpp", "Activate/Deactivate Third Person", function()
	local PlayerSystem = Game.GetPlayerSystem()
	local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()

	if(JB.isTppEnabled) then
		Cron.After(1.0, function()
			local ts     = Game.GetTransactionSystem()
			local player = Game.GetPlayer()
			ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
			Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
		end)
		JB:DeactivateTPP(false)
	else
		if(JB.weaponOverride) then
			if(Attachment:HasWeaponActive()) then
				PlayerPuppet:SetWarningMessage("Cant go into Third person when holding a weapon, change weaponOverride to false!")
				JB:SetEnableTPPValue(false)
				JB:RestoreFPPView()
			else
				JB:ActivateTPP()
			end
		else
			JB:ActivateTPP()
		end
	end

	JB:UpdateSecondCam()
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
    if JB.isInitialized then
		if not IsPlayerInAnyMenu() then
			if not (JB.johnnyEntId ~= nil) then
				print("Jb Third Person Mod: Spawned second camera")
				JB.johnnyEntId = exEntitySpawner.Spawn([[base\characters\entities\player\replacer\johnny_silverhand_replacer.ent]], Game.GetPlayer():GetWorldTransform())
			end

			JB:UpdateSecondCam()

			local PlayerSystem = Game.GetPlayerSystem()
			local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
			local fppCam       = PlayerPuppet:GetFPPCameraComponent()

			if not PlayerPuppet:FindVehicleCameraManager():IsTPPActive() == JB.previousPerspective then
				if PlayerPuppet:FindVehicleCameraManager():IsTPPActive() then
					Gender:AddHead(JB.animatedFace)
					Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "TPP")
				else
					Gender:AddFppHead()
					Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
				end
			else
				JB.onChangePerspective = false
			end

			JB.previousPerspective 	= PlayerPuppet:FindVehicleCameraManager():IsTPPActive()
			JB.timerCheckClothes 	= JB.timerCheckClothes + deltaTime
			
			JB:CheckForRestoration(deltaTime)

			if JB.carActivated then
				if JB.inCar then
					carCam = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))
					carCam:Activate(2.0, true)
					JB.tppHeadActivated = true
					JB.carActivated     = false
				end
			end

			JB.isMoving = false

			Cron.Update(deltaTime)
		end
	end
end)

function IsPlayerInAnyMenu()
    blackboard = Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().UI_System);
    uiSystemBB = (Game.GetAllBlackboardDefs().UI_System);
    return(blackboard:GetBool(uiSystemBB.IsInMenu));
end

onOpenDebug = false

registerForEvent("onDraw", function()
	if(onOpenDebug) then
		if Game.GetPlayer() then
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

	            	clicked = ImGui.Button("Player using Model Mod (head)")
		    	if (clicked) then
				JB.ModelMod = not JB.ModelMod
				db:exec("UPDATE settings SET value = " .. tostring(JB.ModelMod) .. " WHERE name = 'ModelMod'")
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

			clicked = ImGui.Button("Reset cameras")
		    	if (clicked) then
				print("resetting cameras...")
	                	db:exec("UPDATE cameras SET x = 0, y = -2, z=-0, rx=0, ry=0, rz=0  WHERE id = 0")
				db:exec("UPDATE cameras SET x = 0.5, y = -2, z=-0, rx=0, ry=0, rz=0  WHERE id = 1")
				db:exec("UPDATE cameras SET x = -0.5, y = -2, z=-0, rx=0, ry=0, rz=0  WHERE id = 2")
				db:exec("UPDATE cameras SET x = 0, y = 4, z=-0, rx=50, ry=0, rz=4000  WHERE id = 3")
				db:exec("UPDATE cameras SET x = 0, y = 4, z=-0, rx=50, ry=0, rz=4000  WHERE id = 4")

				JB:DeactivateTPP()

				print("done!")
			end

		    	clicked = ImGui.Button("Reset zoom")
		    	if (clicked) then
		    		JB:ResetZoom()
				end

				clicked = ImGui.Button("Static camera true/false")
		    	if (clicked) then
		    		JB.directionalStaticCamera = not JB.directionalStaticCamera
					db:exec("UPDATE settings SET value = " .. tostring(JB.directionalStaticCamera) .. " WHERE name = 'directionalStaticCamera'")
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

				local PlayerSystem = Game.GetPlayerSystem()
	    		local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
	    		local fppCam       = PlayerPuppet:GetFPPCameraComponent()
	    		local carCam       = fppCam:FindComponentByName(CName.new("vehicleTPPCamera"))

				ImGui.Text("directionalMovement: " .. tostring(JB.directionalMovement))
				ImGui.Text("directionalStaticCamera: " .. tostring(JB.directionalStaticCamera))
				ImGui.Text("weaponOverride: " .. tostring(JB.weaponOverride))
		      	ImGui.Text("animatedFace: " .. tostring(JB.animatedFace))
		      	ImGui.Text("allowCameraBobbing: " .. tostring(JB.allowCameraBobbing))
	            ImGui.Text("Player using Model Mod (head): " .. tostring(JB.ModelMod))
		      	ImGui.Text("---------------------------------------")
		      	ImGui.Text("isTppEnabled: " .. tostring(JB.isTppEnabled))
		      	ImGui.Text("timerCheckClothes: " .. tostring(JB.timerCheckClothes))
		      	ImGui.Text("inCar: " .. tostring(JB.inCar))
				ImGui.Text("inScene: " .. tostring(JB.inScene))
		      	ImGui.Text("waitTimer: " .. tostring(JB.waitTimer))
		      	ImGui.Text("waitForCar: " .. tostring(JB.waitForCar))
		      	ImGui.Text("Head " .. tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')))
		      	ImGui.Text("carCheckOnce: " .. tostring(JB.carCheckOnce))
		      	ImGui.Text("switchBackToTpp: " .. tostring(JB.switchBackToTpp))
		      	ImGui.Text("camActive: " .. tostring(JB.camActive))
		      	ImGui.Text("timeStamp: " .. tostring(JB.timeStamp))
		      	ImGui.Text("headingLocked: " .. tostring(fppCam.headingLocked))
				ImGui.Text("test: " .. tostring(test))
	        end
		    ImGui.End()
		end
	end
end)