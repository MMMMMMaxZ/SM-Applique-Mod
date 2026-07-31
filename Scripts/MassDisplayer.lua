MDr = class(nil)

function MDr.client_onCreate(self)
    self.massEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.massEffect:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"))
    self.massEffect:setParameter("color",sm.color.new("00fcfc"))
    self.massEffect:setScale(sm.vec3.new(1,1,1))
    self.massEffect:start()
    self.creation = self.shape.body:getCreationBodies()
end

function MDr.client_onFixedUpdate(self,dt)
    self.creation = self.shape.body:getCreationBodies()
    local rvR = sm.quat.inverse(self.shape.worldRotation)
    local massPos = sm.vec3.new(0,0,0)
    local sumMass = 0
    for k,v in pairs(self.creation)do
        massPos = massPos + (v.centerOfMassPosition - self.shape.worldPosition)*v.mass
        sumMass = sumMass + v.mass
    end
    massPos = massPos/sumMass
    self.massEffect:setOffsetPosition(rvR*massPos)
end

function MDr.client_onDestroy(self)
    self.massEffect:destroy()
end