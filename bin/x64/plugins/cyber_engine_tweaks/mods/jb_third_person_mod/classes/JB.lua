local Gender     = require("classes/Gender.lua")
local Attachment = require("classes/Attachment.lua")
local Ref        = require("classes/Ref.lua")

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

    for index, value in db:rows("SELECT value FROM settings WHERE name = 'directionalStaticCamera'") do
        if(index[1] == 0) then
            class.directionalStaticCamera = false
        else
            class.directionalStaticCamera = true
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
    class.moveHorizontal      = false
    class.xroll               = 0.0
    class.yroll               = 0.0
    class.IsMoving            = false
    class.onChangePerspective = false
    class.previousPerspective = false
    class.johnnyEntId         = nil
    class.foundJohnnyEnt      = false
    class.johnnyEnt           = nil
    class.secondCam           = nil
    class.isInitialized       = false
    class.offset              = 5
    class.controllerZoom      = false
    class.controller360       = false
    class.controllerRightTrigger = false
    class.controllerLeftTrigger = false
    class.eyesTimer           = 5.0
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
    local script       = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
    local photoMode    = script.GetPhotoModeSystem()
    local fppCam       = PlayerPuppet:GetFPPCameraComponent()

    self.inScene = Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet)

    if self.secondCam == nil then
        return
    end

    local quat = self.secondCam:GetLocalOrientation()
    
    if (fppCam.headingLocked and self.isTppEnabled) or (self.directionalMovement and self.isTppEnabled and not JB.inScene and not JB.inCar) or self.controllerRightTrigger or self.controllerLeftTrigger then

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

        local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, 0, 0))

        self.secondCam:SetLocalOrientation(quat)
        self.secondCam:SetLocalPosition(Vector4.new(stick.x, stick.y, stick.z + self.offset, 1))

        self.moveHorizontal  = false
    end

    if not self.directionalMovement and self.isTppEnabled and not JB.inScene and not JB.inCar then
        local delta_quatY = GetSingleton('Quaternion'):SetAxisAngle(Vector4.new(1,0,0,0), self.yroll * delta)

        quat = self:RotateQuaternion(quat, delta_quatY)

        local stick = GetSingleton('Quaternion'):Transform(quat, Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, 0, 0))

        self.secondCam:SetLocalOrientation(quat)
        self.secondCam:SetLocalPosition(Vector4.new(stick.x, stick.y, stick.z + self.offset, 1))

        self.moveHorizontal  = false
    end

    local str = "player_photomode_head"

    if self.animatedFace then
        str = "character_customization_head"
    end

    self.headTimer = self.headTimer - delta
    
    if self.headTimer <= 0 then
        if self.isTppEnabled and not self.inCar then
            if Gender:IsMale() then
                Game.EquipItemOnPlayer("Items.CharacterCustomizationMaHead", "TppHead")
            else
                Game.EquipItemOnPlayer("Items.CharacterCustomizationMaHead", "TppHead")
            end
        else
            if not self.inCar then
                if not (tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')) == "player_fpp_head") then
                    Gender:AddFppHead()
                end
            end
        end

        self.headTimer = 2
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

    if self.isTppEnabled and not self.inCar and self.inScene or self.camViews[self.camActive].freeform then
        self.secondCam.yawMaxLeft = 3600
        self.secondCam.yawMaxRight = -3600
        self.secondCam.pitchMax = 100
        self.secondCam.pitchMin = -100
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

        if not self.isTppEnabled and not self.inCar then
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
        end

        if self.inCar and not PlayerPuppet:FindVehicleCameraManager():IsTPPActive() and self.isTppEnabled then
            self:DeactivateTPP()
        end

        if PlayerPuppet:FindVehicleCameraManager():IsTPPActive() then
            Gender:AddHead(self.animatedFace)
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "TPP")
        end

        if not PlayerPuppet:FindVehicleCameraManager():IsTPPActive() and self.secondCam:GetLocalPosition() == Vector4.new(0, 0, 0, 1) then
            Gender:AddFppHead()
            Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
        end

        self.timerCheckClothes = 0.0
    end

	if(self.secondCam:GetLocalPosition().x == 0.0 and self.secondCam:GetLocalPosition().y == 0.0 and self.secondCam:GetLocalPosition().z == 0.0) then
        self:SetEnableTPPValue(false)
	end

    if self.inScene and not self.inCar and photoMode:IsPhotoModeActive() then
        if not (tostring(Attachment:GetNameOfObject('AttachmentSlots.TppHead')) == str) then
            Gender:AddHead(self.animatedFace)
        end
    end
end

