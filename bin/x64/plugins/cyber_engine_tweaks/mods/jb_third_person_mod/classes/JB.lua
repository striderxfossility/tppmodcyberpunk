local Attachment = require("classes/Attachment.lua")
local Item       = require("classes/Item.lua")
local Cron 		 = require("classes/Cron.lua")
local Gender     = require("classes/Gender.lua")

local JB         = {}
      JB.__index = JB

function JB:new()
    local class = {}

    db:exec[=[
        CREATE TABLE cameras(id, x, y, z, w, rx, ry, rz, rw, camSwitch, freeForm);
        INSERT INTO cameras VALUES(0, 0, -2, 0, 0, 0, 0, 0, 1, false, false);
        INSERT INTO cameras VALUES(1, 0.5, -2, 0, 0, 0, 0, 0, 1, false, false);
        INSERT INTO cameras VALUES(2, -0.5, -2, 0, 0, 0, 0, 0, 1, false, false);
        INSERT INTO cameras VALUES(3, 0, -4, 0, 0, 0, 0, 0, 1, true, false);
        INSERT INTO cameras VALUES(4, 0, -4, 0, 0, 0, 0, 0, 1, true, true);
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

    db:exec("INSERT INTO settings SELECT 11, 'horizontalSen', 5 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 11);")

    db:exec("INSERT INTO settings SELECT 12, 'verticalSen', 5 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 12);")

    db:exec("INSERT INTO settings SELECT 13, 'fov', 80 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 13);")

    db:exec("INSERT INTO settings SELECT 14, 'inverted', false WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 14);")

    db:exec("INSERT INTO settings SELECT 15, 'rollAlwaysZero', true WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 15);")

    db:exec("INSERT INTO settings SELECT 16, 'yawAlwaysZero', false WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 16);")

    db:exec("INSERT INTO settings SELECT 18, 'transitionSpeed', 2 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 18);")

    db:exec("INSERT INTO settings SELECT 20, 'zoomFpp', 0.1 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 20);")

    db:exec("INSERT INTO settings SELECT 21, 'disableMod', false WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 21);")

    db:exec("INSERT INTO settings SELECT 22, 'zoomSpeed', 0.2 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 22);")

    db:exec("INSERT INTO settings SELECT 23, 'amountCameras', 5 WHERE NOT EXISTS(SELECT 1 FROM settings WHERE id = 23);")

    db:exec("INSERT INTO cameras SELECT 5, 0, -2, 0, 0, 0, 0, 0, 1, false, false WHERE NOT EXISTS(SELECT 1 FROM cameras WHERE id = 5);")
    db:exec("INSERT INTO cameras SELECT 6, 0.5, -2, 0, 0, 0, 0, 0, 1, false, false WHERE NOT EXISTS(SELECT 1 FROM cameras WHERE id = 6);")
    db:exec("INSERT INTO cameras SELECT 7, -0.5, -2, 0, 0, 0, 0, 0, 1, false, false WHERE NOT EXISTS(SELECT 1 FROM cameras WHERE id = 7);")
    db:exec("INSERT INTO cameras SELECT 8, 0, -4, 0, 0, 0, 0, 0, 1, false, false WHERE NOT EXISTS(SELECT 1 FROM cameras WHERE id = 8);")
    db:exec("INSERT INTO cameras SELECT 9, 0, -4, 0, 0, 0, 0, 0, 1, false, false WHERE NOT EXISTS(SELECT 1 FROM cameras WHERE id = 9);")

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

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'camActive'") do
        class.camActive = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'ModelMod'") do
        if(index[1] == 0) then
            class.ModelMod = false
        else
            class.ModelMod = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'horizontalSen'") do
        class.horizontalSen = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'transitionSpeed'") do
        class.transitionSpeed = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'verticalSen'") do
        class.verticalSen = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'fov'") do
        class.fov = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'inverted'") do
        if(index[1] == 0) then
            class.inverted = false
        else
            class.inverted = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'rollAlwaysZero'") do
        if(index[1] == 0) then
            class.rollAlwaysZero = false
        else
            class.rollAlwaysZero = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'yawAlwaysZero'") do
        if(index[1] == 0) then
            class.yawAlwaysZero = false
        else
            class.yawAlwaysZero = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'zoomFpp'") do
        class.zoomFpp = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'disableMod'") do
        if(index[1] == 0) then
            class.disableMod = false
        else
            class.disableMod = true
        end
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'zoomSpeed'") do
        class.zoomSpeed = tonumber(index[1])
    end

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'amountCameras'") do
        class.amountCameras = tonumber(index[1])
    end
    
    ----------VARIABLES-------------
    class.camViews                  = {}
    class.inCar                     = false
    class.timeStamp                 = 0.0
    class.switchBackToTpp           = false
    class.carCheckOnce              = false
    class.waitForCar                = false
    class.waitTimer                 = 0.0
    class.timerCheckClothes         = 0.0
    class.carActivated              = false
    class.photoModeBeenActive       = false
    class.inScene                   = false
    class.moveHorizontal            = false
    class.xroll                     = 0.0
    class.yroll                     = 0.0
    class.IsMoving                  = false
    class.onChangePerspective       = false
    class.previousPerspective       = false
    class.isInitialized             = false
    class.offset                    = 1.7
    class.controllerZoom            = false
    class.controller360             = false
    class.controllerRightTrigger    = false
    class.controllerLeftTrigger     = false
    class.eyesTimer                 = 5.0
    class.zoomIn                    = false
    class.zoomOut                   = false
    class.updateSettings            = false
    class.updateSettingsTimer       = 3.0
    class.moveCamera                = false
    class.moveCameraOnPlane         = false
    class.resetCams                 = false
    class.collisions                = {
        down = false,
        zoomedIn = 0.0,
        zoomValue = 0.4,
        back = true
    }
    class.colliedTimer              = 0.0
    class.switchDisableMod          = false
    class.jb_replacers              = nil
    ----------VARIABLES-------------

    setmetatable( class, JB )
    return class
end

function JB:SetEnableTPPValue(value)
    self.isTppEnabled   = value
    self.updateSettings = true
end

function JB:CheckForRestoration(delta)
    local PlayerSystem = Game.GetPlayerSystem()
    local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
    local script       = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
    local photoMode    = script.GetPhotoModeSystem()

    if self.updateSettings and self.updateSettingsTimer <= 0.0 then
        self.updateSettings         = false
        self.updateSettingsTimer    = 3.0
        
        db:exec("UPDATE settings SET value = " .. tostring(self.weaponOverride) .. " WHERE name = 'weaponOverride'")
        db:exec("UPDATE settings SET value = " .. tostring(self.horizontalSen) .. " WHERE name = 'horizontalSen'")
        db:exec("UPDATE settings SET value = " .. tostring(self.verticalSen) .. " WHERE name = 'verticalSen'")
        db:exec("UPDATE settings SET value = " .. tostring(self.fov) .. " WHERE name = 'fov'")
        db:exec("UPDATE settings SET value = " .. tostring(self.ModelMod) .. " WHERE name = 'ModelMod'")
        db:exec("UPDATE settings SET value = " .. self.camActive .. " WHERE name = 'camActive'")
        db:exec("UPDATE settings SET value = " .. tostring(self.isTppEnabled) .. " WHERE name = 'isTppEnabled'")
        db:exec("UPDATE settings SET value = " .. tostring(self.inverted) .. " WHERE name = 'inverted'")
        db:exec("UPDATE settings SET value = " .. tostring(self.rollAlwaysZero) .. " WHERE name = 'rollAlwaysZero'")
        db:exec("UPDATE settings SET value = " .. tostring(self.yawAlwaysZero) .. " WHERE name = 'yawAlwaysZero'")
        db:exec("UPDATE settings SET value = " .. tostring(self.transitionSpeed) .. " WHERE name = 'transitionSpeed'")
        db:exec("UPDATE settings SET value = " .. tostring(self.zoomFpp) .. " WHERE name = 'zoomFpp'")
        db:exec("UPDATE settings SET value = " .. tostring(self.disableMod) .. " WHERE name = 'disableMod'")
        db:exec("UPDATE settings SET value = " .. tostring(self.zoomSpeed) .. " WHERE name = 'zoomSpeed'")
        db:exec("UPDATE settings SET value = " .. tostring(self.amountCameras) .. " WHERE name = 'amountCameras'")
        db:exec("UPDATE cameras SET x = " .. self.camViews[1].pos.x .. ", y = " .. self.camViews[1].pos.y .. ", z=" .. self.camViews[1].pos.z .. ", rx=" .. self.camViews[1].rot.i .. ", ry=" .. self.camViews[1].rot.j .. ", rz=" .. self.camViews[1].rot.k .. ", rw=" .. self.camViews[1].rot.r .. "  WHERE id = 0")
        db:exec("UPDATE cameras SET x = " .. self.camViews[2].pos.x .. ", y = " .. self.camViews[2].pos.y .. ", z=" .. self.camViews[2].pos.z .. ", rx=" .. self.camViews[2].rot.i .. ", ry=" .. self.camViews[2].rot.j .. ", rz=" .. self.camViews[2].rot.k .. ", rw=" .. self.camViews[2].rot.r .. "  WHERE id = 1")
        db:exec("UPDATE cameras SET x = " .. self.camViews[3].pos.x .. ", y = " .. self.camViews[3].pos.y .. ", z=" .. self.camViews[3].pos.z .. ", rx=" .. self.camViews[3].rot.i .. ", ry=" .. self.camViews[3].rot.j .. ", rz=" .. self.camViews[3].rot.k .. ", rw=" .. self.camViews[3].rot.r .. "  WHERE id = 2")
        db:exec("UPDATE cameras SET x = " .. self.camViews[4].pos.x .. ", y = " .. self.camViews[4].pos.y .. ", z=" .. self.camViews[4].pos.z .. ", rx=" .. self.camViews[4].rot.i .. ", ry=" .. self.camViews[4].rot.j .. ", rz=" .. self.camViews[4].rot.k .. ", rw=" .. self.camViews[4].rot.r .. "  WHERE id = 3")
        db:exec("UPDATE cameras SET x = " .. self.camViews[5].pos.x .. ", y = " .. self.camViews[5].pos.y .. ", z=" .. self.camViews[5].pos.z .. ", rx=" .. self.camViews[5].rot.i .. ", ry=" .. self.camViews[5].rot.j .. ", rz=" .. self.camViews[5].rot.k .. ", rw=" .. self.camViews[5].rot.r .. "  WHERE id = 4")
    end

    if self.inverted then
        self.xroll = -self.xroll
        self.yroll = -self.yroll
    end

    local tppCamera = GetPlayer():FindComponentByName('tppCamera')

    if self.collisions.down then
        if self.collisions.zoomValue > 0.5 then
            self.collisions.zoomValue = 0.5
        end
        if tppCamera:GetLocalPosition().y > -self.camViews[self.camActive].pos.y or tppCamera:GetLocalPosition().y < self.camViews[self.camActive].pos.y then
            self.collisions.zoomValue = 0
        end
        self:Zoom(self.collisions.zoomValue)
        self.collisions.zoomedIn = self.collisions.zoomedIn + self.collisions.zoomValue
    else
        if self.collisions.back and self.collisions.zoomedIn > 0 then
            self:Zoom(-0.1)
            if tppCamera:GetLocalPosition().y > -self.camViews[self.camActive].pos.y or tppCamera:GetLocalPosition().y < self.camViews[self.camActive].pos.y then
                self.collisions.zoomValue = 0
            end
            self.collisions.zoomedIn = self.collisions.zoomedIn - 0.1
        end
    end

    if self.rollAlwaysZero then
        local euler = GetSingleton("Quaternion"):ToEulerAngles(self.camViews[self.camActive].rot)
        self.camViews[self.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(0, euler.pitch, euler.yaw))
		tppCamera:SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(0, euler.pitch, euler.yaw)))
    end

    self.updateSettingsTimer = self.updateSettingsTimer - delta

    self.inScene = Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet)

    if self.inScene then
        self.resetCams = true
    end

    local quat = tppCamera:GetLocalOrientation()

    tppCamera:SetFOV(self.fov)

    if self.moveCamera then
        local newPos = Vector4.new(
            self.camViews[self.camActive].pos.x + self.xroll / 10, 
            self.camViews[self.camActive].pos.y,
            self.camViews[self.camActive].pos.z + self.yroll / 10, 1)

        self.camViews[self.camActive].pos = newPos
        tppCamera:SetLocalPosition(Vector4.new(newPos.x, newPos.y, newPos.z + self.offset, 1))
        self.updateSettings = true

        self.xroll = 0
        self.yroll = 0
    end

    if self.moveCameraOnPlane then
        local newPos = Vector4.new(
            self.camViews[self.camActive].pos.x + self.xroll / 10, 
            self.camViews[self.camActive].pos.y + self.yroll / 10,
            self.camViews[self.camActive].pos.z, 1)

        self.camViews[self.camActive].pos = newPos
        tppCamera:SetLocalPosition(Vector4.new(newPos.x, newPos.y, newPos.z + self.offset, 1))
        self.updateSettings = true

        self.xroll = 0
        self.yroll = 0
    end

    local isDirectMovement = false
    
    if (tppCamera.headingLocked and self.isTppEnabled) or (self.directionalMovement and self.isTppEnabled and not JB.inScene and not JB.inCar) or self.controllerRightTrigger or self.controllerLeftTrigger then
        if self.controllerLeftTrigger then
            self.xroll = 2
            self.controllerLeftTrigger = false
        end

        if self.controllerRightTrigger then
            self.xroll = -2
            self.controllerRightTrigger = false
        end
        
        local delta_quatX   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(0,0,1,0), -self.xroll * delta)
        local delta_quatY   = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(1,0,0,0), self.yroll * delta)

        quat = self:RotateQuaternion(quat, delta_quatX)
        quat = self:RotateQuaternion(quat, delta_quatY)

        local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, self.camViews[self.camActive].pos.z, 0))

        self.camViews[self.camActive].rot = quat

        tppCamera:SetLocalOrientation(quat)
        tppCamera:SetLocalPosition(Vector4.new(stick.x, stick.y, stick.z + self.offset, 1))

        self.moveHorizontal  = false
    end

    if not self.directionalMovement and self.isTppEnabled and not JB.inScene and not JB.inCar then
        isDirectMovement = true
        local delta_quatY = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(1,0,0,0), self.yroll * delta)

        quat = self:RotateQuaternion(quat, delta_quatY)

        local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, self.camViews[self.camActive].pos.z, 0))

        self.camViews[self.camActive].rot = quat

        tppCamera:SetLocalOrientation(quat)
        tppCamera:SetLocalPosition(Vector4.new(stick.x, stick.y, stick.z + self.offset, 1))

        self.moveHorizontal  = false
    end

    if isDirectMovement then
        if self.yawAlwaysZero then
            local euler = GetSingleton("Quaternion"):ToEulerAngles(self.camViews[self.camActive].rot)
            self.camViews[self.camActive].rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, 0))
            tppCamera:SetLocalOrientation(GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, 0)))
        end
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
                local ts     = Game.GetTransactionSystem()
                local player = Game.GetPlayer()
                ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
                Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
                Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):EnablePlayerTPPRepresenation(false)
                GetPlayer():FindComponentByName('camera'):Activate(0.1)
                self:DeactivateTPP(false)
			end
	    end

        if self.switchBackToTpp and not Attachment:HasWeaponActive() then
            self:ActivateTPP()
            self.switchBackToTpp = false
        end
    end

    if self.isTppEnabled and not self.inCar and self.inScene then
        tppCamera.yawMaxLeft = 3600
        tppCamera.yawMaxRight = -3600
        tppCamera.pitchMax = 100
        tppCamera.pitchMin = -100
    end

    if(self.inCar and self.isTppEnabled and not self.carCheckOnce) then
		self.carCheckOnce = true
	end

	if(not self.inCar and self.carCheckOnce) then
		self.carCheckOnce = false
		self.waitForCar   = true
		self.waitTimer    = 0.0
	end

	if(self.timerCheckClothes > 5.0) then
        
        if not self.photoModeBeenActive and self.isTppEnabled then
            if not Attachment:HasWeaponActive() then
                Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
            end
        end

        if not self.isTppEnabled and not self.inCar then
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
        end

        local bump = GetPlayer():FindComponentByName('BumpComponent')
        if bump ~= nil then
            bump.isEnabled = false
        end

        local cus = GetPlayer():FindComponentByName('uiCharacterCustomizationGenitalsController0140')
        if cus ~= nil then
            cus.forceHideGenitals = false
        end

        self.timerCheckClothes = 0.0
    end

	if(tppCamera:GetLocalPosition().x == 0.0 and tppCamera:GetLocalPosition().y == 0.0 and tppCamera:GetLocalPosition().z == 0.0) then
        self:SetEnableTPPValue(false)
	end

    if self.zoomIn then
        self:Zoom(self.zoomSpeed)
    end

    if self.zoomOut then
        self:Zoom(-self.zoomSpeed)
    end

    if self.camViews[self.camActive].pos.y < 0 then
        self:Collsion()
    end

    self.colliedTimer = self.colliedTimer - delta

    if self.isTppEnabled then
        self:FppCameraMoveDown()
    end

    if self.camViews[self.camActive].rot == Quaternion.new(0, 0, 0, 0) then
        print("JB: Gimbal lock!")
        self.camViews[self.camActive].rot = Quaternion.new(0, 0, 0, 1)
    end
