local JB 				= require("classes/JB.lua")
local Attachment 		= require("classes/Attachment.lua")
local Gender 			= require("classes/Gender.lua")
local Cron 				= require("classes/Cron.lua")
local GameSession 		= require('classes/GameSession.lua')
local Ref        		= require("classes/Ref.lua")
local GameSettings  	= require('classes/GameSettings.lua')
local nativeSettings 	= nil
local ev 				= nil

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
	nativeSettings = GetMod("nativeSettings")

	if nativeSettings ~= nil then
		nativeSettings.addTab("/jb_tpp", "JB Third Person Mod")
		nativeSettings.addSubcategory("/jb_tpp/settings", "Settings")
		nativeSettings.addSubcategory("/jb_tpp/tpp", "Third Person Camera")
		nativeSettings.addSubcategory("/jb_tpp/patches", "Patches")

		nativeSettings.addSwitch("/jb_tpp/settings", "Weapon override", "Activate first person camera when equiping weapon", JB.weaponOverride, true, function(state)
			JB.weaponOverride = state
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/settings", "Eye movements", "Your player is checking out other npc's!", JB.eyeMovement, true, function(state)
			JB.eyeMovement = state
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/tpp", "Inverted camera", "", JB.inverted, false, function(state)
			JB.inverted = state
			JB.updateSettings = true
		end)

		nativeSettings.addRangeInt("/jb_tpp/tpp", "Horizontal Sensitivity only 360 camera", "Determines how quickly the camera moves on the horizontal axis", 1, 30, 1, JB.horizontalSen, 5, function(value)
			JB.horizontalSen = value
			JB.updateSettings = true
		end)

		nativeSettings.addRangeInt("/jb_tpp/tpp", "Vertical Sensitivity", "Determines how quickly the camera moves on the vertical axis", 1, 30, 1, JB.verticalSen, 5, function(value)
			JB.verticalSen = value
			JB.updateSettings = true
		end)

		nativeSettings.addRangeInt("/jb_tpp/tpp", "Field of view", "", 50, 120, 1, JB.fov, 80, function(value)
			JB.fov = value
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/patches", "Model head", "Patch for player replacer (activating head)", JB.ModelMod, false, function(state)
			JB.ModelMod = state
			JB.updateSettings = true
		end)
	end

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

	Override('VehicleSystem', 'IsSummoningVehiclesRestricted;GameInstance', function()
		return false
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

				--if actionName == "mouse_wheel" then
				--	JB:Zoom(actionValue / 2)
				--end

				if actionName == "right_trigger" and JB.controllerZoom then -- CONTROLLER
					JB:Zoom(0.1)
				end

				if actionName == "left_trigger" and JB.controllerZoom then -- CONTROLLER
					JB:Zoom(-0.1)
				end

				if actionName == "right_trigger" and JB.controller360 then -- CONTROLLER
					JB.controllerRightTrigger = true
				end

				if actionName == "left_trigger" and JB.controller360 then -- CONTROLLER
					JB.controllerLeftTrigger = true
				end

				if actionName == "Right" or actionName == "Left" or actionName == "Forward" or actionName == "Back" then
					JB.isMoving = true
				end

				if actionName == 'mouse_y' then
					JB.yroll = (actionValue / 4)  /  (30 / JB.verticalSen)
					JB.moveHorizontal = true
				end

				if actionName == 'right_stick_y' then -- CONTROLLER
					JB.yroll = actionValue
					JB.moveHorizontal = true
				end

				if actionName == 'mouse_x' or actionName == 'right_stick_x' then
					JB.moveHorizontal = true
					JB.xroll = (actionValue / 4) /  (30 / JB.horizontalSen)
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
	local PlayerSystem = Game.GetPlayerSystem()
    local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
    local fppCam       = PlayerPuppet:GetFPPCameraComponent()

	if (isDown) then
	  	JB.directionalMovement = true

		if not JB.inScene then
			fppCam.headingLocked = true
		end
	else
		JB.directionalMovement = false

		if not JB.inScene then
			fppCam.headingLocked = false
		end
	end
end)

registerInput('jb_zoom_in', 'Zoom in', function(isDown)
	if isDown then
		JB.zoomIn = true
	else
		JB.zoomIn = false
	end
end)

registerInput('jb_zoom_out', 'Zoom out', function(isDown)
	if isDown then
		JB.zoomOut = true
	else
		JB.zoomOut = false
	end
end)

registerInput('jb_move_camera', 'Move Camera', function(isDown)
	local PlayerSystem = Game.GetPlayerSystem()
    local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
    local fppCam       = PlayerPuppet:GetFPPCameraComponent()

	if isDown then
		JB.moveCamera = true

		if not JB.inScene then
			fppCam.headingLocked = true
		end
	else
		JB.moveCamera = false

		if not JB.inScene then
			fppCam.headingLocked = false
		end
	end
end)

