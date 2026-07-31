
Mtimer = class( nil )
Mtimer.maxParentCount = 1
Mtimer.maxChildCount = -1
Mtimer.connectionInput = sm.interactable.connectionType.logic
Mtimer.connectionOutput = sm.interactable.connectionType.logic
Mtimer.timerTable = {0.025, 0.05, 0.075, 0.1, 0.125, 0.15, 0.175, 0.2, 0.225, 0.25, 0.275, 0.3, 0.325, 0.35, 0.375, 0.4, 0.425, 0.45, 0.475, 0.5, 0.525, 0.55, 0.575, 0.6, 0.625, 0.65, 0.675, 0.7, 0.725, 0.75, 0.775, 0.8, 0.825, 0.85, 0.875, 0.9, 0.925, 0.95, 0.975, 1.0}

Mtimer.colorNormal = sm.color.new(0x14514ff)
Mtimer.colorHighlight = sm.color.new(0x114514aa)

--------------------------------------------------------------------Server--
function Mtimer.server_onCreate( self )
	self.runTable ={0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	self.readyToBeSaved = true
	self.sendClient = true
	self.i=1
	local savedDataD = self.storage:load()
	if savedDataD ~= nil then self.timerIndex = savedDataD.time end
	if self.timerIndex == nil then
		self.timerIndex = 10
		self.oupT = self.timerTable[self.timerIndex]
		self.storage:save({time = self.timerIndex})
	else
		self.oupT = self.timerTable[self.timerIndex]
	end
	if self.shape.body:isOnLift() then self.interactable:setPublicData({time = self.timerIndex}) end
	self.network:sendToClients("client_getUIData", self.timerIndex)
	--print(self.timerIndex)
end

function Mtimer.server_request( self )
	self.network:sendToClients("client_getUIData", self.timerIndex)
end

function Mtimer.server_timeChange( self, timerIndex )
	self.timerIndex = timerIndex
	self.oupT = self.timerTable[self.timerIndex]
	self.storage:save({time = self.timerIndex})
	self.interactable:setPublicData({time = timerIndex})
	self.network:sendToClients("client_getUIData", self.timerIndex)
end

function Mtimer.server_onFixedUpdate( self, timeStep )
	--[[self.input = self.interactable:getSingleParent()
	if self.input then
		self.inputActive = self.input:isActive()
		if self.inputActive == true then
			self.display = true
		else
			self.display = false
		end
	else
		self.display = false
	end]]--
	--print(self.interactable.publicData)
	if self.interactable.publicData ~= nil and self.timerIndex ~= self.interactable.publicData.time then
		--print(self.timerIndex)
		self.timerIndex = self.interactable.publicData.time
	end

	self.input = self.interactable:getSingleParent()
	if self.input~=nil then self.inputActive = self.input:isActive() end

	--SOLUTION::
	--a list [T/F]
	--i++
	--if i == timerIndex+1 then i=1 end
	--if list[i] = T then oup=T 
	--else oup=F end
	--list[i] = input
	--print(self.shape,self.i)
	self.i=self.i+1
	if self.i > self.timerIndex then self.i = 1 end
	if self.runTable[self.i]==1 then
		self.interactable:setActive(true)
		self.interactable:setPower(1)
	else
		self.interactable:setActive(false)
		self.interactable:setPower(0)
	end
	if self.input then
		if self.inputActive == true then
			self.runTable[self.i] = 1
		else
			self.runTable[self.i] = 0
		end
	end

	if self.shape.body:isOnLift() and self.sendClient then
		self.network:sendToClients("client_getUIData", self.timerIndex)
		self.sendClient = false
		--仅用来当被作为导弹召唤出来时（or蓝图召唤）发给client端
	end
	if self.shape.body:isOnLift() and self.readyToBeSaved then
		self.storage:save({time = self.timerIndex})
		self.readyToBeSaved = false
	else
		self.readyToBeSaved = true
	end

	--[[self.currentPos = sm.shape.getWorldPosition(self.shape)
	local Player = server_getNearestPlayer( self.currentPos )
	self.getID = Player:getId()

	self.timeS = self.oupT
	self.network:sendToClients("client_Display", { text = self.timeS, playerID = self.getID, display = self.display })
	]]--
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

----------------------------------------------------------------Client--
function Mtimer.client_onCreate( self )
	self.UIPosIndex = 10
	self.network:sendToServer("server_request")
end

--[[function Mtimer.client_Display( self, Data )
	if Data.display == true and Data.playerID == sm.localPlayer.getId() then
		if Data.text == "BlackOut" then
			sm.gui.startFadeToBlack(10,10)
		else
			sm.gui.displayMtimer( Data.text , 1)
		end
	end
end]]--

function Mtimer.client_getUIData(self, UIPosIndex )
	self.UIPosIndex = UIPosIndex
end

function Mtimer.client_onInteract(self, character, state)
    if not state then return end
	if self.gui == nil then
		self.gui = sm.gui.createEngineGui()
		self.gui:setSliderCallback( "Setting", "client_onSliderChange")
		self.gui:setText("Name", "计时器timer")
		self.gui:setText("Interaction", "setTime")
		self.gui:setVisible("FuelContainer", false )
	end
	self.gui:setSliderData("Setting", #self.timerTable, self.UIPosIndex-1)
	self.gui:setText("SubTitle", "time: "..self.timerTable[self.UIPosIndex])
	self.gui:open()
end

function Mtimer.client_onSliderChange( self, sliderName, sliderPos )
	local newIndex = sliderPos + 1
	self.UIPosIndex = newIndex
	if self.gui ~= nil then
		self.gui:setText("SubTitle", "time: "..self.timerTable[newIndex])
	end
	self.network:sendToServer("server_timeChange", newIndex)
end

function Mtimer.client_canInteract(self)
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "time : "..self.timerTable[self.UIPosIndex])
	return true
end
