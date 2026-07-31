APLQ = class(nil)

function APLQ:new(DEVICE,id,offP,offR,color,scale,cleanFlag,state)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    obj:init(DEVICE,id,offP,offR,color,scale,cleanFlag,state)
    return obj
end

function APLQ:init(DEVICE,id,offP,offR,color,scale,cleanFlag,state)
    self.id = id or -1
    self.state = state or "origin"
    self.offsetPosition = offP or sm.vec3.new(0,0,0)
    self.offsetRotation = offR or sm.quat.new(0,0,0,1)
    self.color = color or sm.color.new("00000000")
    self.scale = scale or sm.vec3.new(1,1,1)

    self._DEVICE = DEVICE or nil
    self.cleanFlag = cleanFlag or false
    self:addEffect()
end

function APLQ:addEffect()
    if(self._DEVICE == nil)then return end
    self.effect = sm.effect.createEffect("ShapeRenderable",self._DEVICE.interactable)
    self.effect:setParameter("uuid",CE.effectUUIDList[self.id][self.state])
    self.effect:setParameter("color",self.color)
    self.effect:setScale(self.scale*0.255)
    self.effect:setOffsetPosition(self.offsetPosition)
    self.effect:setOffsetRotation(self.offsetRotation)
    self.effect:start()
end

function APLQ:getData()
    local rtn = {}
    rtn.id = self.id
    rtn.state = self.state
    rtn.offsetPosition = {x=self.offsetPosition.x,y=self.offsetPosition.y,z=self.offsetPosition.z}
    rtn.offsetRotation = {x=self.offsetRotation.x,y=self.offsetRotation.y,z=self.offsetRotation.z,w=self.offsetRotation.w}
    rtn.color = self.color:getHexStr()
    rtn.scale = {x=self.scale.x,y=self.scale.y,z=self.scale.z}
    return rtn
end

function APLQ:DataToSm(table)
    local id = table.id
    local state = table.state
    local offsetPosition = sm.vec3.new(table.offsetPosition.x,table.offsetPosition.y,table.offsetPosition.z)
    local offsetRotation = sm.quat.new(table.offsetRotation.x,table.offsetRotation.y,table.offsetRotation.z,table.offsetRotation.w)
    local color = sm.color.new(table.color)
    local scale = sm.vec3.new(table.scale.x,table.scale.y,table.scale.z)
    return id,offsetPosition,offsetRotation,color,scale,false,state
end

function APLQ:fullData(data)
    local rtn = {}
    rtn.id = data.id or -1
    rtn.state = data.state or "origin"
    if data.offsetPosition == nil then
        rtn.offsetPosition = {0,0,0}
    else
        rtn.offsetPosition = {x=data.offsetPosition.x,y=data.offsetPosition.y,z=data.offsetPosition.z}
    end
    if data.offsetRotation == nil then
        rtn.offsetRotation = {0,0,0,1}
    else
        rtn.offsetRotation = {x=data.offsetRotation.x,y=data.offsetRotation.y,z=data.offsetRotation.z,w=data.offsetRotation.w}
    end
    if data.color == nil then
        rtn.color = "00000000"
    else
        rtn.color = data.color:getHexStr()
    end
    if data.scale == nil then
        rtn.scale = {1,1,1}
    else
        rtn.scale = {x=data.scale.x,y=data.scale.y,z=data.scale.z}
    end
    return rtn
end