ChangeColorSize = class(nil)
ChangeColorSize.poseWeightCount = 3

ChangeColorSize.colortable = {"Red","Black","White","Grey"}

--------------------------------------------------------------------Server--
function ChangeColorSize.server_onCreate( self )
	self.colorIndex = self.storage:load()
	if self.colorIndex == nil then
		self.colorIndex = 1
		self.outputText = self.colortable[self.colorIndex]
		self.storage:save(self.colorIndex)
	else
		self.outputText = self.colortable[self.colorIndex]
	end
	
	self.network:sendToClients("client_getUIData", self.colorIndex)
end

function ChangeColorSize.server_request( self )
	self.network:sendToClients("client_getUIData", self.colorIndex)
end

function ChangeColorSize.server_textChange( self, colorIndex )
	self.colorIndex = colorIndex
	self.outputText = self.colortable[self.colorIndex]
	self.storage:save(self.colorIndex)
	self.network:sendToClients("client_getUIData", self.colorIndex)
end

function ChangeColorSize.server_onFixedUpdate( self, timeStep )
	self.input = self.interactable:getSingleParent()
	if self.input then
		self.inputActive = self.input:isActive()
		if self.inputActive == true then
			self.display = true
		else
			self.display = false
		end
	else
		self.display = false
	end

	self.currentPos = sm.shape.getWorldPosition(self.shape)
	Player = server_getNearestPlayer( self.currentPos )
	self.getID = Player:getId()
	
	self.textstring = self.outputText
	self.network:sendToClients("client_Display", { text = self.textstring, playerID = self.getID, display = self.display })

end

function server_getNearestPlayer( position )
	local nearestPlayer = nil
	local nearestDistance = nil
	for id,Player in pairs(sm.player.getAllPlayers()) do
		local length2 = sm.vec3.length2(position - Player.character:getWorldPosition())
		if nearestDistance == nil or length2 < nearestDistance then
			nearestDistance = length2
			nearestPlayer = Player
		end
	end
	return nearestPlayer
end

----------------------------------------------------------------Client--
function ChangeColorSize.client_onCreate( self )
	self.UIPosIndex = 1
	self.network:sendToServer("server_request")
end

function ChangeColorSize.client_Display( self, Data )
	if Data.display == true and Data.playerID == sm.localPlayer.getId() then
		if Data.text == "BlackOut" then
			sm.gui.startFadeToBlack(10,10)
		else
			sm.gui.displayAlertText( Data.text , 1)
		end
	end
end

function ChangeColorSize.client_getUIData(self, UIPosIndex )
	self.UIPosIndex = UIPosIndex
end

function ChangeColorSize.client_onInteract(self, character, state)
    if not state then return end
	if self.gui == nil then
		self.gui = sm.gui.createEngineGui()
		self.gui:setSliderCallback( "Setting", "client_onSliderChange")
		self.gui:setText("Name", "Text setting 文本设置")
		self.gui:setText("Interaction", "Set text 设置文本")
		self.gui:setVisible("FuelContainer", false )
	end
	self.gui:setSliderData("Setting", #self.colortable, self.UIPosIndex-1)
	self.gui:setText("SubTitle", "text文本: "..self.colortable[self.UIPosIndex])
	self.gui:open()
end

function ChangeColorSize.client_onSliderChange( self, sliderName, sliderPos )
	local newIndex = sliderPos + 1
	self.UIPosIndex = newIndex
	if self.gui ~= nil then
		self.gui:setText("SubTitle", "text文本: "..self.colortable[newIndex])
	end
	self.network:sendToServer("server_textChange", newIndex)
end

function ChangeColorSize.client_canInteract(self)
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "设置文本 Set text")
	return true
end
