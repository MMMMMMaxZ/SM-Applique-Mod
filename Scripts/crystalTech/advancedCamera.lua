AC = class(nil)

AC.maxParentCount = 1
AC.maxChildCount = -1
AC.connectionInput = sm.interactable.connectionType.seated + sm.interactable.connectionType.logic
AC.connectionOutput = sm.interactable.connectionType.logic
AC.colorNormal = sm.color.new(0x14514ff)
AC.colorHighlight = sm.color.new(0x114514aa)

--------------------------------------------server-----------------------------------------
function AC.server_onCreate(self)

end

function AC.server_onFixedUpdate(self,dt)

end
--------------------------------------------client-----------------------------------------
function AC.client_onCreate(self)
    self.lastInput = false
    self.lastPos = self.shape.worldPosition
    self.lastRot = self.shape.worldRotation
end

function NearestPlayer(position , playerList)
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

function AC.client_onFixedUpdate(self, dt)
    if self.lastInput and (not self:cl_checkPlayerOffSeat()) then 
        self:cl_endCamera()
        self.lastInput = false
    end
end

function AC.client_onUpdate(self,dt)
    if self:cl_isTarget() then
        self:cl_operateCamera(dt)
    end
end

function AC.cl_checkPlayerOffSeat(self)
    local seat = self.interactable:getSingleParent()
    if seat==nil then return false end
    if seat:getSeatCharacter()==nil then return false end
    return true
end

function AC.client_onInteract(self,character,state)
    if not state then return end
    if self.lastInput == false then
        self:cl_getCurrentPlayerNcharacter()
        self:cl_initAdCamera()
        self.lastInput = true
    else -- true
        self:cl_endCamera()
        self.lastInput = false
    end
end

function AC.cl_getCurrentPlayerNcharacter(self)
    local allPlayers = sm.player.getAllPlayers()
    self.currentPlayer = NearestPlayer(self.shape.worldPosition,allPlayers)
    self.currentCharacter = self.currentPlayer.character
end

function AC.cl_initAdCamera(self)
    if not self:cl_isTarget() then return end
    sm.camera.setCameraState(3)
end

function AC.cl_isTarget(self)
    if self.currentPlayer == nil then return false end
    --if self.currentCharacter then end
    local localID = sm.localPlayer.getId()
    return localID == self.currentPlayer.id
end

function AC.cl_operateCamera(self,dt)
    if self.lastInput == false then return end
    local playerDir = self.shape:getAt() -- self.currentCharacter:getDirection()
    local playerPullBackF,playerPullBackT
    playerPullBackF,playerPullBackT = sm.camera.getCameraPullback()
    local targetPos = self.shape.worldPosition - playerDir:normalize()*playerPullBackT*2
    local targetRot = self.shape.worldRotation

    local lerpP = dt*10
    local actualPos = sm.vec3.lerp(self.lastPos,targetPos,lerpP)
    local actualRot = sm.quat.slerp(self.lastRot,targetRot,lerpP)

    sm.camera.setFov(sm.camera.getDefaultFov()+playerPullBackT)
    sm.camera.setPosition(actualPos)
    sm.camera.setRotation(actualRot)
    
    self.lastPos = actualPos
    self.lastRot = actualRot
end

function AC.cl_endCamera(self)
    if self:cl_isTarget() then
        sm.camera.setCameraState(1)
        self.lastPos = self.shape.worldPosition
        self.lastRot = self.shape.worldRotation
    end
end

function AC.client_onDestroy(self)
	if self.lastInput and self:cl_isTarget() then
		sm.camera.setCameraState(1)
	end
end
