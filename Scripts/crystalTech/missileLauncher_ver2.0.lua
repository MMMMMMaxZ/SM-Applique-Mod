ML = class(nil)
ML.maxParentCount = -1
ML.connectionInput = sm.interactable.connectionType.logic
ML.maxChildCount = -1
ML.connectionOutput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power
ML.colorNormal = sm.color.new(0x14514ff)
ML.colorHighlight = sm.color.new(0x114514aa)

ML.colorWhite = "eeeeeeff"
ML.colorBlack = "222222ff"
ML.colorRed = "d02525ff"
ML.colorBlue = "0a3ee2ff"
ML.colorPurple = "7514edff"
ML.colorGreen = "19e753ff"
ML.colorLightBlue = "2ce6e6ff"
ML.logicgateName ={"and","or","xor","nand","nor","nxor"}

--[[
好的，我觉得：是飞行器的问题
但是，我想到更好的解决！
装填好后，直接生成，但不激活！
然后激活生成器后跑去激活核心就行了！
]]

--server----------------------------------------------

function ML.server_onCreate(self)
	self.savedMissile = self.storage:load()
	self.saved = true
	if self.savedMissile == nil then
		self.saved = false
		self.savedMissle = {} --初始化table
	end
	self.lockedPlayerID=1
	self.ready = {}
	if self.savedMissile ~= nil then self.coldTime = #self.savedMissile 
	else
		self.coldTime = 0
	end
	self.dtTime = 0
	self.missilePrepared = true
	self.shape.interactable:setActive(true)
	--load UUIDs
	self.UUIDs = sm.json.open("$MOD_DATA/Scripts/UUID/UUID.json")
	--print(self.UUIDs[1].Mchip)
end

function nearestPlayer(position , playerList)
	local distance  = nil
	local oupPlayer = nil
	for k,v in pairs(playerList)do
		local vD = sm.vec3.length2(position - v.character.worldPosition)
		if distance == nil or vD<distance then
			distance = vD
			oupPlayer = v
		end
	end
	return oupPlayer
end

function ML.server_onFixedUpdate(self,dt)
	if self.shape.body:isOnLift() then
		self.dtTime = 0
		self.missilePrepared = true
		self.shape.interactable:setActive(true)
	end
	--cold time
	local selfColor = tostring(self.shape.color)
	if not self.missilePrepared then
		--print(self.dtTime,self.coldTime)
		self.dtTime = self.dtTime + dt
		if self.dtTime >= self.coldTime then
			self.dtTime = 0
			self.missilePrepared = true
			self.shape.interactable:setActive(true)
		end
	end

	--print(self.shape.worldPosition)
	local parents = self.shape.interactable:getParents()
	if parents ~= nil then
		for k,v in pairs(parents)do
			if v.active then
				local vColor = tostring(v.shape.color)
				--print(vColor)
				if self.ready[v.id] == nil then self.ready[v.id] = true end ------切换目标的单次判定
				if vColor == self.colorWhite then ------切换目标
					if self.ready[v.id] then
						local allPlayers = sm.player.getAllPlayers()
						self.lockedPlayerID=self.lockedPlayerID % #allPlayers + 1
						self.ready[v.id] = false

						--向客户端发送切换消息
						local Ptext = "target : "..allPlayers[self.lockedPlayerID].name
						self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})

					end
				elseif vColor == self.colorBlack then ------切换目标
					if self.ready[v.id] then
						local allPlayers = sm.player.getAllPlayers()
						self.lockedPlayerID=self.lockedPlayerID-1
						if self.lockedPlayerID == 0 then
							self.lockedPlayerID = #allPlayers
						end
						self.ready[v.id] = false

						--向客户端发送切换消息
						local Ptext = "target : "..allPlayers[self.lockedPlayerID].name
						self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})

					end
				elseif vColor == self.colorLightBlue then ------识别导弹
					local allShapes = self.shape.body:getCreationShapes()
					local missile = {}
					for i,Cshape in pairs(allShapes)do
						if tostring(Cshape.color) == self.colorGreen then
							missile[i] = Cshape
						end
					end
					if missile ~= nil then
						local allPlayers = sm.player.getAllPlayers()
						local Ptext = "[succeed] 成功识别导弹"
						self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
						self.savedMissileGreen = missile
					end
				elseif vColor == self.colorRed then ------保存导弹
					if self.savedMissileGreen ~= nil then
						--get missile color
						local allShapes = self.shape.body:getCreationShapes()
						for i,Cshape in pairs(self.savedMissileGreen)do
							if sm.exists(Cshape) then
								Cshape:setColor(allShapes[i].color)
							else
								local allPlayers = sm.player.getAllPlayers()
								local Ptext = "Error : shape missing \n 错误 : shape缺失"
								self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
								self.savedMissileGreen = nil
								break
							end
						end
						if self.savedMissileGreen ~= nil then
							--start saving
							self.coldTime = #self.savedMissileGreen
							--把原本发送到client端读取logicGate状态的步骤去掉了
							self:server_FixedSaveMissile()
						end
					end
				elseif vColor == self.colorBlue then--创建编辑型导弹（不激活）
					if self.missilePrepared then
						self:server_createMissile({state = "modify"})
					else
						if selfColor == self.colorPurple then
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
						end
						
					end
				elseif vColor == self.colorPurple then -- 创建含燃料型导弹（有时效）
					if self.missilePrepared then
						self:server_createMissile({state = "time"})
					else
						if selfColor == self.colorPurple then
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
						end
					end
				else ------生成导弹
					--print(self.coldTime)
					if self.missilePrepared then
						self:server_createMissile({state = nil})
					else
						if selfColor == self.colorPurple then
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
						end
					end
				end
			else
				local vColor = tostring(v.shape.color)
				if vColor == self.colorWhite or vColor == self.colorBlack then 
					self.ready[v.id] = true

				end
			end
		end
	end
