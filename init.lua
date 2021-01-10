dofile("jb_third_person_mod/parameters.lua")

registerForEvent("onInit", function()
	JbMod = JBMOD:new()

	JbMod.weaponOverride = weaponOverride
	JbMod.animatedFace = animatedFace

	JbMod.camViews = { -- JUST REMOVE OR ADD CAMS TO YOUR LIKING!
		CamView:new(Vector4:new(0.0, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false, false), -- Front Camera
		CamView:new(Vector4:new(0.5, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false, false), -- Left Shoulder Camera
		CamView:new(Vector4:new(-0.5, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false, false), -- Right Shoulder Camera
		CamView:new(Vector4:new(0.0, 4.0, 0.0, 1.0), Quaternion:new(50.0, 0.0, 4000.0, 1.0), true, false), -- Read Camera
		CamView:new(Vector4:new(0.0, 4.0, 0.0, 1.0), Quaternion:new(50.0, 0.0, 4000.0, 1.0), true, true) -- FreeForm Camera
	}

	JbMod.camCar = CamView:new(Vector4:new(0.0, -5.0, 2.0, 1.0), Quaternion:new(-0.1, 0.0, 0.0, 1.0), false, false)
	print('Jb Third Person Mod Loaded')
end)

CamView = {}
CamView.__index = CamView

function CamView:new (pos, rot, camSwitch, freeform)
   local obj = {}
   setmetatable(obj, CamView)
   obj.defaultZoomLevel = pos.y
   obj.pos = pos or Vector4:new(0.0, 0.0, 0.0, 1.0)
   obj.rot = rot or Quaternion:new(0.0, 0.0, 0.0, 1.0)
   obj.camSwitch = camSwitch or false
   obj.freeform = freeform or false
   return obj
end
	
-- Begin CamView Class
JBMOD = {}
JBMOD.__index = JBMOD

function JBMOD:new ()
	local obj = {}
   	setmetatable(obj, self)
   	obj.player = Game.GetPlayer()
   	obj.fppComp = obj.player:GetFPPCameraComponent()
   	obj.transactionComp = Game.GetTransactionSystem()
   	obj.inspectionComp = obj.player:GetInspectionComponent()
   	obj.pSystemComp = obj.inspectionComp:GetPlayerSystem()
   	obj.localPlayerControlledGameObjectComp = obj.pSystemComp:GetLocalPlayerControlledGameObject()
   	obj.vehicleCameraComp = obj.localPlayerControlledGameObjectComp:FindVehicleCameraManager()
   	obj.script = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
   	obj.headString = "Items.PlayerWaPhotomodeHead"
   	obj.femaleHead = "Items.PlayerWaPhotomodeHead"
   	obj.maleHead = "Items.PlayerMaPhotomodeHead"
   	obj.animFemaleHead = "Items.CharacterCustomizationWaHead"
   	obj.animMaleHead = "Items.CharacterCustomizationMaHead"
   	obj.tppHeadString = "Items.PlayerWaTppHead"
   	obj.tppFemaleHead = "Items.PlayerWaTppHead"
   	obj.tppMaleHead = "Items.PlayerMaTppHead"
   	obj.camViews = {}
   	obj.camCar = nil
   	obj.isTppEnabled = false
   	obj.camActive = 1
   	obj.timeStamp = 0.0
   	obj.gender = true
   	obj.weaponOverride = true
   	obj.runTppCommand = false
   	obj.runHeadCommand = false
   	obj.runTppSecCommand = false
   	obj.switchBackToTpp = false
   	obj.carCheckOnce = false
   	obj.animatedFace = false
   	obj.waitForCar = false
   	obj.waitTimer = 0.0
   	obj.timerCheckClothes = 0.0
   	return obj
end

function JBMOD:GetComps()
	self.player = Game.GetPlayer()
   	self.fppComp = self.player:GetFPPCameraComponent()
   	self.transactionComp = Game.GetTransactionSystem()
   	self.inspectionComp = self.player:GetInspectionComponent()
   	self.pSystemComp = self.inspectionComp:GetPlayerSystem()
   	self.localPlayerControlledGameObjectComp = self.pSystemComp:GetLocalPlayerControlledGameObject()
   	self.vehicleCameraComp = self.localPlayerControlledGameObjectComp:FindVehicleCameraManager()
   	self.script = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
end

function JBMOD:CheckForRestoration()
	self:GetComps()
	self:RemoveCrouchBug()
	self:CheckGender()
	self:CheckWeapon()
	self:CheckCar()
	self:CheckPhotoMode()

	if(self.timerCheckClothes > 10.0) then
		self:RestoreClothing('Chest')
		self:RestoreClothing('Torso')
		self:RestoreClothing('Head')
		self.timerCheckClothes = 0.0	
	end

	if(self.fppComp:GetLocalPosition().x == 0.0 and self.fppComp:GetLocalPosition().y == 0.0 and self.fppComp:GetLocalPosition().z == 0.0) then
		self.isTppEnabled = false
	end

	if(self.isTppEnabled and tostring(self:GetNameOfObject('TppHead')) == tostring(CName.new('player_fpp_head'))) then
		self:UpdateCamera()
		self:ActivateTPP()
	end

	self:AddToInventory(self.headString)
	self:AddToInventory(self.tppHeadString)
end

function JBMOD:AddToInventory(nameString)
	local gameItemID = GetSingleton('gameItemID')
	local tdbid = TweakDBID.new(nameString)
	local itemID = gameItemID:FromTDBID(tdbid)

	if(self.transactionComp:HasItem(self.player, itemID) == false) then
		Game.AddToInventory(nameString, 1)
	end
end

function JBMOD:RestoreClothing(attachmentSlot)
	if(attachmentSlot == "Torso") then
		if(self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. attachmentSlot)) ~= nil) then
			local slotID = TweakDBID.new('AttachmentSlots.' .. attachmentSlot)
			local item = self.transactionComp:GetItemInSlot(self.player, slotID)
			local itemName = tostring(self.transactionComp:GetItemAppearance(self.player, self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. attachmentSlot)):GetItemID()))
			
			if (string.find(itemName, "&FPP") and self.isTppEnabled) then
				print("find")
				itemName = tostring(itemName:match("%[(.-)%]"))

				gender = self.player:GetResolvedGenderName() 
				gender = tostring(gender) 
				strfound = string.find(gender, "Female") 

				if (strfound == nil) then
					
					itemName = tostring(string.sub(itemName, 3, -12))
					itemName = itemName .. "Male&TPP"
					print(itemName)
				else
					itemName = tostring(string.sub(itemName, 3, -14))
					itemName = itemName .. "Female&TPP"
					print(itemName)
				end

				self.transactionComp:ChangeItemAppearance(self.player, item:GetItemID(), CName.new(itemName), false)
	 		end
		end
	else
		if(self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. attachmentSlot)) ~= nil) then
			local slotID = TweakDBID.new('AttachmentSlots.' .. attachmentSlot)
			local item = self.transactionComp:GetItemInSlot(self.player, slotID)
			local itemName = tostring(self.transactionComp:GetItemAppearance(self.player, self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. attachmentSlot)):GetItemID()))
			itemName = tostring(itemName:match("%[(.-)%]"))
			itemName = tostring(string.sub(itemName, 3, -4))
 			self.transactionComp:ChangeItemAppearance(self.player, item:GetItemID(), CName.new(itemName), false)
		end
	end
