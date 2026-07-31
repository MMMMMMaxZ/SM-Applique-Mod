-- MAXZ666 --
-- Max's applique generator
MAG = class(nil)
MAG.maxParentCount = 1
MAG.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power

MAG.colorNormal = sm.color.new(0x14514ff)
MAG.colorHighlight = sm.color.new(0x114514aa)

MAG.effectPlayer = {}
MAG.efctPlyrCnt = {}
MAG.effectList = {}
MAG.effectUUIDList = {}

function MAG.sortTable(self,input)
    local oup = {}
    for k,v in pairs(input)do
        local s = tonumber(string.sub(v,1,3))
        oup[s] = v
    end
    return oup
end

function MAG.create_aplq(self)
    local MAGs = sm.json.open("$MOD_DATA/Scripts/MAG_list/MAGs.json")
    local orderedMAGs = {}
    local cnt = 0
    for type,names in pairs(MAGs)do
        cnt = cnt + 1
        orderedMAGs[cnt]=type
    end
    orderedMAGs = self:sortTable(orderedMAGs)
    cnt = 0
    self.efctPlyrCnt[1]=1
    for i,oType in pairs(orderedMAGs)do
        local type = oType
        local names = MAGs[type]
        cnt = cnt + 1
        self.effectPlayer[cnt]=type
        self.efctPlyrCnt[cnt+1]=#names + self.efctPlyrCnt[cnt]
        
        --generate renderable
        for k,v in pairs(names)do
            self.effectList[self.efctPlyrCnt[cnt]+k-1]=v
            local tempRenderable = {lodList={}}
            tempRenderable["lodList"][1]={
                mesh = "$CONTENT_DATA/Objects/Mesh/MAG/testEftFixed.obj",
                minViewSize = 15,
                subMeshList = {
                    {
                        custom = {
                            shadow = false
                        },
                        material = "Leaves",
                        textureList = {
                            "$CONTENT_DATA/Objects/Textures/MAG/_empty-export.tga",
                            "$CONTENT_DATA/Objects/Textures/MAG/"..type.."/"..v.."_asg-export.tga",
                            "$CONTENT_DATA/Objects/Textures/MAG/_empty-nor.tga"
                        }
                    }
                }
            }
            if type == "000MaxZ666" then
                tempRenderable["lodList"][1]["subMeshList"][1]["textureList"][1]="$CONTENT_DATA/Objects/Textures/MAG/MaxZ666_dif.tga"
            end
            --sm.json.save(tempRenderable,"$CONTENT_DATA/Objects/Renderable/MAG/"..type.."/"..v.."_gn.json")
        end
        
        --generate shape set
        local tempTable = {partList = {}}
        for k,v in pairs(names)do
            local a=(k-k%100)/100%10
            local b=(k-k%10)/10%10
            local c=k%10
            local ca=(cnt-cnt%100)/100%10
            local cb=(cnt-cnt%10)/10%10
            local cc=cnt%10
            tempTable["partList"][k]={
                box={
                    x=1,
                    y=1,
                    z=1
                },
                color = "FFFFFF",
                name = v,
                physicsMaterial = "Default",
                renderable = "$CONTENT_DATA/Objects/Renderable/MAG/"..type.."/"..v.."_gn.json",
                rotationSet = "Default",
                showInInventory = false,
                uuid = ca..cb..cc.."2359a-1068-4de7-b7a0-a41682e47"..a..b..c
            } 

            self.effectUUIDList[self.efctPlyrCnt[cnt]+k-1]=sm.uuid.new(ca..cb..cc.."2359a-1068-4de7-b7a0-a41682e47"..a..b..c)
        end
        --sm.json.save(tempTable,"$CONTENT_DATA/Objects/Database/ShapeSets/MAG_"..type.."_gn.json")
    end
    cnt = cnt + 1
    self.effectPlayer[cnt]="End"
    self.effectList[self.efctPlyrCnt[cnt]]="lazer"
    print(self.effectPlayer)
    print(self.efctPlyrCnt)
    print(self.effectList)
    print(self.effectUUIDList)