function JB:UpdateSecondCam()
    if not self.foundJohnnyEnt then
        if Game.FindEntityByID(self.johnnyEntId) ~= nil then
            self.foundJohnnyEnt                 = true
            self.johhnyEnt          	        = Ref.Weak(Game.FindEntityByID(self.johnnyEntId)) -- the spawned object
            self.johhnyEnt.audioResourceName    = CName.new("johnnysecondcam")

            local root = self.johhnyEnt:FindComponentByName(CName.new("root"))

            root:SetLocalPosition(Vector4.new(0, 0, -self.offset, 1))
            
            self.secondCam = Ref.Weak(self.johhnyEnt:FindComponentByName(CName.new("camera")))

            self.secondCam:SetLocalPosition(Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, self.offset, 1))

            self:DeactivateMesh()

            print('Jb Third Person Mod Loaded')
        end
    end

    if self.secondCam ~= nil then
        local PlayerSystem = Game.GetPlayerSystem()
        local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
        local fppCam       = PlayerPuppet:GetFPPCameraComponent()

        self.secondCam:SetLocalPosition(Vector4.new(self.secondCam:GetLocalPosition().x, self.secondCam:GetLocalPosition().y, fppCam:GetLocalPosition().z + self.offset, 1))

        local moveEuler = EulerAngles.new(0, 0, Game.GetPlayer():GetWorldYaw())
        local transform = Game.GetPlayer():GetWorldPosition()
        local vec = Vector4.new(transform.x, transform.y, transform.z - 0)
        if self.johhnyEnt ~= nil then
            Game.GetTeleportationFacility():Teleport(self.johhnyEnt, vec, moveEuler)
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
        Gender:AddHead(self.animatedFace)
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

function JB:Zoom(i)
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].pos.y + i
end

function JB:RestoreFPPView()
	if not self.isTppEnabled then
        local PlayerSystem = Game.GetPlayerSystem()
        local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
        local fppCam       = PlayerPuppet:GetFPPCameraComponent()

        fppCam:Activate(1)
	end
end

function JB:UpdateCamera()
	if self.isTppEnabled then
		self.secondCam:SetLocalPosition(Vector4.new(self.camViews[self.camActive].pos.x, self.camViews[self.camActive].pos.y, self.camViews[self.camActive].pos.z + self.offset, 1))
		self.secondCam:SetLocalOrientation(self.camViews[self.camActive].rot)
	end
end

function JB:ActivateTPP()
    Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head", "AttachmentSlots.Outfit", "AttachmentSlots.Eyes"}, "TPP")
    self.secondCam:Activate(1)
    self:SetEnableTPPValue(true)
    self:UpdateCamera()
    Gender:AddHead(self.animatedFace)
end

function JB:DeactivateTPP(noUpdate)
    local PlayerSystem = Game.GetPlayerSystem()
    local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
    local fppCam       = PlayerPuppet:GetFPPCameraComponent()

    fppCam:ResetPitch()

	if self.isTppEnabled and noUpdate == nil then
        local ts     = Game.GetTransactionSystem()
        local player = Game.GetPlayer()
		ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
        Attachment:TurnArrayToPerspective({"AttachmentSlots.Head", "AttachmentSlots.Eyes"}, "FPP")
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
    local parts = {};
    local searchQuery = Game["TSQ_ALL;"]()

    targetingSystem:AddIgnoredCollisionEntities(Game.GetPlayer())
    
    searchQuery.maxDistance = 10
    searchQuery.testedSet = Enum.new('gameTargetingSet', 0)

    success, parts = targetingSystem:GetTargetParts(Game.GetPlayer(), searchQuery);

    return parts
end

