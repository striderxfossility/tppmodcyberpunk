dofile("jb_third_person_mod/parameters.lua")

CamView = {}
CamView.__index = CamView

function CamView:new (pos, rot, camSwitch)
   local obj = {}
   setmetatable(obj, CamView)
   obj.pos = pos or Vector4:new(0.0, 0.0, 0.0, 1.0)
   obj.rot = rot or Quaternion:new(0.0, 0.0, 0.0, 1.0)
   obj.camSwitch = camSwitch or false
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
   	obj.headString = "Items.CharacterCustomizationWaHead"
   	obj.femaleHead = "Items.CharacterCustomizationWaHead"
   	obj.maleHead = "Items.CharacterCustomizationMaHead"
   	obj.tppHeadString = "Items.PlayerWaTppHead"
   	obj.tppFemaleHead = "Items.PlayerWaTppHead"
   	obj.tppMaleHead = "Items.PlayerMaTppHead"
   	obj.camViews = {}
   	obj.isTppEnabled = false
   	obj.camActive = 1
   	obj.inCar = false
   	obj.exitCar = false
   	obj.timeStamp = 0.0
   	obj.enterCar = false
   	obj.gender = true
   	obj.genderOverride = false
   	obj.weaponOverride = true
   	obj.headEquipped = false
   	obj.runTimer = false
   	obj.timer = 0.0
   	obj.runTppCommand = false
   	obj.runHeadCommand = false
   	obj.runTppSecCommand = false
   	obj.switchBackToTpp = false
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
end

function JBMOD:CheckForRestoration()
	self:GetComps()
	self:CheckGender()
	self:CheckWeapon()

	if(self.fppComp:GetLocalPosition().x == 0.0 and self.fppComp:GetLocalPosition().y == 0.0 and self.fppComp:GetLocalPosition().z == 0.0) then
		self.isTppEnabled = false
	end
	
	self.inCar = self.vehicleCameraComp:IsTPPActive()

	if(self.inCar) then
		self.enterCar = true
	end

	local gameItemID = GetSingleton('gameItemID')
	local tdbid = TweakDBID.new(self.headString)
	local itemID = gameItemID:FromTDBID(tdbid)

	if(self.transactionComp:HasItem(self.player, itemID) == false) then
		Game.AddToInventory(self.headString, 1)
		Game.AddToInventory("Items.Jacket_05_old_01", 1)
	end

	if(self.exitCar and (self.timeStamp + 18.0) <= Game.GetTimeSystem():GetGameTimeStamp()) then
		self:EquipHead()
		self.exitCar = false
		self.enterCar = false
	end

	if(self.enterCar and self.inCar == false and self.isTppEnabled and self.exitCar == false) then
		self.timeStamp = Game.GetTimeSystem():GetGameTimeStamp()
		self:EquipHead()
		self:UpdateCamera()
		self.exitCar = true
	end
end

function JBMOD:CheckWeapon()
	if(self.weaponOverride) then
		if(self.isTppEnabled) then
			if(self.transactionComp:GetItemInSlot(self.player, TweakDBID.new('AttachmentSlots.WeaponRight')) ~= nil) then
				self:SetTppRep(false)
				self.switchBackToTpp = true
				self:DeactivateTPP()
			end
	    end
    end
end

function JBMOD:CheckGender()
	gender = self.player:GetResolvedGenderName() 
	gender = tostring(gender) 
	strfound = string.find(gender, "Female") 

	if strfound == nil then -- male
		if(self.genderOverride == false) then
	    	self.headString = self.maleHead
	    	self.tppHeadString = self.tppMaleHead
	    else
	    	self.headString = self.femaleHead
	    	self.tppHeadString = self.tppFemaleHead
	    end
	else -- female
	    if(self.genderOverride == false) then
	    	self.headString = self.femaleHead
	    	self.tppHeadString = self.tppFemaleHead
	    else
	    	self.headString = self.maleHead
	    	self.tppHeadString = self.tppMaleHead
	    end
	end
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

function JBMOD:RestoreFPPView()
	if (self.isTppEnabled == false) then
		self.fppComp:SetLocalPosition(Vector4:new(0.0, 0.0, 0.0, 1.0))
		self.fppComp:SetLocalOrientation(Quaternion:new(0.0, 0.0, 0.0, 1.0))
	end
end

function JBMOD:UpdateCamera ()
	if (self.isTppEnabled) then
		self.fppComp.nearPlaneOverride = 0.0
		self.fppComp.farPlaneOverride = 0.0
		self.fppComp:SetLocalPosition(self.camViews[self.camActive].pos)
		self.fppComp:SetLocalOrientation(self.camViews[self.camActive].rot)
	end
end

function JBMOD:EquipHead()
	Game.EquipItemOnPlayer(self.headString, "TppHead")
	self.headEquipped = not self.headEquipped
end

function JBMOD:ActivateTPP ()
	if(self:HasClothingInSlot('Torso') or self:HasClothingInSlot('Chest')) then
		self.isTppEnabled = true
		self.runTimer = true
		self:UpdateCamera()
	else
		print("JB Third Person Mod Error: you can't activate the mod when you're tits are out at the moment :(")
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
	else
		self.camActive = 1
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

function JBMOD:RunTimer(deltaTime)
	if(self.runTimer) then
		self.timer = self.timer + deltaTime
		if (self.timer > 0.0 and not self.runTppCommand) then
			self:CheckClothing()
			self.runTppCommand = true
			Game.EquipItemOnPlayer(self.tppHeadString, "TppHead")
		end

		if (self.timer > 0.6 and not self.runHeadCommand) then
			self:EquipHead()
			self.runHeadCommand = true
		end

		if (self.timer > 1.2 and not self.runTppSecCommand) then
			self:SetTppRep(true)
			self.runTppSecCommand = true
		end

		if (self.timer > 1.5) then
			self:CheckClothing()
			self:EquipHead()

			self.timer = 0.0
			self.runTimer = false
			self.runTppCommand = false
			self.runHeadCommand = false
			self.runTppSecCommand = false
		end

		if(self.timer > 2.0) then
			print("bugged out")
		end
	end
