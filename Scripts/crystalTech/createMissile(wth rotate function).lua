function ML.server_createMissile(self,data) -- return [error_level] [the_missile_itself]
	if self.saved then
		local Cmissile = self.shape.body
		local missileShapes = {}
		for index,shape in pairs(self.savedMissile)do
			local OzAxis
			local OxAxis
			if shape.OzAxis ~= nil then
				OzAxis = sm.vec3.new(shape.OzAxis.x,shape.OzAxis.y,shape.OzAxis.z)
				OxAxis = sm.vec3.new(shape.OxAxis.x,shape.OxAxis.y,shape.OxAxis.z)
			else--OLD
				OzAxis = self.shape.zAxis
				OxAxis = self.shape.xAxis
			end
			local Zquat = sm.vec3.getRotation(self.shape.zAxis,OzAxis)
			local Xquat = sm.vec3.getRotation(self.shape.xAxis,OxAxis)
			print("cM\n--check!-[each shape]-----\n\n\n",(Zquat*self.shape.zAxis),"\n",OzAxis,"\n\n")
			local SLocalPosition = sm.vec3.new(shape.localPosition.x,shape.localPosition.y,shape.localPosition.z)
			SLocalPosition = Zquat*SLocalPosition*-1
			SLocalPosition = Xquat*SLocalPosition
			SLocalPosition = SLocalPosition + self.shape.localPosition
			print(SLocalPosition)
			--create
			if shape.isBlock then
				local Ssize = Xquat*sm.vec3.new(shape.boundingBox.x,shape.boundingBox.y,shape.boundingBox.z)
				Ssize = Zquat*Ssize
				missileShapes[index] = Cmissile:createBlock(sm.uuid.new(shape.uuid),Ssize,SLocalPosition,false)
				missileShapes[index]:setColor(sm.color.new(shape.color))
			else
				local SZAxis = sm.vec3.new(shape.zAxis.x,shape.zAxis.y,shape.zAxis.z)
				local SXAxis = sm.vec3.new(shape.xAxis.x,shape.xAxis.y,shape.xAxis.z)
				print(SXAxis,SZAxis)
				local SZQA = sm.vec3.getRotation(OzAxis,SZAxis)
				local SXQA = sm.vec3.getRotation(OxAxis,SXAxis)
				SZAxis = SZQA*self.shape.zAxis
				SXAxis = SXQA*self.shape.xAxis
				if shape.logicstate ~= nil then
					--logicGate
					if shape.uuid == "2010aaab-5494-11e6-beb8-9e71128cae77" or shape.uuid == "3015aaac-5494-11e6-beb8-9e71128cae77" or shape.uuid == self.UUIDs[1].MlogCQ then--legend's logicGate
						missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].MlogCQ),SLocalPosition,SZAxis,SXAxis,false)
						missileShapes[index].interactable:setPublicData({state = shape.logicstate})
					else
						missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].MlogYB),SLocalPosition,SZAxis,SXAxis,false)
						missileShapes[index].interactable:setPublicData({state = shape.logicstate})
					end
				elseif shape.timerData ~= nil then
					--timer
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].Mtimer),SLocalPosition,SZAxis,SXAxis,false)
					missileShapes[index].interactable:setPublicData({time = shape.timerData})
					--print({time = shape.timerData})
				elseif shape.thrusterData ~= nil then
					--thruster
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].Mthruster),SLocalPosition,SZAxis,SXAxis,false)
					missileShapes[index].interactable:setPublicData({level = shape.thrusterData})
				elseif shape.eyeData ~= nil then
					--eye
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].Meye),SLocalPosition,SZAxis,SXAxis,false)
					missileShapes[index].interactable:setPublicData({tIndex = self.lockedPlayerID})
				else
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(shape.uuid),SLocalPosition,SZAxis,SXAxis,false)
				end
				missileShapes[index]:setColor(sm.color.new(shape.color))
				if data.state ~= nil and shape.uuid == self.UUIDs[1].Mchip then
					missileShapes[index].interactable:setPublicData(data)
					self.missileCore = missileShapes[index]
				end
			end
		end
		--connect
		for index,shape in pairs(self.savedMissile)do
			if not shape.isBlock then
				if shape.canInteract then
					for i,j in pairs(shape.children)do
						missileShapes[index].interactable:connect(missileShapes[j].interactable)
					end
				end
			end
		end
		self.coldTime = #self.savedMissile
		print("<caution> function \"createMissile\" ended, successfully built "..self.coldTime.." shapes!")
		return missileShapes
	end
	return {}
end