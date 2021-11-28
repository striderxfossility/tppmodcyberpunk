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

    db:exec("INSERT INTO settings SELECT 5, 'ModelMod', false WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 5);")

    db:exec("INSERT INTO settings SELECT 6, 'directionalMovement', true WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 6);")

    db:exec("INSERT INTO settings SELECT 7, 'directionalStaticCamera', true WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 7);")

    db:exec("INSERT INTO settings SELECT 8, 'normalCameraRotateWhenStill', false WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 8);")

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

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'directionalMovement'") do
        if(index[1] == 0) then
            class.directionalMovement = false
        else
            class.directionalMovement = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'directionalStaticCamera'") do
        if(index[1] == 0) then
            class.directionalStaticCamera = false
        else
            class.directionalStaticCamera = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'normalCameraRotateWhenStill'") do
        if(index[1] == 0) then
            class.normalCameraRotateWhenStill = false
        else
            class.normalCameraRotateWhenStill = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'ModelMod'") do
        if(index[1] == 0) then
            class.ModelMod = false
        else
            class.ModelMod = true
        end
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
    class.zoomIn              = false
    class.zoomOut             = false
    class.moveHorizontal      = false
    class.xroll               = 0.0
    class.IsMoving            = false
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
    local fppCam       = PlayerPuppet:FindComponentByName(CName.new("camera"))
    local script       = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
    local photoMode    = script.GetPhotoModeSystem()
    local quat         = fppCam:GetLocalOrientation()

    if self.moveHorizontal and self.directionalMovement and self.isTppEnabled and not JB.inScene and not JB.inCar then
        local pos           = fppCam:GetLocalPosition()
        local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), -self.xroll * delta)

        fppCam:SetLocalPosition(Vector4.new(pos.x, pos.y, 0.0, 1.0))

        quat        = self:RotateQuaternion(quat, delta_quatX)
        local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(0, self.camViews[self.camActive].pos.y, 0.0, 0))

        if stick.y < -0.5 then
            fppCam.pitchMin = -15
            fppCam.pitchMax = 15
        else
            fppCam.pitchMin = -5;
            fppCam.pitchMax = 5;
        end

        fppCam:SetLocalOrientation(quat)
        fppCam:SetLocalPosition(stick)

        self.moveHorizontal  = false
    else
        if self.normalCameraRotateWhenStill then

            if not self.isMoving and self.isTppEnabled and (self.directionalMovement or self.normalCameraRotateWhenStill) and self.xroll == 0 and not Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet) then

                if quat.k > -0.999 and quat.k < -0.001 and quat.r > 0.001 and quat.r < 0.999 then
                    local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), delta)
                    quat        = self:RotateQuaternion(quat, delta_quatX)
                    fppCam:SetLocalOrientation(quat)
                    local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(0, self.camViews[self.camActive].pos.y, 0.0, 0))
                    fppCam:SetLocalPosition(stick)

                    local moveEuler = EulerAngles.new(0, 0, Game.GetPlayer():GetWorldYaw() - delta * -self.camViews[self.camActive].pos.y * 20)
                    Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), Game.GetPlayer():GetWorldPosition(), moveEuler)
                end

                if quat.k > 0.001 and quat.k < 0.999 and quat.r > 0.001 and quat.r < 0.999 then
                    local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), -delta)
                    quat        = self:RotateQuaternion(quat, delta_quatX)
                    fppCam:SetLocalOrientation(quat)
                    local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(0, self.camViews[self.camActive].pos.y, 0.0, 0))
                    fppCam:SetLocalPosition(stick)

                    local moveEuler = EulerAngles.new(0, 0, Game.GetPlayer():GetWorldYaw() - delta * self.camViews[self.camActive].pos.y * 20)
                    Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), Game.GetPlayer():GetWorldPosition(), moveEuler)
                end

                if quat.k > -0.999 and quat.k < -0.001 and quat.r > -0.999 and quat.r < -0.001 then
                    local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), -delta)
                    quat        = self:RotateQuaternion(quat, delta_quatX)
                    fppCam:SetLocalOrientation(quat)
                    local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(0, self.camViews[self.camActive].pos.y, 0.0, 0))
                    fppCam:SetLocalPosition(stick)

                    local moveEuler = EulerAngles.new(0, 0, Game.GetPlayer():GetWorldYaw() - delta * self.camViews[self.camActive].pos.y * 20)
                    Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), Game.GetPlayer():GetWorldPosition(), moveEuler)
                end

                if quat.k > 0.001 and quat.k < 0.999 and quat.r > -0.999 and quat.r < -0.001 then
                    local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), delta)
                    quat        = self:RotateQuaternion(quat, delta_quatX)
                    fppCam:SetLocalOrientation(quat)
                    local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(0, self.camViews[self.camActive].pos.y, 0.0, 0))
                    fppCam:SetLocalPosition(stick)

                    local moveEuler = EulerAngles.new(0, 0, Game.GetPlayer():GetWorldYaw() - delta * -self.camViews[self.camActive].pos.y * 20)
                    Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), Game.GetPlayer():GetWorldPosition(), moveEuler)
                end
            end

            if not PlayerPuppet:IsMoving() and self.isTppEnabled and not JB.inCar and not self.directionalMovement and not Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet) and not Game['GetMountedVehicle;GameObject'](Game.GetPlayer()) ~= nil then
                local pos           = fppCam:GetLocalPosition()
                local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), -self.xroll * delta)

                fppCam:SetLocalPosition(Vector4.new(pos.x, pos.y, 0.0, 1.0))

                quat        = self:RotateQuaternion(quat, delta_quatX)
                local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(0, self.camViews[self.camActive].pos.y, 0.0, 0))

                if stick.y < -0.5 then
                    fppCam.pitchMin = -15
                    fppCam.pitchMax = 15
                else
                    fppCam.pitchMin = -5;
                    fppCam.pitchMax = 5;
                end

                fppCam:SetLocalOrientation(quat)
                fppCam:SetLocalPosition(stick)

                self.moveHorizontal  = false

                if fppCam.headingLocked then
                    fppCam.headingLocked = true
                end
            end

            if PlayerPuppet:IsMoving() and self.isTppEnabled and not JB.inCar and not self.directionalMovement and not Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet) then
                self:UpdateCamera()
                --fppCam.headingLocked = false
            end

            if not PlayerPuppet:IsMoving() and not self.isTppEnabled and not JB.inCar and not self.directionalMovement and not Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet) then
                --fppCam.headingLocked = false
            end
        end
    end

    if Game['GetMountedVehicle;GameObject'](Game.GetPlayer()) ~= nil then 
        if self.isTppEnabled then
            self:DeactivateTPP()
        end
    else
        --if not Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet) then
        --    if self.directionalMovement and PlayerPuppet:IsMoving() and self.isTppEnabled then
        --        fppCam.headingLocked = true
        --    end
        --
        --    if self.directionalMovement and not self.isTppEnabled then
        --        fppCam.headingLocked = false
        --   end
        --end
    end

    if not self.isTppEnabled and not self.inCar and fppCam.headingLocked then
        --fppCam.headingLocked = false
    end

    if not self.isTppEnabled and fppCam.headingLocked and self.inScene then
        --fppCam.headingLocked = false
    end

    if(self.zoomIn) then
        self:Zoom(0.20)
    end

    if(self.zoomOut) then
        self:Zoom(-0.20)
    end

    local str = "player_photomode_head"

    if self.animatedFace then
        str = "character_customization_head"
    end

    self.headTimer = self.headTimer - delta
    
    if self.headTimer <= 0 then
        if self.isTppEnabled and not self.inCar then
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

        self.headTimer = 0.1
    end

    if self.isTppEnabled then
        if photoMode:IsPhotoModeActive() and not self.inScene then
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

        if self.switchBackToTpp and not Attachment:HasWeaponActive() then
            self:ActivateTPP()
            self.switchBackToTpp = false
        end
    end
    
	
    self.inScene = Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet)

    if self.isTppEnabled and not self.inCar and self.inScene or self.camViews[self.camActive].freeform then
        fppCam.yawMaxLeft = 3600
        fppCam.yawMaxRight = -3600
        fppCam.pitchMax = 100
        fppCam.pitchMin = -100
    end

    if(self.inCar and self.isTppEnabled and not self.carCheckOnce) then
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
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
        end

        if not self.isTppEnabled then
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
        end

        self.timerCheckClothes = 0.0
    end

	if(fppCam:GetLocalPosition().x == 0.0 and fppCam:GetLocalPosition().y == 0.0 and fppCam:GetLocalPosition().z == 0.0) then
        self:SetEnableTPPValue(false)
	end

    if self.inScene and not self.inCar and photoMode:IsPhotoModeActive() then
        if not (tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')) == str) then
            Gender:AddHead(self.animatedFace)
        end
    end
end

function JB:RotateQuaternion(orig_quat, delta_quat)
    local x = orig_quat.r * delta_quat.i + orig_quat.i * delta_quat.r + orig_quat.j * delta_quat.k - orig_quat.k * delta_quat.j;
    local y = orig_quat.r * delta_quat.j + orig_quat.j * delta_quat.r + orig_quat.k * delta_quat.i - orig_quat.i * delta_quat.k;
    local z = orig_quat.r * delta_quat.k + orig_quat.k * delta_quat.r + orig_quat.i * delta_quat.j - orig_quat.j * delta_quat.i;
    local w = orig_quat.r * delta_quat.r - orig_quat.i * delta_quat.i - orig_quat.j * delta_quat.j - orig_quat.k * delta_quat.k;

    return Quaternion.new(x, y, z, w)
end

function JB:CarTimer(deltaTime)
	if(self.waitTimer > 0.4) then
		self.tppHeadActivated = false
		self:SetEnableTPPValue(true)
        self:UpdateCamera()
	end

	if(self.waitTimer > 1.0) then
		Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
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

		fppCam:SetLocalPosition(Vector4.new(0.0, 0.0, 0.0, 1.0))
		fppCam:SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
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
    Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
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