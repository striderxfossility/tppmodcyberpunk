local JB 				= require("classes/JB.lua")
local Gender 			= require("classes/Gender.lua")
local GameSession 		= require("classes/GameSession.lua")
local Attachment 		= require("classes/Attachment.lua")
local Cron 				= require("classes/Cron.lua")
local UI			  	= require('classes/UI.lua')
local nativeSettings 	= nil

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

function dd(class)
	print(Dump(class, false))
end

function ddArr(arr)
	for index, value in ipairs(arr) do
		dd(value)
	end
end

registerForEvent('onTweak', function()
	TweakDB:SetFlat('Character.Player_Puppet_Base.tags', {"Player", "TPP_Player"})
	TweakDB:SetFlat('Character.Player_Puppet_Base.itemGroups', {})
	TweakDB:SetFlat('Character.Player_Puppet_Base.appearanceName', "TPP_Body")
	TweakDB:SetFlat('Character.Player_Puppet_Base.isBumpable', false)
end)

registerForEvent("onInit", function()
	Observe("gameuiPhotoModeMenuController", "OnAnimationEnded", function(self)
		if JB.replacer ~= '' then
			local parts = JB:GetEYEObjects()

			for index, value in ipairs(parts) do
				if value:GetComponent():GetEntity():GetClassName() == CName.new("NPCPuppet") then
					if value:GetComponent():GetEntity():IsPaperdoll() then
						value:GetComponent():GetEntity():ScheduleAppearanceChange(JB.replacer)
					end
				end
			end
		end
	end)

	nativeSettings = GetMod("nativeSettings")
	if nativeSettings ~= nil then
		nativeSettings.addTab("/jb_tpp", "JB Third Person Mod")
		nativeSettings.addSubcategory("/jb_tpp/settings", "Settings")
		nativeSettings.addSubcategory("/jb_tpp/tpp", "Third Person Camera")
		nativeSettings.addSubcategory("/jb_tpp/patches", "Patches / Requests")

		nativeSettings.addSwitch("/jb_tpp/settings", "Disable Mod", "Disable the running mod", JB.disableMod, true, function(state)
			JB.disableMod = state
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/settings", "Weapon override", "Activate first person camera when equiping weapon", JB.weaponOverride, true, function(state)
			JB.weaponOverride = state
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/tpp", "Inverted camera", "", JB.inverted, false, function(state)
			JB.inverted = state
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/tpp", "Roll always 0", "", JB.rollAlwaysZero, false, function(state)
			JB.rollAlwaysZero = state
			JB.updateSettings = true
		end)

		nativeSettings.addSwitch("/jb_tpp/tpp", "Yaw always 0", "", JB.yawAlwaysZero, false, function(state)
			JB.yawAlwaysZero = state
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

	GameSession.OnStart(function()
		if JB.isTppEnabled then
			JB:ActivateTPP()
		end
	end)

	local speed = 8

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
			if JB.inCar then
				JB.isTppEnabled = false
				--GetPlayer():FindComponentByName('camera'):Activate(JB.transitionSpeed)
				--Gender:AddTppHead()
				if GetMod('EnhancedVehicleCamera') == nil then
					GetPlayer():FindComponentByName('camera'):SetLocalPosition(Vector4.new(0, 0, 0, 1))
				end
			end
        else
            JB.inCar = false
        end
	end)

	Observe('PlayerPuppet', 'OnAction', function(self, action)
		if not JB.disableMod then
			if JB.isInitialized then
				if not IsPlayerInAnyMenu() then
					local actionName  = Game.NameToString(ListenerAction.GetName(action))
					local actionValue = ListenerAction.GetValue(action)

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
		end
	end)
    
	for row in db:rows("SELECT * FROM cameras") do
		local vec4 = Vector4.new(tonumber(row[2]), tonumber(row[3]), tonumber(row[4]), 1.0)
		local quat = Quaternion.new(tonumber(row[6]), tonumber(row[7]), tonumber(row[8]), tonumber(row[9]))
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

end)

