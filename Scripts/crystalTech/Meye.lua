Meye = class(nil)
Meye.maxParentCount = 1
Meye.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power

Meye.colorNormal = sm.color.new(0x14514ff)
Meye.colorHighlight = sm.color.new(0x114514aa)

Meye.RYD_UUID = "5001aada-5494-11e6-beb8-9e71128cae77" --热诱弹

function Meye.server_onCreate(self)
    self.targetIndex = 1
end

function Meye.server_onFixedUpdate(self,dt)
    --读取内部储存的目标
    if self.interactable.publicData ~= nil and self.targetIndex ~= self.interactable.publicData.tIndex then
        self.targetIndex = self.interactable.publicData.tIndex
    end

    --判定输入
    self.input = self.interactable:getSingleParent()
    if self.input ~= nil then 
        self.inputActive = self.input:isActive()
        self.inputPower = self.input.power
        if self.inputPower ~= 0 and not self.inputActive then self.inputActive = true end
    end

    --执行追踪
    if self.inputActive then
        self.playerList = sm.player.getAllPlayers()
        self.targetPlayer = self.playerList[self.targetIndex]:getCharacter()
        self.targetPosition = self.targetPlayer.worldPosition
        --获得距离
        self.targetDistance = sm.vec3.length2(self.targetPosition - self.shape.worldPosition)
        --热诱弹判定
        --uuid : 5001aada-5494-11e6-beb8-9e71128cae77
        --改为RYD_UUID
        local allBodies = sm.body.getAllBodies()
        for i,Ibody in pairs(allBodies)do
            local Ishapes = Ibody:getShapes()
            for j,Jshape in pairs(Ishapes)do
                local Juuid = tostring(Jshape.uuid)
                if Juuid == self.RYD_UUID then
                    --热诱弹
                    local RYD_Position = Jshape.worldPosition
                    local RYD_Distance = sm.vec3.length2(RYD_Position - self.shape.worldPosition)
                    if RYD_Distance < self.targetDistance then
                        self.targetPosition = RYD_Position
                    end
                end
            end
        end
        --开始制导
        self.targetVec = sm.vec3.normalize(self.shape.worldPosition - self.targetPosition) * -0.5 * self.shape.body.mass
        sm.physics.applyImpulse(self.shape,self.targetVec,true)
    end
end