end

--server
function MAG.server_onCreate(self)
    --self:create_aplq()
    self.Server_effectTable = self.storage:load()
    if(self.Server_effectTable==nil)then
        self.Server_effectTable={}
    end
    self.Server_tableCnt = #self.Server_effectTable
    self.network:sendToClients("client_getSavedData",self.Server_effectTable)
end

function MAG.server_onFixedUpdate(self,dt)
    self.input = self.interactable:getSingleParent()
    if self.input ~= nil then
        self.inputActive = self.input:isActive()
    else
        self.inputActive = false
    end
    if self.inputActive then
        self.interactable:setActive(true)
    else 
        self.interactable:setActive(false)
    end
end

function MAG.server_saveData(self,data)
    self.Server_effectTable = {}
    local i=1
    --print("saveeee\n")
    for idx,data in pairs(data)do
        --print("data[",idx,"]")
        --print(data)
        if not data.cleanFlag then
            self.Server_effectTable[i] = data
            i = i + 1
        end
    end
    --print("\n",self.Server_effectTable)
    self.storage:save(self.Server_effectTable)
    self.network:sendToClients("client_getSavedData",self.Server_effectTable)
    --print("\n\n")
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

--------------------------------------------client-----------------------------------------

function MAG.client_onCreate(self)
    self:create_aplq()
    self.effectTableData = {}
    self.effectTable = {}
    self.tableCnt = 0

    self.currentScale = {x=10,y=10,z=10}
    self.currentRotation = 12
    self.currentEffectId = 1
    self.maxEffectId = #self.effectList
    self.currentEfctPlyr = 1
    self.currentEfctPlus = 0

    self.localPlayer = sm.localPlayer.getPlayer()
    self.ready = true
    self.lastState = false -- false未启动，true启动

    self.scaleTable = {
        0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,
        1,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,
        2,2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,
        3,3.1,3.2,3.3,3.4,3.5,3.6,3.7,3.8,3.9,
        4,4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,
        5
    }--0.255
    self.rotaTable = {15,30,45,60,75,90,105,120,135,150,165,180,195,210,225,240,255,270,285,300,315,330,345,360}
    self.rotaTable[0]=0

    self.currentEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.currentEffect:setParameter("uuid",self.effectUUIDList[1])

    self.pointEffect = sm.effect.createEffect("point",self.interactable)
end

function MAG.client_getSavedData(self,savedTable)
    self.effectTableData = savedTable
    self:translateData(self.effectTableData)
    self.tableCnt = #self.effectTableData + 1
end

function MAG.translateData(self,inputData)
    for k,v in pairs(self.effectTable)do
        v:destroy()
        self.effectTable[k]=nil
    end
    --print("\n\n -- client_translate -- \n")
    for idx,data in pairs(inputData)do
        --print("data[",idx,"]")
        --print(data)
        --if self.effectTable[idx] ~= nil then self.effectTable[idx]:destroy() end
        self.effectTable[idx] = sm.effect.createEffect("ShapeRenderable",self.interactable)
        self.effectTable[idx]:setParameter("uuid",self.effectUUIDList[data.id])
        self.effectTable[idx]:setOffsetPosition(sm.vec3.new(data.offsetPosition.x,data.offsetPosition.y,data.offsetPosition.z))
        self.effectTable[idx]:setOffsetRotation(sm.quat.new(data.offsetRotation.x,data.offsetRotation.y,data.offsetRotation.z,data.offsetRotation.w))
        self.effectTable[idx]:setParameter("color",sm.color.new(data.color))
        self.effectTable[idx]:setScale(sm.vec3.new(data.scale.x,data.scale.y,data.scale.z)*0.255)
        self.effectTable[idx]:start()
    end
    --print("\n -- client_end -- \n\n")
end