registerInput('jb_hold_360_cam', 'Hold to activate 360 camera', function(isDown)
	if not JB.disableMod then
		local tppCam = GetPlayer():FindComponentByName('camera')

		if (isDown) then
			JB.directionalMovement = true

			if not JB.inScene then
				tppCam.headingLocked = true
			end
		else
			if not JB.inScene then
				JB.directionalMovement = false
			end
			tppCam.headingLocked = false
		end
	end
end)

registerInput('jb_zoom_in', 'Zoom in', function(isDown)
	if not JB.disableMod then
		if isDown then
			JB.zoomIn = true
			JB.collisions.zoomedIn = 0.0
		else
			JB.zoomIn = false
		end
	end
end)

registerInput('jb_zoom_out', 'Zoom out', function(isDown)
	if not JB.disableMod then
		if isDown then
			JB.zoomOut = true
			JB.collisions.zoomedIn = 0.0
		else
			JB.zoomOut = false
		end
	end
end)

registerInput('jb_move_camera', 'Move Camera up/down', function(isDown)
	if not JB.disableMod then
		local tppCam = GetPlayer():FindComponentByName('camera')

		if isDown then
			JB.moveCamera = true

			if not JB.inScene then
				tppCam.headingLocked = true
			end
		else
			JB.moveCamera = false
			tppCam.headingLocked = false
		end
	end
end)

registerInput('jb_move_camera_forward', 'Move Camera forward/backwards', function(isDown)
	if not JB.disableMod then
		local tppCam = GetPlayer():FindComponentByName('camera')

		if isDown then
			JB.moveCameraOnPlane = true

			if not JB.inScene then
				tppCam.headingLocked = true
			end
		else
			JB.moveCameraOnPlane = false
			tppCam.headingLocked = false
		end
	end
end)

registerHotkey("jb_activate_tpp", "Activate/Deactivate Third Person", function()
	if not JB.disableMod then
		local PlayerSystem = Game.GetPlayerSystem()
		local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()

		if JB.inCar then
			PlayerPuppet:SetWarningMessage("JB: Do you want to have bugs?")
			return;
		end

		if(JB.isTppEnabled) then
			Cron.After(JB.transitionSpeed, function()
				Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):EnablePlayerTPPRepresenation(false)
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
	end
end)
	
registerHotkey("jb_switch_cam", "To next Camera view", function()
	if not JB.disableMod then
		JB:NextCam()
	end
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
	if not JB.disableMod then
		ResetCameras()
	end
end)

function ResetCameras() 
	JB.camViews[1].pos 	= JB.camViews[6].pos
	JB.camViews[1].rot = JB.camViews[6].rot
	JB.camViews[2].pos 	= JB.camViews[7].pos
	JB.camViews[2].rot = JB.camViews[7].rot
	JB.camViews[3].pos 	= JB.camViews[8].pos
	JB.camViews[3].rot = JB.camViews[8].rot
	JB.camViews[4].pos 	= JB.camViews[9].pos
	JB.camViews[4].rot = JB.camViews[9].rot
	JB.camViews[5].pos 	= JB.camViews[10].pos
	JB.camViews[5].rot = JB.camViews[10].rot

	GetPlayer():FindComponentByName('tppCamera'):SetLocalOrientation(JB.camViews[JB.camActive].rot)
	GetPlayer():FindComponentByName('tppCamera'):SetLocalPosition(JB.camViews[JB.camActive].pos)
	
	JB.updateSettings = true
	JB.collisions.zoomedIn = 0.0
end

registerHotkey("jb_reset_zoom", "Reset zoom", function()
	if not JB.disableMod then
		JB:ResetZoom()
		JB.collisions.zoomedIn = 0.0
	end
end)