registerHotkey("jb_activate_tpp", "Activate/Deactivate Third Person", function()
	local PlayerSystem = Game.GetPlayerSystem()
	local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()

	if JB.foundJohnnyEnt == false then
		PlayerPuppet:SetWarningMessage("JB Third person mod not loaded yet!")
		return;
	end

	if(JB.isTppEnabled) then
		Cron.After(1.5, function()
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

registerHotkey("jb_controller_zoom_activate", "Controller: Activate zoom", function()
	JB.controllerZoom = not JB.controllerZoom
end)

registerHotkey("jb_controller_360", "Controller: Activate 360 camera", function()
	JB.controller360 = not JB.controller360
end)

registerHotkey("jb_reset", "Reset cameras", function()
	JB.camViews[1].pos 	= Vector4.new(0, -2, 0, 1)
	JB.camViews[1].rot = Quaternion.new(0, 0, 0, 1)
	JB.camViews[2].pos 	= Vector4.new(0.5, -2, 0, 1)
	JB.camViews[2].rot = Quaternion.new(0, 0, 0, 1)
	JB.camViews[3].pos 	= Vector4.new(-0.5, -2, 0, 1)
	JB.camViews[3].rot = Quaternion.new(0, 0, 0, 1)
	JB.camViews[4].pos 	= Vector4.new(0, -2, 0, 1)
	JB.camViews[4].rot = Quaternion.new(0, 0, 0, 1)
	JB.camViews[5].pos 	= Vector4.new(0, -2, 0, 1)
	JB.camViews[5].rot = Quaternion.new(0, 0, 0, 1)

	JB.secondCam:SetLocalOrientation(JB.camViews[JB.camActive].rot)
	JB.secondCam:SetLocalPosition(JB.camViews[JB.camActive].pos)
	
	JB.updateSettings = true
end)

registerHotkey("jb_reset_zoom", "Reset zoom", function()
	JB:ResetZoom()
end)

-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)
    if JB.isInitialized then
		if not IsPlayerInAnyMenu() then

			if not (JB.johnnyEntId ~= nil) then
				print("Jb Third Person Mod: Spawned second camera")
				JB.johnnyEntId = exEntitySpawner.Spawn([[base\characters\entities\player\replacer\johnny_silverhand_replacer.ent]], Game.GetPlayer():GetWorldTransform())
			end

			if ev == nil then
				ev = LookAtAddEvent.new()
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

			if ev ~= nil then
				if JB.eyeMovement then
					EyesFollowCamera(deltaTime)
				end
			end
		end
	end
end)

function EyesFollowCamera(deltaTime)
	if JB.eyesTimer <= 0 then
		local arr = JB:GetEYEObjects()
		for _, v in ipairs(arr) do
			local obj = v:GetComponent(v):GetEntity()
			if obj:GetClassName() == CName.new("NPCPuppet") then
				ev:SetEntityTarget(obj, CName.new('pla_default_tgt'), GetSingleton('Vector4'):EmptyVector())
				ev.SetStyle = Enum.new('animLookAtStyle', 2)
				ev.bodyPart = CName.new('Eyes')
				ev.request.limits.softLimitDegrees = 360.00;
				ev.request.limits.hardLimitDegrees = 270.00;
				ev.request.limits.backLimitDegrees = 210.00;
				ev.request.calculatePositionInParentSpace = true

				Game.GetPlayer():QueueEvent(ev)
				JB.eyesTimer = 15
				break
			end
		end
	end

	JB.eyesTimer = JB.eyesTimer - deltaTime
end

function IsPlayerInAnyMenu()
	if Game.GetSystemRequestsHandler():IsGamePaused() then
        return true
    end

    local blackboard = Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().UI_System);
    local uiSystemBB = (Game.GetAllBlackboardDefs().UI_System);
    return(blackboard:GetBool(uiSystemBB.IsInMenu));
end

onOpenDebug = false

