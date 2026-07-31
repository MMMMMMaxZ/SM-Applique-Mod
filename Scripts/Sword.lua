Sword = class(nil)
Sword.maxParentCount = 1
Sword.connectionInput = sm.interactable.connectionType.logic
Sword.poseWeightCount = 1
Sword.colorNormal = sm.color.new(0x14514ff)
Sword.colorHighlight = sm.color.new(0x114514aa)

Sword.bladeUuid = sm.uuid.new("a6d16258-887c-44aa-8e8c-5609b83e2712")
Sword.lengthTable = {1,2,3,4,6,7,8,9,10,11,12,13,14,15}

Sword.validCheckType = {joint=true,body=true}
Sword.whiteList = {}

function Sword.server_onCreate(self)
	self.lengthIndex = self.storage:load()
	if self.lengthIndex == nil then
		self.lengthIndex = 4
		self.SwordLength = self.lengthTable[self.lengthIndex]
		self.storage:save(self.lengthIndex)
	else
		self.SwordLength = self.lengthTable[self.lengthIndex]
	end
	self:getCreationBody()
	self:funcValidType()
	self.network:sendToClients("client_getUIData",self.lengthIndex)
end

function Sword.funcValidType(self)
	self.validCheckType["joint"] = function (result)
		local joint = result:getJoint()
		local shapeA = joint:getShapeA()
		local bodyA = shapeA.body
		return Sword.whiteList[bodyA.id]
	end
	self.validCheckType["body"] = function (result)
		local bodyA = result:getBody()
		return Sword.whiteList[bodyA.id]
	end
end

function Sword.server_request(self)
	self.network:sendToClients("client_getUIData",self.lengthIndex)
end

function Sword.server_lengthChange(self,lengthIndex)
	self.lengthIndex = lengthIndex
	self.SwordLength = self.lengthTable[self.lengthIndex]
	self.storage:save(self.lengthIndex)
	self.network:sendToClients("client_getUIData",self.lengthIndex)
end

function Sword.server_onFixedUpdate(self,dt)
	if self:checkChanged() then
		print("change")
		self:getCreationBody()
		print(self.whiteList)
	end
	local input = self.interactable:getSingleParent()
	if input then
		if input:isActive() then
			-- check change whiteList
			if self:checkChanged() then
				print("change")
				self:getCreationBody()
				print(self.whiteList)
			end
			-- sword
			local selfPos = self.shape:getWorldPosition()
			local selfAt = self.shape:getAt()
			local startPos = selfPos + selfAt*0.25*5
			local endPos = selfPos + selfAt*self.SwordLength*self.data.length
			local hit,result = sm.physics.raycast(startPos,endPos,self.shape.body)
			if hit then
				if self:checkExplode(result) then
					sm.physics.explode(result.pointWorld,7,0.15,0.01,0,nil,self.shape)
				end
				--local targetShape = result:getShape()
				--targetShape.destroyShape(targetShape,9)
			end
			self.interactable:setActive(true)
		else
			self.interactable:setActive(false)
		end
	else
		self.interactable:setActive(false)
	end
end

function Sword.getCreationBody(self)
	self.creationAllBodies = self.shape.body:getCreationBodies()
	for k,v in pairs(self.whiteList)do self.whiteList[k] = nil end
	for k,v in pairs(self.creationAllBodies)do
		self.whiteList[v.id] = true
	end
end

function Sword.checkChanged(self)
	local CurCreationAllBodies = self.shape.body:getCreationBodies()
	return #CurCreationAllBodies ~= #self.creationAllBodies
end

function Sword.checkExplode(self,result)
	local type = result.type
	if not self.validCheckType[type] then return true end
	return not self.validCheckType[type](result)
end

-----------------------------------------------------------------------------------client
function Sword.client_onCreate(self)
	self.UIPosIndex = 4
	self.network:sendToServer("server_request")
	self.swordLazer = sm.effect.createEffect("ShapeRenderable",self.interactable)
	self.swordLazer:setParameter("uuid",self.bladeUuid)
	self.swordActive = false
end

function Sword.client_getUIData(self,UIPosIndex)
	self.UIPosIndex = UIPosIndex
end

function Sword.client_createSword(self,currentLength)
	self.swordActive = true
	local midPos = sm.vec3.new(0,0.5,0)*currentLength*self.data.length
	self.swordLazer:setOffsetPosition(midPos+sm.vec3.new(0,0.15,0))
	self.swordLazer:setParameter("color",self.shape.color)
	self.swordLazer:setScale((sm.vec3.new(0.5,0,0.5)+midPos*2*4)*0.255)
	self.swordLazer:start()
end

function Sword.client_endSword(self,currentLength)
	self.swordLazer:stop()
	self.swordActive = false
end

function Sword.client_onFixedUpdate(self,dt)
	local isActive = self.interactable.active
	if isActive then 
		if not self.swordActive then
			self:client_createSword(self.lengthTable[self.UIPosIndex])
		end
	else
		if self.swordActive then
			self:client_endSword()
		end
	end
end

function Sword.client_onInteract( self,character,state)
	 if not state then return end
		if self.gui==nil then
			self.gui = sm.gui.createEngineGui()
			self.gui:setSliderCallback("Setting","client_onSliderChange")
			self.gui:setText("Name","SwordLengthSetting")
			self.gui:setText("Interaction","Set text")
			self.gui:setVisible("FuelContainer",false)
		end
		self.gui:setSliderData("Setting",#self.lengthTable,self.UIPosIndex-1)
		self.gui:setText("SubTitle", "length长度: "..self.lengthTable[self.UIPosIndex]*self.data.length*4)
		self.gui:open()
end

function Sword.client_onSliderChange(self,sliderName,sliderPos)
	local newIndex = sliderPos + 1
	self.UIPosIndex = newIndex
	if self.gui ~= nil then
		self.gui:setText("SubTitle","length长度: "..self.lengthTable[newIndex]*self.data.length*4)
	end
	self:client_createSword(self.lengthTable[self.UIPosIndex])
	self.network:sendToServer("server_lengthChange",newIndex)
end

function Sword.client_canInteract(self)
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "设置长度 Set sword's length")
	return true
end

function Sword.client_onDestroy(self)
	self.swordLazer:destroy()
end
