local Gender     = require("classes/Gender.lua")
local Attachment = require("classes/Attachment.lua")

local JB         = {}
      JB.__index = JB

function JB:new()
    local class = {}

    db:exec[=[
        CREATE TABLE cameras(id, x, y, z, w, rx, ry, rz, rw, camSwitch, freeForm);
        INSERT INTO cameras VALUES(0, 0, -2, 0, 0, 0, 0, 0, 0, false, false);
        INSERT INTO cameras VALUES(1, 0.5, -2, 0, 0, 0, 0, 0, 0, false, false);
        INSERT INTO cameras VALUES(2, -0.5, -2, 0, 0, 0, 0, 0, 0, false, false);
        INSERT INTO cameras VALUES(3, 0, 4, 0, 0, 50, 0, 4000, 0, true, false);
        INSERT INTO cameras VALUES(4, 0, 4, 0, 0, 50, 0, 4000, 0, true, true);
    ]=]

    db:exec[=[
        CREATE TABLE settings(id, name, value);
        INSERT INTO settings VALUES(0, "isTppEnabled", false);
        INSERT INTO settings VALUES(1, "weaponOverride", true);
        INSERT INTO settings VALUES(2, "animatedFace", false);
        INSERT INTO settings VALUES(3, "allowCameraBobbing", false);
    ]=]

    db:exec("INSERT INTO settings SELECT 4, 'camActive', 1 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 4);")

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'weaponOverride'") do
        if(index[1] == 0) then
            class.weaponOverride = false
        else
            class.weaponOverride = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'isTppEnabled'") do
        if(index[1] == 0) then
            class.isTppEnabled = false
        else
            class.isTppEnabled = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'animatedFace'") do
        if(index[1] == 0) then
            class.animatedFace = false
        else
            class.animatedFace = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'allowCameraBobbing'") do
        if(index[1] == 0) then
            class.allowCameraBobbing = false
        else
            class.allowCameraBobbing = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'camActive'") do
        class.camActive = tonumber(index[1])
    end

    ----------VARIABLES-------------
    class.camViews            = {}
    class.inCar               = false
    class.timeStamp           = 0.0
    class.switchBackToTpp     = false
    class.carCheckOnce        = false
    class.waitForCar          = false
    class.waitTimer           = 0.0
    class.timerCheckClothes   = 0.0
    class.carActivated        = false
    class.photoModeBeenActive = false
    class.headTimer           = 1.0
    class.inScene             = false
    ----------VARIABLES-------------

    setmetatable( class, JB )
    return class
end

function JB:SetEnableTPPValue(value)
    self.isTppEnabled = value
    db:exec("UPDATE settings SET value = " .. tostring(self.isTppEnabled) .. " WHERE name = 'isTppEnabled'")
end

function JB:CheckForRestoration(delta)
    local PlayerSystem = Game.GetPlayerSystem()
    local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
    local fppCam       = PlayerPuppet:GetFPPCameraComponent()
    local script       = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
    local photoMode    = script:GetPhotoModeSystem(script)

    self.headTimer = self.headTimer - delta
    
    if self.headTimer <= 0 then
        if self.isTppEnabled and not self.inCar then
            local str = "player_photomode_head"

            if self.animatedFace then
                str = "character_customization_head"
            end

            if not (tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')) == str) then
                Gender:AddHead(self.animatedFace)
            end
        else
            if not self.inCar then
                if not (tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')) == "player_fpp_head") then
                    Gender:AddFppHead()
                end
            end
        end

        --if self.inCar then
            --if not (tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')) == "player_tpp_head") then
                --Gender:AddTppHead()
                --print("adding TPP head")
            --end
        --end

        self.headTimer = 0.1
    end

    if self.isTppEnabled then
        if photoMode:IsPhotoModeActive() then
            self.photoModeBeenActive = true
            self:DeactivateTPP()
        end
    end

    if not self.isTppEnabled and self.photoModeBeenActive and not photoMode:IsPhotoModeActive() then
        if self.photoModeBeenActive then
            self.photoModeBeenActive = false
            self:ActivateTPP()
        end
    end

	if(self.weaponOverride) then
		if(self.isTppEnabled) then
			if(Attachment:HasWeaponActive()) then
				self.switchBackToTpp = true
				self:DeactivateTPP()
			end
	    end
    end
    
    if Game['GetMountedVehicle;GameObject'](Game.GetPlayer()) ~= nil then
        self.inCar = Game['GetMountedVehicle;GameObject'](Game.GetPlayer()):IsPlayerDriver()
    else
        self.inCar = false
    end
	
    self.inScene = Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet)

    if not self.inCar and self.inScene or self.camViews[self.camActive].freeform then
        fppCam.yawMaxLeft = 3600
        fppCam.yawMaxRight = -3600
        fppCam.pitchMax = 100
        fppCam.pitchMin = -100
    end

    if(self.inCar and self.isTppEnabled and not self.carCheckOnce) then
        Gender:AddFppHead()
		self.carCheckOnce = true
	end

	if(not self.inCar and self.carCheckOnce) then
		self.carCheckOnce = false
		self.waitForCar   = true
		self.waitTimer    = 0.0
	end

	if(self.timerCheckClothes > 10.0) then

        if not self.inCar then
            if self.allowCameraBobbing then
                PlayerPuppet:DisableCameraBobbing(false)
            else
                PlayerPuppet:DisableCameraBobbing(true)
            end
        end
        
        if not self.photoModeBeenActive and self.isTppEnabled then
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head"}, "TPP")
        end

        self.timerCheckClothes = 0.0
    end

	if(fppCam:GetLocalPosition().x == 0.0 and fppCam:GetLocalPosition().y == 0.0 and fppCam:GetLocalPosition().z == 0.0) then
        self:SetEnableTPPValue(false)
	end
end

function JB:CarTimer(deltaTime)
	if(self.waitTimer > 0.4) then
		self.tppHeadActivated = false
		self:SetEnableTPPValue(true)
        self:UpdateCamera()
	end

	if(self.waitTimer > 1.0) then
		Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head"}, "TPP")
		self.waitTimer  = 0.0
		self.waitForCar = false
	end

	if(self.waitForCar) then
		self.carCheckOnce = false
		self.waitTimer    = self.waitTimer + deltaTime
	end
end

function JB:ResetZoom()
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].defaultZoomLevel
	self:UpdateCamera()
end

function JB:MoveHorizontal(i)
    self.camViews[self.camActive].pos.x = self.camViews[self.camActive].pos.x + i
    self:UpdateCamera()
    db:exec("UPDATE cameras SET x = '" .. self.camViews[self.camActive].pos.x .. "' WHERE id = " .. self.camActive - 1)
end

function JB:MoveVertical(i)
    self.camViews[self.camActive].pos.z = self.camViews[self.camActive].pos.z + i
    self:UpdateCamera()
    db:exec("UPDATE cameras SET z = '" .. self.camViews[self.camActive].pos.z .. "' WHERE id = " .. self.camActive - 1)
end

function JB:Zoom(i)
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].pos.y + i
	self:UpdateCamera()
	db:exec("UPDATE cameras SET y = '" .. self.camViews[self.camActive].pos.y .. "' WHERE id = " .. self.camActive - 1)
