--MAXZ666--
MLG=class(nil)
MLG.maxParentCount = -1
MLG.maxChildCount = -1
MLG.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power
MLG.connectionOutput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power
MLG.logicgateName = {"and","or","xor","nand","nor","nxor"}
MLG.KeyLogicgate = {}

MLG.colorNormal = sm.color.new(0x14514ff)
MLG.colorHighlight = sm.color.new(0x114514aa)

function MLG.server_onCreate(self)
	self.savedState = 1
	self.sendClient = true
	self.readyToBeSaved = true
	if self.shape.body:isOnLift() then
		self.interactable:setPublicData({state = "and"})--创建出来默认是and
	end
	local savedData = self.storage:load()
	--print(savedData)
	if savedData ~= nil then
		self.interactable:setPublicData(savedData)
		--self.interactable:setPublicData({state = "and"})--创建出来默认是and
	end
end

--[[
when to send Client state?
	is Missile :
	YES:
		on Lift --> send once
	NO:
		
]]--

function MLG.server_onFixedUpdate(self,dt)
	if self.interactable.publicData ~= nil then
		--print(self.interactable.power)
		local state = self.interactable.publicData.state
		local parents = self.interactable:getParents()
		local flag
		if state == "and" or state == "nand" then
			flag = true
			for k,v in pairs(parents)do
				flag = flag and v.active
			end
			if state == "and" then
				self.interactable:setActive(flag)
			else
				self.interactable:setActive(not(flag))
				flag = not(flag)
			end
		elseif state == "or" or state == "nor" then
			flag = false
			for k,v in pairs(parents)do
				flag = flag or v.active
			end
			if state == "or" then
				self.interactable:setActive(flag)
			else
				self.interactable:setActive(not(flag))
				flag = not(flag)
			end
		elseif state == "xor" or state == "nxor" then
			local cnt = 0
			for k,v in pairs(parents)do
				if v.active then
					cnt = cnt + 1
				end
			end
			flag = true
			if cnt%2 == 0 then
				flag = false
			end
			if state == "xor" then
				self.interactable:setActive(flag)
			else
				self.interactable:setActive(not(flag))
				flag=not(flag)
			end
		end
		if flag then
			self.interactable:setPower(1)
		else
			self.interactable:setPower(0)
		end

		if self.shape.body:isOnLift() and self.sendClient then
			self.network:sendToClients("client_changeState",state)
			self.sendClient = false
			--仅用来当被作为导弹召唤出来时（or蓝图召唤）发给client端
		end
		if self.shape.body:isOnLift() and self.readyToBeSaved then
			self.storage:save({state = state})
			self.readyToBeSaved = false
		else
			self.readyToBeSaved = true
		end
	end
end

function MLG.server_changeState(self,inp)
	self.interactable:setPublicData({state = self.logicgateName[inp]})
	self.readyToBeSaved = true
end

function MLG.client_onCreate(self)
	self.KeyLogicgate["and"]=1
	self.KeyLogicgate["or"]=2
	self.KeyLogicgate["xor"]=3
	self.KeyLogicgate["nand"]=4
	self.KeyLogicgate["nor"]=5
	self.KeyLogicgate["nxor"]=6
	
end

function MLG.client_onInteract(self,character,state)
	if not state then
		return
	end
	self.savedState = (self.savedState)%6+1
	--print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
	--print("Client : "..self.savedState)
	self.network:sendToServer("server_changeState",self.savedState)
end

function MLG.client_changeState(self,inpState)
	--只进行一次，so，酱紫的做法就酱吧
	--[[self.KeyLogicgate["and"]=1
	self.KeyLogicgate["or"]=2
	self.KeyLogicgate["xor"]=3
	self.KeyLogicgate["nand"]=4
	self.KeyLogicgate["nor"]=5
	self.KeyLogicgate["nxor"]=6
	]]--
	self.savedState=self.KeyLogicgate[inpState]
	--print("Client : "..self.savedState)
end

function MLG.client_canInteract(self)
	--print(self.savedState)
	sm.gui.setInteractionText( "(put on lift to modify) : "..self.logicgateName[self.savedState])
	return true
end