registerForEvent("onDraw", function()
	if onOpenDebug then
		if Game.GetPlayer() then
			ImGui.SetNextWindowPos(300, 300, ImGuiCond.FirstUseEver)

			if (ImGui.Begin("JB Third Person Mod DEBUG MENU")) then

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Settings")

				value, pressedWeaponOverride = ImGui.Checkbox("Weapon Override", JB.weaponOverride)

				if pressedWeaponOverride then
					JB.weaponOverride = value
					JB.updateSettings = true
				end

				value, pressedEyeMovement = ImGui.Checkbox("Eye movements", JB.eyeMovement)

				if pressedEyeMovement then
					JB.eyeMovement = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Third Person Camera")

				value, pressedInverted = ImGui.Checkbox("Inverted camera", JB.inverted)

				if pressedInverted then
					JB.inverted = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Horizontal Sensitivity only 360 camera")

				value, usedHorizontalSen = ImGui.SliderInt("hor", JB.horizontalSen, 0, 30, "%d")

				if usedHorizontalSen then
					JB.horizontalSen = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Vertical Sensitivity")

				value, usedVerticalSen = ImGui.SliderInt("ver", JB.verticalSen, 0, 30, "%d")

				if usedVerticalSen then
					JB.verticalSen = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Field of view")

				value, usedFov = ImGui.SliderInt("fov", JB.fov, 50, 120, "%d")

				if usedFov then
					JB.fov = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Camera options")

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "X-Axis")

				value, usedX = ImGui.SliderFloat("x", tonumber(JB.camViews[JB.camActive].pos.x), -3.0, 3.0)

				if usedX then
					JB.camViews[JB.camActive].pos.x = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Y-Axis")

				value, usedX = ImGui.SliderFloat("y", tonumber(JB.camViews[JB.camActive].pos.y), -10.0, 10.0)

				if usedX then
					JB.camViews[JB.camActive].pos.y = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Z-Axis")

				value, usedX = ImGui.SliderFloat("z", tonumber(JB.camViews[JB.camActive].pos.z), -3.0, 3.0)

				if usedX then
					JB.camViews[JB.camActive].pos.z = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				local euler = GetSingleton("Quaternion"):ToEulerAngles(JB.camViews[JB.camActive].rot)

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Roll")

				value, usedroll = ImGui.SliderFloat("roll", euler.roll, -180.0, 180.0)

				if usedroll then
					JB.camViews[JB.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(value, euler.pitch, euler.yaw))
					JB.secondCam:SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(value, euler.pitch, euler.yaw)))
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Pitch")

				value, usedpitch = ImGui.SliderFloat("pitch", euler.pitch, -90.0, 90.0)

				if usedpitch then
					JB.camViews[JB.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, value, euler.yaw))
					JB.secondCam:SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, value, euler.yaw)))
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Yaw")

				value, usedpitch = ImGui.SliderFloat("yaw", euler.yaw, -180.0, 180.0)

				if usedpitch then
					JB.camViews[JB.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, value))
					JB.secondCam:SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, value)))
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Patches")

				value, pressed = ImGui.Checkbox("Model head", JB.ModelMod)

				if (pressed) then
					JB.ModelMod = value
					JB.updateSettings = true
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Mods required")
				if tonumber(GetVersion():gsub("%.", ""):gsub("-", ""):gsub(" ", ""):gsub('%W',''):match("%d+")) >= 11802 then
					ImGui.TextColored(0, 1, 0, 1, "(Installed) Cyber Engine Tweaks V1.18.0 or later")
				else
					ImGui.TextColored(1, 0, 0, 1, "(NOT INSTALLED!) Cyber Engine Tweaks V1.18.0 or later")
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Mods optional")
				if GetMod('nativeSettings') ~= nil then
					ImGui.TextColored(0, 1, 0, 1, "(Installed) Native Settings")
				else
					ImGui.TextColored(0.8627, 0.8627, 0.8627, 1, "(Not installed) Native Settings")
				end

				if ModArchiveExists('grey_mesh_remover.archive') == true then
					ImGui.TextColored(0, 1, 0, 1, "(Installed) Grey Mesh Remover")
				else
					ImGui.TextColored(0.8627, 0.8627, 0.8627, 1, "(Not installed) Grey Mesh Remover")
				end

				if ModArchiveExists('BreastJigglePhysicsTPP&FPP&PM.archive') == true then
					ImGui.TextColored(0, 1, 0, 1, "(Installed) Breast Jiggle Physics")
				else
					ImGui.TextColored(0.8627, 0.8627, 0.8627, 1, "(Not installed) Breast Jiggle Physics")
				end

				if ModArchiveExists('jb-clothing-fit-and-better-grey-mesh-fix.archive') == true then
					ImGui.TextColored(0, 1, 0, 1, "(Installed) JB Clothing Fit and Better Grey mesh")
				else
					ImGui.TextColored(0.8627, 0.8627, 0.8627, 1, "(Not installed) JB Clothing Fit and Better Grey mesh")
				end

				ImGui.NewLine()

				ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Mods NOT COMPATIBLE!")
				if ModArchiveExists('modNS.archive') == true then
					ImGui.TextColored(1, 0, 0, 1, "(Installed) Night OS")
				else
					ImGui.TextColored(0, 1, 0, 1, "(Not installed) Night OS")
				end

				ImGui.NewLine()

				ImGui.NewLine()

				local PlayerSystem = Game.GetPlayerSystem()
				local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
				local fppCam       = PlayerPuppet:GetFPPCameraComponent()

				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "---------------------------------------")
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "isTppEnabled: " .. tostring(JB.isTppEnabled))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "timerCheckClothes: " .. tostring(JB.timerCheckClothes))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "inCar: " .. tostring(JB.inCar))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "inScene: " .. tostring(JB.inScene))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "waitTimer: " .. tostring(JB.waitTimer))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "waitForCar: " .. tostring(JB.waitForCar))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "Head " .. tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "carCheckOnce: " .. tostring(JB.carCheckOnce))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "switchBackToTpp: " .. tostring(JB.switchBackToTpp))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "camActive: " .. tostring(JB.camActive))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "timeStamp: " .. tostring(JB.timeStamp))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "headingLocked: " .. tostring(fppCam.headingLocked))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "updateSettings: " .. tostring(JB.updateSettings))
				ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "updateSettingsTimer: " .. tostring(JB.updateSettingsTimer))
	        end
		    ImGui.End()
		end
	end
end)