end

function JB:MoveRotX(i)
    self.camViews[self.camActive].rot.i = self.camViews[self.camActive].rot.i + i
	self:UpdateCamera()
	db:exec("UPDATE cameras SET rx = '" .. self.camViews[self.camActive].rot.i .. "' WHERE id = " .. self.camActive - 1)
end

function JB:MoveRotY(i)
    self.camViews[self.camActive].rot.j = self.camViews[self.camActive].rot.j + i
	self:UpdateCamera()
	db:exec("UPDATE cameras SET ry = '" .. self.camViews[self.camActive].rot.j .. "' WHERE id = " .. self.camActive - 1)
end

function JB:MoveRotZ(i)
    self.camViews[self.camActive].rot.k = self.camViews[self.camActive].rot.k + i
	self:UpdateCamera()
	db:exec("UPDATE cameras SET rz = '" .. self.camViews[self.camActive].rot.k .. "' WHERE id = " .. self.camActive - 1)
end

function JB:RestoreFPPView()
	if not self.isTppEnabled then
        local PlayerSystem = Game.GetPlayerSystem()
        local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
        local fppCam       = PlayerPuppet:GetFPPCameraComponent()

		fppCam:SetLocalPosition(Vector4:new(0.0, 0.0, 0.0, 1.0))
		fppCam:SetLocalOrientation(Quaternion:new(0.0, 0.0, 0.0, 1.0))
	end
end

function JB:UpdateCamera()
	if self.isTppEnabled then
        local PlayerSystem = Game.GetPlayerSystem()
        local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
        local fppCam       = PlayerPuppet:GetFPPCameraComponent()

		fppCam:SetLocalPosition(self.camViews[self.camActive].pos)
		fppCam:SetLocalOrientation(self.camViews[self.camActive].rot)
	end
end

function JB:ActivateTPP()
    Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head"}, "TPP")
    self:SetEnableTPPValue(true)
    self:UpdateCamera()
    Gender:AddHead(self.animatedFace)
end

function JB:DeactivateTPP ()
	if self.isTppEnabled then
        local ts     = Game.GetTransactionSystem()
        local player = Game.GetPlayer()
		ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
	end

	self:SetEnableTPPValue(false)
	self:RestoreFPPView()
end

function JB:NextCam()
         self:SwitchCamTo(self.camActive + 1)
end

function JB:SwitchCamTo(cam)
    local ps     = Game.GetPlayerSystem()
    local puppet = ps:GetLocalPlayerMainGameObject()
    local ic     = puppet:GetInspectionComponent()

	if self.camViews[cam] ~= nil then
	    self.camActive = cam
        db:exec("UPDATE settings SET value = " .. self.camActive .. " WHERE name = 'camActive'")

		if self.camViews[cam].freeform then
			ic:SetIsPlayerInspecting(true)
		else 
			ic:SetIsPlayerInspecting(false)
		end

		self:UpdateCamera()
	else
		self.camActive = 1
        db:exec("UPDATE settings SET value = " .. self.camActive .. " WHERE name = 'camActive'")
		ic:SetIsPlayerInspecting(false)
		self:UpdateCamera()
	end
end

return JB:new()