function MAG.changeCurrentEffect(self)
    self.currentEffect:destroy()
    self.currentEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.currentEffect:setParameter("uuid",self.effectUUIDList[self.currentEffectId])
    self.currentEffect:setOffsetPosition(self.shape.up*0.3)
    self.currentEffect:setScale(sm.vec3.new(self.scaleTable[self.currentScale.x],self.scaleTable[self.currentScale.y],self.scaleTable[self.currentScale.z])*0.255)

    self.currentEffect:start()
end

function MAG.findEfctPlyr(self)
    local oup
    for k,v in pairs(self.efctPlyrCnt)do
        if self.currentEffectId >=v and self.currentEffectId <self.efctPlyrCnt[k+1] then
            oup = k
        end
    end
    self.currentEfctPlyr = oup
    self.currentEfctPlus = self.currentEffectId - self.efctPlyrCnt[self.currentEfctPlyr]
end

function MAG.client_onFixedUpdate(self,dt)
    if self.shape.body:isOnLift() then
        for idx,efct in pairs(self.effectTable)do
            if not efct:isPlaying() and not self.effectTableData[idx].cleanFlag then
                efct:start()
            end
        end
    end
    if self.interactable:isActive()then
        if self.lastState == false then --第一次启动获取最近玩家并绑定
            self.lastState = true
            local allPlayers = sm.player.getAllPlayers()
            self.currentPlayer = NearestPlayer(self.shape.worldPosition,allPlayers)
            self.currentCharacter = self.currentPlayer.character
            self.currentEffect:start()
        end
        if self.localPlayer == self.currentPlayer then 
            local get,result = sm.localPlayer.getRaycast(10)
            if get then
                local hitLocation = result.pointWorld
                local hitNormal = result.normalWorld
                local offR = sm.vec3.getRotation(self.shape.at,hitNormal)
                local fixRotation = sm.quat.inverse(self.shape.worldRotation)
                local offP = fixRotation*(hitLocation-self.shape.worldPosition)

                local efctUp = offR*self.shape.up
                local efctAt = offR*self.shape.at
                local efctRotaUp = efctUp:rotate(self.rotaTable[self.currentRotation]/180*3.14,efctAt)
                local efctRota = sm.vec3.getRotation(efctUp,efctRotaUp)
                offR = efctRota*offR
                ----蹲下的箭头
                if self.currentCharacter:isCrouching() then
                    local nIdx,nDistance = 1,1000
                    for idx,data in pairs(self.effectTableData)do
                        local ofp = offP - sm.vec3.new(data.offsetPosition.x,data.offsetPosition.y,data.offsetPosition.z)
                        local ofpd = ofp:length()
                        if ofpd <= nDistance then
                            nDistance = ofpd
                            nIdx = idx
                        end
                    end
                    if(nDistance<=0.23)then
                        self.nearestEffectID = nIdx
                        local PoffP = self.effectTableData[nIdx].offsetPosition
                        local PoffR = self.effectTableData[nIdx].offsetRotation
                        self.pointEffect:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
                        self.pointEffect:setOffsetRotation(sm.quat.new(PoffR.x,PoffR.y,PoffR.z,PoffR.w))
                        if not self.pointEffect:isPlaying() then self.pointEffect:start() end
                        if self.currentEffect:isPlaying() then self.currentEffect:stop() end
                    else
                        if self.pointEffect:isPlaying() then self.pointEffect:stop() end
                        if not self.currentEffect:isPlaying() then self.currentEffect:start() end
                    end
                else
                    if self.pointEffect:isPlaying() then self.pointEffect:stop() end
                    if not self.currentEffect:isPlaying() then self.currentEffect:start() end
                end
                ----贴上 or 删除
                if not self.currentCharacter:isAiming() then
                    self.ready = true
                    self.currentEffect:setOffsetPosition(fixRotation*(hitLocation-self.shape.worldPosition))
                    self.currentEffect:setOffsetRotation(offR)
                    self.currentEffect:setParameter("color",self.shape.color)
                    self.currentEffect:setScale(sm.vec3.new(self.scaleTable[self.currentScale.x],self.scaleTable[self.currentScale.y],self.scaleTable[self.currentScale.z])*0.255)
                elseif self.ready then
                    if not self.currentCharacter:isCrouching() then--put
                        self.ready = false
                        self.effectTable[self.tableCnt]=sm.effect.createEffect("ShapeRenderable",self.interactable)
                        self.effectTable[self.tableCnt]:setParameter("uuid",self.effectUUIDList[self.currentEffectId])
                        self.effectTable[self.tableCnt]:setParameter("color",self.shape.color)
                        self.effectTable[self.tableCnt]:setScale(sm.vec3.new(self.scaleTable[self.currentScale.x],self.scaleTable[self.currentScale.y],self.scaleTable[self.currentScale.z])*0.255)
                        self.effectTable[self.tableCnt]:setOffsetPosition(offP)
                        self.effectTable[self.tableCnt]:setOffsetRotation(offR)
                        self.effectTable[self.tableCnt]:start()
                        self.effectTableData[self.tableCnt]={
                            id = self.currentEffectId ,
                            offsetPosition = {x=offP.x,y=offP.y,z=offP.z},
                            offsetRotation = {x=offR.x,y=offR.y,z=offR.z,w=offR.w},
                            color = self.shape.color:getHexStr(),
                            scale = {x=self.scaleTable[self.currentScale.x],y=self.scaleTable[self.currentScale.y],z=self.scaleTable[self.currentScale.z]},
                            cleanFlag = false
                        }
                        self.tableCnt = self.tableCnt + 1
                        --print(self.tableCnt-1)
                    elseif #self.effectTableData > 0 then --erase
                        local nIdx = self.nearestEffectID
                        self.effectTableData[nIdx].cleanFlag = true
                        --print(self.effectTable[nIdx]:isPlaying())
                        self.effectTable[nIdx]:stop()
                    end
                end
            end
        end
    else
        if self.lastState == true then
            if self.localPlayer == self.currentPlayer then 
                self.currentEffect:stop()
                --send back data
                sm.gui.displayAlertText("sending data to server 同步数据到服务端中",2)
                self.network:sendToServer("server_saveData",self.effectTableData)
            end
        end
        self.lastState = false
    end
