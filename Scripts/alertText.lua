
alertText = class( nil )
alertText.maxParentCount = 1
alertText.connectionInput = sm.interactable.connectionType.logic
alertText.colorNormal = sm.color.new(0x114514ff)
alertText.colorHighlight = sm.color.new(0x114514aa)

alertText.textTable = {"MODE - 01","MODE - 02","MODE - 03","模式 - 01","模式 - 02","模式 - 03","/////[WARNING]/////","Ready","Set","GO!","BlackOut"}

--------------------------------------------------------------------Server--
function alertText.server_onCreate( self )
	self.savedData = self.storage:load()
	if self.savedData == nil then
		self.savedData = {text="null"}
		self.storage:save(self.savedData)
	elseif type(self.savedData) == "number" then
		local lcText = self.textTable[self.savedData]
		self.savedData = {text=lcText}
	end

	self.network:sendToClients("client_getUIData", self.savedData)
end

function alertText.server_request( self )
	self.network:sendToClients("client_getUIData", self.savedData)
end

function alertText.server_textChange( self, text )
	--创建时确保过savedData是含text键值的table
	self.savedData.text = text
	self.storage:save(self.savedData)
	self.network:sendToClients("client_getUIData", self.savedData)
end

----------------------------------------------------------------Client--
function alertText.client_onCreate( self )
	self.text="null"
	self.network:sendToServer("server_request")
end

function alertText.client_onFixedUpdate(self,dt)
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

	if not self.display then return end

	local currentPos = sm.shape.getWorldPosition(self.shape)
	local lPlayer = sm.localPlayer.getPlayer()
	local lCharacter = lPlayer:getCharacter()
	local lCpos = lCharacter:getWorldPosition()
	local l2 = (lCpos - currentPos):length2()
	if l2<36 then
		self:client_Display({text = self.text})
	end
end

function alertText.client_Display( self, Data )
	if Data.text == "BlackOut" then
		sm.gui.startFadeToBlack(3,3)
	else
		sm.gui.displayAlertText( Data.text , 1)
	end
end

function alertText.client_getUIData(self, data )
	self.text = data.text
end

function alertText.client_onInteract(self, character, state)
    if not state then return end
	if self.gui == nil then
		self.gui = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/MAGControlPadV3.layout')
    	self.gui:setVisible("List",false)
		self.gui:setTextChangedCallback("EditText","cl_onTextChange")
		self.gui:setText("EditText",self.text)
		self.gui:setButtonCallback("ESCbutton","cl_escEdit")
	end
	self.gui:open()
end

function alertText.cl_escEdit(self)
	self.gui:close()
end

function alertText.cl_onTextChange( self, name, txt )
	self.UIPosIndex = txt
	self.network:sendToServer("server_textChange", txt)
end

function alertText.client_canInteract(self)
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "设置文本 Set text")
	return true
end