end

function JB:FppCameraMoveDown()
    local fppCam    = GetPlayer():FindComponentByName('camera')
    local dist      = GetSingleton("Vector4"):Distance(GetPlayer():FindComponentByName('tppCamera'):GetLocalToWorld():GetTranslation(), fppCam:GetLocalToWorld():GetTranslation())
    
    if dist < 0.50 then
        local loc = fppCam:GetLocalPosition()
        fppCam:SetLocalPosition(Vector4.new(loc.x, loc.y, loc.z - 0.1, 1));
    end
end

function JB:Collsion()
    local filters = {
		'Static',
		'Water',
		'Terrain',
    }

    self.collisions.down = false

    local tppCam    = GetPlayer():FindComponentByName('tppCamera')
    local fppCam    = GetPlayer():FindComponentByName('camera')
    local from      = fppCam:GetLocalToWorld():GetTranslation()
    local to        = tppCam:GetLocalToWorld():GetTranslation()
    local forw      = GetPlayer():GetWorldForward()

    local extendedTo = Vector4.new(to.x - forw.x, to.y - forw.y, to.z, 1)

    for _, filter in ipairs(filters) do
        local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)
        if success then
            self.collisions.down = true
            self.collisions.zoomValue = 0.2
        end
    end

    self.collisions.back = true

    for _, filter in ipairs(filters) do
        local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, extendedTo, filter, false, false)
        if success then
            self.collisions.back = false
        end
    end

    from = tppCam:GetLocalToWorld():GetTranslation()
    to = Vector4.new(from.x, from.y, from.z - 0.5, 1)

    for _, filter in ipairs(filters) do
        local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)
        if success then
            self.collisions.back = false
        end
    end

    to = Vector4.new(from.x, from.y, from.z + 0.5, 1)

    for _, filter in ipairs(filters) do
        local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)
        if success then
            self.collisions.back = false
        end
    end

    to = Vector4.new(from.x, from.y - 0.5, from.z, 1)

    for _, filter in ipairs(filters) do
        local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)
        if success then
            self.collisions.back = false
        end
    end

    to = Vector4.new(from.x, from.y + 0.5, from.z, 1)

    for _, filter in ipairs(filters) do
        local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)
        if success then
            self.collisions.back = false
        end
    end
