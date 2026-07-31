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
ML.colorYellow = "e2db13ff"
ML.logicgateName ={"and","or","xor","nand","nor","nxor"}

--server----------------------------------------------

function ML.server_onCreate(self)
	self.savedMissile = self.storage:load()
	self.saved = true
	if self.savedMissile == nil then
		self.saved = false
		self.savedMissile = {} --初始化table
	end
	self.lockedPlayerID=1
	self.ready = {}
	self.coldTime = #self.savedMissile
	self.savedMissileLocalPosition = self:server_createPositionList()
	self.dtTime = self.coldTime
	self.missilePrepared = false
	self.controller = false
	self.createdMissile = {}
	--load UUIDs
	self.UUIDs = sm.json.open("$MOD_DATA/Scripts/UUID/UUID.json")
	--print(self.UUIDs[1].Mchip)
	self:server_clearSpace()
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
	--print(self.dtTime,self.createdMissile)
	--on lift
	if self.shape.body:isOnLift() then
		self.dtTime = 1
		if self.createdMissile["rec"] ~= 114514 then
			print("state : onLift clear (FIRST)")
			self:server_deleteMissile()
		end
	end
	--get color
	local selfColor = tostring(self.shape.color)
	--cold time
	if self.dtTime <= -2000 then -- 待机层
	elseif self.dtTime <= -1000 then -- 安全层（用于检验是否生成，生成了就调ready，没生成成功就丢recycle）
		--check!
		local flag = true
		for i,mShape in pairs(self.createdMissile)do
			local MSstate = sm.exists(mShape)
			if not MSstate then
				flag = false
			end
		end
		if flag then
			self.missilePrepared = true
			self.dtTime = -2001
			print("<CAUTION> missile is ready!~")
		else
			self:server_recycleScrap()
			print("<ERROR> missile has error, run \"recycleScrap\"")
		end
	elseif self.dtTime <=0 and self.controller then -- 尝试生成（恒为0,（-1000，0）是延迟缓冲层, 因为不确定有没有这个bug）
		print("start create missile [dtTime == 0]")
		self.createdMissile = self:server_createMissile({state = "modify"})
		print("succeed created missile [dtTime == 0]")
		self.dtTime = -1001
	else -- 减CD中
		self.dtTime = self.dtTime - dt
	end

	--print(self.shape.worldPosition)
	local parents = self.shape.interactable:getParents()
	if parents ~= nil then
		for k,v in pairs(parents)do
			if tostring(v.shape.color)==self.colorYellow and v.active then ------控制生成
				self.controller = true
			elseif tostring(v.shape.color)==self.colorYellow and not v.active then
				self.controller = false
			end
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
							self.savedMissileGreen = nil
							self.dtTime = self.coldTime
						end
					end
				elseif vColor == self.colorBlue then--清理残缺导弹
					if self.missilePrepared then
						self:server_recycleScrap()
						self.missilePrepared = false
					else
						if selfColor == self.colorPurple then
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
						end
					end
				elseif vColor == self.colorPurple then -- 创建含燃料型导弹（有时效）
					if self.missilePrepared then
						self.dtTime = self.coldTime
						self.missilePrepared = false
						if sm.exists(self.missileCore) then
							self.missileCore.interactable:setPublicData({state = "time"})
							self.missileCore = nil
							self.createdMissile = {["rec"] = 114514}
						else
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "<!> 导弹芯片缺失 自动回收碎片 / fixing error!"
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
							self:server_recycleScrap()
						end
					else
						if selfColor == self.colorPurple then
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "冷却时间剩余 / CD : "..math.floor((self.dtTime))
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
						end
					end
				elseif vColor ~= self.colorYellow and self.controller then ------生成导弹
					if self.missilePrepared then
						self.dtTime = self.coldTime
						self.missilePrepared = false
						if sm.exists(self.missileCore) then
							self.missileCore.interactable:setPublicData({state = nil})
							self.missileCore = nil
							self.createdMissile = {["rec"] = 114514}
						else
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "<!> 导弹芯片缺失 自动回收碎片 / fixing error!"
							self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
							self:server_recycleScrap()
						end
					else
						if selfColor == self.colorPurple then
							local allPlayers = sm.player.getAllPlayers()
							local Ptext = "冷却时间剩余 / CD : "..math.floor((self.dtTime))
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

function ML.server_createMissile(self,data) -- return [error_level] [the_missile_itself]
	if self.saved then
		local Cmissile = self.shape.body
		local missileShapes = {}
		for index,shape in pairs(self.savedMissile)do
			local SLocalPosition = sm.vec3.new(shape.localPosition.x,shape.localPosition.y,shape.localPosition.z)
			SLocalPosition = SLocalPosition + self.shape.localPosition
			--create
			if shape.isBlock then
				local Ssize = sm.vec3.new(shape.boundingBox.x,shape.boundingBox.y,shape.boundingBox.z)
				missileShapes[index] = Cmissile:createBlock(sm.uuid.new(shape.uuid),Ssize,SLocalPosition,false)
				missileShapes[index]:setColor(sm.color.new(shape.color))
			else
				local SZAxis = sm.vec3.new(shape.zAxis.x,shape.zAxis.y,shape.zAxis.z)
				local SXAxis = sm.vec3.new(shape.xAxis.x,shape.xAxis.y,shape.xAxis.z)
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
		print("a")
		return missileShapes
	end
	return {}
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
			localPosition = {x = missileShape.localPosition.x-self.shape.localPosition.x, y = missileShape.localPosition.y-self.shape.localPosition.y, z = missileShape.localPosition.z-self.shape.localPosition.z},
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
	self.savedMissileLocalPosition = self:server_createPositionList()
	self.saved = true
	self.storage:save(self.savedMissile)
	--sm.json.save(self.savedMissile,"$MOD_DATA/Scripts/NEWtestMissile.json")
end

function ML.server_recycleScrap(self)
	local recycledCnt = self:server_deleteMissile()
	self.dtTime = self.coldTime - recycledCnt + 1
end

function ML.server_deleteMissile(self) -- return delete shape count
	local recycledCnt = 0
	for k,v in pairs(self.createdMissile)do
		local Vstate = sm.exists(v)
		if Vstate then
			recycledCnt = recycledCnt + 1
			destroyShape(v)
		end
	end
	self.missileCore = nil
	self.createdMissile = {["rec"] = 114514}
	return recycledCnt
end


function ML.server_createPositionList(self) -- return a Table of missilePosition
	local oup = {}
	for k,v in pairs(self.savedMissile) do
		local SLocalPosition = sm.vec3.new(v.localPosition.x,v.localPosition.y,v.localPosition.z)
		local SLPS = tostring(SLocalPosition)
		oup[SLPS]=true
	end
	return oup
end

function ML.server_clearSpace(self)
	local allShapes = self.shape.body:getCreationShapes()
	for i,Cshape in pairs(allShapes)do
		local SP = tostring(Cshape.localPosition)
		if self.savedMissileLocalPosition[SP] then
			destroyShape(Cshape)
		end
	end
end

function destroyShape(v)
	if v.isBlock then
		v:destroyBlock(v.localPosition,v:getBoundingBox()*4)
	else
		v:destroyPart()
	end
end

function ML.client_sendMessage(self,data)
	sm.gui.displayAlertText(data.text,1)
end