function JB:DeactivateMesh()
    local search = Game.FindEntityByID(self.johnnyEntId)
    search:FindComponentByName(CName.new("t0_000_pma_base__full_shadow")).isEnabled = false
    search:FindComponentByName(CName.new("legs")).isEnabled = false
    search:FindComponentByName(CName.new("shoes")).isEnabled = false
    search:FindComponentByName(CName.new("head_shadowmesh")).isEnabled = false
    search:FindComponentByName(CName.new("a0_008_ma__fpp_right_q001_injection_mark")).isEnabled = false
    search:FindComponentByName(CName.new("n0_000_pma_base__full")).isEnabled = false
    search:FindComponentByName(CName.new("a0_000_nomad_base_fists")).isEnabled = false
    search:FindComponentByName(CName.new("t0_000_pma_base__full_shadow")).isEnabled = false
    search:FindComponentByName(CName.new("shadow")).isEnabled = false
    search:FindComponentByName(CName.new("OccupantSlots")).isEnabled = false
    search:FindComponentByName(CName.new("CarryOverrides")).isEnabled = false
    search:FindComponentByName(CName.new("WidgetHud0516")).isEnabled = false
    search:FindComponentByName(CName.new("cyberspace_character_light")).isEnabled = false
    search:FindComponentByName(CName.new("EffectSpawnercs101")).isEnabled = false
    search:FindComponentByName(CName.new("VisionModeActivator")).isEnabled = false
    search:FindComponentByName(CName.new("AnimationControllerComponent")).isEnabled = false
    search:FindComponentByName(CName.new("Slot1777")).isEnabled = false
    search:FindComponentByName(CName.new("Inventory")).isEnabled = false
    search:FindComponentByName(CName.new("fx")).isEnabled = false
    search:FindComponentByName(CName.new("AttachmentSlots")).isEnabled = false
    search:FindComponentByName(CName.new("phone")).isEnabled = false
    search:FindComponentByName(CName.new("inspect")).isEnabled = false
    search:FindComponentByName(CName.new("DEBUG_Visualizer")).isEnabled = false
    search:FindComponentByName(CName.new("BodyDescription")).isEnabled = false
    search:FindComponentByName(CName.new("PuppetMountable4032")).isEnabled = false
    search:FindComponentByName(CName.new("MoveComponent")).isEnabled = false
    search:FindComponentByName(CName.new("AnimGraphResourceContainer")).isEnabled = false
    search:FindComponentByName(CName.new("CombatHUDManager")).isEnabled = false
    search:FindComponentByName(CName.new("CarAnimsets")).isEnabled = false
    search:FindComponentByName(CName.new("TriggerActivator")).isEnabled = false
    search:FindComponentByName(CName.new("PlayerVoice")).isEnabled = false
    search:FindComponentByName(CName.new("slots")).isEnabled = false
    search:FindComponentByName(CName.new("fx_player")).isEnabled = false
    search:FindComponentByName(CName.new("hud_component")).isEnabled = false
    search:FindComponentByName(CName.new("monodisc_light")).isEnabled = false
    search:FindComponentByName(CName.new("menu_component")).isEnabled = false
    search:FindComponentByName(CName.new("EnvTriggerActivator")).isEnabled = false
    search:FindComponentByName(CName.new("LeftFootRepeller")).isEnabled = false
    search:FindComponentByName(CName.new("RightFootRepeller")).isEnabled = false
    search:FindComponentByName(CName.new("HipsRepeller")).isEnabled = false
    search:FindComponentByName(CName.new("HitPhysicalQueryMesh")).isEnabled = false
    search:FindComponentByName(CName.new("HitRepresentation")).isEnabled = false
    search:FindComponentByName(CName.new("ItemAttachmentSlots")).isEnabled = false
    search:FindComponentByName(CName.new("targeting_primary")).isEnabled = false
    search:FindComponentByName(CName.new("targeting_cyberarm")).isEnabled = false
    search:FindComponentByName(CName.new("fx_status_effects")).isEnabled = false
    search:FindComponentByName(CName.new("ScanningActivator")).isEnabled = false
    search:FindComponentByName(CName.new("PlayerMappin5838")).isEnabled = false
    search:FindComponentByName(CName.new("PlayerGarage")).isEnabled = false
    search:FindComponentByName(CName.new("PlayerInteractions")).isEnabled = false
    search:FindComponentByName(CName.new("quickSlots")).isEnabled = false
    search:FindComponentByName(CName.new("EffectAttachment5471")).isEnabled = false
    search:FindComponentByName(CName.new("UI_Slots")).isEnabled = false
    search:FindComponentByName(CName.new("BumpComponent")).isEnabled = false
    search:FindComponentByName(CName.new("FX_Glitches")).isEnabled = false
    search:FindComponentByName(CName.new("StimBroadcaster")).isEnabled = false
    search:FindComponentByName(CName.new("TargetingActivator8632")).isEnabled = false
    search:FindComponentByName(CName.new("fx_damage")).isEnabled = false
    search:FindComponentByName(CName.new("TEMP_flashlight")).isEnabled = false
    search:FindComponentByName(CName.new("ResourceLibrary")).isEnabled = false
    search:FindComponentByName(CName.new("EffectAttachment5224")).isEnabled = false
    search:FindComponentByName(CName.new("targetShootComponent")).isEnabled = false
    search:FindComponentByName(CName.new("PlayerTier7886")).isEnabled = false
    search:FindComponentByName(CName.new("senseSensorObject")).isEnabled = false
    search:FindComponentByName(CName.new("disarm")).isEnabled = false
    search:FindComponentByName(CName.new("TransformHistoryComponent")).isEnabled = false
    search:FindComponentByName(CName.new("QuestCustomEffects")).isEnabled = false
    search:FindComponentByName(CName.new("senseVisibleObject")).isEnabled = false
    search:FindComponentByName(CName.new("influenceObstacle")).isEnabled = false
    search:FindComponentByName(CName.new("fx_cyberware")).isEnabled = false
    search:FindComponentByName(CName.new("Slot6342")).isEnabled = false
    search:FindComponentByName(CName.new("q_blood_mesh_decal")).isEnabled = false
    search:FindComponentByName(CName.new("environmentDamageReceiver")).isEnabled = false
    search:FindComponentByName(CName.new("WorldSpaceBlendCamera")).isEnabled = false
    search:FindComponentByName(CName.new("vehicleTPPCamera")).isEnabled = false
    search:FindComponentByName(CName.new("vehicleCameraManager")).isEnabled = false
    search:FindComponentByName(CName.new("vehicleVehicleProxyBlendCamera4681")).isEnabled = false
    search:FindComponentByName(CName.new("BigObjectsRepeller")).isEnabled = false
    search:FindComponentByName(CName.new("VisualController5425")).isEnabled = false
    search:FindComponentByName(CName.new("7551")).isEnabled = false

    search:ScheduleAppearanceChange(CName.new("None"))
    Game.GetTransactionSystem():RemoveAllItems(search)
    search.renderSceneLayerMask = Enum.new("RenderSceneLayerMask", 2)
end

return JB:new()