end

function JB:RotateQuaternion(orig_quat, delta_quat)
    local x = orig_quat.r * delta_quat.i + orig_quat.i * delta_quat.r - orig_quat.j * delta_quat.k - orig_quat.k * delta_quat.j;
    local y = orig_quat.r * delta_quat.j + orig_quat.j * delta_quat.r + orig_quat.k * delta_quat.i + orig_quat.i * delta_quat.k;
    local z = orig_quat.r * delta_quat.k + orig_quat.k * delta_quat.r - orig_quat.i * delta_quat.j + orig_quat.j * delta_quat.i;
    local w = orig_quat.r * delta_quat.r + orig_quat.i * delta_quat.i + orig_quat.j * delta_quat.j - orig_quat.k * delta_quat.k;

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
    self.updateSettings = true
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].defaultZoomLevel
	self:UpdateCamera()
end

function JB:Zoom(i)
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].pos.y + i
end

function JB:RestoreFPPView()
	if not self.isTppEnabled then
        GetPlayer():FindComponentByName('camera'):SetLocalPosition(Vector4.new(0, 0, 0, 1))
        GetPlayer():FindComponentByName('camera'):Activate(self.transitionSpeed)
	end
end

function JB:UpdateCamera()
	if self.isTppEnabled then
		GetPlayer():FindComponentByName('tppCamera'):SetLocalPosition(Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, self.camViews[self.camActive].pos.z + self.offset, 1))
		GetPlayer():FindComponentByName('tppCamera'):SetLocalOrientation(self.camViews[self.camActive].rot)
	end
