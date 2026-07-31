--MAXZ666--
Mthruster = class(nil)
Mthruster.maxParentCount = 1
Mthruster.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power

Mthruster.colorNormal = sm.color.new(0x14514ff)
Mthruster.colorHighlight = sm.color.new(0x114514aa)

Mthruster.levelTable = {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 12000, 14000, 16000, 18000, 20000, 22000, 24000, 26000, 28000, 30000, 32000, 34000, 36000, 38000, 40000, 42000, 44000, 46000, 48000, 50000, 52000, 54000, 56000, 58000, 60000, 62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000}
Mthruster.colorWhite = "eeeeeeff"

----------------------------------server
function Mthruster.server_onCreate(self)
    self.interactable:setActive(false)
    self.readyToBeSaved = true
    self.sendClient = true
    local savedDataD = self.storage:load()
    if savedDataD ~= nil then self.levelIndex = savedDataD.level end
    if self.levelIndex == nil then
        self.levelIndex = 10
        self.oup = self.levelTable[self.levelIndex]
        self.storage:save({level = self.levelIndex})
    else
        self.oup = self.levelTable[self.levelIndex]
    end
    if self.shape.body:isOnLift() then
        self.interactable:setPublicData({level = self.levelIndex})
    end
    self.network:sendToClients("client_getUIData", self.levelIndex)
end

function Mthruster.server_request(self)
    self.network:sendToClients("client_getUIData", self.levelIndex)
end

function Mthruster.server_levelChange(self,levelIndex)
    self.levelIndex = levelIndex
    self.oup = self.levelTable[self.levelIndex]
    self.storage:save({level = self.levelIndex})
    self.interactable:setPublicData({level = self.levelIndex})
    self.network:sendToClients("client_getUIData", self.levelIndex)
end

function Mthruster.server_onFixedUpdate(self,dt)
    if self.interactable.publicData ~= nil and self.levelIndex ~= self.interactable.publicData.level then
        self.levelIndex = self.interactable.publicData.level
    end

    self.input = self.interactable:getSingleParent()
    if self.input ~= nil then 
        self.inputActive = self.input:isActive()
        self.inputPower = self.input.power
        if self.inputPower == 0 and self.inputActive then self.inputPower = 1 end
        --createEffect
        if self.lastInput ~= nil then
            if self.lastInput ~= self.inputActive then
                if self.inputActive then
                    --self.network:sendToClients("client_startEffect")
                    if tostring(self.input.shape.color) ~= self.colorWhite then
                        self.interactable:setActive(true)
                    end
                else
                    self.interactable:setActive(false)
                    --self.network:sendToClients("client_endEffect")
                end
            end
        end
        self.lastInput = self.inputActive
    end

    --main
        if self.inputActive then
            --print("active")
            local k = self.levelTable[self.levelIndex]
            --print(k)
            sm.physics.applyImpulse(self.shape, sm.vec3.new(0,-k,0)*dt*self.inputPower)
        end
    --end

    if self.shape.body:isOnLift() and self.sendClient then
		self.network:sendToClients("client_getUIData", self.levelIndex)
		self.sendClient = false
		--仅用来当被作为导弹召唤出来时（or蓝图召唤）发给client端
	end
	if self.shape.body:isOnLift() and self.readyToBeSaved then
		self.storage:save({level = self.levelIndex})
		self.readyToBeSaved = false
	else
		self.readyToBeSaved = true
	end
end
----------------------------------client
function Mthruster.client_onCreate(self)
    self.UIPosIndex = 10
    self.network:sendToServer("server_request")
    self.effect = sm.effect.createEffect("shine")
    self.readyToEffect = true
end

function Mthruster.client_getUIData(self, UIPosIndex)
    self.UIPosIndex = UIPosIndex
end

function Mthruster.client_onInteract(self,character,state)
    if not state then return end
    if self.gui == nil then
        self.gui = sm.gui.createEngineGui()
        self.gui:setSliderCallback("Setting","client_onSliderChange")
        self.gui:setText("Name","M_thruster")
        self.gui:setText("Interaction","setLevel")
        self.gui:setVisible("FuelContainer",false)
    end
    self.gui:setSliderData("Setting",#self.levelTable,self.UIPosIndex-1)
    self.gui:setText("SubTitle","level : "..self.levelTable[self.UIPosIndex])
    self.gui:open()
end

function Mthruster.client_onSliderChange(self,sliderName,sliderPos)
    local newIndex = sliderPos + 1
    self.UIPosIndex = newIndex
    if self.gui~=nil then
        self.gui:setText("SubTitle","level : "..self.levelTable[newIndex])
    end
    self.network:sendToServer("server_levelChange",newIndex)
end

function Mthruster.client_canInteract(self)
    sm.gui.setInteractionText("",sm.gui.getKeyBinding("Use"),"level : "..self.levelTable[self.UIPosIndex])
    return true
end

function Mthruster.client_startEffect(self)
    self.effect:setPosition(self.shape:getWorldPosition())
    self.effect:setRotation(self.shape:getWorldRotation())
    self.effect:start()
end

function Mthruster.client_endEffect(self)
    self.effect:stop()
end

function Mthruster.client_onDestroy(self)
    self.effect:stop()
end

function Mthruster.client_onUpdate(self)
    if self.interactable:isActive() then
        self.effect:setPosition(self.shape:getWorldPosition())
        self.effect:setRotation(self.shape:getWorldRotation())
        if self.readyToEffect then
            self.effect:start()
            self.readyToEffect = false
        end
    else
        self.effect:stop()
        self.readyToEffect = true
    end
end