end
-- End JBMOD Class

JbMod = JBMOD:new()

JbMod.weaponOverride = weaponOverride

JbMod.camViews = { -- JUST REMOVE OR ADD CAMS TO YOUR LIKING!
	CamView:new(Vector4:new(0.0, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false), -- Front Camera
	CamView:new(Vector4:new(0.5, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false), -- Left Shoulder Camera
	CamView:new(Vector4:new(-0.5, -2.0, 0.0, 1.0), Quaternion:new(0.0, 0.0, 0.0, 1.0), false), -- Right Shoulder Camera
	CamView:new(Vector4:new(0.0, 4.0, 0.0, 1.0), Quaternion:new(50.0, 0.0, 4000.0, 1.0), true) -- Read Camera
}

-- GAME RUNNING
registerForEvent("onUpdate", function(deltaTime)

	JbMod:CheckForRestoration()
	JbMod:RunTimer(deltaTime)

	if (ImGui.IsKeyDown(string.byte('0'))) then
		JbMod:Zoom(0.06)
	end
	
	if (ImGui.IsKeyDown(string.byte('9'))) then
		JbMod:Zoom(-0.06)
	end

	if(JbMod.switchBackToTpp and not JbMod.HasWeaponEquipped()) then
		JbMod:ActivateTPP()
		JbMod.switchBackToTpp = false
	end

	if(JbMod.inCar == false) then
		if (ImGui.IsKeyPressed(string.byte('B'))) then
			if(JbMod.isTppEnabled) then
				JbMod:SetTppRep(false)
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

		if (GetAsyncKeyState(0x71)) then -- F2
			JbMod:SwitchCamTo(JbMod.camActive + 1)
		end
	end

end)

onOpenDebug = false

registerForEvent("onDraw", function()
	if (GetAsyncKeyState(0x72)) then -- F3
	    if(onOpenDebug) then
	    	onOpenDebug = false
	    else
	    	onOpenDebug = true
	    end
	end

	if(onOpenDebug) then
		ImGui.SetNextWindowPos(300, 300, ImGuiCond.FirstUseEver)

	    if (ImGui.Begin("JB Third Person Mod")) then

	    	clicked = ImGui.Button("Equip / unequip head")
			if (clicked) then
				JbMod:EquipHead()
			end

			slotID = TweakDBID.new('AttachmentSlots.TppHead')
			item = JbMod.transactionComp:GetItemInSlot(JbMod.player, slotID)
			itemID = item:GetItemID()
			data = JbMod.transactionComp:GetItemData(JbMod.player, itemID)

	      	ImGui.Text("CURRENT EQUIPPED: " ..  tostring(data:GetName()))
	      	ImGui.Text("timer: " .. tostring(JbMod.timer))
	      	ImGui.Text("isTppEnabled: " .. tostring(JbMod.isTppEnabled))
	      	ImGui.Text("HasWeaponEquipped: " .. tostring(JbMod.HasWeaponEquipped()))
	      	ImGui.Text("headEquipped: " .. tostring(JbMod.headEquipped))
	      	ImGui.Text("weaponOverride: " .. tostring(JbMod.weaponOverride))
	      	ImGui.Text("switchBackToTpp: " .. tostring(JbMod.switchBackToTpp))
	      	ImGui.Text("genderOverride: " .. tostring(JbMod.genderOverride))
	      	ImGui.Text("headString: " .. tostring(JbMod.headString))
	      	ImGui.Text("camActive: " .. tostring(JbMod.camActive))
	      	ImGui.Text("inCar: " .. tostring(JbMod.inCar))
	      	ImGui.Text("exitCar: " .. tostring(JbMod.exitCar))
	      	ImGui.Text("enterCar: " .. tostring(JbMod.enterCar))
	      	ImGui.Text("timeStamp: " .. tostring(JbMod.timeStamp))
	      	ImGui.Text("playerAttached: " .. tostring(Game.GetPlayer():IsPlayer()))
	      	ImGui.Text("Current Cam: x:" .. tostring(JbMod.fppComp:GetLocalPosition().x) .. " y:" .. tostring(JbMod.fppComp:GetLocalPosition().y) .. " z: " .. tostring(JbMod.fppComp:GetLocalPosition().z))
	      	ImGui.Text("CAM1: x:" .. tostring(JbMod.camViews[1].pos.x) .. " y:" .. tostring(JbMod.camViews[1].pos.y) .. " z: " .. tostring(JbMod.camViews[1].pos.z))
	      	ImGui.Text("CAM2: x:" .. tostring(JbMod.camViews[2].pos.x) .. " y:" .. tostring(JbMod.camViews[2].pos.y) .. " z: " .. tostring(JbMod.camViews[2].pos.z))
	      	ImGui.Text("CAM3: x:" .. tostring(JbMod.camViews[3].pos.x) .. " y:" .. tostring(JbMod.camViews[3].pos.y) .. " z: " .. tostring(JbMod.camViews[3].pos.z))
	      	ImGui.Text("CAM4: x:" .. tostring(JbMod.camViews[4].pos.x) .. " y:" .. tostring(JbMod.camViews[4].pos.y) .. " z: " .. tostring(JbMod.camViews[4].pos.z))	
	    end

	    ImGui.End()
	end
end)


--obj.camViews = {}