end

function JB:ActivateTPP()
    if not self.inCar then
        local replacer      = ""
        local replacePlayer = false
        local placeHead     = false

        if self.jb_replacers ~= nil then
            replacer        = self.jb_replacers.replacer
            replacePlayer   = self.jb_replacers.replacePlayer
            placeHead       = self.jb_replacers.placeHead
        end

        local tpp = ActivateTPPRepresentationEvent.new()
        tpp.playerController = Game.GetPlayer()
        GetPlayer():QueueEvent(tpp)
        
        if replacer == '' and not replacePlayer then 
            Gender:AddTppHead()
        else
            if not placeHead then
                Cron.After(1.0, function ()
                    if self.jb_replacers ~= nil then
                        self.jb_replacers.replaceF = replacer
                    end
                end)
                Gender:AddFppHead()
            end
        end

        if placeHead then
            Gender:AddTppHead()
        end

        if replacer ~= '' and replacePlayer then
            if self.jb_replacers ~= nil then
                self.jb_replacers.replaceF = replacer
            end
        end

        Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
        GetPlayer():FindComponentByName('tppCamera'):Activate(self.transitionSpeed)
        self:SetEnableTPPValue(true)
        self:UpdateCamera()
    end
end

function JB:DeactivateTPP(noUpdate)
    -- IFP FIX
    GetPlayer():FindComponentByName('camera'):ResetPitch()

	if self.isTppEnabled and noUpdate == nil then
        local ts     = Game.GetTransactionSystem()
        local player = Game.GetPlayer()
        Cron.After(self.transitionSpeed, function()
            ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
        end)
	end

	self:SetEnableTPPValue(false)
	self:RestoreFPPView()
