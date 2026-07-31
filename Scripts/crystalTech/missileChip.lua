MC = class(nil)
MC.maxChildCount = -1
MC.connectionOutput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power

MC.colorNormal = sm.color.new(0x14514ff)
MC.colorHighlight = sm.color.new(0x114514aa)

function MC.server_onCreate(self)
	self.shape.interactable:setActive(false)
	self.shape.interactable:setPower(0)
	self.activated = false
	self.counter = 0
	if self.shape.body:isOnLift() then
        self.interactable:setPublicData({state = "modify"})
    end
end

function MC.server_onFixedUpdate(self,dt)
	if self.shape.interactable.publicData ~= nil then
		if self.shape.interactable.publicData.state == "modify" then --编辑
			self.shape.interactable:setActive(false)
			self.shape.interactable:setPower(0)
		elseif self.shape.interactable.publicData.state == "time" then  -- 带燃料
			self.counter = self.counter + dt
			if self.counter > 10 then
				self.shape.interactable:setActive(false)
				self.shape.interactable:setPower(0)
			else
				self.shape.interactable:setActive(true)
				self.shape.interactable:setPower(1)
			end
		else
			if not self.activated then
				self.shape.interactable:setActive(true)
				self.shape.interactable:setPower(1)
				self.activated = true
			end
		end
	end
end

