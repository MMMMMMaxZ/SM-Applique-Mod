------------------------------------ MaxZ666 -----------------
SBP = class(nil)
SBP.maxParentCount = 2
SBP.maxChildCount = 1
SBP.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SBP.connectionOutput = sm.interactable.connectionType.logic
SBP.poseWeightCount = 1

SBP.colorNormal = sm.color.new(0x114514ff)
SBP.colorHighlight = sm.color.new(0x114514aa)

---思路：当 放上架子时 首先判定上次是否是内部储存的玩家放上架子的 
---->如果不是的话，开始读取所有玩家数据，然后再对每个玩家进行视角射线判定（玩家坐标和视角起点有偏差，z轴为纵轴），直到有玩家的视角落在了架子上
----（要盗作品肯定要对着架子按E嘛）然后判定射线落点和该方块的{最短}距离 {当不止一个人对着架子时}
---- 将最近的玩家的架子删除

--------------------------------Server--
function SBP.server_onCreate( self )
	self.savePlayerName = self.storage:load()
	self.LastInput = 0
	for k, v in pairs(self.interactable:getParents()) do
		self.LastInput = self.LastInput + 1
	end
	---self.LastInput = self.interactable:getSingleParent()
	if self.savePlayerName== nil or self.savePlayerName== "null" then
		self.savePlayerName = "null"
		self.storage:save(self.savePlayerName)
		self.savedInformation = false
	else
		self.savedInformation = true
	end
	---print(self.LastInput)
	---print(self.savedInformation)
	local creationShapes = self.shape.body.getCreationShapes(self.shape.body)
	local selfCount = 0
	for k, v in pairs(creationShapes) do
		if v.uuid==self.shape.uuid then
			selfCount = selfCount + 1
		end 
	end
	if selfCount > 3 then
		self.network:sendToClients("client_Warning")
		sm.shape.destroyPart( self.shape )
	end 
	self.lastCreationShapes = #creationShapes

	self.isCreator = false

	self.network:sendToClients("client_freshData",{savedPname = self.savePlayerName})
end

function SBP.server_nameChange( self, savePlayerName )
	self.savePlayerName = savePlayerName
	if savePlayerName == "null" then
		self.LastInput = 0
		self.savedInformation = false
	end
	self.storage:save(self.savePlayerName)
	self.network:sendToClients("client_freshData",{savedPname = self.savePlayerName})
end

function SBP.server_onFixedUpdate( self, timeStep )
	--[[local creationShapes = self.shape.body.getCreationShapes(self.shape.body)
	if #creationShapes ~= self.lastCreationShapes then
		local selfCount = 0
		for k, v in pairs(creationShapes) do
			if v.uuid==self.shape.uuid then
				selfCount = selfCount + 1
			end 
		end
		if selfCount > 3 then
			--sm.physics.explode( self.shape.worldPosition, 10, 40.0, 0.0, 0, self.explosionEffectName, self.shape )
			if self.lastCreationShapes < #creationShapes-self.lastCreationShapes then
				self.network:sendToClients("client_Warning")
				sm.shape.destroyPart( self.shape )
			end
		end 
	end
	self.lastCreationShapes = #creationShapes
	]]--
