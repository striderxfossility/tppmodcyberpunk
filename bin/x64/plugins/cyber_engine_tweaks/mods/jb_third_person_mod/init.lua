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
	local speed = 8

    Observe("vehicleCarBaseObject", "OnVehicleFinishedMounting", function (self)
        if Game['GetMountedVehicle;GameObject'](Game.GetPlayer()) ~= nil then
            JB.inCar = Game['GetMountedVehicle;GameObject'](Game.GetPlayer()):IsPlayerDriver()
        else
            JB.inCar = false
        end
	end)

	Observe('PlayerPuppet', 'OnAction', function(self, action)
		local actionName  = Game.NameToString(ListenerAction.GetName(action))
		local actionValue = ListenerAction.GetValue(action)
		local actionType  = action:GetType(action).value

		if actionName == 'ChoiceApply' then
            if actionType == 'BUTTON_PRESSED' then
                JB.interaction = true
            elseif actionType == 'BUTTON_RELEASED' then
                JB.interaction = false
            end
        end

		if actionName == 'mouse_y' then
			JB.moveHorizontal = true
		end

		if actionName == 'mouse_x' then
			JB.moveHorizontal = true
			JB.xroll = 0.025 * actionValue
		end

		if actionName == 'world_map_menu_move_vertical' then
            if actionValue >= 0 then
                speed = 1 + actionValue * 8
            else
                speed = 1 + actionValue * 8
            end
        end

		if actionName == 'world_map_menu_move_horizontal' and JB.directionalMovement and JB.isTppEnabled and not JB.inCar then
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

registerInput('jb_zoom_in', 'Zoom in', function(isDown)
	if (isDown) then
		JB.zoomIn = true
	else
		JB.zoomIn = false
	end
end)

registerInput('jb_zoom_out', 'Zoom out', function(isDown)
	if (isDown) then
		JB.zoomOut = true
	else
		JB.zoomOut = false
	end
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
                JB.tppHeadActivated = true
                JB.carActivated     = false
            end
        end
    
	    local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, true)

	    if not target then return end
	    if Vector4.Distance(target:GetWorldPosition(), Game.GetPlayer():GetWorldPosition()) > 2.9 then return end

	    if target:GetClassName().value == "Door" then
	        local ps = target:GetDevicePS()
			local state = ps:IsOpen()

			if not state then
				createInteractionHub(tostring("Open Door"), "Choice1", true)
			else
				createInteractionHub(tostring("Close Door"), "Choice1", true)
			end
			

			if JB.interaction then
				JB.interaction = false

				if ps:IsLocked() then
					ps:ToggleLockOnDoor()
				end
	            if ps:IsSealed() then
					ps:ToggleSealOnDoor()
				end

				if not state then
					target:OpenDoor()
				else
					target:CloseDoor()
				end
			end
	    end

	    if target:GetClassName().value == "DataTerm" then -- fast travel
	    	createInteractionHub(tostring("Select Destination"), "Choice1", true)

	        target:TurnOnDevice()
	        target:TurnOnScreen()

	        if JB.interaction then
	            target:TriggerMenuEvent(CName.new('OnOpenFastTravel'))
	            JB.interaction = false
	        end
	    end

	    if target:GetClassName().value == "VendingMachine" then
	        createInteractionHub(tostring("Get a drink"), "Choice1", true)

	        target:TurnOnDevice()

	        if JB.interaction then
	            target:PlayItemFall()
	            local dispenseRequest = target:CreateDispenseRequest(true, target:GetJunkItem())
	            target:DispenseItems(dispenseRequest)
	            JB.interaction = false
	        end
	    end

    end
end)

function createInteractionChoice(action, title)
    local choiceData =  InteractionChoiceData.new()
    choiceData.localizedName = title
    choiceData.inputAction = action

    local choiceType = ChoiceTypeWrapper.new()
    choiceType:SetType(gameinteractionsChoiceType.Blueline)
    choiceData.type = choiceType

    return choiceData
end

function prepareVisualizersInfo(hub)
    local visualizersInfo = VisualizersInfo.new()
    visualizersInfo.activeVisId = hub.id
    visualizersInfo.visIds = { hub.id }

    return visualizersInfo
end

function createInteractionHub(titel, action, active)
    local choiceHubData =  InteractionChoiceHubData.new()
    choiceHubData.id = -1001
    choiceHubData.active = active
    choiceHubData.flags = EVisualizerDefinitionFlags.Undefined
    choiceHubData.title = titel

    local choices = {}
    table.insert(choices, createInteractionChoice(action, titel))
    choiceHubData.choices = choices

    local visualizersInfo = prepareVisualizersInfo(choiceHubData)

    local blackboardDefs = Game.GetAllBlackboardDefs()
    local interactionBB = Game.GetBlackboardSystem():Get(blackboardDefs.UIInteractions)
    interactionBB:SetVariant(blackboardDefs.UIInteractions.InteractionChoiceHub, ToVariant(choiceHubData), true)
    interactionBB:SetVariant(blackboardDefs.UIInteractions.VisualizersInfo, ToVariant(visualizersInfo), true)
end

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

			clicked = ImGui.Button("Directional Movement true/false")
	    	if (clicked) then
	    		JB.directionalMovement = not JB.directionalMovement

	    		if not JB.directionalMovement then
	    			local PlayerSystem 		= Game.GetPlayerSystem()
		    		local PlayerPuppet 		= PlayerSystem:GetLocalPlayerMainGameObject()
		    		local fppCam       		= PlayerPuppet:GetFPPCameraComponent()
	    			fppCam.headingLocked 	= false
	    		end
				db:exec("UPDATE settings SET value = " .. tostring(JB.directionalMovement) .. " WHERE name = 'directionalMovement'")
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
	      	--ImGui.Text("HasWeaponEquipped: " .. tostring(JB:HasWeaponEquipped()))
	      	ImGui.Text("switchBackToTpp: " .. tostring(JB.switchBackToTpp))
	      	ImGui.Text("camActive: " .. tostring(JB.camActive))
	      	ImGui.Text("timeStamp: " .. tostring(JB.timeStamp))
        end
	    ImGui.End()
	end
end)