end

function JB:NextCam()
    self.updateSettings = true
    self:SwitchCamTo(self.camActive + 1)
end

function JB:SwitchCamTo(cam)
	if cam < self.amountCameras + 1 then
	    self.camActive = cam
		self:UpdateCamera()
	else
		self.camActive = 1
		self:UpdateCamera()
	end
end

function JB:GetPlayerObjects()
    local targetingSystem = Game.GetTargetingSystem();
    local parts = {};
    local searchQuery = Game["TSQ_ALL;"]()

    targetingSystem:AddIgnoredCollisionEntities(Game.GetPlayer())
    
    searchQuery.maxDistance = 10
    searchQuery.testedSet = Enum.new('gameTargetingSet', 4)

    success, parts = targetingSystem:GetTargetParts(Game.GetPlayer(), searchQuery);

    return parts
end

function JB:GetEYEObjects()
    local targetingSystem = Game.GetTargetingSystem();

    if targetingSystem ~= nil then
        local parts = {};
        local searchQuery = Game["TSQ_ALL;"]()

        targetingSystem:AddIgnoredCollisionEntities(Game.GetPlayer())
        
        searchQuery.maxDistance = 15

        success, parts = targetingSystem:GetTargetParts(Game.GetPlayer(), searchQuery);

        return parts
    end

    return {};
end

return JB:new()