-----------------------------因为就算别人想要通过焊接多放在作品上也不能阻止他的架子被删，最坏的情况就是没人能把作品放上架子罢了，所以不判定了，省延迟

	---self.input = self.interactable:getSingleParent()
	local input
	self.inputActive = false
	local lastin = false
	local inputNumber = 0
	for k, v in pairs(self.interactable:getParents()) do
		input = v
		self.inputActive = input.active or lastin
		lastin = input.active
		inputNumber = inputNumber + 1
	end
	
	--[[if input then
		
		if self.inputActive == true then
			if self.ready then
				self.display = true
			else
				self.display = false
			end
		else
			self.display = false
			self.ready = true
		end
	else
		self.display = false
	end]]--
	if self.LastInput ~=inputNumber and self.LastInput ~= 0 then
		sm.physics.explode( self.shape.worldPosition, 10, 40.0, 0.0, 0, self.explosionEffectName, self.shape )
		sm.shape.destroyPart( self.shape )
	end


	--[[self.currentPos = sm.shape.getWorldPosition(self.shape)
	Player = server_getNearestPlayer( self.currentPos )
	self.getID = Player:getId()

	self.textstring = self.savePlayerName
	self.network:sendToClients("client_Display", { text = self.textstring, playerID = self.getID, display = self.display })
	]]--

	-------查看是否被其他人放上架子了
	if self.shape.body:isOnLift() and self.savePlayerName ~= "null" and not self.isCreator then
		local nearestPlayer = nil
		local nearestDistance = nil
		for id,Player in pairs(sm.player.getAllPlayers())do
			--local PlayerCharacter = Player.character
			local DirVec = Player.character.direction
			DirVec = DirVec.normalize(DirVec)
			local upVec = sm.vec3.new(0,0,0.5)
			local start = Player.character.worldPosition + upVec
			local hit,result = sm.physics.raycast(start, start + DirVec*10)
			--sm.physics.explode(result.pointWorld,7,0.15,0,0,nil,self.shape)
			--print(start)
			if result:getLiftData() then
				local length2 = sm.vec3.length2(self.shape.worldPosition - result.pointWorld)
				if nearestDistance == nil or length2 < nearestDistance then
					nearestDistance = length2
					nearestPlayer = Player
				end
			end
			if Player.name == self.savePlayerName then
				self.isCreator = true
			else
				Player:removeLift()
			end
		end
	end
	if not self.shape.body:isOnLift() then
		self.isCreator = false
	end

end

--[[function server_getNearestPlayer( position )
	local nearestPlayer = nil
	local nearestDistance = nil
	for id,Player in pairs(sm.player.getAllPlayers())
	do
		local length2 = sm.vec3.length2(position - Player.character:getWorldPosition())
		if nearestDistance == nil or length2 < nearestDistance
		then
			nearestDistance = length2
			nearestPlayer = Player
		end
	end
	return nearestPlayer
end]]--

function SBP.server_freshReady(self)
	self.ready = false
end

----------------------------------------------------------------Client--

function SBP.client_freshData(self,Data)
	self.savePlayerName = Data.savedPname
end

function SBP.client_Display( self, Data )
	if Data.display == true and Data.playerID == sm.localPlayer.getId() then
		--self.ready = false
		self.network:sendToServer("server_freshReady")
		if Data.text == "null" then
			sm.gui.displayAlertText( "未设置保护玩家蓝图" , 1)
		else
			sm.gui.displayAlertText( "蓝图作者 :"..Data.text , 3)
			sm.gui.chatMessage("蓝图作者 :"..Data.text)
		end
	end
end

function SBP.client_Warning(self)
	sm.gui.displayAlertText( "蓝图保护装置已达上限" , 2)
end

function SBP.client_onUpdate( self, dt )
	if self.savePlayerName == "null" then
		self.interactable:setUvFrameIndex(0)
		self.interactable:setPoseWeight(0,0)
		--print("0")
	else 
		self.interactable:setUvFrameIndex(6)
		self.interactable:setPoseWeight(0,1)
		--print("1")
	end
end

function SBP.client_onInteract(self, character, state)
    if not state then return end
	local playerName = sm.localPlayer.getPlayer():getName()
	if self.savePlayerName == playerName then
		sm.gui.displayAlertText( "已取消锁定玩家", 2)
		local nullName = "null"
		--self.LastInput = 0
		self.network:sendToServer("server_nameChange", nullName)
	else 
		if self.savePlayerName == "null" then
			sm.gui.displayAlertText( "已设置锁定玩家", 2)
			self.network:sendToServer("server_nameChange", playerName)
		else 
			sm.gui.displayAlertText( "非设定玩家，无法修改", 2)
		end
	end
	
end

function SBP.client_canInteract(self)
	if self.savePlayerName == "null" then
		sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "未设置保护玩家蓝图")
	else
		sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "已设置保护玩家蓝图")
	end
	return true
end