end

function JBMOD:CheckWeapon()
	if(self.weaponOverride) then
		if(self.isTppEnabled) then
			if(self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.WeaponRight')) ~= nil) then
				self.switchBackToTpp = true
				self:DeactivateTPP()
			end
	    end
    end
end

function JBMOD:CheckCar()
	self.inCar = Game.GetWorkspotSystem():IsActorInWorkspot(self.player)

	if(self.inCar and self.isTppEnabled) then
		self.fppComp:Activate(0.0, true)
	end

	if(self.inCar and self.isTppEnabled and not self.carCheckOnce) then
		self.carCheckOnce = true
		self:SetTppRep(false)
		self:SetCarView()
	end

	if(not self.inCar and self.carCheckOnce) then
		self.carCheckOnce = false
		self.waitForCar = true
		self.waitTimer = 0.0
	end
end

function JBMOD:CheckGender()
	gender = self.player:GetResolvedGenderName() 
	gender = tostring(gender) 
	strfound = string.find(gender, "Female") 

	if strfound == nil then
		if(self.animatedFace) then
			self.headString = self.animMaleHead
		else
			self.headString = self.maleHead
		end
    	self.tppHeadString = self.tppMaleHead
	else
		if(self.animatedFace) then
			self.headString = self.animFemaleHead
		else
			self.headString = self.femaleHead
		end
    	self.tppHeadString = self.tppFemaleHead
	end
end

function JBMOD:ResetZoom()
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].defaultZoomLevel
	self:UpdateCamera()
