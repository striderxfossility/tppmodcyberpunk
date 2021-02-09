local Gender     = require("classes/Gender.lua")
local Attachment = require("classes/Attachment.lua")

local JB         = {}
      JB.__index = JB

function JB:new()
    local class = {}

    ----------VARIABLES-------------
    class.camViews            = {}
    class.camActive           = 1
    class.isTppEnabled        = false
    class.inCar               = false
    class.timeStamp           = 0.0
    class.weaponOverride      = true
    class.animatedFace        = false
    class.allowCameraBobbing  = false
    class.switchBackToTpp     = false
    class.carCheckOnce        = false
    class.waitForCar          = false
    class.waitTimer           = 0.0
    class.timerCheckClothes   = 0.0
    class.carActivated        = false
    class.photoModeBeenActive = false
    ----------VARIABLES-------------

    setmetatable( class, JB )
    return class
end

function JB:CheckForRestoration()
    local PlayerSystem = Game.GetPlayerSystem()
    local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
    local fppCam       = PlayerPuppet:GetFPPCameraComponent()
    local script       = Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):GetGameInstance()
    local photoMode    = script:GetPhotoModeSystem(script)

	if(photoMode:IsPhotoModeActive(true)) then
		self.photoModeBeenActive = true
		Attachment.TurnArrayToPerspective({'AttachmentSlots.Chest', 'AttachmentSlots.Torso', 'AttachmentSlots.Head'}, 'FPP')
	else
		if self.photoModeBeenActive then
			self.photoModeBeenActive = false
			Attachment.TurnArrayToPerspective({'AttachmentSlots.Chest', 'AttachmentSlots.Torso', 'AttachmentSlots.Head'}, 'TPP')
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

	self.inCar = Game.GetWorkspotSystem():IsActorInWorkspot(PlayerPuppet)

    if(self.inCar and self.isTppEnabled and not self.carCheckOnce) then
        Gender.AddTppHead()
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

        Attachment:TurnArrayToPerspective({"AttachmentSlots.Chest", "AttachmentSlots.Torso", "AttachmentSlots.Head"}, "TPP")

        self.timerCheckClothes = 0.0
    end

	if(fppCam:GetLocalPosition().x == 0.0 and fppCam:GetLocalPosition().y == 0.0 and fppCam:GetLocalPosition().z == 0.0) then
		self.isTppEnabled = false
	end
end

function JB:CarTimer(deltaTime)
	if(self.waitTimer > 0.4) then
		self.tppHeadActivated = false
		self.isTppEnabled     = true
        self:UpdateCamera()
        Gender:AddHead(self.animatedFace)
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

function JB:Zoom(z)
	self.camViews[self.camActive].pos.y = self.camViews[self.camActive].pos.y + z
	self:UpdateCamera()
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
    self.isTppEnabled = true
    self:UpdateCamera()
    Gender:AddHead(self.animatedFace)
end

function JB:DeactivateTPP ()
	if self.isTppEnabled then
        local ts     = Game.GetTransactionSystem()
        local player = Game.GetPlayer()
		ts:RemoveItemFromSlot(player, TweakDBID.new('AttachmentSlots.TppHead'), true, true, true)
	end

	self.isTppEnabled = false
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
	   self.camActive       = cam

		if(self.camViews[cam].freeform) then
			ic:SetIsPlayerInspecting(true)
		else 
			ic:SetIsPlayerInspecting(false)
		end

		self:UpdateCamera()
	else
		self.camActive = 1
		ic:SetIsPlayerInspecting(false)
		self:UpdateCamera()
	end
end

return JB:new()