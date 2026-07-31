MDS = class(nil)
MDS.maxParentCount = 1
MDS.maxChildCount = -1
MDS.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
MDS.connectionOutput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power
MDS.poseWeightCount = 1

MDS.colorNormal = sm.color.new(0x14514ff)
MDS.colorHighlight = sm.color.new(0x114514aa)

MDS.ZDMKUuid = "5006aaba-5494-11e6-beb8-9e71128cae77"
--MDS.Meye = "796ddab6-e143-4c2c-9037-dc77579576da"

function MDS.server_onCreate(self)
	self.ready = true
	self.shoot = false
	self.counter = 0
	self.preCold = 0
	--print(self.data.CD)
	--print(self.data.delay)
	if inspectAmountIsWrong(self) then
		self.network:sendToClients("client_warning")
		self.shape:destroyPart()
	end
	self.UUIDs = sm.json.open("$MOD_DATA/Scripts/UUID/UUID.json")
end

function MDS.server_onFixedUpdate(self,dt)
	--self.delay --> 运作时间
	--self.CD --> 冷却时间
	--self.preCold --> 预冷却时间
	local input = self.interactable:getSingleParent()
	if input then
		if self.shoot then
			self.counter = self.counter + dt
			if not input:isActive() then self.preCold = self.preCold + dt end
			if self.counter <= self.data.delay then
				self.ready = true
				self.interactable:setActive(true)
			elseif self.counter <=self.data.CD+self.data.delay - self.preCold then
				self.ready = false
				self.interactable:setActive(false)
			else
				self.interactable:setActive(true)
				self.ready = true
				self.shoot = false
				self.counter = 0
				self.preCold = 0
			end
		end
		if input:isActive() and self.ready then
			if inspectAmountIsWrong(self) then
				self.network:sendToClients("client_warning","该型号干扰系统超过"..self.data.maxAmount.."台，无法运作")
				self.counter = 0
			else
				--print("start")
				--print(self.counter)
				--print(dt)
				self.shoot = true
				local allBodies = sm.body.getAllBodies()
				local creationBodies = self.shape.body.getCreationBodies(self.shape.body)
				local selfPosition = sm.shape.getWorldPosition(self.shape)
				for k,v in pairs(allBodies)do
					local currentBodyPosition = v:getWorldPosition()
					local length2 = sm.vec3.length2(selfPosition-currentBodyPosition)
					--print(v)
					--print(selfPosition)
					--print(currentBodyPosition)
					--print(length2)
					if length2 < self.data.disturbRadius then
						local inCreation = false
						for k2,v2 in pairs(creationBodies)do
							if v2 == v then
								inCreation = true
							end
						end
						if not inCreation then
							local MissileShapes = v:getShapes()
							local effectTable = {}
							for k2,v2 in pairs(MissileShapes)do
								if tostring(v2.uuid)==self.ZDMKUuid or tostring(v2.uuid)==self.UUIDs[1].Meye then
									--print(selfPosition-currentBodyPosition)
									sm.physics.applyImpulse(v,v.velocity*v.mass*-1)
									sm.physics.applyImpulse(v,sm.vec3.normalize(v2.worldPosition-selfPosition)*500,true)
									--[[self.targetPosition = v.worldPosition
									local localX = sm.shape.getRight(v2)
									local localY = sm.shape.getAt(v2)
									local localZ = sm.shape.getUp(v2)
									self.totalMass = v.mass
									self.targetVec = sm.vec3.normalize(sm.shape.getWorldPosition(self.shape) - self.targetPosition) * -0.5 * self.totalMass
									--print("new",sm.vec3.new(self.targetVec:dot(localX), self.targetVec:dot(localY), self.targetVec:dot(localZ)))
									--print("ori",self.targetVec)
									--print("end")
									sm.physics.applyImpulse(v2, sm.vec3.new(self.targetVec:dot(localX), self.targetVec:dot(localY), self.targetVec:dot(localZ)))
									--sm.physics.applyTorque(v,v.angularVelocity*v.mass)
									]]
									effectTable[k2] = v2.worldPosition
									v2.destroyShape(v2,10)
									--sm.physics.explode(currentBodyPosition,9,5,0,0,nil,self.shape)
									--break
								end
							end
							if effectTable ~= nil then self.network:sendToClients("client_effect",effectTable) end
						end
					end
				end
			end
		end
	end
end

function inspectAmountIsWrong(self)
	local selfCount = 0
	for k,v in pairs(self.shape.body.getCreationShapes(self.shape.body))do
		if v.uuid == self.shape.uuid then
			selfCount = selfCount + 1
		end
	end
	if selfCount > self.data.maxAmount then
		return true
	else
		return false
	end
end

function MDS.client_onCreate(self)
	local effect = sm.effect.createEffect("shield")
	effect:setPosition(self.shape:getWorldPosition())
	effect:setRotation(self.shape:getWorldRotation())
	effect:start()
end

function MDS.client_effect(self,positionTable)
	for k,v in pairs(positionTable)do
		--print(v)
		local effect = sm.effect.createEffect("shield")
        effect:setPosition(v)
        effect:setRotation(self.shape:getWorldRotation())
        effect:start()
	end
end

function MDS.client_warning(self,text)
	sm.gui.displayAlertText( text , 2) --"该型号干扰系统超过"..self.data.maxAmount.."台，无法运作"
end