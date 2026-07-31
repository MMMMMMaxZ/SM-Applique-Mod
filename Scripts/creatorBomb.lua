creatorBomb = class(nil)
creatorBomb.maxParentCount = 1
creatorBomb.maxChildCount = 1
creatorBomb.connectionInput =  sm.interactable.connectionType.logic
creatorBomb.connectionOutput = sm.interactable.connectionType.logic
creatorBomb.poseWeightCount = 1

creatorBomb.colorNormal = sm.color.new(0x14514ff)
creatorBomb.colorHighlight = sm.color.new(0x114514aa)

--------------------------------Server--
function creatorBomb.server_onCreate( self )
	self.LastInput = self.interactable:getSingleParent()
	self.savePlayerName = self.storage:load()
	if self.savePlayerName== nil or self.savePlayerName== "null" then
		self.savePlayerName = "null"
		self.storage:save(self.savePlayerName)
		self.savedInformation = false
	else
		self.savedInformation = true
	end
end

function creatorBomb.server_nameChange( self, savePlayerName )
	self.savePlayerName = savePlayerName
	if savePlayerName == "null" then
		self.savedInformation = false
	end
	self.storage:save(self.savePlayerName)
end

function creatorBomb.server_onFixedUpdate( self, timeStep )
	self.input = self.interactable:getSingleParent()
	if self.input then
		self.inputActive = self.input:isActive()
		if self.inputActive == true then
			self.interactable:setActive(false)
		else
			self.interactable:setActive(false)
		end
	else
		if  self.LastInput and self.savedInformation then
			sm.physics.explode( self.shape.worldPosition, 10, 40.0, 0.0, 0, self.explosionEffectName, self.shape )
			sm.shape.destroyPart( self.shape )
		else
			self.interactable:setActive(false)
		end
	end

end

-----------------------client--
function creatorBomb.client_onInteract(self, character, state)
    if not state then return end
	local playerName = sm.localPlayer.getPlayer():getName()
	if self.savePlayerName == playerName then
		sm.gui.displayAlertText( "已取消锁定玩家", 2)
		local nullName = "null"
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

function creatorBomb.client_canInteract(self)
	if self.savePlayerName == "null" then
		sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "未设置")
	else
		sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "已设置")
	end
	return true
end