-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)
	if not JB.disableMod then
		if JB.isInitialized then
			if not IsPlayerInAnyMenu() then

				local PlayerSystem = Game.GetPlayerSystem()
				local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
				local fppCam       = GetPlayer():FindComponentByName('camera')

				if not PlayerPuppet:FindVehicleCameraManager():IsTPPActive() == JB.previousPerspective then
					if PlayerPuppet:FindVehicleCameraManager():IsTPPActive() then
						Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "TPP")
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
						carCam:Activate(JB.transitionSpeed, true)
						JB.tppHeadActivated = true
						JB.carActivated     = false
					end
				end

				JB.isMoving = false

				Cron.Update(deltaTime)
			end
		end
	end
end)

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

				if ImGui.BeginTabBar("Tabbar") then
					if ImGui.BeginTabItem("Main settings") then

						if ModArchiveExists('jb_tpp_mod_0.archive') == true then
							ImGui.TextColored(1, 0, 0, 1, "REMOVE jb_tpp_mod_0.archive!!!")
							ImGui.NewLine()
						end

						ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Settings")

						value, pressedDisableMod = ImGui.Checkbox("Disable Mod", JB.disableMod)

						if pressedDisableMod then
							JB.disableMod = value
							JB.updateSettings = true
						end

						if not JB.disableMod then

							value, pressedWeaponOverride = ImGui.Checkbox("Weapon Override", JB.weaponOverride)

							if pressedWeaponOverride then
								JB.weaponOverride = value
								JB.updateSettings = true
							end

							value, pressedResetZoom = ImGui.Checkbox("Reset Zoom", false)

							if pressedResetZoom then
								JB:ResetZoom()
								JB.collisions.zoomedIn = 0.0
							end

							value, pressedResetCameras = ImGui.Checkbox("Reset Cameras", false)

							if pressedResetCameras then
								ResetCameras()
							end

							ImGui.NewLine()

							ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Third Person Camera")

							value, pressedInverted = ImGui.Checkbox("Inverted camera", JB.inverted)

							if pressedInverted then
								JB.inverted = value
								JB.updateSettings = true
							end

							value, pressedRollAlwaysZero = ImGui.Checkbox("Roll always 0", JB.rollAlwaysZero)

							if pressedRollAlwaysZero then
								JB.rollAlwaysZero = value
								JB.updateSettings = true
							end

							value, pressedYawAlwaysZero = ImGui.Checkbox("Yaw always 0", JB.yawAlwaysZero)

							if pressedYawAlwaysZero then
								JB.yawAlwaysZero = value
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

							ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Zoom speed")

							value, usedZoomSpeed = ImGui.SliderFloat("zp", tonumber(JB.zoomSpeed), 0.0, 1.0)

							if usedZoomSpeed then
								JB.zoomSpeed = value
								JB.updateSettings = true
							end

							ImGui.NewLine()

							ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Camera options")

							ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Amount of cameras")

							value, usedAmountCameras = ImGui.SliderInt("ac", JB.amountCameras, 1, 5, "%d")

							if usedAmountCameras then
								JB.amountCameras = value
								JB.updateSettings = true
							end

							ImGui.NewLine()

							ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Transition Speed FPP to TPP")

							value, usedTrans = ImGui.SliderFloat("sp", tonumber(JB.transitionSpeed), 0.0, 5.0)

							if usedTrans then
								JB.transitionSpeed = value
								JB.updateSettings = true
							end

							ImGui.NewLine()

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
								GetPlayer():FindComponentByName('tppCamera'):SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(value, euler.pitch, euler.yaw)))
								JB.updateSettings = true
							end

							ImGui.NewLine()

							ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Pitch")

							value, usedpitch = ImGui.SliderFloat("pitch", euler.pitch, -90.0, 90.0)

							if usedpitch then
								JB.camViews[JB.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, value, euler.yaw))
								GetPlayer():FindComponentByName('tppCamera'):SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, value, euler.yaw)))
								JB.updateSettings = true
							end

							ImGui.NewLine()

							ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Yaw")

							value, usedpitch = ImGui.SliderFloat("yaw", euler.yaw, -180.0, 180.0)

							if usedpitch then
								JB.camViews[JB.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, value))
								GetPlayer():FindComponentByName('tppCamera'):SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, value)))
								JB.updateSettings = true
							end

							ImGui.EndTabItem()
						end
					end

					if not JB.disableMod then
						if ImGui.BeginTabItem("Patches / Requests") then
							ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Patches / Requests")

							value, pressed = ImGui.Checkbox("Model head", JB.ModelMod)

							if (pressed) then
								JB.ModelMod = value
								JB.updateSettings = true
							end

							ImGui.EndTabItem()
						end

						if ImGui.BeginTabItem("info") then

							ImGui.TextColored(0.509803, 0.57255, 0.59607, 1, "Mods required")
							if tonumber(GetVersion():gsub("%.", ""):gsub("-", ""):gsub(" ", ""):gsub('%W',''):match("%d+")) >= 1181 then
								ImGui.TextColored(0, 1, 0, 1, "(Installed) Cyber Engine Tweaks V1.18.1 or later")
							else
								ImGui.TextColored(1, 0, 0, 1, "(NOT INSTALLED!) Cyber Engine Tweaks V1.18.1 or later")
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

							ImGui.NewLine()

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
							ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "updateSettings: " .. tostring(JB.updateSettings))
							ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "updateSettingsTimer: " .. tostring(JB.updateSettingsTimer))
							
							ImGui.EndTabItem()
						end

						if ImGui.BeginTabItem("Reset camera default") then

							ImGui.NewLine()

							if ImGui.BeginTabBar("Cameras") then
								if ImGui.BeginTabItem("cam 1") then
									UI:DrawCam(JB.camViews[6], 5)
									ImGui.EndTabItem()
								end

								if ImGui.BeginTabItem("cam 2") then
									UI:DrawCam(JB.camViews[7], 6)
									ImGui.EndTabItem()
								end

								if ImGui.BeginTabItem("cam 3") then
									UI:DrawCam(JB.camViews[8], 7)
									ImGui.EndTabItem()
								end

								if ImGui.BeginTabItem("cam 4") then
									UI:DrawCam(JB.camViews[9], 8)
									ImGui.EndTabItem()
								end

								if ImGui.BeginTabItem("cam 5") then
									UI:DrawCam(JB.camViews[10], 9)
									ImGui.EndTabItem()
								end

							end
							ImGui.EndTabBar()
							ImGui.EndTabItem()
						end

						if ImGui.BeginTabItem("Replacers") then

							ImGui.NewLine()

							ImGui.TextColored(1, 0, 0, 1, "Do not report bugs if you use this, this is purely for fun")

							ImGui.NewLine()

							value, pressed = ImGui.Checkbox("Player", JB.replacer == "")

							if (pressed) then
								
								Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):EnablePlayerTPPRepresenation(false)

								if JB.isTppEnabled then
									Cron.After(1.0, function()
										JB:ActivateTPP()
									end)
								end

								if GetPlayer():FindComponentByName('torso') ~= nil then
									GetPlayer():FindComponentByName('torso'):Toggle(true)
									GetPlayer():FindComponentByName('legs'):Toggle(true)
									GetPlayer():FindComponentByName('n0_000_pma_base__full'):Toggle(true)
								else
									GetPlayer():FindComponentByName('body'):Toggle(true)
								end

								GetPlayer():ScheduleAppearanceChange("none")
								
								JB.replacer = ""
							end

							if GetPlayer():FindComponentByName('torso') ~= nil then
								ImGui.TextColored(0.58039, 0.4667, 0.5451, 1, "MALE: Reload a save to set the player back")
							end

							ImGui.NewLine()

							if ImGui.BeginTabBar("replacers") then
								Replacers(Gender:IsFemale())
							end

							ImGui.EndTabItem()
						end
					end
				end
	        end
		    ImGui.End()
		end
	end
