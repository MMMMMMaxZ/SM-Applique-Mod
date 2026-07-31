Test = class(nil)
Test.maxParentCount = 1
Test.connectionInput = sm.interactable.connectionType.logic
Test.poseWeightCount = 1
Test.SwordLength = 100

function Test.server_onFixedUpdate(self,dt)
	local input = self.interactable:getSingleParent()
	if input then
		if input:isActive() then
			local selfPos = self.shape:getWorldPosition()
			local selfAt = self.shape:getAt()
			local startPos = selfPos + selfAt*0.2
			local endPos = selfPos + selfAt*self.SwordLength
			local hit,result = sm.physics.raycast(startPos,endPos,self.shape.body)
			if hit then
				sm.physics.explode(result.pointWorld,7,0.15,0,0,nil,self.shape)
			end
		end
	end
end

function Test.client_onInteract( self,character,state)
	 if not state then return end
	
end