end

function MAG.client_canInteract(self,character)
	--print(self.savedState)
	--sm.gui.setInteractionText( sm.gui.getKeyBinding( "Use" ).." : current applique 当前贴图 : "..self.effectList[self.currentEffectId].."  //  "..(sm.gui.getKeyBinding( "Tinker" )).." : rotate 旋转")
	return true
end

function MAG.client_onInteract(self,character,state)
    if not state then return end
    self:findEfctPlyr()
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAG_int.layout")
    self.gui:setText("Name", " MAG ")
    self.gui:setText("SubTitle", self.effectPlayer[self.currentEfctPlyr].." : "..self.effectList[self.currentEffectId])
    self.gui:createHorizontalSlider("slider1",#self.effectPlayer-1,self.currentEfctPlyr-1,"client_onSliderChangePlayer",true)
    self.gui:createHorizontalSlider("slider2",20,self.currentEfctPlus,"client_onSliderChangeApplique",true)
    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAG.client_canTinker(self,character)
    if not self.shape.usable then
		return false
	end
    return true
end

function MAG.client_onTinker(self,character,state)
    if not state then return end
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAG_rota_scale.layout")
    self.gui:setText("Name", "Rotation and Scale")
    self.gui:setText("SubTitle", "旋转"..self.rotaTable[self.currentRotation].."大小"..self.scaleTable[self.currentScale.x]..","..self.scaleTable[self.currentScale.y]..","..self.scaleTable[self.currentScale.z])
    self.gui:createHorizontalSlider("slider1",#self.rotaTable-1,self.currentRotation,"client_onSliderChangeOffRota",false)
    self.gui:createHorizontalSlider("slider2",#self.scaleTable,self.currentScale.x-1,"client_onSliderChangeScaleX",false)
    self.gui:createHorizontalSlider("slider3",#self.scaleTable,self.currentScale.y-1,"client_onSliderChangeScaleY",false)
    self.gui:createHorizontalSlider("slider4",#self.scaleTable,self.currentScale.z-1,"client_onSliderChangeScaleZ",false)
    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAG.client_onSliderChangePlayer(self, sliderPos)
    --print("P",sliderPos)
    self.currentEfctPlyr = sliderPos+1
    self.currentEfctPlus = 0
    self.currentEffectId = self.efctPlyrCnt[self.currentEfctPlyr]+self.currentEfctPlus
    --self.gui:setSliderRangeLimit("belongingPlayer2",self.efctPlyrCnt[self.currentEfctPlyr+1]-self.efctPlyrCnt[self.currentEfctPlyr]+1)
    self.gui:setText("SubTitle", self.effectPlayer[self.currentEfctPlyr].." : "..self.effectList[self.currentEffectId])
    self:changeCurrentEffect()
end

function MAG.client_onSliderChangeApplique(self, sliderPos)
    --print("A",sliderPos)
    if sliderPos >= self.efctPlyrCnt[self.currentEfctPlyr+1]-self.efctPlyrCnt[self.currentEfctPlyr]  then
        self.currentEfctPlus = self.efctPlyrCnt[self.currentEfctPlyr+1]-self.efctPlyrCnt[self.currentEfctPlyr] - 1
    else
        self.currentEfctPlus = sliderPos
    end
    
    self.currentEffectId = self.efctPlyrCnt[self.currentEfctPlyr]+self.currentEfctPlus
    self.gui:setText("SubTitle", self.effectPlayer[self.currentEfctPlyr].." : "..self.effectList[self.currentEffectId])
    self:changeCurrentEffect()
end

function MAG.client_onSliderChangeOffRota(self, sliderPos)
    --print("R",sliderPos)
    self.currentRotation = sliderPos
    self.gui:setText("SubTitle", "旋转"..self.rotaTable[self.currentRotation].."大小"..self.scaleTable[self.currentScale.x]..","..self.scaleTable[self.currentScale.y]..","..self.scaleTable[self.currentScale.z])
    self:changeCurrentEffect()
end

function MAG.client_onSliderChangeScaleX(self, sliderPos)
    --print("R",sliderPos)
    self.currentScale.x = sliderPos+1
    self.gui:setText("SubTitle", "旋转"..self.rotaTable[self.currentRotation].."大小"..self.scaleTable[self.currentScale.x]..","..self.scaleTable[self.currentScale.y]..","..self.scaleTable[self.currentScale.z])
    self:changeCurrentEffect()
end

function MAG.client_onSliderChangeScaleY(self, sliderPos)
    --print("R",sliderPos)
    self.currentScale.y = sliderPos+1
    self.gui:setText("SubTitle", "旋转"..self.rotaTable[self.currentRotation].."大小"..self.scaleTable[self.currentScale.x]..","..self.scaleTable[self.currentScale.y]..","..self.scaleTable[self.currentScale.z])
    self:changeCurrentEffect()
end

function MAG.client_onSliderChangeScaleZ(self, sliderPos)
    --print("R",sliderPos)
    self.currentScale.z = sliderPos+1
    self.gui:setText("SubTitle", "旋转"..self.rotaTable[self.currentRotation].."大小"..self.scaleTable[self.currentScale.x]..","..self.scaleTable[self.currentScale.y]..","..self.scaleTable[self.currentScale.z])
    self:changeCurrentEffect()
end

function MAG.client_onClose(self)
    if self.gui then
        self.gui:close()
        self.gui:destroy()
        self.gui = nil
    end
    self:changeCurrentEffect()
end