end

function JBMOD:Zoom(z)
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].pos.y + z

	if(self.camViews[self.camActive].camSwitch == false) then
		if(self.camViews[self.camActive].pos.y >= -1.5) then
			self.camViews[self.camActive].pos.y = -1.5
		end
	else
		if(self.camViews[self.camActive].pos.y <= 1.5) then
			self.camViews[self.camActive].pos.y = 1.5
		end
	end

	self:UpdateCamera()
end

function JBMOD:ZoomCar(z)
	self.camCar.pos.y = self.camCar.pos.y + z

	if(self.camCar.pos.y >= -1.5) then
		self.camCar.pos.y = -1.5
	end

	self:UpdateCamera()
end

function JBMOD:RestoreFPPView()
	if (self.isTppEnabled == false) then
		self.player:DisableCameraBobbing(false)
		self.fppComp:SetLocalPosition(Vector4:new(0.0, 0.0, 0.0, 1.0))
		self.fppComp:SetLocalOrientation(Quaternion:new(0.0, 0.0, 0.0, 1.0))
	end
end

function JBMOD:SetCarView()
	self.player:DisableCameraBobbing(true)
	self.fppComp:SetLocalPosition(self.camCar.pos)
	self.fppComp:SetLocalOrientation(self.camCar.rot)
end

function JBMOD:UpdateCamera ()
	if (self.isTppEnabled) then
		if(self.inCar) then
			self.player:DisableCameraBobbing(true)
			self.fppComp:SetLocalPosition(self.camCar.pos)
			self.fppComp:SetLocalOrientation(self.camCar.rot)
			self.fppComp:Activate(0.0, false)
		else
			self.player:DisableCameraBobbing(true)
			self.fppComp:SetLocalPosition(self.camViews[self.camActive].pos)
			self.fppComp:SetLocalOrientation(self.camViews[self.camActive].rot)
			self.fppComp:Activate(0.0, false)
		end
	end
end

function JBMOD:EquipHead()
	Game.EquipItemOnPlayer(self.headString, "TppHead")
end

function JBMOD:ActivateTPP ()
	if(self:HasClothingInSlot('Torso') or self:HasClothingInSlot('Chest')) then
		self:RestoreClothing('Chest')
		self:RestoreClothing('Torso')
		self:RestoreClothing('Head')
		self.isTppEnabled = true
		self:SetTppRep(true)
		self:UpdateCamera()
	else
		print("JB Third Person Mod Error: you can't activate the mod when you're tits/manboobs are out at the moment :(")
		print("Equip a torso item, enter Third person, unequip the torso item. Flasher")
	end
end

function JBMOD:DeactivateTPP ()
	self.isTppEnabled = false
	self:EquipHead()
	self:RestoreFPPView()
end

function JBMOD:SwitchCamTo(cam)
	if self.camViews[cam] ~= nil then
		self.camActive = cam
		self:UpdateCamera()
		if(self.camViews[cam].freeform) then
			self.inspectionComp:SetIsPlayerInspecting(true)
		else 
			self.inspectionComp:SetIsPlayerInspecting(false)
		end
	else
		self.camActive = 1
		self.inspectionComp:SetIsPlayerInspecting(false)
		self:UpdateCamera()
	end
end

function JBMOD:HasClothingInSlot(slot)
	return self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. slot)) ~= nil
end

function JBMOD:ResetAppearance(slot)
	local slotID = TweakDBID.new('AttachmentSlots.' .. slot)
	local item = self.transactionComp:GetItemInSlot(self.player, slotID)
	local itemID = item:GetItemID()

	self.transactionComp:ResetItemAppearance(self.player, itemID)
end

function JBMOD:CheckClothing()
	if(self:HasClothingInSlot('Torso')) then
		self:ResetAppearance('Torso')
	elseif(self:HasClothingInSlot('Chest')) then
		self:ResetAppearance('Chest')
	end
end

function JBMOD:SetTppRep(setBool)
	Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):EnablePlayerTPPRepresenation(setBool)