end

function ML.server_createMissile(self,data)
	if self.saved then
		self.missilePrepared = false
		self.shape.interactable:setActive(false)
		local Cmissile = self.shape.body
		local missileShapes = {}
		for index,shape in pairs(self.savedMissile)do
			local SLocalPosition = sm.vec3.new(shape.localPosition.x,shape.localPosition.y,shape.localPosition.z)
			
			if shape.isBlock then
				local Ssize = sm.vec3.new(shape.boundingBox.x,shape.boundingBox.y,shape.boundingBox.z)
				missileShapes[index] = Cmissile:createBlock(sm.uuid.new(shape.uuid),Ssize,SLocalPosition,true)
				missileShapes[index]:setColor(sm.color.new(shape.color))
			else
				local SZAxis = sm.vec3.new(shape.zAxis.x,shape.zAxis.y,shape.zAxis.z)
				local SXAxis = sm.vec3.new(shape.xAxis.x,shape.xAxis.y,shape.xAxis.z)
				if shape.logicstate ~= nil then
					--logicGate
					if shape.uuid == "2010aaab-5494-11e6-beb8-9e71128cae77" or shape.uuid == "3015aaac-5494-11e6-beb8-9e71128cae77" or shape.uuid == self.UUIDs[1].MlogCQ then--legend's logicGate
						missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].MlogCQ),SLocalPosition,SZAxis,SXAxis,true)
						missileShapes[index].interactable:setPublicData({state = shape.logicstate})
					else
						missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].MlogYB),SLocalPosition,SZAxis,SXAxis,true)
						missileShapes[index].interactable:setPublicData({state = shape.logicstate})
					end
				elseif shape.timerData ~= nil then
					--timer
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].Mtimer),SLocalPosition,SZAxis,SXAxis,true)
					missileShapes[index].interactable:setPublicData({time = shape.timerData})
					--print({time = shape.timerData})
				elseif shape.thrusterData ~= nil then
					--thruster
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].Mthruster),SLocalPosition,SZAxis,SXAxis,true)
					missileShapes[index].interactable:setPublicData({level = shape.thrusterData})
				elseif shape.eyeData ~= nil then
					--eye
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(self.UUIDs[1].Meye),SLocalPosition,SZAxis,SXAxis,true)
					missileShapes[index].interactable:setPublicData({tIndex = shape.eyeData})
				else
					missileShapes[index] = Cmissile:createPart(sm.uuid.new(shape.uuid),SLocalPosition,SZAxis,SXAxis,true)
				end
				missileShapes[index]:setColor(sm.color.new(shape.color))
				if data.state ~= nil and shape.uuid == self.UUIDs[1].Mchip then
					missileShapes[index].interactable:setPublicData(data)
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
	end
