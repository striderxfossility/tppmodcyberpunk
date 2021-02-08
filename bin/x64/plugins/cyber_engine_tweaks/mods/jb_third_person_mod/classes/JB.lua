local JB = {}
JB.__index = JB

function JB:new()
    local class = {}

    ----------VARIABLES-------------
    class.camViews = {}
    class.camActive = 0
    class.isTppEnabled = false
    ----------VARIABLES-------------

    setmetatable( class, JB )
    return class
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

function JB:UpdateCamera ()
	if self.isTppEnabled then
        local PlayerSystem = Game.GetPlayerSystem()
        local PlayerPuppet = PlayerSystem:GetLocalPlayerMainGameObject()
        local fppCam       = PlayerPuppet:GetFPPCameraComponent()

		fppCam:SetLocalPosition(self.camViews[self.camActive].pos)
		fppCam:SetLocalOrientation(self.camViews[self.camActive].rot)
	end
end

function JB:ActivateTPP ()
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
    local ts = Game.GetTransactionSystem()

	if self.camViews[cam] ~= nil then
        self.camActive = cam

		if(self.camViews[cam].freeform) then
			ts:SetIsPlayerInspecting(true)
		else 
			ts:SetIsPlayerInspecting(false)
		end

		self:UpdateCamera()
	else
		self.camActive = 1
		ts:SetIsPlayerInspecting(false)
		self:UpdateCamera()
	end
end

return JB:new()