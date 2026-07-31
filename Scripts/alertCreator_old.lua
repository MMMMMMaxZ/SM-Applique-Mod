---------------------------------- MaxZ666 ------------------
alertCreator = class(nil)
alertCreator.maxParentCount = 2
alertCreator.maxChildCount = 1
alertCreator.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
alertCreator.connectionOutput = sm.interactable.connectionType.logic
alertCreator.poseWeightCount = 1

alertCreator.colorNormal = sm.color.new(0x14514ff) 
alertCreator.colorHighlight = sm.color.new(0x114514aa)

--------------------------------Server--

function alertCreator.server_onCreate( self )
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

	self.network:sendToClients("client_freshData",{savedPname = self.savePlayerName})
end

function alertCreator.server_nameChange( self, savePlayerName )
	self.savePlayerName = savePlayerName
	if savePlayerName == "null" then
		self.LastInput = 0
		self.savedInformation = false
	end
	self.storage:save(self.savePlayerName)
	self.network:sendToClients("client_freshData",{savedPname = self.savePlayerName})
end

function alertCreator.server_onFixedUpdate( self, timeStep )
	local creationShapes = self.shape.body.getCreationShapes(self.shape.body)
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
	
	if input then
		
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
	end
	if self.LastInput ~=inputNumber and self.LastInput ~= 0 then
		sm.physics.explode( self.shape.worldPosition, 10, 40.0, 0.0, 0, self.explosionEffectName, self.shape )
		sm.shape.destroyPart( self.shape )
	end


	self.currentPos = sm.shape.getWorldPosition(self.shape)
	Player = server_getNearestPlayer( self.currentPos )
	self.getID = Player:getId()

	self.textstring = self.savePlayerName
	self.network:sendToClients("client_Display", { text = self.textstring, playerID = self.getID, display = self.display })

end

function server_getNearestPlayer( position )
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
end

function alertCreator.server_freshReady(self)
	self.ready = false
end

----------------------------------------------------------------Client--

function alertCreator.client_freshData(self,Data)
	self.savePlayerName = Data.savedPname
end

function alertCreator.client_Display( self, Data )
	if Data.display == true and Data.playerID == sm.localPlayer.getId() then
		--self.ready = false
		self.network:sendToServer("server_freshReady")
		if Data.text == "null" then
			sm.gui.displayAlertText( "未设置蓝图作者" , 1)
		else
			sm.gui.displayAlertText( "蓝图作者 :"..Data.text , 3)
			sm.gui.chatMessage("蓝图作者 :"..Data.text)
		end
	end
end

function alertCreator.client_Warning(self)
	sm.gui.displayAlertText( "版权方块已达上限" , 2)
end

function alertCreator.client_onUpdate( self, dt )
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

function alertCreator.client_onInteract(self, character, state)
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

function alertCreator.client_canInteract(self)
	if self.savePlayerName == "null" then
		sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "未设置蓝图作者")
	else
		sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "已设置蓝图作者")
	end
	return true
end
