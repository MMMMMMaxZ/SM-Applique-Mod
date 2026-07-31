--MAXZ666--
MHUD = class(nil)
MHUD.maxParentCount = 1
MHUD.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power

MHUD.colorNormal = sm.color.new(0x14514ff)
MHUD.colorHighlight = sm.color.new(0x114514aa)

----------------------------------server
function MHUD.server_onCreate(self)
    self.serverScale = self.storage:load()
    if self.serverScale == nil then
        self.serverScale = 1
    end
    self.network:sendToClients("client_onChangeScale",self.serverScale)
end

function MHUD.server_onFixedUpdate(self,dt)
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
    if self.interactable.active then
        --[[print("PRINT\n\n")
        print(self.shape.worldPosition)
        local X = sm.vec3.new(1,0,0)
        local Y = sm.vec3.new(0,1,0)
        local Z = sm.vec3.new(0,0,1)
        local t = sm.vec3.normalize(sm.vec3.new(self.shape.at:dot(X),self.shape.at:dot(Y),0))
        print(t,"\n")
        print(self.shape.worldRotation*sm.vec3.new(0,1,0))
        print(self.shape.at)
        print(self.shape.worldRotation*sm.vec3.new(0,0,1))
        print(self.shape.up)
        print("\n\n")]]
    end
    --end

end

function MHUD.server_saveScale(self,inpScale)
    self.storage:save(inpScale)
end
----------------------------------client
function MHUD.client_onCreate(self)
    self.scale = 1
    --self.HUD1 = sm.effect.createEffect("HUD1_"..scale.."x",self.interactable)
    self.HUD1 = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.HUD1:setParameter("uuid" , sm.uuid.new("2407b2be-5d2c-4e52-984a-64cf482fe4b0"))
    self.HUD2 = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.HUD2:setParameter("uuid" , sm.uuid.new("2407b2be-5d2c-4e52-984a-64cf482fe4b1"))
    self.HUD2_2 = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.HUD2_2:setParameter("uuid" , sm.uuid.new("2407b2be-5d2c-4e52-984a-64cf482fe4b2"))
    self.lastInp = false
    self.lastVel = self.shape.velocity

    --self.tempE1 = sm.effect.createEffect("testEffect",self.interactable)
    --self.tempE2 = sm.effect.createEffect("testEffect",self.interactable)
end

function MHUD.client_onUpdate(self,dt)
    if self.interactable:isActive() then
        if self.lastInp == false then
            self.HUD1:start()
            self.HUD2:start()
            self.HUD2_2:start()
        end
        local v=0.41*self.scale
        self.HUD1:setParameter("color",self.shape.color)
        self.HUD2:setParameter("color",self.shape.color)
        self.HUD2_2:setParameter("color",self.shape.color)
        self.HUD1:setScale(sm.vec3.new(v,v,v))
        self.HUD2:setScale(sm.vec3.new(v,v,v))
        self.HUD2_2:setScale(sm.vec3.new(v,v,v))

        local X=sm.vec3.new(1,0,0) -- 对应初始Right
        local Y=sm.vec3.new(0,1,0) -- 对应初始At
        local Z=sm.vec3.new(0,0,1) -- 竖直的轴，对应默认的Up向量（*-1）

        local Astandard=Y*-1 --用于定位水平面的旋转的标准
        local AXY=(sm.vec3.new(self.shape.at.x,self.shape.at.y,0)) -- At的水平分向量
        local AXYrtt=sm.vec3.getRotation(AXY,Astandard) -- 水平分向量转到初始的标准水平向量Astandard
        local AXYRVrtt=sm.vec3.getRotation(Astandard,AXY)--reverse

        local Zsrdrt = sm.vec3.getRotation(AXY,Z*-1) -- 水平分向量转到竖直Z轴，用于定位未绕At向量旋转的标准Up向量
        local Zstandard = Zsrdrt*self.shape.at -- 将At向量按上面的旋转去转，得到未绕At向量旋转的标准Up向量
        local cosSita = sm.vec3.dot(self.shape.up,Zstandard) -- 现在的Up向量与标准Up向量的夹角的cos值

        local newAt = sm.vec3.new(self.shape.at.x,self.shape.at.y,self.shape.at.z*cosSita) -- 用旋转或计算旋转太复杂了，我想到简单快速有效的方法是将At在Z轴的分向量乘以上面cos值实现偏转对寻找水平面的影响
        -- 这中间的部分（计算偏转）针对的是当整个倒过来的时候你会发现只考虑At的话方向是错的，这样中间可能会不准，但是未水平时本来就难看出来，所以不需要考虑哈哈哈哈
        local atRotation = sm.vec3.getRotation(newAt,AXY)
        -- 将NewAt转到水平面的旋转量（四元数）
        self.HUD1:setOffsetRotation(AXYrtt*atRotation*AXYRVrtt) -- 先把At转到标准（At所在竖直面转到ZY平面），再上下旋转，最后再转回去。

        local antiRota = sm.quat.inverse(self.shape.worldRotation)

        local HUD2_2rota = sm.vec3.getRotation(antiRota*self.shape.up,antiRota*Zstandard*-1)
        self.HUD2_2:setOffsetRotation(HUD2_2rota)

    else
        self.HUD1:stop()
        self.HUD2:stop()
        self.HUD2_2:stop()
    end
    self.lastInp = self.interactable:isActive()
    self.lastVel = self.shape.velocity
end

function MHUD.client_onInteract(self,character,state)
    if not state then return end
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/HUD_int.layout")
    self.gui:setText("Name", " HUD ")
    self.gui:setText("SubTitle", "scale "..self.scale)
    self.gui:createHorizontalSlider("scale",10,self.scale-1,"client_onSliderChangeScale")
    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MHUD.client_onSliderChangeScale(self,sliderPos)
    self.scale = sliderPos + 1
    self.gui:setText("SubTitle", "scale "..self.scale)
end

function MHUD.client_onClose(self)
    if self.gui then
        self.gui:close()
        self.gui:destroy()
        self.gui = nil
    end
    self.network:sendToServer("server_saveScale",self.scale)
end

function MHUD.client_onChangeScale(self,serverScale)
    self.scale = serverScale
end