end

function JBMOD:HasWeaponEquipped()
	return JbMod.transactionComp:GetItemInSlot(JbMod.player, TweakDBID.new('AttachmentSlots.WeaponRight')) ~= nil
end

function JBMOD:GetNameOfObject(attachmentSlot)
	if(self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. attachmentSlot)) ~= nil) then
		local slotID = TweakDBID.new('AttachmentSlots.' .. attachmentSlot)
		local item = self.transactionComp:GetItemInSlot(self.player, slotID)
		local data = self.transactionComp:GetItemData(self.player, item:GetItemID())

		return data:GetName()
	end

	return ''
end

function JBMOD:RestoreAttachment(attachmentSlot)
	if(self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.' .. attachmentSlot)) ~= nil) then
		local slotID = TweakDBID.new('AttachmentSlots.' .. attachmentSlot)
		local item = self.transactionComp:GetItemInSlot(self.player, slotID)
		self.transactionComp:ResetItemAppearance(self.player, item:GetItemID())
	end
end

function JBMOD:RemoveCrouchBug()
	if(tostring(self:GetNameOfObject('TppHead')) == tostring(CName.new('player_tpp_head')) or not self.isTppEnabled) then
		self.transactionComp:RemoveItemFromSlot(self.player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
	else
		if(self.isTppEnabled) then
			self:EquipHead()
		end
	end
end

function JBMOD:CheckPhotoMode()
	if(self.isTppEnabled) then
		local photoMode = JbMod.script:GetPhotoModeSystem(JbMod.script)

		if(photoMode:IsPhotoModeActive(true)) then
			self:SetTppRep(false)
		end
	end
end

function JBMOD:CarTimer(deltaTime)
	if(self.waitTimer > 0.4) then
		if(self:HasClothingInSlot('Torso') or self:HasClothingInSlot('Chest')) then
			self.isTppEnabled = true
			self:SetTppRep(true)
			self:UpdateCamera()
		else
			print("JB Third Person Mod Error: you can't activate the mod when you're tits/manboobs are out at the moment :(")
			print("Equip a torso item, enter Third person, unequip the torso item. Flasher")
		end
	end

	if(self.waitTimer > 1.0) then
		if(self:HasClothingInSlot('Torso') or self:HasClothingInSlot('Chest')) then
			self:SetTppRep(true)
			self:RestoreClothing('Torso')
			self:RestoreClothing('Chest')
			self:RestoreClothing('Head')
		else
			print("JB Third Person Mod Error: you can't activate the mod when you're tits/manboobs are out at the moment :(")
			print("Equip a torso item, enter Third person, unequip the torso item. Flasher")
		end
		self.waitTimer = 0.0
		self.waitForCar = false
	end

	if(self.waitForCar) then
		self.carCheckOnce = false
		self.waitTimer = self.waitTimer + deltaTime
	end
end
-- End JBMOD Class

-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)
	JbMod.timerCheckClothes = JbMod.timerCheckClothes + deltaTime
	JbMod:CheckForRestoration()

	JbMod:CarTimer(deltaTime)

	if (ImGui.IsKeyDown(zoomInKey)) then
		if(JbMod.inCar and JbMod.isTppEnabled) then
			JbMod:ZoomCar(0.06)
		else
			JbMod:Zoom(0.06)
		end
	end
	
	if (ImGui.IsKeyDown(zoomOutKey)) then
		if(JbMod.inCar and JbMod.isTppEnabled) then
			JbMod:ZoomCar(-0.06)
		else
			JbMod:Zoom(-0.06)
		end
		
	end

	if(JbMod.switchBackToTpp and not JbMod.HasWeaponEquipped()) then
		JbMod:ActivateTPP()
		JbMod.switchBackToTpp = false
	end

	if (ImGui.IsKeyPressed(activateTppModeKey, false)) then
		if(JbMod.isTppEnabled) then
			JbMod:DeactivateTPP()
		else
			if(JbMod.weaponOverride) then
				if(JbMod:HasWeaponEquipped()) then
					JbMod.isTppEnabled = false
					JbMod:RestoreFPPView()
				else
					JbMod:ActivateTPP()
				end
			else
				JbMod:ActivateTPP()
			end
		end
	end

	if (ImGui.IsKeyPressed(switchCamKey, false)) then
		JbMod:SwitchCamTo(JbMod.camActive + 1)
	end

end)

