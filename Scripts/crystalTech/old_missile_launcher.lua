ML = class(nil)
ML.maxParentCount = -1
ML.connectionInput = sm.interactable.connectionType.logic

ML.colorNormal = sm.color.new(0x14514ff)
ML.colorHighlight = sm.color.new(0x114514aa)

ML.colorWhite = "eeeeeeff"
ML.colorBlack = "222222ff"
ML.colorRed = "d02525ff"
ML.colorBlue = "0a3ee2ff"
ML.colorPurple = "7514edff"
ML.logicgateName ={"and","or","xor","nand","nor","nxor"}
--[[ML.triggerUuid = "796ddab6-e143-4c2c-9037-dc77579576d2"
ML.MlogCQ = "796ddab6-e143-4c2c-9037-dc77579576d3"--传奇
ML.MlogYB = "796ddab6-e143-4c2c-9037-dc77579576d4"--原版
ML.Mtimer = "796ddab6-e143-4c2c-9037-dc77579576d7"
ML.Mthruster = "796ddab6-e143-4c2c-9037-dc77579576d9"
ML.Meye = "796ddab6-e143-4c2c-9037-dc77579576da"]]

--[[

bug:
    现象：
        高速运作时，生成的导弹会乱飞
        其他情况又完全不会
    猜测原因：
        高速运作时，生成的导弹会撞上正在高速飞行的飞行器，因此会乱转
        至于为什么会撞上，我也不知道
    解决方案：
        将生成 body 改成 在joint上生成一个shapeB，在shapeB.body上生成导弹，再删除shapeB
        推测：
            能完美同步生成位置
            能同步速度和方向
		方案：failed

		新方案：
			joint的蜜汁bug，导致它会崩
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
	--cold time
	if not self.missilePrepared then
		--print(self.dtTime,self.coldTime)
		self.dtTime = self.dtTime + dt
		if self.dtTime >= self.coldTime then
			self.dtTime = 0
			self.missilePrepared = true
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
				elseif vColor == self.colorRed then ------保存导弹
					local allBodies = self.shape.body:getCreationBodies()
					local missile = nil
					for i,CreationBody in pairs(allBodies)do
						if missile == nil then
							for j,BodyShape in pairs(CreationBody:getShapes())do
								if missile == nil then
									if tostring(BodyShape.uuid) == self.UUIDs[1].Mchip then
										missile = CreationBody
									end
								end
							end
						end
					end
					
					if missile ~= nil then
						self.coldTime = #(missile:getShapes())
						local allPlayers = sm.player.getAllPlayers()
						local Host = allPlayers[1]
						self.network:sendToClient(Host,"client_readLogicgateStates",{Smissile = missile})-----检测逻辑门状态
					end
				elseif vColor == self.colorBlue then--创建编辑型导弹（不激活）
					if self.missilePrepared then
						self:server_createMissile({state = "modify"})
					else
						local allPlayers = sm.player.getAllPlayers()
						local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
						self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
					end
				elseif vColor == self.colorPurple then -- 创建含燃料型导弹（有时效）
					if self.missilePrepared then
						self:server_createMissile({state = "time"})
					else
						local allPlayers = sm.player.getAllPlayers()
						local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
						self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
					end
				else ------生成导弹
					if self.missilePrepared then
						self:server_createMissile({state = nil})
					else
						local allPlayers = sm.player.getAllPlayers()
						local Ptext = "冷却时间剩余 / CD : "..math.floor((self.coldTime - self.dtTime))
						self.network:sendToClient(nearestPlayer(self.shape.worldPosition,allPlayers),"client_sendMessage",{text = Ptext})
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
		local Cmissile = sm.body.createBody(self.shape.worldPosition,self.shape.body.worldRotation)
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
					if shape.uuid == "2010aaab-5494-11e6-beb8-9e71128cae77" or shape.uuid == "3015aaac-5494-11e6-beb8-9e71128cae77" then--legend's logicGate
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
		--add impulse (利用冲量来达成与生成器同速（惯性系）)
		local velocity = self.shape.body.velocity
		local mass = Cmissile.mass
		sm.physics.applyImpulse(Cmissile,velocity*mass)
	end
end

function ML.server_saveMissile(self,Data)	
	local savedMissile = {} ----最终保存 ----- 
	local idToIndex = {} ----将id和creation中的index对应
	local missile = Data.Smissile:getShapes()
	
	for index,missileShape in pairs(missile)do
		idToIndex[missileShape.id]=index
	end
	for index,missileShape in pairs(missile)do
		--print(index)
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
		--logicGate
		local logicgateS = "unknow"
		if Data.logicStates[index] ~= nil then
			if Data.logicStates[index] == 114514 then
				local temp = missileShape.interactable:getPublicData()
				logicgateS = temp.state
			else
				logicgateS = self.logicgateName[Data.logicStates[index]+1]
			end
			
			--print("logicState:"..logicgateS)
		else
			logicgateS = nil
		end
		--timer
		local timerData = 0
		if Data.timerStates[index] ~= nil then
			local temp = missileShape.interactable:getPublicData()
			timerData = temp.time
			--print(timerData)
		else
			timerData = nil
		end
		--thruster
		local thrusterData = 0
		if Data.thrusterStates[index] ~= nil then
			local temp = missileShape.interactable:getPublicData()
			thrusterData = temp.level
		else
			thrusterData = nil
		end
		--eye
		local eyeData = 0
		if Data.eyeS[index]~= nil then
			eyeData = self.lockedPlayerID
		else
			eyeData = nil
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
			logicstate = logicgateS,
			timerData = timerData,
			thrusterData = thrusterData,
			eyeData = eyeData
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
	--sm.json.save(self.savedMissile,"$MOD_DATA/Scripts/testMissile.json")
	--print("123")
end

--client

function ML.client_readLogicgateStates(self,Data)
	local logicgateStates={}
	local timerStatesS={}
	local MthrusterStatesS={}
	local MeyeStates={}
	local missile = Data.Smissile:getShapes()
	for k,Mshape in pairs(missile)do
		--print(Mshape.uuid)
		if Mshape.interactable ~= nil then
			local Itype = Mshape.interactable:getType()
			if Itype == "logic" then 
				--print("logic:")
				--print(Mshape.interactable:getUvFrameIndex())
				logicgateStates[k] = Mshape.interactable:getUvFrameIndex()%6
			elseif tostring(Mshape.uuid)==self.UUIDs[1].Mtimer  then--elseif Itype == "timer" then
				--print("timer:")
				--Itester = Mshape.interactable:getPublicData()
				--print(Itester)

				--My Mtimer
				timerStatesS[k] = true
			elseif tostring(Mshape.uuid) == self.UUIDs[1].MlogCQ or tostring(Mshape.uuid) == self.UUIDs[1].MlogYB  then
				--My MlogicGate
				logicgateStates[k] = 114514
				--print(114514)
			elseif tostring(Mshape.uuid)==self.UUIDs[1].Mthruster then
				--My Mthruster
				MthrusterStatesS[k] = true
			elseif tostring(Mshape.uuid)==self.UUIDs[1].Meye then
				MeyeStates[k] = true
			end
		end
	end
	print("-------------------------END---------------------")
	self.network:sendToServer("server_saveMissile",{Smissile = Data.Smissile,logicStates = logicgateStates, timerStates = timerStatesS, thrusterStates = MthrusterStatesS, eyeS = MeyeStates})
end

function ML.client_sendMessage(self,data)
	sm.gui.displayAlertText(data.text,1)
end