end)

function Replacers(female)
	if female then
		if ImGui.BeginTabItem("Panam") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"panam_default",
				"panam_nude",
				"panam_underwear",
				"panam_no_jacket",
				"panam__q203__shower_censored",
				"panam__q203__shower",
				"panam_default_scars",
				"panam__q203__after_shower",
				"panam_nude_fpp",
				"panam_no_jacket_and_harness",
				"panam_nude_fpp_censored",
				"panam_default_wounded"
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Judy") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"judy_default",
				"judy_diving_suit",
				"judy_braindance_on",
				"judy_braindance_off",
				"judy_panties",
				"judy_nude",
				"judy_diving_suit_mask",
				"judy_glove",
				"judy_default__no_makeup",
				"judy_diving_suit_no_mask",
				"judy__q203__shower",
				"judy_crying"
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Evelyn") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"evelyn_transparent",
				"evelyn_default",
				"evelyn_no_coat",
				"evelyn_recovering",
				"evelyn_disguised",
				"evelyn_dead",
				"evelyn_wounded",
				"evelyn_default_FPP",
				"evelyn_braindance",
				"evelyn_braindance_FPP"
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Alt") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"alt_naked",
				"alt_underwear",
				"alt_default",
				"alt_cyberspace",
				"alt_undress_01",
				"alt_undress_02",
				"alt_naked_censored",
				"alt_naked_bottom",
				"alt_naked_bottom_censored",
				"alt_cyberspace_visible",
				"alt_naked__no_breast_sim",
				"alt_cyberspace_visible_shader",
				"alt_naked_bottom__no_breast_sim",
				"alt_naked_bottom_lying_down"
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Oda") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"oda",
				"oda_no_mask",
				"oda_cloak",
				"oda_mask_damage",
				"oda_no_gear",
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Other") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"service__dining_wa_waitress_avarage_01",
				"demo_player_wa_default",
				"woman_average_v_street_kid_suit",
				"prostitute_wa_01",
				"8ug8ear_default"
			})
			ImGui.EndTabItem()
		end
	else
		if ImGui.BeginTabItem("Johnny") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"q108_johnny_default",
				"man_average_q108_johnny_no_sunglasses",
				"silverhand_riot",
				"silverhand_riot__no_glasses",
				"silverhand_default",
				"silverhand_clean_2020__no_glasses",
				"silverhand_clean_2020",
				"silverhand_wounded",
				"silverhand__q101_bomb_bag",
				"silverhand_riot_wounded",
				"silverhand_wounded_bandaged",
				"silverhand_riot_no_spikes",
				"silverhand_default__cyberspace",
				"silverhand_riot_cyberspace",
				"silverhand_riot__no_glasses_no_spikes",
				"silverhand_default__cyberspace_no_glasses",
				"silverhand_blendable",
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Adam Smasher") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"adam_smasher_bossfight_stage_00",
				"adam_smasher_bossfight_stage_01",
				"adam_smasher_bossfight_stage_02",
				"adam_smasher_bossfight_stage_03",
				"adam_smasher_bossfight_stage_04",
				"adam_smasher_bossfight_stage_05",
				"adam_smasher_2020_quest_appearance",
				"adam_smasher_2077_quest_appearance"
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Kerry") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"kerry_eurodyne_old",
				"kerry_eurodyne_young",
				"kerry_nude",
				"kerry_eurodyne_old_no_sunglasses",
				"kerry_eurodyne_undress_01",
				"kerry_eurodyne_undress_02",
				"kerry_eurodyne_undress_03",
				"kerry_eurodyne_undercover",
				"kerry_eurodyne_undercover_no_glasses",
				"kerry_eurodyne_bathrobe",
				"kerry_eurodyne_undercover_backstage_pass",
				"kerry_eurodyne_undercover_no_glasses_backstage_pass",
				"kerry_eurodyne_undress_sexscene",
				"kerry__q203__shower",
				"kerry_eurodyne_young_2013",
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Oda") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"oda",
				"oda_no_mask",
				"oda_cloak",
				"oda_mask_damage",
				"oda_no_gear",
			})
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Other") then
			ImGui.NewLine()
			UI:ReplacerArray(JB, {
				"gangster__lvl3_02",
			})
			ImGui.EndTabItem()
		end
		
	end
end