end

function ML.server_FixedSaveMissile(self)
	local savedMissile = {} ----最终保存 ----- 
	local idToIndex = {} ----将id和creation中的index对应
	local missile = {}
	local tot = 1
	
	--预处理（Green里的index是按在body里的排序的，而保存到json后index会按排序排）
	for k,v in pairs(self.savedMissileGreen)do
		missile[tot] = v
		tot = tot + 1
	end

	--构建对照表 --> 连线用
	for index,missileShape in pairs(missile)do
		idToIndex[missileShape.id] = index
	end
	--处理
	for index,missileShape in pairs(missile)do
		local shapeInteract = missileShape.interactable ----可连线？
		local canInteract = false
		local connectedChildren = {} ----连接的子级
		if shapeInteract ~= nil then
			canInteract = true
			local IntChildren = shapeInteract:getChildren()----子级
			for i,j in pairs(IntChildren)do
				connectedChildren[i]=idToIndex[j.shape.id]--保存对应子级在导弹保存序列中的编号
			end
		end
		local Idata = {logic =  nil , timer = nil , thruster = nil , eye = nil} -- saveStuff
		if missileShape.interactable ~= nil then
			if tostring(missileShape.uuid) == self.UUIDs[1].MlogCQ or tostring(missileShape.uuid) == self.UUIDs[1].MlogYB  then
				local temp = missileShape.interactable:getPublicData()
				Idata["logic"] = temp.state
			elseif tostring(missileShape.uuid)==self.UUIDs[1].Mtimer then
				local temp = missileShape.interactable:getPublicData()
				Idata["timer"] = temp.time
			elseif tostring(missileShape.uuid)==self.UUIDs[1].Mthruster then
				local temp = missileShape.interactable:getPublicData()
				Idata["thruster"] = temp.level
			elseif tostring(missileShape.uuid)==self.UUIDs[1].Meye then
				Idata["eye"] = self.lockedPlayerID
			end
		end
		savedMissile[index]={
			uuid = tostring(missileShape.uuid),
			color = tostring(missileShape.color),
			isBlock = missileShape.isBlock,
			canInteract = canInteract,
			children = connectedChildren,
			localPosition = {x = missileShape.localPosition.x, y = missileShape.localPosition.y, z = missileShape.localPosition.z},
			zAxis = {x = missileShape.zAxis.x, y = missileShape.zAxis.y, z = missileShape.zAxis.z},
			xAxis = {x = missileShape.xAxis.x, y = missileShape.xAxis.y, z = missileShape.xAxis.z},
			boundingBox = {x = missileShape:getBoundingBox().x*4, y = missileShape:getBoundingBox().y*4, z = missileShape:getBoundingBox().z*4},--碰撞箱--为了给block确定大小用
			logicstate = Idata["logic"],
			timerData = Idata["timer"] ,
			thrusterData = Idata["thruster"] ,
			eyeData = Idata["eye"] 
		}
		if missileShape.isBlock then
			missileShape:destroyBlock(missileShape.localPosition,missileShape:getBoundingBox()*4)
		else
			missileShape:destroyPart()
		end
	end
	self.savedMissile = savedMissile
	self.saved = true
	self.storage:save(self.savedMissile)
	sm.json.save(self.savedMissile,"$MOD_DATA/Scripts/NEWtestMissile.json")
end

function ML.client_sendMessage(self,data)
	sm.gui.displayAlertText(data.text,1)
end