onOpenDebug = false

registerForEvent("onDraw", function()
	if (ImGui.IsKeyPressed(openDebugMenuKey, false)) then
	    if(onOpenDebug) then
	    	onOpenDebug = false
	    else
	    	onOpenDebug = true
	    end
	end

	if(onOpenDebug) then
		ImGui.SetNextWindowPos(300, 300, ImGuiCond.FirstUseEver)

	    if (ImGui.Begin("JB Third Person Mod")) then

	    	clicked = ImGui.Button("Reset zoom")
	    	if (clicked) then
	    		JbMod:ResetZoom()
			end
	    	
	    	clicked = ImGui.Button("Forced Fix Collar")
	    	if (clicked) then
	    		JbMod:SetTppRep(true)
			end

	      	ImGui.Text(tostring(JbMod:GetNameOfObject('TppHead')))
	      	ImGui.Text(tostring(tostring(CName.new('player_fpp_head'))))
	      	ImGui.Text("isTppEnabled: " .. tostring(JbMod.isTppEnabled))
	      	ImGui.Text("isMoving: " .. tostring(JbMod.localPlayerControlledGameObjectComp:IsMoving()))
	      	ImGui.Text("timerCheckClothes: " .. tostring(JbMod.timerCheckClothes))
	      	ImGui.Text("inCar: " .. tostring(JbMod.inCar))
	      	ImGui.Text("waitTimer: " .. tostring(JbMod.waitTimer))
	      	ImGui.Text("waitForCar: " .. tostring(JbMod.waitForCar))
	      	ImGui.Text("isHeadOn " .. tostring(tostring(JbMod:GetNameOfObject('TppHead')) == tostring(CName.new('player_fpp_head'))))
	      	ImGui.Text("carCheckOnce: " .. tostring(JbMod.carCheckOnce))
	      	ImGui.Text("HasWeaponEquipped: " .. tostring(JbMod.HasWeaponEquipped()))
	      	ImGui.Text("weaponOverride: " .. tostring(JbMod.weaponOverride))
	      	ImGui.Text("animatedFace: " .. tostring(JbMod.animatedFace))
	      	ImGui.Text("switchBackToTpp: " .. tostring(JbMod.switchBackToTpp))
	      	ImGui.Text("headString: " .. tostring(JbMod.headString))
	      	ImGui.Text("camActive: " .. tostring(JbMod.camActive))
	      	ImGui.Text("timeStamp: " .. tostring(JbMod.timeStamp))
	      	ImGui.Text("playerAttached: " .. tostring(JbMod.player:IsPlayer()))
	      	ImGui.Text("Camera: " .. tostring(JbMod.fppComp:GetName()))
	      	ImGui.Text("Current Cam: x:" .. tostring(JbMod.fppComp:GetLocalPosition().x) .. " y:" .. tostring(JbMod.fppComp:GetLocalPosition().y) .. " z: " .. tostring(JbMod.fppComp:GetLocalPosition().z))
	      	ImGui.Text("CAM1: x:" .. tostring(JbMod.camViews[1].pos.x) .. " y:" .. tostring(JbMod.camViews[1].pos.y) .. " z: " .. tostring(JbMod.camViews[1].pos.z))
	      	ImGui.Text("CAM2: x:" .. tostring(JbMod.camViews[2].pos.x) .. " y:" .. tostring(JbMod.camViews[2].pos.y) .. " z: " .. tostring(JbMod.camViews[2].pos.z))
	      	ImGui.Text("CAM3: x:" .. tostring(JbMod.camViews[3].pos.x) .. " y:" .. tostring(JbMod.camViews[3].pos.y) .. " z: " .. tostring(JbMod.camViews[3].pos.z))
	      	ImGui.Text("CAM4: x:" .. tostring(JbMod.camViews[4].pos.x) .. " y:" .. tostring(JbMod.camViews[4].pos.y) .. " z: " .. tostring(JbMod.camViews[4].pos.z))	
	      	ImGui.Text("CAMCAR: x:" .. tostring(JbMod.camCar.pos.x) .. " y:" .. tostring(JbMod.camCar.pos.y) .. " z: " .. tostring(JbMod.camCar.pos.z))	
	    end

	    ImGui.End()
	end
end)