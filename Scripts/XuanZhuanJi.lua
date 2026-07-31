XZJ = class(nil)
XZJ.maxParentCount = -1
XZJ.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
XZJ.colorNormal = sm.color.new(0x14514ff)
XZJ.colorHighlight = sm.color.new(0x114514aa)
XZJ.poseWeightCount = 1

function XZJ.server_onCreate(self)
	ObjectX = sm.shape.getRight(self.shape)
	self.turning = false
end

function XZJ.server_onFixedUpdate(self,dt)
	local input
	self.inputActive = false
	self.inputPower = 0
	local lastInput = false
	for k, v in pairs(self.interactable:getParents()) do
		input = v
		self.inputActive = input.active or lastInput
		lastin = input.active
		self.inputPower = self.inputPower + input.power
	end
	if input then
		if self.inputActive == true then
			if self.turning == false then
				
				--print(self.inputPower)
				local ObjectX2 = ObjectX.rotateY(ObjectX,100*self.inputPower)
				sm.physics.applyTorque(self.shape.body,ObjectX2)
				self.turning = true
			end
		else
			self.turning = false
		end
	end
end