-- MAXZ666 --
-- Max's applique creator
MAC = class(nil)
MAC.maxParentCount = 1
MAC.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power

MAC.colorNormal = sm.color.new(0x14514ff)
MAC.colorHighlight = sm.color.new(0x114514aa)

MAC.colorRed = "d02525ff"

syncTable = {}
syncPlayer = {}

--server
function MAC.server_onCreate(self)
    local fullData = self.storage:load()
    
    if fullData==nil then -- 无储存
        self.partUUIDList = {}
        self.Server_effectTable={}
    elseif fullData["partUUIDList"]==nil then -- 旧版本（0.3.0~0.3.5）
        self.partUUIDList = {}
        self.Server_effectTable=fullData
    else -- 新版本（0.3.6+）
        self.partUUIDList = fullData.partUUIDList
        self.Server_effectTable = fullData.effectTableData
    end
    

    self.Server_tableCnt = #self.Server_effectTable
    self.Server_lastInput = false

    self.lastTick = sm.game.getCurrentTick()
    self.lastPlayerList = sm.player.getAllPlayers()
    self.lastDeviceAmount = 0

    self.network:sendToClients("client_getSavedData",{partUUIDList=self.partUUIDList,effectTableData=self.Server_effectTable})
end

function MAC.sv_syncData(self)
    local curRestTime -- = math.ceil(40*4*0.5^(#syncTable))
    if #syncTable~=0 then curRestTime = 10
    else curRestTime = 10 end
    local deltaTick = (sm.game.getCurrentTick() - self.lastTick) / 40 -- tick to second
    if deltaTick <= curRestTime then return end -- 每隔一段时间检查一次来优化
    self.lastTick = sm.game.getCurrentTick()
    local currentPlayerList = sm.player.getAllPlayers()
    -- > 除了同步问题
    if #syncTable~=0 and #syncTable == self.lastDeviceAmount then -- 没消去-->表首的装置不存在，需要清理
        syncPlayer[#syncPlayer]=nil
        syncTable[#syncTable]=nil
    end
    self.lastDeviceAmount = #syncTable
    if #syncTable == 0 or syncTable[#syncTable]~=self.shape.id then
        goto continue
    end
    if sm.exists(syncPlayer[#syncPlayer]) then
        self.network:sendToClient(syncPlayer[#syncPlayer],"client_getSavedData",{partUUIDList=self.partUUIDList,effectTableData=self.Server_effectTable})
    end
    syncPlayer[#syncPlayer]=nil
    syncTable[#syncTable]=nil
    ::continue::
    if #currentPlayerList <= #self.lastPlayerList then
        self.lastPlayerList = currentPlayerList
        return
    end
    -- > 有玩家加入
    syncTable[#syncTable+1] = self.shape.id
    syncPlayer[#syncPlayer+1] = currentPlayerList[#currentPlayerList]
    self.lastPlayerList = currentPlayerList
end

function MAC.server_onFixedUpdate(self,dt)
    self.sv_input = self.interactable:getSingleParent()
    if self.sv_input ~= nil then
        self.sv_inputActive = self.sv_input:isActive()
    else
        self.sv_inputActive = false
    end
    if self.sv_inputActive then
        if tostring(self.sv_input.shape.color) == self.colorRed then
            self.interactable:setActive(false)
            if not self.Server_lastInput then
                local allPlayers = sm.player.getAllPlayers()
                local nPlayer = NearestPlayer(self.shape.worldPosition,allPlayers)
                self.network:sendToClient(nPlayer,"client_onFileOperate")
            end
        else
            self.interactable:setActive(true)
        end
    else 
        self.interactable:setActive(false)
    end
    self:sv_syncData()
    self.Server_lastInput = self.sv_inputActive
end

function MAC.tableToString(self,data) -- element:int 小数取三位
    local rtn = ""
    for k,v in pairs(data)do
        local strV
        if  type(v)=="number" then
            strV = tostring(math.floor(v*1e3)/1e3)
        elseif type(v)=="string" then
            strV = v
        elseif type(v)=="table" then
            strV = self:tableToString(v)
        else
            strV = tostring(v)
        end
        rtn = rtn..strV
    end
    return rtn
end

function MAC.aplqToString(self,data)
    if data.state == nil then
        data.state = "origin"
    end
    local hashStr = data.color..tostring(data.id)..data.state
    hashStr = hashStr..self:tableToString(data.scale)..self:tableToString(data.offsetPosition)..self:tableToString(data.offsetRotation)
    return hashStr
end

function MAC.server_saveData(self,data)
    self.Server_effectTable = {}
    self.hashTable = {} --> 去重！
    local partUUIDList = data.partUUIDList
    local i=1
    for idx,data in pairs(data.effectTableData)do
        local hashData = self:aplqToString(data)
        if not data.cleanFlag and self.hashTable[hashData]==nil then
            self.Server_effectTable[i] = data
            self.hashTable[hashData] = 1
            i = i + 1
        end
    end
    self.storage:save({partUUIDList=partUUIDList,effectTableData=self.Server_effectTable})
    self.network:sendToClients("client_getSavedData",{partUUIDList=partUUIDList,effectTableData=self.Server_effectTable})
end

function MAC.sv_onCreateBackUp(self)
    local allPlayers = sm.player.getAllPlayers()
    local hostChar = allPlayers[1]:getCharacter()
    local BKbody = sm.body.createBody(hostChar.worldPosition)
    BKbody:createPart(sm.uuid.new("51da94d6-a215-4f69-b569-c45bc1557d0f"),sm.vec3.new(0,0,0),sm.vec3.new(0,-1,0),sm.vec3.new(1,0,0))
end

function MAC.sv_deleteConvertedPart(self,CPids)
    for k,v in pairs(CPids) do
        if sm.exists(v) then
            v:destroyShape(0)
        end
    end
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

function MAC.client_onCreate(self)
    if localPlayer == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_localPlayer.lua") -- 获取玩家操作
    end
    if CE == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_createEffects.lua") -- self:create_aplq()
        CE:init()
    end
    if MLines == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_MLines.lua") -- 适应多语言文本
        MLines:init()
    end
    if SS == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_selectSystem.lua") -- 用于编辑贴花（选择、对称）
        SS:init()
    end
    if TEST_POINT == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_testPoint.lua") -- 测试用的debug_draw
        TEST_POINT:init()
        TEST_POINT:set_description(1,"align_flag")
        TEST_POINT:set_description(2,"mirrorVecSt")
        TEST_POINT:set_description(3,"mirrorVecEd")
        TEST_POINT:set_description(4,"dragPoint")
        TEST_POINT:set_description(5,"centerPoint")
    end
    if MACP == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_MAC_Parameter.lua") -- 记录同一玩家的编辑参数
        MACP:init()
    end

    self.effectTableData = {}
    MACP:clear_action_table()
    self.effectTable = {}
    self.tableCnt = 1

    self.localPlayer = sm.localPlayer.getPlayer()
    self.leftReady = true
    self.rightReady = true
    self.lastState = false -- false未启动，true启动

    self.currentEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.currentEffect:setParameter("uuid",CE.effectUUIDList[1]["origin"])

    self.pointEffect = sm.effect.createEffect("point",self.interactable)

    self.mirrorEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.mirrorEffect:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f")) -- 玻璃UUID
    self.mirrorEffect:setParameter("color",sm.color.new("ffffff"))
    self.mirrorEffect:setScale(sm.vec3.new(20,0.001,20))

    self.mirrorPointEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.mirrorPointEffect:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f")) -- 玻璃UUID
    self.mirrorPointEffect:setParameter("color",sm.color.new("000000"))
    self.mirrorPointEffect:setScale(sm.vec3.new(0.1,0.1,0.1))

    self.mirrorFlag = false

    self.selectedMAGData = {}
    self.selectedBox = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.selectedBox:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f")) -- 玻璃UUID
    self.selectedBox:setParameter("color",sm.color.new("fcfcfc"))
    self.selectedBoxText = sm.gui.createNameTagGui()
    self.eraseTag = false

    self.rotateEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.rotateEffect:setParameter("uuid",sm.uuid.new("51da94d6-a215-4f69-b569-c45bc1557d10"))
    self.rotateEffect:setScale(sm.vec3.new(1,1.5,1)*0.25)

    self.freeSelectBox = {
        st = nil,
        ed = nil,
        box = sm.effect.createEffect("ShapeRenderable",self.interactable),
        cP = nil,
        sP = nil
    }
    self.freeSelectBox.box:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"))
    self.freeSelectBox.box:setParameter("color",sm.color.new("fcfcfc"))

    self.temporarySelectFlag = false
    self.moverArrow = sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.moverArrow:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f")) -- 玻璃UUID
    self.moverArrow:setParameter("color",sm.color.new("000000"))
    self.moverArrowText = sm.gui.createNameTagGui()

    self.moverAxisArrow = {
        x = sm.effect.createEffect("ShapeRenderable",self.interactable),
        y = sm.effect.createEffect("ShapeRenderable",self.interactable),
        z = sm.effect.createEffect("ShapeRenderable",self.interactable)
    }
    self.moverAxisArrow.x:setParameter("uuid",sm.uuid.new("51da94d6-a215-4f69-b569-c45bc1557d12")) -- Arrow UUID
    self.moverAxisArrow.x:setParameter("color",sm.color.new("FF0000"))
    self.moverAxisArrow.x:setOffsetRotation(sm.vec3.getRotation(sm.vec3.new(0,-1,0),MACP.axis.x*-1))
    self.moverAxisArrow.x:setScale(sm.vec3.new(0.25,10,0.25))
    self.moverAxisArrow.y:setParameter("uuid",sm.uuid.new("51da94d6-a215-4f69-b569-c45bc1557d12")) -- Arrow UUID
    self.moverAxisArrow.y:setParameter("color",sm.color.new("00FF00"))
    self.moverAxisArrow.y:setOffsetRotation(sm.vec3.getRotation(sm.vec3.new(0,-1,0),MACP.axis.y*-1))
    self.moverAxisArrow.y:setScale(sm.vec3.new(0.25,10,0.25))
    self.moverAxisArrow.z:setParameter("uuid",sm.uuid.new("51da94d6-a215-4f69-b569-c45bc1557d12")) -- Arrow UUID
    self.moverAxisArrow.z:setParameter("color",sm.color.new("0000FF"))
    self.moverAxisArrow.z:setOffsetRotation(sm.vec3.getRotation(sm.vec3.new(0,-1,0),MACP.axis.z*-1))
    self.moverAxisArrow.z:setScale(sm.vec3.new(0.25,10,0.25))

    self.convertGUI = sm.gui.createWorldIconGui(500,200,"$MOD_DATA/Gui/Layouts/HUD_WorldIcon.layout")
    self.chosenPart = sm.effect.createEffect("ShapeRenderable")
    self.chosenPart:setScale(sm.vec3.new(0.3,0.3,0.3))
    self.chosenPart:setParameter("visualization", true)
    self.convertList = {}

    self.controlPadStartIdx = 1
end

function MAC.client_getSavedData(self,fullData)
    local partUUIDList = fullData.partUUIDList
    self.effectTableData = fullData.effectTableData
    self:adaptData(self.effectTableData,partUUIDList)
    self:translateData(self.effectTableData)
    self.tableCnt = #self.effectTableData + 1
    self.nearestEffectID = nil
    self.selectedMAGData = {}
end

function MAC.adaptData(self,inputData,partUUIDList)
    for k,v in pairs(partUUIDList)do
        CE:addPartUUID(sm.uuid.new(v))
    end
    for k,v in pairs(inputData)do
        if v.id < 0 then -- part!
            v.id = CE.partUUIDtoID[partUUIDList["t"..v.id]]
        end
    end
end

function MAC.readMAC(self,type,name)
    local fullData = CE:fileOpen(type,name)
    local partUUIDList = fullData.partUUIDList
    local effectTableData = fullData.effectTableData
    if effectTableData == nil then -- 旧版本
        partUUIDList = {}
        effectTableData = fullData
    end
    if partUUIDList == nil then partUUIDList = {} end -- 应对json中{}被存为null
    self:adaptData(effectTableData,partUUIDList)
    return effectTableData
end

function MAC.translateData(self,inputData)
    for k,v in pairs(self.effectTable)do
        v:destroy()
        self.effectTable[k]=nil
    end
    for idx,data in pairs(inputData)do -- 读取初始化
        if data.state == nil then data.state = "origin" end -- 旧版本没有贴花状态
        self.effectTable[idx] = sm.effect.createEffect("ShapeRenderable",self.interactable)
        self.effectTable[idx]:setParameter("uuid",CE.effectUUIDList[data.id][data.state])
        self.effectTable[idx]:setOffsetPosition(sm.vec3.new(data.offsetPosition.x,data.offsetPosition.y,data.offsetPosition.z))
        self.effectTable[idx]:setOffsetRotation(sm.quat.new(data.offsetRotation.x,data.offsetRotation.y,data.offsetRotation.z,data.offsetRotation.w))
        self.effectTable[idx]:setParameter("color",sm.color.new(data.color))
        self.effectTable[idx]:setScale(sm.vec3.new(data.scale.x,data.scale.y,data.scale.z)*0.255)
        self.effectTable[idx]:start()
    end
end

function MAC.changeCurrentEffect(self,changeColorFlag)
    self.currentEffect:destroy()
    self:findEfctPlyr()
    --MACP.currentScale.mirror = 1
    if CE.effectPlayer[MACP.currentEfctPlyr] ~= "Saved保存的图" then
        self.currentEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
        self.currentEffect:setScale(sm.vec3.new(MACP.scaleTable[MACP.currentScale.x]*MACP.currentScale.mirror,MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])*0.255)
        self.currentEffect:setParameter("uuid",CE.effectUUIDList[MACP.currentEffectId][MACP.curAplqState])
    else
        self.currentEffect = sm.effect.createEffect("ShapeRenderable",self.interactable)
        self.currentEffect:setScale(sm.vec3.new(0.1,0.5,0.1)*0.255)
        self.currentEffect:setParameter("uuid",CE.effectUUIDList[1]["origin"])
        if MACP.selectedMAC == "Null" then
            self:cl_cleanCurrentMAC(true)
        else
            if MACP.selectedMACEfct == nil then
                local MacType = CE:MACexists(MACP.selectedMAC)
                if MacType == 0 then MacType = CurrentModType end -- 粘贴板 --> 本地 -- 我不知道，但是现在就是这附近有bug，我不敢删(2025/11/14)
                MACP.selectedMACData = self:readMAC(MacType,MACP.selectedMAC)
                MACP.selectedMACEfct = {}
                for k,v in pairs(MACP.selectedMACData)do -- 读取初始化
                    if v.state == nil then v.state = "origin" end
                    MACP.selectedMACEfct[k] = sm.effect.createEffect("ShapeRenderable",self.interactable)
                    MACP.selectedMACEfct[k]:setParameter("uuid",CE.effectUUIDList[v.id][v.state])
                end
            elseif changeColorFlag then
                for k,v in pairs(MACP.selectedMACData)do
                    v.color = MACP.colorList[MACP.chosenColorType][MACP.chosenColorIdx]
                end
            end
        end
    end
    self.currentEffect:setOffsetPosition(self.shape.up*0.3)
    --self.currentEffect:start()
end

function MAC.findEfctPlyr(self)
    local oup
    for k,v in pairs(CE.efctPlyrCnt)do
        if MACP.currentEffectId >=v and MACP.currentEffectId <CE.efctPlyrCnt[k+1] then
            oup = k
        end
    end
    MACP.currentEfctPlyr = oup
    MACP.currentEfctPlus = MACP.currentEffectId - CE.efctPlyrCnt[MACP.currentEfctPlyr]
end

function MAC.client_onFixedUpdate(self,dt)
    if self.shape.body:isOnLift() then
        for idx,efct in pairs(self.effectTable)do
            if not efct:isPlaying() and not self.effectTableData[idx].cleanFlag then
                efct:start()
            end
        end
    end
    if self.interactable:isActive()then
        if self.lastState == false then --第一次启动获取最近玩家并绑定
            localPlayer:reset()
            self.lastState = true
            local allPlayers = sm.player.getAllPlayers()
            self.currentPlayer = NearestPlayer(self.shape.worldPosition,allPlayers)
            --self.currentCharacter = self.currentPlayer.character
            
            if MACP.selectedMAC ~= "Null" and MACP.selectedMACData ~= nil then
                for k,v in pairs(MACP.selectedMACData)do
                    MACP.selectedMACEfct[k]:start()
                end
            end
            if self.localPlayer == self.currentPlayer then
                self.currentEffect:start()
                self:changeCurrentEffect(false)
                self.convertList = {}
            end
        end
        if self.localPlayer == self.currentPlayer then 
            --开始客户端的贴花编辑！
            local Left_condition = localPlayer.state.left   --self.currentCharacter:isAiming()
            local Right_condition = localPlayer.state.right  --self.currentCharacter:isCrouching()
            local R_condition = localPlayer.state.r
            local Q_condition = localPlayer.state.q
            local toolMode = localPlayer.tool

            localPlayer.state.deviceOn = true -- 避免启动两个关一个另一个被刷掉

            local get,result = sm.localPlayer.getRaycast(10)
            if not get then
                local FromP = sm.camera.getPosition()
                local DirV = sm.camera.getDirection()
                result = {
                    pointWorld = FromP + DirV*10,
                    normalWorld = DirV*(-1),
                    getBody = function()
                        return nil
                    end,
                    getShape = function()
                        return nil
                    end
                }
            end
            local offP,offR,hitNormal,fixRotation,sameBody,offB = self:cl_calculateRaycast(result)
            localPlayer.state.sameBody = sameBody
            ----删除的箭头
            if (toolMode == "MAGgun" and Right_condition) or (toolMode == "MAGpainter" and Right_condition) or toolMode == "MAGselector" then
                self:cl_generateSelectFlag(offP,fixRotation,hitNormal)
            else
                self:cl_clearSelectFlag()
            end
            ----工具切换
            if MACP.lastTool ~= toolMode then
                self.currentEffect:setScale(sm.vec3.new(1,1,1)*0.01)
                if toolMode == "MAGmover" then
                    self:cl_setMoverArrow()
                    self:cl_refreshSelectAxisRota()
                else
                    self:cl_clearArrow()
                end
                if toolMode == "MAGconvertor" then
                    self:cl_activateConvertGUI()
                else
                    self:cl_clearConvertGUI()
                end
                if MACP.selectedMAC~="Null" then
                    self:setMACpreview(toolMode == "MAGgun" or toolMode == "MAGpainter" or toolMode == "MAGeditor")
                end
                --因为设置currentEffect时会重置大小，没有使用该函数的工具便会保持隐藏贴画预览的状态
            end
            ----左键
            if not Left_condition then
                if not self.leftReady then
                    -- 第一次松开
                    if toolMode == "MAGmirror" then
                        self:cl_endSetMirror(offB)
                    elseif toolMode == "MAGmover" then
                        self:cl_endSetMover(offP)
                        self:cl_refreshSelectAxisRota()
                    elseif toolMode == "MAGgun" or toolMode == "MAGpainter" or toolMode == "MAGeditor" then
                        self:cl_clearRotaEfct()
                    end
                end
                self.leftReady = true
                --松开时
                if toolMode == "MAGgun" or toolMode == "MAGpainter" or toolMode == "MAGeditor" then
                    self:cl_setPreview(offP,offR,fixRotation,hitNormal)
                elseif toolMode == "MAGconvertor" then
                    self:cl_locateConvertGUI(offP,result)
                end
                
            elseif self.leftReady then
                self.leftReady = false
                --第一次按下
                if toolMode == "MAGgun" then
                    if not Right_condition then--put
                        self:cl_placeApplique(offP,offR,fixRotation,hitNormal)
                        self:cl_setFirstPlacePR(offP,offR)
                    else -- holding右键
                        if #self.effectTableData > 0 and self.nearestEffectID ~= nil then --erase
                            self:cl_eraseApplique(self.nearestEffectID)
                        end
                    end
                elseif toolMode == "MAGeditor" then
                    if not Right_condition then--put
                        self:cl_placeApplique(offP,offR,fixRotation,hitNormal)
                    end
                elseif toolMode == "MAGpainter" then
                    if not Right_condition then--put
                        self:cl_readColor(result)
                    else -- holding右键
                        if #self.effectTableData > 0 and self.nearestEffectID ~= nil then --paint
                            self:cl_paintApplique(self.nearestEffectID)
                        end
                    end
                elseif toolMode == "MAGselector" then
                    self:cl_addSelect(offP,0,true)
                elseif toolMode == "MAGmirror" then
                    self:cl_startSetMirror(offB)
                elseif toolMode == "MAGmover" then
                    self:cl_startSetMover(offP,offR)
                elseif toolMode == "MAGconvertor" then
                    self:cl_checkConvertPart(result)
                elseif toolMode == "MAGstep" then
                    self:cl_onOpenControlPad()
                end
            else
                --按下时
                if toolMode == "MAGgun" then
                    if not Right_condition then -- put
                        self:cl_rotateApplique(offP,offR,fixRotation,hitNormal)
                    end
                elseif toolMode == "MAGmirror" then
                    self:cl_drawMirror(offB)
                elseif toolMode == "MAGmover" then
                    self:cl_setMover(offP)
                end
            end
            ----右键
            if not Right_condition then
                if not self.rightReady then
                    -- 第一次松开
                    if toolMode == "MAGselector" then
                        self:cl_getFreeSelect()
                    end
                end
                --松开时
                self.rightReady = true
            elseif self.rightReady then
                self.rightReady = false
                --第一次按下
                if toolMode == "MAGeditor" then -- 复制所选贴花
                    self:cl_copySelected()
                elseif toolMode == "MAGselector" then -- 自由框选
                    self:cl_setFreeSelectBoxStart(offP,fixRotation,hitNormal)
                elseif toolMode == "MAGmirror" and self.mirrorFlag then -- 镜像翻转所选贴花
                    self:cl_mirrorApplique()
                elseif toolMode == "MAGmover" then
                    if self.leftReady then
                        self:cl_nextMoverMode()
                        self:cl_refreshSelectAxisRota()
                    end
                elseif toolMode == "MAGconvertor" then
                    self:cl_checkDeleteConverted()
                end
            else
                --按下时
                if toolMode == "MAGselector" then
                    self:cl_setFreeSelectBox(offP,fixRotation,hitNormal)
                end
            end
            --R
            if R_condition then
                if toolMode == "MAGgun" then -- 切换 特效种类
                    self:cl_createMAG_select_GUI()
                elseif toolMode == "MAGeditor" then
                    self:client_onFileOperate()
                elseif toolMode == "MAGmirror" and self.mirrorFlag then
                    self:cl_mirrorPasteAplq()
                elseif toolMode == "MAGselector" then
                    self:cl_nextSelectMode()
                elseif toolMode == "MAGmover" then
                    self:cl_refreshSelectAxisRota()
                    self:cl_activateOffsetAxis()
                elseif toolMode == "MAGstep" then
                    MACP:redoAction(self)
                end
            end
            --Q
            if Q_condition then
                if toolMode == "MAGselector" then-- 清空选择
                    self:cl_clearSelect()
                elseif toolMode == "MAGpainter" then-- 颜色编辑
                    self:cl_createColorEditGui()
                elseif toolMode == "MAGmirror" then
                    self:cl_clearMirror()
                elseif toolMode == "MAGmover" then
                    self:cl_refreshSelectAxisRota()
                    self:cl_nextMoverType()
                elseif toolMode == "MAGstep" then
                    MACP:undoAction(self)
                else--设置 旋转和大小
                    self:cl_createMAG_rota_scale_color_GUI()
                end
            end
            --clear localPlayer state
            MACP.lastTool = toolMode
            localPlayer:reset()
        end
    else
        if self.lastState == true then
            if self.localPlayer == self.currentPlayer then 
                localPlayer.state.deviceOn = false
                TEST_POINT:clear()
                self.mirrorFlag = false
                self.mirrorEffect:stop()
                self.mirrorPointEffect:stop()
                self.currentEffect:stop()
                self.selectedBox:stop()
                self.selectedBoxText:close()
                self:cl_clearMoveEfct()
                self:cl_cleanCurrentMAC(true)
                self:cl_clearArrow()
                self.chosenPart:stop()
                self.convertGUI:close()
                MACP:clear_action_table()
                MACP.selectOffsetData = {}
                MACP.selectAxisRota = nil
                MACP.selectAxisRotaIdx = 0
                --send back data
                sm.gui.displayAlertText(MLines.lines["MAC"][MLines.currentLanguage][1],2)
                self.network:sendToServer("server_saveData",CE:formatData(self.effectTableData))
            end
        end
        self.lastState = false
    end
end

function MAC.client_onInteract(self,player,state)
    if not state then return end
    if not self.lastState then return end
    if self.localPlayer == self.currentPlayer then
        TEST_POINT:clear()
        self.mirrorFlag = false
        self.mirrorEffect:stop()
        self.mirrorPointEffect:stop()
        self.currentEffect:stop()
        self.selectedBox:stop()
        self.selectedBoxText:close()
        self:cl_clearMoveEfct()
        self:cl_cleanCurrentMAC(true)
        self:cl_clearArrow()
        self.chosenPart:stop()
        self.convertGUI:close()
        MACP:clear_action_table()
        MACP.selectOffsetData = {}
        MACP.selectAxisRota = nil
        MACP.selectAxisRotaIdx = 0
        --send back data
        sm.gui.displayAlertText(MLines.lines["MAC"][MLines.currentLanguage][1],2)
        local cleanData = {}
        for k,v in pairs(self.effectTableData)do
            if self:cl_CP_checkFormattedEditStr(v) == 0 then
                cleanData[#cleanData+1] = v -- 删掉错误数据（可能是导致错误或者错误时被编辑到一半的数据）
            end
        end
        self.network:sendToServer("server_saveData",CE:formatData(cleanData))
        print("<!> Saving data...")
    end
end

--[[ MAG function ]]------------------------------------

function MAC.setMACpreview(self,flag)
    if MACP.selectedMACData == nil then return end
    for k,v in pairs(MACP.selectedMACData)do
        if flag then
            if not MACP.selectedMACEfct[k]:isPlaying() then MACP.selectedMACEfct[k]:start() end
        else
            MACP.selectedMACEfct[k]:stop()
        end
    end
end

function MAC.cl_checkDeleteConverted(self)
    self.warningGUI = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/warning.layout",true)
    self.warningGUI:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][7])
    self.warningGUI:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage]["warning_delete_converted"])
    self.warningGUI:setButtonCallback("No","cl_deleteCdP_wnNo")
    self.warningGUI:setButtonCallback("Yes","cl_deleteCdP_wnYes")
    self.warningGUI:open()
end

function MAC.cl_deleteCdP_wnNo(self)
    self.warningGUI:close()
end

function MAC.cl_deleteCdP_wnYes(self)
    local CPids = {}
    for k,v in pairs(self.convertList) do
        if type(k) == "number" then
            CPids[#CPids+1] = v
        end
    end
    self.network:sendToServer("sv_deleteConvertedPart",CPids)
    self.warningGUI:close()
end

function MAC.cl_activateConvertGUI(self)
    self.convertGUI:open()
end

function MAC.cl_locateConvertGUI(self,offP,result)
    local worldPosition = self.shape.worldPosition + self.shape.worldRotation*offP
    self.convertGUI:setWorldPosition(worldPosition)
    local hitShape = result:getShape()
    if hitShape == nil then
        self.convertGUI:setIconImage("IconBox",sm.uuid.getNil())
        self.chosenPart:stop()
        return
    end
    self.chosenPart:stop()
    self.chosenPart:start()
    local hitUUID = hitShape.uuid
    local RVHitColor = sm.color.new(1,1,1)-hitShape.color
    self.convertGUI:setIconImage("IconBox",hitUUID)
    self.chosenPart:setParameter("uuid",hitUUID)
    self.chosenPart:setParameter("color",RVHitColor)
    self.chosenPart:setPosition(hitShape.worldPosition)
    self.chosenPart:setRotation(hitShape.worldRotation)
    if hitShape.isBlock then
        local blockScale = hitShape:getBoundingBox()
        self.chosenPart:setScale(blockScale*1)
    else
        self.chosenPart:setScale(sm.vec3.new(1,1,1)*0.25)
    end
end

function MAC.cl_clearConvertGUI(self)
    self.chosenPart:stop()
    self.convertGUI:close()
end

function MAC.cl_checkConvertPart(self,result)
    local hitShape = result:getShape()
    if hitShape == nil then return end
    if not self:cl_checkOverSized(1) then return end
    if self.convertList[hitShape.id] ~= nil and self.convertList["c"..tostring(hitShape.id)]==nil then
        self:cl_askReconvert(hitShape)
        return
    else
        self:cl_convertPart(hitShape)
    end
end


function MAC.cl_askReconvert(self,hitShape)
    self.reconvertShape = hitShape
    self.warningGUI = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/warning.layout",true)
    self.warningGUI:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][7])
    self.warningGUI:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage]["recovert_warning_content"])
    self.warningGUI:setButtonCallback("No","cl_reconvert_wnNo")
    self.warningGUI:setButtonCallback("Yes","cl_reconvert_wnYes")
    self.warningGUI:open()
end

function MAC.cl_reconvert_wnNo(self)
    self.warningGUI:close()
    self.reconvertShape = nil
end

function MAC.cl_reconvert_wnYes(self)
    self:cl_convertPart(self.reconvertShape)
    self.warningGUI:close()
    self.convertList["c"..tostring(self.reconvertShape.id)] = true
    self.reconvertShape = nil
end

function MAC.cl_convertPart(self,hitShape)
    if not sm.exists(hitShape) then return end
    local hitUUID = hitShape.uuid
    local hitColor = hitShape.color
    local hitPosition = hitShape.worldPosition
    local hitRotation = hitShape.worldRotation
    local inverseRota = sm.quat.inverse(self.shape.worldRotation)
    local offP = inverseRota*(hitPosition-self.shape.worldPosition)
    local offR = inverseRota*hitRotation
    local offScale = sm.vec3.new(0.25,0.25,0.25)
    if hitShape.isBlock then
        local blockScale = hitShape:getBoundingBox()
        offScale = blockScale
    end
    CE:addPartUUID(hitUUID)
    self:cl_addEffect(CE.partUUIDtoID[tostring(hitUUID)],offP,offR,hitColor,offScale/0.255,false,"origin")
    sm.particle.createParticle("paint_smoke", hitPosition, hitRotation, hitColor)
    self.convertList[hitShape.id] = hitShape
end

function MAC.cl_checkAxisSimilarity(self,slData)
    return type(MACP.selectAxisRota) ~= "nil"
end

function MAC.cl_activateOffsetAxis(self)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if self:cl_checkAxisSimilarity(slData) then
        MACP.offsetAxisFlag = not MACP.offsetAxisFlag
        self:cl_setOffsetRotation(slData)
    else
        MACP.offsetAxisFlag = false
    end
    self:cl_setMoverArrow()
end

function MAC.cl_setOffsetRotation(self,slData)
    if not self:cl_checkAxisSimilarity(slData) then
        MACP.offsetAxisRotation = sm.quat.new(1,0,0,0)
    else
        self:cl_refreshSelectAxisRota()
        MACP.offsetAxisRotation = MACP.selectAxisRota
    end
    MACP.offsetAxisRotationReverse = sm.quat.inverse(MACP.offsetAxisRotation)
end

function MAC.cl_nextMoverMode(self)
    MACP.moverMode = (MACP.moverMode+1)%3
    if MACP.moverMode == 2 then
        local slData,slEfct = self:cl_getSelectedAplqData()
        self:cl_setOffsetRotation(slData)
    end
    self:cl_setMoverArrow()
end

function MAC.cl_startSetMover(self,offP,offR)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if not self:cl_checkAxisSimilarity(slData) then
        MACP.offsetAxisFlag = false
    end
    if #slData == 0 then
        local addedFlag = self:cl_addSelect(offP,0,true)
        if not addedFlag then return end
        self.temporarySelectFlag = true
    end
    slData,slEfct = self:cl_getSelectedAplqData()
    local centerP,scaleP = SS:getSelectedBox(slData,false)

    if MACP.moverMode == 0 then self:cl_startSetMove(offP,centerP)
    elseif MACP.moverMode == 1 then self:cl_startSetRotate(offP,offR,centerP)
    else
        self:cl_setOffsetRotation(slData)
        self:cl_startSetMove(offP,centerP)
    end -- scale和move共用一个初始化
    self:cl_setMoverArrow()
end

function MAC.cl_setMover(self,offP)
    if MACP.moverMode == 0 then self:cl_setMove(offP)
    elseif MACP.moverMode == 1 then self:cl_setRotate(offP)
    else self:cl_setMove(offP) end -- scale与move共用
end

function MAC.cl_endSetMover(self,offP)
    TEST_POINT:stop_test_point(4)
    TEST_POINT:stop_test_point(5)
    if MACP.moverMode == 0 then self:cl_endSetMove(offP)
    elseif MACP.moverMode == 1 then self:cl_endSetRotate(offP)
    else self:cl_endSetMove(offP) end -- scale与move共用
end

function MAC.cl_getSelectedAplqData(self)
    local slData = {}
    local slEfct = {}
    for k,v in pairs(self.selectedMAGData)do
        slData[#slData+1] = self.effectTableData[k]
        slEfct[#slEfct+1] = self.effectTable[k]
    end
    return slData,slEfct
end

function MAC.cl_clearArrow(self)
    self.moverAxisArrow.x:stop()
    self.moverAxisArrow.y:stop()
    self.moverAxisArrow.z:stop()
end

function MAC.cl_nextMoverType(self)
    MACP.moverType = (MACP.moverType + 1) % 7
    self:cl_setMoverArrow()
end

function MAC.cl_refreshSelectAxisRota(self)
    if type(MACP.selectAxisRota)=="nil" then return end
    local nIdx = MACP.selectAxisRotaIdx
    MACP.selectAxisRota = sm.quat.new(self.effectTableData[nIdx].offsetRotation.x,self.effectTableData[nIdx].offsetRotation.y,self.effectTableData[nIdx].offsetRotation.z,self.effectTableData[nIdx].offsetRotation.w)
end

function MAC.cl_setMoverArrow(self)
    self:cl_clearArrow()
    if MACP.moverType == 0 then return end
    local slData,slEfct = self:cl_getSelectedAplqData()
    if MACP.moverTypeAxisActive[MACP.moverType+1]["x"] and not self.moverAxisArrow.x:isPlaying() then self.moverAxisArrow.x:start() end
    if MACP.moverTypeAxisActive[MACP.moverType+1]["y"] and not self.moverAxisArrow.y:isPlaying() then self.moverAxisArrow.y:start() end
    if MACP.moverTypeAxisActive[MACP.moverType+1]["z"] and not self.moverAxisArrow.z:isPlaying() then self.moverAxisArrow.z:start() end
    if #slData == 0 then
        self:cl_locateMoverAxis(sm.vec3.new(0,0,0))
        self.moverAxisArrow.x:setScale(sm.vec3.new(0.25,1,0.25))
        self.moverAxisArrow.y:setScale(sm.vec3.new(0.25,1,0.25))
        self.moverAxisArrow.z:setScale(sm.vec3.new(0.25,1,0.25))
        return
    end
    if not self:cl_checkAxisSimilarity(slData) then
        MACP.offsetAxisFlag = false
    end
    local centerP,scaleP = SS:getSelectedBox(slData,false)
    self:cl_locateMoverAxis(centerP)
    self.moverAxisArrow.x:setScale(sm.vec3.new(0.25,scaleP.x*5,0.25))
    self.moverAxisArrow.y:setScale(sm.vec3.new(0.25,scaleP.y*5,0.25))
    self.moverAxisArrow.z:setScale(sm.vec3.new(0.25,scaleP.z*5,0.25))
    local rtAxisX = sm.vec3.getRotation(sm.vec3.new(0,-1,0),MACP.axis.x*-1)
    local rtAxisY = sm.vec3.getRotation(sm.vec3.new(0,-1,0),MACP.axis.y*-1)
    local rtAxisZ = sm.vec3.getRotation(sm.vec3.new(0,-1,0),MACP.axis.z*-1)
    if MACP.offsetAxisFlag or (MACP.moverMode==2 and self:cl_checkAxisSimilarity(slData)) then
        self.moverAxisArrow.x:setScale(sm.vec3.new(0.25,1,0.25))
        self.moverAxisArrow.y:setScale(sm.vec3.new(0.25,1,0.25))
        self.moverAxisArrow.z:setScale(sm.vec3.new(0.25,1,0.25))
        self.moverAxisArrow.x:setOffsetRotation(MACP.offsetAxisRotation*rtAxisX)
        self.moverAxisArrow.y:setOffsetRotation(MACP.offsetAxisRotation*rtAxisY)
        self.moverAxisArrow.z:setOffsetRotation(MACP.offsetAxisRotation*rtAxisZ)
    else
        self.moverAxisArrow.x:setOffsetRotation(rtAxisX)
        self.moverAxisArrow.y:setOffsetRotation(rtAxisY)
        self.moverAxisArrow.z:setOffsetRotation(rtAxisZ)
    end
end

function MAC.cl_locateMoverAxis(self,offP)
    if MACP.moverType == 0 then return end
    self.moverAxisArrow.x:setOffsetPosition(offP)
    self.moverAxisArrow.y:setOffsetPosition(offP)
    self.moverAxisArrow.z:setOffsetPosition(offP)
end

function MAC.cl_startSetMove(self,offP,centerP)
    self.moverArrow:start()
    self.moverArrowText:open()
    if MACP.moverType == 0 then
        MACP.moverStartPoint = offP
    else
        TEST_POINT:show_test_point(4)
        TEST_POINT:show_test_point(5)
        local fixRotation = sm.quat.inverse(self.shape.worldRotation)
        local PlayerDir = fixRotation*sm.camera.getDirection()
        local PlayerPos = fixRotation*(sm.camera.getPosition()-self.shape.worldPosition)
        local t = (centerP - PlayerPos):length()
        MACP.moverStartPoint = PlayerPos + PlayerDir*t
        MACP.moverMultiT = t
    end
end

function MAC.cl_setMove(self,offP)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData == 0 then return end
    if MACP.moverType == 0 then
        self:cl_setMoveType0(offP,slData,slEfct)
        return
    end
    -- 启用锁定轴
    self:cl_setMoveType0(self:cl_getMovementTypeXYZ(slData),slData,slEfct)
end

function MAC.cl_getMovementTypeXYZ(self,slData)
    local fixRotation = sm.quat.inverse(self.shape.worldRotation)
    local PlayerDir = fixRotation*sm.camera.getDirection()
    local PlayerPos = fixRotation*(sm.camera.getPosition()-self.shape.worldPosition)
    local t = MACP.moverMultiT
    local StartPoint = MACP.moverStartPoint
    local sumMovement = sm.vec3.new(0,0,0)
    for k,v in pairs(MACP.moverTypeTable[MACP.moverType+1])do
        local Axis = MACP.axis[v]
        if MACP.offsetAxisFlag or (MACP.moverMode==2 and self:cl_checkAxisSimilarity(slData)) then
            Axis = MACP.offsetAxisRotation*Axis
        end
        local newMovement = PlayerPos + PlayerDir*t - StartPoint
        local actualMovement = Axis*(newMovement:dot(Axis))
        sumMovement = sumMovement+actualMovement
    end
    local endPoint = (StartPoint + sumMovement)
    TEST_POINT:set_test_point(5,self.shape.worldPosition + self.shape.worldRotation*StartPoint)
    TEST_POINT:set_test_point(4,self.shape.worldPosition + self.shape.worldRotation*endPoint)
    return endPoint
end

function MAC.cl_setMoveType0(self,offP,slData,slEfct) -- scale与move共用
    local movement = offP - MACP.moverStartPoint
    local centerP = (offP + MACP.moverStartPoint)/2
    local movementL = movement:length()
    local arrowRotation
    if movementL <= 0.001 then 
        arrowRotation = sm.quat.new(1,0,0,0)
    else
        arrowRotation = sm.vec3.getRotation(sm.vec3.new(0,1,0),movement)
    end
    self.moverArrow:setOffsetPosition(centerP)
    self.moverArrow:setOffsetRotation(arrowRotation)
    self.moverArrow:setScale(sm.vec3.new(0.02,movementL,0.02))

    self.moverArrowText:setWorldPosition(self.shape.worldPosition+self.shape.worldRotation*offP)
    self.moverArrowText:setText("Text",tostring(math.floor(movementL*400)/100))

    if MACP.moverMode == 0 then
        for k,v in pairs(slData)do
            local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            vP = vP + movement
            slEfct[k]:setOffsetPosition(vP)
        end
    elseif MACP.moverMode == 2 then
        if self:cl_checkAxisSimilarity(slData) and MACP.moverType ~= 0 then
            local newScale = sm.vec3.new(0,0,0)
            local SelectedCenterP,SScaleP = SS:getSelectedBox(slData,false)
            for k,v in pairs(MACP.moverTypeTable[MACP.moverType+1])do
                local Axis = MACP.offsetAxisRotation*MACP.axis[v]
                local projectV = Axis*Axis:dot(movement)
                projectV = MACP.offsetAxisRotationReverse*projectV
                newScale = newScale + projectV*4
            end
            for k,v in pairs(self.selectedMAGData)do
                local vData = self.effectTableData[k]
                local vScale = sm.vec3.new(vData.scale.x,vData.scale.y,vData.scale.z)
                local adjustVecTable = {x = MACP.selectOffsetData[k].x, y = MACP.selectOffsetData[k].y, z = MACP.selectOffsetData[k].z}
                local adjustVec = sm.vec3.new(1+self:getVecDataFromStr(newScale,adjustVecTable.x),
                                              1+self:getVecDataFromStr(newScale,adjustVecTable.y),
                                              1+self:getVecDataFromStr(newScale,adjustVecTable.z))
                vScale = vScale * adjustVec
                self.effectTable[k]:setScale(vScale*0.255)
                local vP = sm.vec3.new(vData.offsetPosition.x,vData.offsetPosition.y,vData.offsetPosition.z)
                local oP = vP - SelectedCenterP
                local NRota = sm.quat.new(vData.offsetRotation.x,vData.offsetRotation.y,vData.offsetRotation.z,vData.offsetRotation.w)
                local Nx,Ny,Nz = NRota*sm.vec3.new(1,0,0),NRota*sm.vec3.new(0,1,0),NRota*sm.vec3.new(0,0,1)
                local ONX,ONY,ONZ = oP:dot(Nx),oP:dot(Ny),oP:dot(Nz)
                ONX = ONX*adjustVec.x
                ONY = ONY*adjustVec.y
                ONZ = ONZ*adjustVec.z
                local newOffsetP = SelectedCenterP + Nx*ONX + Ny*ONY + Nz*ONZ
                self.effectTable[k]:setOffsetPosition(newOffsetP)
            end
        else
            local SelectedCenterP,SScaleP = SS:getSelectedBox(slData,false)
            for k,v in pairs(slData)do
                local newScale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
                local originP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
                local delta = originP - SelectedCenterP
                delta = delta*(movementL*4)
                newScale = newScale*(movementL*4)
                slEfct[k]:setOffsetPosition(SelectedCenterP+delta)
                slEfct[k]:setScale(newScale*0.255)
            end
        end
    end
    

    self:cl_locateMoverAxis(offP)
end

function MAC.getVecDataFromStr(self,vec,str)
    if type(vec)~="Vec3" or type(str)~="string" then return nil end
    if str == "x" then
        return vec.x
    elseif str == "y" then
        return vec.y
    elseif str == "z" then
        return vec.z
    end
    return nil
end

function MAC.cl_endSetMove(self,offP)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData == 0 then return end
    if MACP.moverType == 0 then
        self:cl_endSetMoveType0(offP,slData,slEfct)
    else
        -- 启用锁定轴
        self:cl_endSetMoveType0(self:cl_getMovementTypeXYZ(slData),slData,slEfct)
    end
    if self.temporarySelectFlag then
        self:cl_clearSelect()
        self.temporarySelectFlag = false
    end
end

function MAC.cl_endSetMoveType0(self,offP,slData,slEfct)
    self.moverArrow:stop()
    self.moverArrowText:close()

    local movement = offP - MACP.moverStartPoint
    local movementL = movement:length()
    if MACP.moverMode == 0 then
        for k,v in pairs(slData)do
            local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            vP = vP + movement
            v.offsetPosition = {x=vP.x,y=vP.y,z=vP.z}
            slEfct[k]:setOffsetPosition(vP)
        end
        for k,v in pairs(self.selectedMAGData)do
            MACP:addAction(k,5,{x=movement.x,y=movement.y,z=movement.z})
        end
    elseif MACP.moverMode == 2 then
        if self:cl_checkAxisSimilarity(slData) and MACP.moverType ~= 0 then
            local newScale = sm.vec3.new(0,0,0)
            local SelectedCenterP,SScaleP = SS:getSelectedBox(slData,false)
            for k,v in pairs(MACP.moverTypeTable[MACP.moverType+1])do
                local Axis = MACP.offsetAxisRotation*MACP.axis[v]
                local projectV = Axis*Axis:dot(movement)
                projectV = MACP.offsetAxisRotationReverse*projectV
                newScale = newScale + projectV*4
            end
            for k,v in pairs(self.selectedMAGData)do
                local vData = self.effectTableData[k]
                local vScale = sm.vec3.new(vData.scale.x,vData.scale.y,vData.scale.z)
                local adjustVecTable = {x = MACP.selectOffsetData[k].x, y = MACP.selectOffsetData[k].y, z = MACP.selectOffsetData[k].z}
                local adjustVec = sm.vec3.new(1+self:getVecDataFromStr(newScale,adjustVecTable.x),
                                              1+self:getVecDataFromStr(newScale,adjustVecTable.y),
                                              1+self:getVecDataFromStr(newScale,adjustVecTable.z))
                vScale = vScale * adjustVec
                self.effectTable[k]:setScale(vScale*0.255)
                self.effectTableData[k].scale = {x=vScale.x,y=vScale.y,z=vScale.z}
                local vP = sm.vec3.new(vData.offsetPosition.x,vData.offsetPosition.y,vData.offsetPosition.z)
                local oP = vP - SelectedCenterP
                local NRota = sm.quat.new(vData.offsetRotation.x,vData.offsetRotation.y,vData.offsetRotation.z,vData.offsetRotation.w)
                local Nx,Ny,Nz = NRota*sm.vec3.new(1,0,0),NRota*sm.vec3.new(0,1,0),NRota*sm.vec3.new(0,0,1)
                local ONX,ONY,ONZ = oP:dot(Nx),oP:dot(Ny),oP:dot(Nz)
                ONX = ONX*adjustVec.x
                ONY = ONY*adjustVec.y
                ONZ = ONZ*adjustVec.z
                local newOffsetP = SelectedCenterP + Nx*ONX + Ny*ONY + Nz*ONZ
                self.effectTable[k]:setOffsetPosition(newOffsetP)
                self.effectTableData[k].offsetPosition = {x=newOffsetP.x,y=newOffsetP.y,z=newOffsetP.z}
            end
            for k,v in pairs(self.selectedMAGData)do
                MACP:addAction(k,7,{type="axis",x=newScale.x,y=newScale.y,z=newScale.z,o={x=MACP.selectAxisRota.x,y=MACP.selectAxisRota.y,z=MACP.selectAxisRota.z,w=MACP.selectAxisRota.w}})
            end
        else
            local SelectedCenterP,SScaleP = SS:getSelectedBox(slData,false)
            for k,v in pairs(self.selectedMAGData)do
                local delta = movementL
                MACP:addAction(k,7,{type="all",T=delta})
            end
            for k,v in pairs(slData)do
                local newScale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
                local originP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
                local delta = originP - SelectedCenterP
                newScale = newScale*(movementL*4)
                delta = delta*(movementL*4)
                local newOffsetP = SelectedCenterP + delta
                v.scale = {x=newScale.x,y=newScale.y,z=newScale.z}
                v.offsetPosition = {x=newOffsetP.x,y=newOffsetP.y,z=newOffsetP.z}
                slEfct[k]:setOffsetPosition(newOffsetP)
                slEfct[k]:setScale(newScale*0.255)
            end
        end
    end

    self:cl_redrawSelectedBox(slData)
end

function MAC.cl_startSetRotate(self,offP,offR,centerP)
    self.rotateEffect:start()
    if MACP.moverType <=3 then
        self.rotateEffect:setOffsetPosition(offP)
        self.rotateEffect:setOffsetRotation(offR)
        MACP.moverStartPoint = offP
        MACP.rotatBasicVec = nil
    else
        self.rotateEffect:setOffsetPosition(centerP)
        local atVec
        if MACP.moverType == 4 then
            atVec = MACP.axis.z
        elseif MACP.moverType == 5 then
            atVec = MACP.axis.x
        elseif MACP.moverType == 6 then
            atVec = MACP.axis.y
        end
        if MACP.offsetAxisFlag then
            atVec = MACP.offsetAxisRotation*atVec
        end
        self.rotateEffect:setOffsetRotation(sm.vec3.getRotation(sm.vec3.new(0,-1,0),atVec*-1))
        local fixRotation = sm.quat.inverse(self.shape.worldRotation)
        local PlayerDir = fixRotation*sm.camera.getDirection()
        local PlayerPos = fixRotation*(sm.camera.getPosition()-self.shape.worldPosition)
        local t = (centerP - PlayerPos):length()
        MACP.moverStartPoint = PlayerPos + PlayerDir*t
        MACP.moverStartPoint = self:cl_getMovementTypeXYZ({})
        MACP.rotatBasicVec = nil
    end
    
end

function MAC.cl_setRotate(self,offP)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData == 0 then return end
    if MACP.moverType <= 3 then
        self:cl_setRotateType0(offP,slData,slEfct)
        return
    end
    -- 启用锁定轴
    self:cl_setRotateType0(self:cl_getMovementTypeXYZ(slData),slData,slEfct)
end

function MAC.cl_setRotateType0(self,offP,slData,slEfct)
    local distance = offP - MACP.moverStartPoint
    if distance:length2() < 0.005 then return end
    if MACP.rotatBasicVec == nil then MACP.rotatBasicVec = distance end
    local rota = sm.vec3.getRotation(MACP.rotatBasicVec,distance)
    for k,v in pairs(slData)do
        local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
        local vR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
        vR = rota*vR
        vP = rota*(vP-MACP.moverStartPoint) + MACP.moverStartPoint
        slEfct[k]:setOffsetPosition(vP)
        slEfct[k]:setOffsetRotation(vR)
    end
end

function MAC.cl_endSetRotate(self,offP)
    self.rotateEffect:stop()
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData == 0 then return end
    if MACP.moverType <= 3 then
        self:cl_endSetRotateType0(offP,slData,slEfct)
    else
        -- 启用锁定轴
        self:cl_endSetRotateType0(self:cl_getMovementTypeXYZ(slData),slData,slEfct)
    end
    if MACP.offsetAxisFlag then
        self:cl_setOffsetRotation(slData)
    end
    self:cl_setMoverArrow()
    if self.temporarySelectFlag then
        self:cl_clearSelect()
        self.temporarySelectFlag = false
    end
end

function MAC.cl_endSetRotateType0(self,offP,slData,slEfct)
    local distance = offP - MACP.moverStartPoint
    if distance:length2() < 0.005 then 
        for k,v in pairs(slData)do
            local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            local vR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            slEfct[k]:setOffsetPosition(vP)
            slEfct[k]:setOffsetRotation(vR)
        end
        return
    end
    if MACP.rotatBasicVec == nil then MACP.rotatBasicVec = distance end
    local rota = sm.vec3.getRotation(MACP.rotatBasicVec,distance)
    for k,v in pairs(slData)do
        local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
        local vR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
        vR = rota*vR
        vP = rota*(vP-MACP.moverStartPoint) + MACP.moverStartPoint
        v.offsetPosition = {x=vP.x,y=vP.y,z=vP.z}
        v.offsetRotation = {x=vR.x,y=vR.y,z=vR.z,w=vR.w}
        slEfct[k]:setOffsetPosition(vP)
        slEfct[k]:setOffsetRotation(vR)
    end
    for k,v in pairs(self.selectedMAGData)do
        MACP:addAction(k,6,{x1=MACP.rotatBasicVec.x,y1=MACP.rotatBasicVec.y,z1=MACP.rotatBasicVec.z,x2=distance.x,y2=distance.y,z2=distance.z,x3=MACP.moverStartPoint.x,y3=MACP.moverStartPoint.y,z3=MACP.moverStartPoint.z})
    end

    self:cl_redrawSelectedBox(slData)
end

function MAC.cl_clearMoveEfct(self)
    self.moverArrow:stop()
    self.moverArrowText:close()
end

function MAC.cl_clearRotaEfct( self )
    if self.rotateEffect:isPlaying() then
        self.rotateEffect:stop()
    end
end

function MAC.cl_redrawSelectedBox(self,slData)
    local centerP,scaleP = SS:getSelectedBox(slData,false)
    self.selectedBox:setScale(scaleP)
    self.selectedBox:setOffsetPosition(centerP)
    self.selectedBoxText:setText("Text"," "..tostring(#slData).." ")
    self.selectedBoxText:setWorldPosition(self.shape.worldPosition+self.shape.worldRotation*centerP)
end

function MAC.cl_mirrorPasteAplq(self)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData > 0 and self:cl_checkOverSized(#slData) then
        -- 复制所选择的
        for k,v in pairs(slData)do
            local originVoffP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            local originVoffR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            local originVscale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
            local originVcolor = sm.color.new(v.color)
            self:cl_addEffect(v.id,originVoffP,originVoffR,originVcolor,originVscale,v.cleanFlag,v.state)
        end
        -- 镜像所选择的
        SS:setMirror(slEfct,slData,MACP.mirrorVecMid,MACP.mirrorVecNor,true)
        -- 重新绘制选择框
        self:cl_redrawSelectedBox(slData)
    elseif self:cl_checkOverSized(#self.effectTableData) then
        -- 拷贝原列表
        local idx = 1
        local copyTable = {}
        local copyEfct = {}
        for k,v in pairs(self.effectTableData)do
            if v.cleanFlag == false then
                copyTable[idx]=v
                copyEfct[idx]=self.effectTable[k]
                idx = idx + 1
            end
        end
        -- 复制原列表数据到原列表
        for k,v in pairs(copyTable)do
            local originVoffP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            local originVoffR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            local originVscale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
            local originVcolor = sm.color.new(v.color)
            self:cl_addEffect(v.id,originVoffP,originVoffR,originVcolor,originVscale,v.cleanFlag,v.state)
        end
        -- 镜像拷贝列表
        SS:setMirror(copyEfct,copyTable,MACP.mirrorVecMid,MACP.mirrorVecNor,true)
    end
end

function MAC.cl_mirrorApplique(self)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData > 0 then
        SS:setMirror(slEfct,slData,MACP.mirrorVecMid,MACP.mirrorVecNor,true)
        self:cl_redrawSelectedBox(slData)
    else
        SS:setMirror(self.effectTable,self.effectTableData,MACP.mirrorVecMid,MACP.mirrorVecNor,true)
    end
end

function MAC.cl_clearMirror(self)
    self.mirrorEffect:stop()
    self.mirrorPointEffect:stop()
    self.mirrorFlag = false
end

function MAC.cl_endSetMirror(self,offB)
    TEST_POINT:stop_test_point(2)
    TEST_POINT:stop_test_point(3)
    TEST_POINT:stop_test_point(4)
    MACP.mirrorVecNor = MACP.mirrorVecEd - MACP.mirrorVecSt
    self.mirrorEffect:setOffsetPosition(MACP.mirrorVecMid)
    self.mirrorPointEffect:setOffsetPosition(MACP.mirrorVecMid)
    if MACP.mirrorVecNor:length2() <= 0.01 then
        MACP.mirrorVecNor = sm.vec3.new(0,1,0)
    end
    local mirR = sm.vec3.getRotation(sm.vec3.new(0,1,0),MACP.mirrorVecNor)
    self.mirrorEffect:setOffsetRotation(mirR)
    if not self.mirrorEffect:isPlaying() then
        self.mirrorEffect:start()
        self.mirrorPointEffect:start()
    end
    self.mirrorFlag = true
end

function MAC.cl_startSetMirror(self,offB)
    self:cl_clearMirror()
    MACP.mirrorVecSt = offB
    TEST_POINT:show_test_point(2)
    TEST_POINT:show_test_point(3)
    TEST_POINT:show_test_point(4)
    TEST_POINT:set_test_point_scale(2,sm.vec3.new(1,1,1)*0.27)
    TEST_POINT:set_test_point_rotation(2,self.shape.worldRotation)
    TEST_POINT:set_test_point(2,self.shape.worldPosition + self.shape.worldRotation*offB)
end

function MAC.cl_drawMirror(self,offB)
    MACP.mirrorVecEd = offB
    MACP.mirrorVecMid = (MACP.mirrorVecSt + MACP.mirrorVecEd)/2

    TEST_POINT:set_test_point(2,self.shape.worldPosition + self.shape.worldRotation*MACP.mirrorVecSt)

    TEST_POINT:set_test_point_scale(3,sm.vec3.new(1,1,1)*0.27)
    TEST_POINT:set_test_point_rotation(3,self.shape.worldRotation)
    TEST_POINT:set_test_point(3,self.shape.worldPosition + self.shape.worldRotation*offB)

    TEST_POINT:set_test_point_color(4,sm.color.new("fc1111ff"))
    TEST_POINT:set_test_point_scale(4,sm.vec3.new(1,1,1)*0.3)
    TEST_POINT:set_test_point_rotation(4,self.shape.worldRotation)
    TEST_POINT:set_test_point(4,self.shape.worldPosition + self.shape.worldRotation*MACP.mirrorVecMid)

end

function MAC.cl_setFreeSelectBoxStart(self,offP,fixRotation,hitNormal)
    local startPoint = offP + fixRotation*hitNormal*-0.03
    self.freeSelectBox.st = startPoint
    self.freeSelectBox.box:start()
end

function MAC.cl_setFreeSelectBox(self,offP,fixRotation,hitNormal)
    local endPoint = offP + fixRotation*hitNormal*0.03
    self.freeSelectBox.ed = endPoint
    local startPoint = self.freeSelectBox.st
    local tempET = {
        {
            offsetPosition = {x=startPoint.x,y=startPoint.y,z=startPoint.z}
        },
        {
            offsetPosition = {x=endPoint.x,y=endPoint.y,z=endPoint.z}
        }
    }
    local cP,sP = SS:getSelectedBox(tempET,true)
    self.freeSelectBox.cP = cP
    self.freeSelectBox.sP = sP
    self.freeSelectBox.box:setScale(sP)
    self.freeSelectBox.box:setOffsetPosition(cP)
end

function MAC.cl_getFreeSelect(self)
    local sT = SS:getFreeSelectApplique(self.freeSelectBox.cP,self.freeSelectBox.sP,self.effectTableData)
    for k,v in pairs(sT)do
        local curV = self.effectTableData[v]
        local VOffP = sm.vec3.new(curV.offsetPosition.x,curV.offsetPosition.y,curV.offsetPosition.z)
        self:cl_addSelect(VOffP,v,true)
    end
    self:cl_clearFreeSelect()
end

function MAC.cl_clearFreeSelect(self)
    if not self.freeSelectBox.box:isPlaying() then return end
    self.freeSelectBox.box:stop()
end

function MAC.cl_clearSelect(self)
    for k,v in pairs(self.selectedMAGData)do
        local PoffP = self.effectTableData[k].offsetPosition
        self.effectTable[k]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
        MACP:addAction(k,3,{})
    end
    self.selectedMAGData = {}
    self.selectedBox:stop()
    self.selectedBoxText:close()
    self:cl_setMoverArrow()
    MACP.offsetAxisRotation = sm.quat.new(1,0,0,0)
    MACP.offsetAxisRotationReverse = sm.quat.inverse(MACP.offsetAxisRotation)
end

function MAC.cl_addSelect(self,offP,vIdx,actionFlag)
    local nIdx,nDistance = vIdx,0
    if nIdx == 0 then nIdx,nDistance = self:cl_getNearestApplique(offP) end
    if(nDistance<=0.23)then
        if self.selectedMAGData[nIdx] then
            self.selectedMAGData[nIdx] = nil
            if actionFlag then MACP:addAction(nIdx,3,{}) end
        else
            self.selectedMAGData[nIdx] = true
            if actionFlag then MACP:addAction(nIdx,2,{}) end
        end
        local slData,slEfct = self:cl_getSelectedAplqData()
        if #slData>0 then
            self:cl_redrawSelectedBox(slData)
            if not self.selectedBox:isPlaying() then
                self.selectedBox:start()
                self.selectedBoxText:open()
            end
        else
            if self.selectedBox:isPlaying() then
                self.selectedBox:stop()
                self.selectedBoxText:close()
            end
        end
        if self.selectedMAGData[nIdx] then -- 增
            if #slData == 1 then -- 第一个
                MACP.selectAxisRota = sm.quat.new(slData[1].offsetRotation.x,slData[1].offsetRotation.y,slData[1].offsetRotation.z,slData[1].offsetRotation.w)
                MACP.selectAxisRotaIdx = nIdx
                MACP.selectOffsetData[nIdx] = {x="x",y="y",z="z"}
            else
                self:cl_selectedAplqAxisSimilarityCheck(nIdx)
            end
        else
            if type(MACP.selectAxisRota)=="nil" then
                MACP.selectAxisRota = sm.quat.new(slData[1].offsetRotation.x,slData[1].offsetRotation.y,slData[1].offsetRotation.z,slData[1].offsetRotation.w)
                for k,v in pairs(self.selectedMAGData)do
                    MACP.selectAxisRotaIdx = k
                    break    
                end
                for k,v in pairs(self.selectedMAGData)do
                    local similarFlag = self:cl_selectedAplqAxisSimilarityCheck(k)
                    if not similarFlag then break end
                end
            end
        end
        self:cl_clearSelectFlag()
        return true
    end
    return false
end

function MAC.cl_selectedAplqAxisSimilarityCheck(self,nIdx)
    if MACP.selectAxisRota == nil then return false end
    local Ox,Oy,Oz = MACP.selectAxisRota*sm.vec3.new(1,0,0),MACP.selectAxisRota*sm.vec3.new(0,1,0),MACP.selectAxisRota*sm.vec3.new(0,0,1)
    local NRota = sm.quat.new(self.effectTableData[nIdx].offsetRotation.x,self.effectTableData[nIdx].offsetRotation.y,self.effectTableData[nIdx].offsetRotation.z,self.effectTableData[nIdx].offsetRotation.w)
    local Nx,Ny,Nz = NRota*sm.vec3.new(1,0,0),NRota*sm.vec3.new(0,1,0),NRota*sm.vec3.new(0,0,1)
    local PNX = Nx:dot(Ox) -- projection
    local PNY = Nx:dot(Oy) -- projection
    local f = 0.05
    local similarAxis = math.abs(math.abs(PNX)-0.5)>=0.5-f and math.abs(math.abs(PNY)-0.5)>=0.5-f and math.abs(math.abs(Nx:dot(Oz))-0.5)>=0.5-f
    if similarAxis then
        MACP.selectOffsetData[nIdx] = {}
        for Nk,NAxis in pairs({x=Nx,y=Ny,z=Nz})do
            for Ok,OAxis in pairs({x=Ox,y=Oy,z=Oz})do
                if math.abs(NAxis:dot(OAxis))>=1-f then
                    MACP.selectOffsetData[nIdx][Nk] = Ok
                end
            end
        end
    else
        MACP.selectAxisRota = nil
    end
    return similarAxis
end

function MAC.cl_readColor(self,result)
    local hitShape = result:getShape()
    if hitShape == nil then return end
    local hitColor = hitShape.color
    local hitColorHexStr = hitColor:getHexStr()
    MACP.currentColor = hitColor
    hitColorHexStr = hitColorHexStr:sub(1,6)
    sm.gui.chatMessage("#"..hitColorHexStr.."-"..hitColorHexStr.."-")
    
    self:cl_painterColorRefresh(false,true)
end

function MAC.cl_copySelected(self)
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData > 0 then
        self:cl_cleanCurrentMAC(true)
        MACP.currentEfctPlyr = #CE.efctPlyrCnt-1
        MACP.currentEfctPlus = 0
        MACP.currentEffectId = CE.efctPlyrCnt[#CE.efctPlyrCnt-1] + 0 -- 即贴花选择系统
        MACP.selectedMAC = "MaxCopy_079685746352413"
        local newList = CE:fileOpen(CurrentModType,"__List")
        self:cl_saveMAC(newList,slData,"MaxCopy_079685746352413",2)
        self:changeCurrentEffect(false)
    end
end

function MAC.cl_eraseApplique(self,nIdx) -- erase nearestEffectID
    if self.selectedMAGData[nIdx] then
        for k,v in pairs(self.selectedMAGData)do
            self.effectTableData[k].cleanFlag = true
            self.effectTable[k]:stop()
            MACP:addAction(k,1,{})
        end
        self.selectedMAGData = {}
        self.selectedBox:stop()
        self.selectedBoxText:close()
    else
        self.effectTableData[nIdx].cleanFlag = true
        self.effectTable[nIdx]:stop()
        MACP:addAction(nIdx,1,{})
    end
end

function MAC.cl_paintApplique(self,nIdx) -- paint nearestEffectID
    local paintColorHexStr = MACP.currentColor:getHexStr()
    local paintColor = MACP.currentColor
    if self.selectedMAGData[nIdx] then
        for k,v in pairs(self.selectedMAGData)do
            local oldColor = self.effectTableData[k].color
            self.effectTableData[k].color = paintColorHexStr
            self.effectTable[k]:setParameter("color",paintColor)
            MACP:addAction(k,8,{c1=oldColor,c2=paintColorHexStr})
        end
    else
        local oldColor = self.effectTableData[nIdx].color
        self.effectTableData[nIdx].color = paintColorHexStr
        self.effectTable[nIdx]:setParameter("color",paintColor)
        MACP:addAction(nIdx,8,{c1=oldColor,c2=paintColorHexStr})
    end
end

function MAC.cl_rotateApplique(self,offP,offR,fixRotation,hitNormal)
    if not self.rotateEffect:isPlaying() then
        self.rotateEffect:setOffsetPosition(offP)
        self.rotateEffect:setOffsetRotation(offR)
        self.rotateEffect:start()
    end

    local OoffP = MACP.placeOffP
    local OoffR = MACP.placeOffR -- origin offset position / rotation
    local distance = offP - OoffP
    if distance:length2() < 0.05 then return end -- 拉一定距离再开始旋转
    if MACP.rotationInitialPoint == nil then 
        MACP.rotationInitialPoint = offP-OoffP
    end
    --local efctUp = sm.quat.geOtUp(OoffR)
    --local efctAt = sm.quat.getAt(OoffR)
    --local efctRotaAt = efctAt:rotate(MACP.rotaTable[MACP.currentRotation]/180*3.14,efctUp)
    local efctRota
    if pcall(function() efctRota = sm.vec3.getRotation(MACP.rotationInitialPoint,(offP-OoffP)) end) then
    else
        return
    end
    OoffR = efctRota*OoffR

    -- 设置
    if CE.effectPlayer[MACP.currentEfctPlyr] ~= "Saved保存的图" then
        if self:cl_checkOverSized(1) then -- not oversized
            local scaleV = sm.vec3.new(MACP.scaleTable[MACP.currentScale.x]*MACP.currentScale.mirror,MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])
            self.currentEffect:setOffsetRotation(OoffR)
            self:cl_setEffect(self.tableCnt-1,MACP.currentEffectId,OoffP,OoffR,sm.color.new(MACP.colorList[MACP.chosenColorType][MACP.chosenColorIdx]),scaleV,false,MACP.curAplqState,false)
        end
    else
        if MACP.selectedMAC == "Null" then
           self:createMACselectGUI()
        else
            local loadedMAC = MACP.selectedMACData
            if loadedMAC ~= nil and self:cl_checkOverSized(#loadedMAC) then
                local loadedMACsize = #loadedMAC
                for k,v in pairs(loadedMAC)do
                    local scaleV = sm.vec3.new(MACP.scaleTable[MACP.currentScale.x],MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])
                    local originVoffP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)*scaleV
                    local originVoffR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
                    local originVscale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)*scaleV
                    local fixedOffR = sm.quat.inverse(sm.quat.new(0,1,0,0))
                    local VoffP = OoffP+OoffR*fixedOffR*originVoffP+fixRotation*hitNormal*0.01
                    local VoffR = OoffR*fixedOffR*originVoffR

                    self:cl_setEffect(self.tableCnt-loadedMACsize+k-1,v.id,VoffP,VoffR,sm.color.new(v.color),originVscale,v.cleanFlag,v.state,false)
                    MACP.selectedMACEfct[k]:setOffsetPosition(VoffP)
                    MACP.selectedMACEfct[k]:setOffsetRotation(VoffR)
                end
            end
        end
    end
end

function MAC.cl_setFirstPlacePR(self,offP,offR)
    MACP.placeOffP = offP
    MACP.placeOffR = offR
    MACP.rotationInitialPoint = nil
end

function MAC.cl_placeApplique(self,offP,offR,fixRotation,hitNormal)
    if CE.effectPlayer[MACP.currentEfctPlyr] ~= "Saved保存的图" then
        if self:cl_checkOverSized(1) then -- not oversized
            local scaleV = sm.vec3.new(MACP.scaleTable[MACP.currentScale.x]*MACP.currentScale.mirror,MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])
            self:cl_addEffect(MACP.currentEffectId,offP,offR,sm.color.new(MACP.colorList[MACP.chosenColorType][MACP.chosenColorIdx]),scaleV,false,MACP.curAplqState)
        end
    else
        if MACP.selectedMAC == "Null" then
           self:createMACselectGUI()
        else
            local loadedMAC = MACP.selectedMACData
            if loadedMAC ~= nil and self:cl_checkOverSized(#loadedMAC) then
                for k,v in pairs(loadedMAC)do
                    local scaleV = sm.vec3.new(MACP.scaleTable[MACP.currentScale.x],MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])
                    local originVoffP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)*scaleV
                    local originVoffR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
                    local originVscale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)*scaleV
                    local fixedOffR = sm.quat.inverse(sm.quat.new(0,1,0,0))
                    local VoffP = offP+offR*fixedOffR*originVoffP+fixRotation*hitNormal*0.01
                    local VoffR = offR*fixedOffR*originVoffR

                    self:cl_addEffect(v.id,VoffP,VoffR,sm.color.new(v.color),originVscale,v.cleanFlag,v.state)
                end
            end
        end
    end
end

function MAC.cl_setPreview(self,offP,offR,fixRotation,hitNormal)
    self.currentEffect:setOffsetPosition(offP)
    self.currentEffect:setOffsetRotation(offR)
    self.currentEffect:setScale(sm.vec3.new(MACP.scaleTable[MACP.currentScale.x]*MACP.currentScale.mirror,MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])*0.255)
    if CE.effectPlayer[MACP.currentEfctPlyr] ~= "Saved保存的图" then
        self.currentEffect:setParameter("color",sm.color.new(MACP.colorList[MACP.chosenColorType][MACP.chosenColorIdx]))
    elseif MACP.selectedMAC ~= "Null" and MACP.selectedMACData ~= nil then
        self.currentEffect:setScale(sm.vec3.new(0.1,0.5,0.1)*0.255)
        for k,v in pairs(MACP.selectedMACData)do
            local scaleV = sm.vec3.new(MACP.scaleTable[MACP.currentScale.x],MACP.scaleTable[MACP.currentScale.y],MACP.scaleTable[MACP.currentScale.z])
            local originVoffP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)*scaleV
            local originVoffR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            local originVscale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)*scaleV
            local fixedOffR = sm.quat.inverse(sm.quat.new(0,1,0,0))
            local VoffP = offP+offR*fixedOffR*originVoffP+fixRotation*hitNormal*0.01
            local VoffR = offR*fixedOffR*originVoffR

            MACP.selectedMACEfct[k]:setParameter("color",sm.color.new(v.color))
            MACP.selectedMACEfct[k]:setScale(originVscale*0.255)
            MACP.selectedMACEfct[k]:setOffsetPosition(VoffP)
            MACP.selectedMACEfct[k]:setOffsetRotation(VoffR)
            MACP.selectedMACEfct[k]:start()
        end
    end
end

function MAC.cl_generateSelectFlag(self,offP,fixRotation,hitNormal) -- set nearestEffectID = nIdx
    local nIdx,nDistance = self:cl_getNearestApplique(offP)
    if(nDistance<=0.23)then
        self.eraseTag = true
        if self.nearestEffectID ~= nIdx and self.nearestEffectID ~= nil and self.effectTable[self.nearestEffectID]:isPlaying() then
            if self.selectedMAGData[self.nearestEffectID] then
                self.selectedBox:setParameter("color",sm.color.new("ccfcfc"))
                for k,v in pairs(self.selectedMAGData)do
                    local PoffP = self.effectTableData[k].offsetPosition
                    self.effectTable[k]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
                end
            else
                local PoffP = self.effectTableData[self.nearestEffectID].offsetPosition
                self.effectTable[self.nearestEffectID]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
            end
        end
        self.nearestEffectID = nIdx
        local PoffP = self.effectTableData[nIdx].offsetPosition
        local PoffR = self.effectTableData[nIdx].offsetRotation
        self.pointEffect:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
        self.pointEffect:setOffsetRotation(sm.quat.new(PoffR.x,PoffR.y,PoffR.z,PoffR.w))
        if self.selectedMAGData[nIdx] then
            for k,v in pairs(self.selectedMAGData)do
                local PoffP = self.effectTableData[k].offsetPosition
                self.effectTable[k]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z)+fixRotation*hitNormal*0.05)
            end
            self.selectedBox:setParameter("color",sm.color.new("fc0000"))
        else
            self.effectTable[nIdx]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z)+fixRotation*hitNormal*0.05)
        end
        if not self.pointEffect:isPlaying() then self.pointEffect:start() end
        if self.currentEffect:isPlaying() then self.currentEffect:stop() end
    else
        if self.pointEffect:isPlaying() then self.pointEffect:stop() end
        if not self.currentEffect:isPlaying() then self.currentEffect:start() end
        if self.nearestEffectID ~= nil and self.effectTable[self.nearestEffectID]:isPlaying() then
            local PoffP = self.effectTableData[self.nearestEffectID].offsetPosition
            self.effectTable[self.nearestEffectID]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
            self.nearestEffectID = nil
        end
        if self.nearestEffectID ~= nil and self.effectTableData[self.nearestEffectID].cleanFlag then
            self.nearestEffectID = nil
        end
        if self.eraseTag then
            for k,v in pairs(self.selectedMAGData)do
                local PoffP = self.effectTableData[k].offsetPosition
                self.effectTable[k]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
            end
            self.selectedBox:setParameter("color",sm.color.new("ccfcfc"))
            self.eraseTag = false
        end
        
    end
end

function MAC.cl_clearSelectFlag(self)
    if self.pointEffect:isPlaying() then self.pointEffect:stop() end
    if not self.currentEffect:isPlaying() then self.currentEffect:start() end
    if self.nearestEffectID ~= nil and self.effectTable[self.nearestEffectID]:isPlaying() then
        local PoffP = self.effectTableData[self.nearestEffectID].offsetPosition
        self.effectTable[self.nearestEffectID]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
        self.nearestEffectID = nil
    end
    if self.eraseTag then
        for k,v in pairs(self.selectedMAGData)do
            local PoffP = self.effectTableData[k].offsetPosition
            self.effectTable[k]:setOffsetPosition(sm.vec3.new(PoffP.x,PoffP.y,PoffP.z))
        end
        self.selectedBox:setParameter("color",sm.color.new("ccfcfc"))
        self.eraseTag = false
    end
end

function MAC.cl_nextSelectMode(self)
    MACP.selectMode = (MACP.selectMode+1)%2
end

function MAC.cl_getNearestApplique(self,offP) -- return: nIdx,nDistance(OK<=0.23)
    local nIdx,nDistance,nK = 1,1000,0
    if MACP.selectMode == 0 then
        for idx,data in pairs(self.effectTableData)do
            if not data.cleanFlag and self.effectTable[idx]:isPlaying() then
                local ofp = offP - sm.vec3.new(data.offsetPosition.x,data.offsetPosition.y,data.offsetPosition.z)
                local ofpd = ofp:length()
                if ofpd <= nDistance then
                    nDistance = ofpd
                    nIdx = idx
                end
            end
        end
    else
        local PlayerDir = sm.camera.getDirection()
        for idx,data in pairs(self.effectTableData)do
            if not data.cleanFlag and self.effectTable[idx]:isPlaying() then
                local VoffP = self.shape.worldRotation*sm.vec3.new(data.offsetPosition.x,data.offsetPosition.y,data.offsetPosition.z)-(sm.camera.getPosition()-self.shape.worldPosition)
                local tCosK = sm.vec3.dot(VoffP,PlayerDir)
                if tCosK > 0 then
                    local projectV2 = tCosK -- 投影 -- PlayerDir,length = 1
                    local cosK2 = tCosK*tCosK/VoffP:length2()
                    if cosK2 > 0.99 and cosK2 > nK and projectV2/20<=nDistance then
                        nIdx = idx
                        nDistance = projectV2/20
                        nK = cosK2
                    end
                end
            end
        end
    end
    return nIdx,nDistance
end

function MAC.cl_calculateRaycast(self,result)
    local hitLocation = result.pointWorld
    local hitNormal = result.normalWorld

    --法线修正：
    if MACP.fixNormalFlag then
        hitNormal = MACP.lastNormal
        TEST_POINT:show_test_point(1)
        TEST_POINT:set_test_point(1,hitLocation+hitNormal:normalize()*0.06)
    else
        MACP.lastNormal = hitNormal
        TEST_POINT:stop_test_point(1)
    end

    local nhitN = hitNormal:normalize()
    local nAt = self.shape.at:normalize()
    local cosK = sm.vec3.dot(nAt,nhitN)
    local KStandard = -1 -- represent the front side
    local errorRange = 0.01
    if cosK-KStandard <= errorRange then
        hitNormal = self.shape.at*-1
    end

    local fixRotation = sm.quat.inverse(self.shape.worldRotation)
    local offR = sm.vec3.getRotation(fixRotation*self.shape.at,fixRotation*hitNormal)
    local offP = fixRotation*(hitLocation-self.shape.worldPosition)

    --offP对齐修正
    if MACP.curAlign > 1 then
        local offFixV = sm.vec3.new(1,1,1)*(0.25/4/MACP.alignTable[MACP.curAlign])
        offP = offP + offFixV
        offP = offP*10*MACP.alignTable[MACP.curAlign]
        offP = sm.vec3.new(math.floor(offP.x),math.floor(offP.y),math.floor(offP.z))/MACP.alignTable[MACP.curAlign]/10 + hitNormal*0.25/MACP.alignTable[MACP.curAlign]
    end

    local efctUp = sm.quat.getUp(offR)
    local efctAt = sm.quat.getAt(offR)
    local efctRotaAt = efctAt:rotate(MACP.rotaTable[MACP.currentRotation]/180*3.14,efctUp)
    local efctRota = sm.vec3.getRotation(efctAt,efctRotaAt)
    offR = efctRota*offR

    local hitBody = result:getBody()
    local sameBody = false
    if hitBody ~= nil and hitBody == self.shape.body then
        sameBody = true
    end

    -- 计算相对方块
    local relativeOffP = (offP + hitNormal:normalize()/10)*4 + sm.vec3.new(0.5,0.5,0.5)
    local floorROP = sm.vec3.new(
        math.floor(relativeOffP.x),
        math.floor(relativeOffP.y),
        math.floor(relativeOffP.z)
    )
    local offB = floorROP/4

    return offP,offR,hitNormal,fixRotation,sameBody,offB
end

function MAC.cl_cleanCurrentMAC(self,resetMACflag)
    if MACP.selectedMACEfct~=nil then
        for k,v in pairs(MACP.selectedMACEfct)do
            v:destroy()
        end
        MACP.selectedMACEfct = nil
    end
    if resetMACflag then
        MACP.selectedMAC = "Null"
    end
    MACP.selectedMACData = nil
end

function MAC.cl_checkOverSized(self,addT)
    local limit = 270
    if #self.effectTableData + addT > limit then
        sm.gui.displayAlertText(MLines.lines["MAC"][MLines.currentLanguage][10])
        return false
    else
        return true
    end
end

function MAC.cl_addEffect(self,id,offP,offR,color,scale,cleanFlag,state)
    self.effectTable[self.tableCnt]=sm.effect.createEffect("ShapeRenderable",self.interactable)
    self.effectTable[self.tableCnt]:setParameter("uuid",CE.effectUUIDList[id][state])
    self.effectTable[self.tableCnt]:setParameter("color",color)
    self.effectTable[self.tableCnt]:setScale(scale*0.255)
    self.effectTable[self.tableCnt]:setOffsetPosition(offP)
    self.effectTable[self.tableCnt]:setOffsetRotation(offR)
    self.effectTable[self.tableCnt]:start()
    self.effectTableData[self.tableCnt]={
        id = id ,
        state = state ,
        offsetPosition = {x=offP.x,y=offP.y,z=offP.z},
        offsetRotation = {x=offR.x,y=offR.y,z=offR.z,w=offR.w},
        color = color:getHexStr(),
        scale = {x=scale.x,y=scale.y,z=scale.z},
        cleanFlag = cleanFlag
    }
    MACP:addAction(self.tableCnt,0,{})
    self.tableCnt = self.tableCnt + 1
end

function MAC.cl_setEffect(self,TableIdx,id,offP,offR,color,scale,cleanFlag,state,addAction)
    if id~=nil and state ~= nil and (id~=self.effectTableData[TableIdx].id or state~=self.effectTableData[TableIdx].state) then
        if addAction then MACP:addAction(TableIdx,9,{id1=self.effectTableData[TableIdx].id,state1=self.effectTableData[TableIdx].state,id2=id,state2=state}) end
        self.effectTable[TableIdx]:setParameter("uuid",CE.effectUUIDList[id][state])
        self.effectTableData[TableIdx].id = id
        self.effectTableData[TableIdx].state = state
        self.effectTable[TableIdx]:stop()
        self.effectTable[TableIdx]:start()
    end
    if color~=nil and self.effectTableData[TableIdx].color~=color:getHexStr() then
        if addAction then MACP:addAction(TableIdx,8,{c1=self.effectTableData[TableIdx].color,c2=color:getHexStr()}) end
        self.effectTable[TableIdx]:setParameter("color",color)
        self.effectTableData[TableIdx].color = color:getHexStr()
    end
    if scale~=nil and self:tableToString(self.effectTableData[TableIdx].scale)~=self:tableToString({x=scale.x,y=scale.y,z=scale.z}) then
        local curScale = self.effectTableData[TableIdx].scale
        if addAction then MACP:addAction(TableIdx,12,{x1=curScale.x,y1=curScale.y,z1=curScale.z,x2=scale.x,y2=scale.y,z2=scale.z}) end
        self.effectTable[TableIdx]:setScale(scale*0.255)
        self.effectTableData[TableIdx].scale = {x=scale.x,y=scale.y,z=scale.z}
    end
    if offP~=nil and self:tableToString(self.effectTableData[TableIdx].offsetPosition)~=self:tableToString({x=offP.x,y=offP.y,z=offP.z}) then
        local curP = self.effectTableData[TableIdx].offsetPosition
        if addAction then MACP:addAction(TableIdx,10,{x1=curP.x,y1=curP.y,z1=curP.z,x2=offP.x,y2=offP.y,z2=offP.z}) end
        self.effectTable[TableIdx]:setOffsetPosition(offP) 
        self.effectTableData[TableIdx].offsetPosition = {x=offP.x,y=offP.y,z=offP.z}
    end
    if offR~=nil and self:tableToString(self.effectTableData[TableIdx].offsetRotation)~=self:tableToString({x=offR.x,y=offR.y,z=offR.z,w=offR.w}) then
        local curR = self.effectTableData[TableIdx].offsetRotation
        if addAction then MACP:addAction(TableIdx,11,{x1=curR.x,y1=curR.y,z1=curR.z,w1=curR.w,x2=offR.x,y2=offR.y,z2=offR.z,w2=offR.w}) end
        self.effectTable[TableIdx]:setOffsetRotation(offR) 
        self.effectTableData[TableIdx].offsetRotation = {x=offR.x,y=offR.y,z=offR.z,w=offR.w}
    end
end

function MAC.cl_MAGselectGUI_LeftList(self)
    for i=1,10 do
        self.gui:setText("TypeButton"..tostring(i),CE.effectPlayer[CE.abandonedList[MACP.aplqListStartIdx+i]])
        if CE.effectPlayer[CE.abandonedList[MACP.aplqListStartIdx+i]] == "Saved保存的图" then
            self.gui:setIconImage("TypeI"..tostring(i),self.shape.uuid)
        elseif CE.effectPlayer[CE.abandonedList[MACP.aplqListStartIdx+i]] == "000MaxZ666" then
            self.gui:setIconImage("TypeI"..tostring(i),CE.effectUUIDList[0+CE.efctPlyrCnt[CE.abandonedList[MACP.aplqListStartIdx+i]]]["origin"])
        else
            self.gui:setIconImage("TypeI"..tostring(i),CE.effectUUIDList[1+CE.efctPlyrCnt[CE.abandonedList[MACP.aplqListStartIdx+i]]]["origin"])
        end
        if CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx >=1 and CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx <=10 then
            self.gui:setButtonState("TypeButton"..tostring(CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx),true)
        end
    end
end

--[[  MAG GUI ]]-----------------------------------------------

function MAC.cl_createMAG_select_GUI(self)
    self:cl_cleanCurrentMAC(true)
    self:findEfctPlyr()
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAG_int_V6.layout")
    self.gui:setText("Name", " MAG ")
    self:cl_appliqueChangedGuiRefresh()
    self.gui:createHorizontalSlider("slider1",#CE.abandonedList-1,CE.reverseToAbandonedList[MACP.currentEfctPlyr]-1,"client_onSliderChangePlayer",true)
    --self.gui:createHorizontalSlider("slider2",20,MACP.currentEfctPlus,"client_onSliderChangeApplique",true)
    self.gui:setImage("Tutorial","$MOD_DATA/Gui/Layouts/black.png")
    --self.gui:setText("Content",CE.EfctPlyrListSTR)

    for i=1,30 do
        self.gui:setButtonCallback( "apqButton" .. tostring(i), "cl_chooseApplique" ) 
    end
    self.gui:setButtonState("apqButton"..tostring(MACP.currentEfctPlus+1),true)

    for i=1,10 do
        self.gui:setButtonCallback("TypeButton"..tostring(i),"cl_setAplqType")
    end
    self.gui:setButtonCallback("TypeButtonUp","cl_aplqListUp")
    self.gui:setButtonCallback("TypeButtonDown","cl_aplqListDown")
    self:cl_MAGselectGUI_LeftList()

    self:cl_itemListRefresh()
    self:cl_appliqueChangedGuiRefresh()

    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAC.cl_createMAG_rota_scale_color_GUI(self)
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAG_rota_scale_color_V3.layout")
    self.gui:setText("Name", "")
    self.gui:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][2]..MACP.rotaTable[MACP.currentRotation]..MLines.lines["MAC"][MLines.currentLanguage][3]..MACP.scaleTable[MACP.currentScale.x]..","..MACP.scaleTable[MACP.currentScale.y]..","..MACP.scaleTable[MACP.currentScale.z])
    self.gui:setText("colorText",MLines.lines["MAC"][MLines.currentLanguage][11])
    self.gui:setImage("Tutorial","$MOD_DATA/Gui/Layouts/black.png")

    for k,name in pairs({"HorizonImg","VerticalImg","LayerImg","RotationImg"})do
        self.gui:setImage(name,"$MOD_DATA/Gui/Layouts/MAG/"..name..".png")
    end
    self.gui:createHorizontalSlider("slider1",#MACP.rotaTable,MACP.currentRotation,"client_onSliderChangeOffRota",false)
    self.gui:createHorizontalSlider("slider2",#MACP.scaleTable,MACP.currentScale.x-1,"client_onSliderChangeScaleX",false)
    self.gui:createVerticalSlider("slider3",#MACP.scaleTable,MACP.currentScale.y-1,"client_onSliderChangeScaleY")
    self.gui:createVerticalSlider("slider4",#MACP.scaleTable,MACP.currentScale.z-1,"client_onSliderChangeScaleZ")

    self.gui:setText("xText",tostring(MACP.scaleTable[MACP.currentScale.x]))
    self.gui:setText("yText",tostring(MACP.scaleTable[MACP.currentScale.y]))
    self.gui:setText("zText",tostring(MACP.scaleTable[MACP.currentScale.z]))
    self.gui:setText("rText",tostring(MACP.rotaTable[MACP.currentRotation]))

    self.gui:createHorizontalSlider("alignSlider",#MACP.alignTable,MACP.curAlign-1,"client_onSliderChangeAlign",false)
    self.gui:setText("AlignText",MLines.lines["MAC"][MLines.currentLanguage][17])
    
    for k=1, 10 do
        self.gui:setColor("emptyColorA" .. tostring(k),sm.color.new(MACP.colorList[MACP.chosenColorType][k]))
        self.gui:setButtonCallback( "colorB" .. tostring(k), "cl_chooseColor" ) 
    end
    
    self.gui:createVerticalSlider("ColorTypeSlider",#MACP.colorList,#MACP.colorList-MACP.chosenColorType,"client_onSliderChangeColorType")

    self.gui:setButtonCallback("ResetButton","cl_onResetQstate")
    self.gui:setText("ResetButton",MLines.lines["MAC"][MLines.currentLanguage][13])
    self.gui:setButtonCallback("MirrorButton","cl_onMirrorQstate")
    self.gui:setText("MirrorButton",MLines.lines["MAC"][MLines.currentLanguage][14])
    self.gui:setButtonCallback("GlowButton","cl_onGlowQstate")
    self.gui:setText("GlowButton",MLines.lines["MAC"][MLines.currentLanguage][15])

    self.gui:setButtonCallback("fixNormal","cl_onFixNormalQstate")
    self.gui:setText("fixNormalText",MLines.lines["MAC"][MLines.currentLanguage][16])
    self.gui:setImage("fixNormalImage","$MOD_DATA/Gui/Layouts/MAG/FixNormalImg.png")
    self.gui:setButtonState("fixNormal",MACP.fixNormalFlag)

    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAC.cl_createColorEditGui(self)
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAG_color_edit.layout")
    self.gui:setText("Name", "Edit Color")
    self.gui:setText("colorText",MLines.lines["MAC"][MLines.currentLanguage][18])
    
    for k=1, 10 do
        self.gui:setColor("emptyColorA" .. tostring(k),sm.color.new(MACP.colorList[MACP.chosenColorType][k]))
        self.gui:setButtonCallback( "colorB" .. tostring(k), "cl_readGUIColor" ) 
    end
    for k=1, 10 do
        self.gui:setText("readColorB" .. tostring(k),MLines.lines["MAC"][MLines.currentLanguage][19])
        self.gui:setButtonCallback( "readColorB" .. tostring(k), "cl_setGUIColor" ) 
    end
    
    self.gui:createVerticalSlider("ColorTypeSlider",#MACP.colorList,#MACP.colorList-MACP.chosenColorType,"client_onSliderChangeColorType")

    local curHexStr = MACP.currentColor:getHexStr():sub(1,6)
    self.gui:setText("editHexStr","##"..curHexStr:upper())
    self.gui:setColor("emptyEditA",MACP.currentColor)
    self.gui:createHorizontalSlider("Rslider",256,MACP.currentColor.r*255,"client_onSliderChangeColorR",false)
    self.gui:createHorizontalSlider("Gslider",256,MACP.currentColor.g*255,"client_onSliderChangeColorG",false)
    self.gui:createHorizontalSlider("Bslider",256,MACP.currentColor.b*255,"client_onSliderChangeColorB",false)

    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAC.client_onFileOperate(self)
    if self.gui ~= nil then return end
    MACP.MACfiles = CE:getMACfiles()
    self.tempMACname = 1
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAC_int_V2.layout" , false)
    --self.gui:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][4])
    self.gui:setTextChangedCallback("AppliqueName","cl_onChangeApqName")
    self.gui:setTextAcceptedCallback("AppliqueName","cl_onChangeDoneApqName")
    MACP.fileName = MACP.MACfiles[1]--if MACP.fileName == "Name" then MACP.fileName = MACP.MACfiles[1] end
    self.gui:setText("AppliqueName",MACP.fileName)
    self.gui:createDropDown("AppliqueList","cl_onDropDownInteract",MACP.MACfiles)
    self.gui:setSelectedDropDownItem("AppliqueList", MACP.MACfiles[1])
    self.gui:setButtonCallback("Type1","cl_setSaveType")
    self.gui:setImage("TypeImg1","$MOD_DATA/Gui/Layouts/MAC/type1.png")
    self.gui:setText("Type1",MLines.lines["MAC"][MLines.currentLanguage][20])
    self.gui:setText("TypeDes1",MLines.lines["MAC"][MLines.currentLanguage][21])
    self.gui:setButtonCallback("Type2","cl_setSaveType")
    self.gui:setImage("TypeImg2","$MOD_DATA/Gui/Layouts/MAC/type2.png")
    self.gui:setText("Type2",MLines.lines["MAC"][MLines.currentLanguage][22])
    self.gui:setText("TypeDes2",MLines.lines["MAC"][MLines.currentLanguage][23])

    self:cl_setSaveGuiStateShowing()

    self.gui:setButtonCallback("NewButton","cl_onNewMAC")
    self.gui:setButtonCallback("OpenButton","cl_onOpenMAC")
    self.gui:setButtonCallback("SaveButton","cl_onSaveMAC")
    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAC.createMACselectGUI(self)
    if self.gui ~= nil then return end
    MACP.MACfiles = CE:getMACfiles()
    self.tempMACname = 1
    self.gui = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/MAC_fileOpen.layout" , false)
    --self.gui:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][4])
    self.gui:createDropDown("AppliqueList","cl_onDropDownSelect",MACP.MACfiles)
    self.gui:setSelectedDropDownItem("AppliqueList", MACP.MACfiles[1])
    MACP.selectedMAC = MACP.MACfiles[1]
    self.gui:setButtonCallback("OpenButton","cl_onOpenSelectedMAC")
    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAC.cl_painterColorRefresh(self,guiChange,specialSet)
    if specialSet then
        MACP.chosenColorType = 5
        MACP.chosenColorIdx = 11
        MACP.colorList[5][11] = MACP.currentColor:getHexStr()
    end
    self:changeCurrentEffect(true)
    if guiChange then
        local curHexStr = MACP.currentColor:getHexStr():sub(1,6)
        self.gui:setText("editHexStr","##"..curHexStr:upper())
        self.gui:setColor("emptyEditA",MACP.currentColor)
        for k=1, 10 do
            self.gui:setColor("emptyColorA" .. tostring(k),sm.color.new(MACP.colorList[MACP.chosenColorType][k]))
            self.gui:setButtonCallback( "colorB" .. tostring(k), "cl_readGUIColor" ) 
        end
        self.gui:setSliderPosition("ColorTypeSlider",5-MACP.chosenColorType)
    end
end

function MAC.cl_setGUIColor(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    if type(buttonId) == "nil" or MACP.chosenColorType<=4 then return end
    self.gui:setColor("emptyColorA" .. tostring(buttonId),MACP.currentColor)
    MACP.colorList[MACP.chosenColorType][buttonId] = MACP.currentColor:getHexStr()
end

function MAC.cl_readGUIColor(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    MACP.chosenColorIdx = buttonId
    if type(buttonId) == "nil" then return end
    MACP.currentColor = sm.color.new(MACP.colorList[MACP.chosenColorType][buttonId])
    self:cl_painterColorRefresh(true,false)
    self.gui:setSliderPosition("Rslider",MACP.currentColor.r*255)
    self.gui:setSliderPosition("Gslider",MACP.currentColor.g*255)
    self.gui:setSliderPosition("Bslider",MACP.currentColor.b*255)
end

function MAC.client_onSliderChangeColorR(self,sliderPos)
    MACP.currentColor.r=(sliderPos/255)
    self:cl_painterColorRefresh(true,true)
end

function MAC.client_onSliderChangeColorG(self,sliderPos)
    MACP.currentColor.g=(sliderPos/255)
    self:cl_painterColorRefresh(true,true)
end

function MAC.client_onSliderChangeColorB(self,sliderPos)
    MACP.currentColor.b=(sliderPos/255)
    self:cl_painterColorRefresh(true,true)
end

function MAC.cl_chooseColor(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    MACP.chosenColorIdx = buttonId
    self:changeCurrentEffect(true)
end

function MAC.cl_onDropDownSelect(self,DDname)
    MACP.selectedMAC = DDname
end

function MAC.cl_onOpenSelectedMAC(self)
    self.gui:close()
end

function MAC.cl_onChangeApqName(self,editBoxName,MACname)
    MACP.fileName = MACname
    self:cl_setSaveGuiStateShowing()
end

function MAC.cl_onChangeDoneApqName(self,editBoxName,MACname)
    MACP.fileName = MACname
    self:cl_setSaveGuiStateShowing()
end

function MAC.cl_onDropDownInteract(self,DDname)
    MACP.fileName = DDname
    self.gui:setText("AppliqueName",MACP.fileName)
    self:cl_setSaveGuiStateShowing()
end

function MAC.cl_setSaveGuiStateShowing(self)
    self.gui:setText("state","name:"..MACP.fileName.." / type:"..MACP.fileType)
    if MACP.fileType == 1 then
        self.gui:setButtonState("Type1",true)
        self.gui:setButtonState("Type2",false)
    else
        self.gui:setButtonState("Type1",false)
        self.gui:setButtonState("Type2",true)
    end
    
end

function MAC.cl_setSaveType(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    MACP.fileType = buttonId
    self:cl_setSaveGuiStateShowing()
end

function MAC.cl_onNewMAC(self,button)
    if #self.effectTableData > 0 then
        self.gui:close()
        self.warningGUI = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/warning.layout",true)
        self.warningGUI:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][7])
        self.warningGUI:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][8])
        self.warningGUI:setButtonCallback("No","cl_wnNo")
        self.warningGUI:setButtonCallback("Yes","cl_wnYesNew")
        self.warningGUI:open()
    end
end

function MAC.cl_onOpenMAC(self,button)
    if #self.effectTableData > 0 then
        self.gui:close()
        self.warningGUI = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/warning.layout",true)
        self.warningGUI:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][7])
        self.warningGUI:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][8])
        self.warningGUI:setButtonCallback("No","cl_wnNo")
        self.warningGUI:setButtonCallback("Yes","cl_wnYesOpen")
        self.warningGUI:open()
    else
        self:openMAC()
    end
end

function MAC.cl_wnYesNew(self)
    self.network:sendToServer("server_saveData",{partUUIDList={},effectTableData={}})
    self.effectTableData={}
    MACP:clear_action_table()
    self.tableCnt = 1
    self.warningGUI:close()
end

function MAC.openMAC(self)
    local MacType = CE:MACexists(MACP.fileName)
    local MacExist = false
    if MacType == 0 then MacExist,MacType = CE:fileExists(0,MACP.fileName) end
    if MacType == 0 then
        sm.gui.chatMessage(MLines.lines["MAC"][MLines.currentLanguage][5])
        self.effectTableData = {}
        MACP:clear_action_table()
    else
        self.effectTableData = self:readMAC(MacType,MACP.fileName)
        MACP:clear_action_table()
        sm.gui.chatMessage(MLines.lines["MAC"][MLines.currentLanguage][6])
    end
    self.network:sendToServer("server_saveData",CE:formatData(self.effectTableData))
end

function MAC.cl_wnYesOpen(self)
    self:openMAC()
    self.warningGUI:close()
end

function MAC.cl_onSaveMAC(self,button)
    local existType = CE:MACexists(MACP.fileName)
    --create New added List
    local newList = CE:fileOpen(CurrentModType,"__List")
    if existType == 0 then
        --MACP.MACfiles[#MACP.MACfiles+1] = MACP.fileName
        newList[#newList+1] = MACP.fileName
        local slData,slEfct = self:cl_getSelectedAplqData()
        if #slData > 0 then
            self:cl_saveMAC(newList,slData,MACP.fileName,MACP.fileType)
        end
    elseif existType == CurrentModType then -- 本地重名
        self.gui:close()
        self.warningGUI = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/warning.layout",true)
        self.warningGUI:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][7])
        self.warningGUI:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][8])
        self.warningGUI:setButtonCallback("No","cl_wnNo")
        self.warningGUI:setButtonCallback("Yes","cl_wnYes")
        self.warningGUI:open()
    else -- 异地重名
        self.gui:close()
        self.warningGUI = sm.gui.createGuiFromLayout("$MOD_DATA/Gui/Layouts/warning.layout",true)
        self.warningGUI:setText("Name", MLines.lines["MAC"][MLines.currentLanguage][7])
        self.warningGUI:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][12])
        self.warningGUI:setButtonCallback("No","cl_wnNo")
        self.warningGUI:setButtonCallback("Yes","cl_wnNo")
        self.warningGUI:open()
    end
end

function MAC.cl_saveMAC(self,newList,efctTableData,fileName,fileType)
    if #efctTableData == 0 then return end

    local centerPosition = sm.vec3.new(0,0,0)
    local fullDeltaPlus = 0
    local FDPstandard = 0.95
    local fixRotation = sm.quat.inverse(self.shape.worldRotation)
    local targetAt = fixRotation*self.shape.at
    local averUp = sm.vec3.new(0,0,0)
    local adjustFlag = false
    local adjustRota
    if fileType == 2 then
        for k,v in pairs(efctTableData)do
            centerPosition = centerPosition + sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            local offsetRotation = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            local offRUp = sm.quat.getUp(offsetRotation)
            averUp = averUp + offRUp
        end
        averUp = averUp:normalize()
        for k,v in pairs(efctTableData)do
            local offsetRotation = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            local offRUp = sm.quat.getUp(offsetRotation)
            local cosK = sm.vec3.dot(averUp,offRUp)
            fullDeltaPlus = fullDeltaPlus + (cosK+1)/2
        end
        fullDeltaPlus = fullDeltaPlus/#efctTableData
        adjustFlag = fullDeltaPlus >= FDPstandard -- 太大偏差说明故意偏的
        if adjustFlag then
            adjustRota = sm.vec3.getRotation(averUp,targetAt)
        end
        centerPosition = centerPosition/#efctTableData
        for k,v in pairs(efctTableData)do
            local VnewOffPosition = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)-centerPosition
            if adjustFlag then
                VnewOffPosition = adjustRota*VnewOffPosition
                local VnOffR = adjustRota*sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
                v.offsetRotation = {x=VnOffR.x,y=VnOffR.y,z=VnOffR.z,w=VnOffR.w}
            end
            v.offsetPosition = {x=VnewOffPosition.x,y=VnewOffPosition.y,z=VnewOffPosition.z}
        end
    end
    
    sm.json.save(newList,"$CONTENT_"..FileMODuuid.."/Appliques/__List.json")
    sm.json.save(CE:formatData(efctTableData),"$CONTENT_"..FileMODuuid.."/Appliques/"..fileName..".json")
    sm.gui.chatMessage(MLines.lines["MAC"][MLines.currentLanguage][9])
    if sm.isHost and fileName ~= "MaxCopy_079685746352413" then
        self.network:sendToServer("sv_onCreateBackUp")
    end

    --reverse operation
    if fileType == 2 then
        if adjustFlag then adjustRota = sm.quat.inverse(adjustRota) end
        for k,v in pairs(efctTableData)do
            local VnewOffPosition = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            if adjustFlag then
                VnewOffPosition = adjustRota*VnewOffPosition
                local VnOffR = adjustRota*sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
                v.offsetRotation = {x=VnOffR.x,y=VnOffR.y,z=VnOffR.z,w=VnOffR.w}
            end
            VnewOffPosition = VnewOffPosition + centerPosition
            v.offsetPosition = {x=VnewOffPosition.x,y=VnewOffPosition.y,z=VnewOffPosition.z}
        end
    end
end

function MAC.cl_wnNo(self)
    self.warningGUI:close()
    self:client_onFileOperate()
end

function MAC.cl_wnYes(self) -- 本地重名
    local newList = CE:fileOpen(CurrentModType,"__List")
    local slData,slEfct = self:cl_getSelectedAplqData()
    if #slData > 0 then
        self:cl_saveMAC(newList,slData,MACP.fileName,MACP.fileType)
    end
    self:cl_saveMAC(newList,slData,MACP.fileName,MACP.fileType)
    self.warningGUI:close()
end

function MAC.client_onSliderChangePlayer(self, sliderPos)
    self.gui:setButtonState("apqButton"..tostring(MACP.currentEfctPlus+1),false)
    self.gui:setButtonState("TypeButton"..tostring(CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx),false)

    MACP.currentEfctPlyr = CE.abandonedList[sliderPos+1]
    MACP.currentEfctPlus = 0
    MACP.currentEffectId = CE.efctPlyrCnt[MACP.currentEfctPlyr]+MACP.currentEfctPlus

    MACP.curAplqState = "origin"

    self.gui:setButtonState("apqButton"..tostring(MACP.currentEfctPlus+1),true)
    if CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx >=1 and CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx <=10 then
        self.gui:setButtonState("TypeButton"..tostring(CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx),true)
    end

    self:cl_itemListRefresh()
    self:cl_appliqueChangedGuiRefresh()
    self:changeCurrentEffect(false)
end

function MAC.cl_itemListRefresh(self)
    if self.gui == nil then return end
    if CE.effectPlayer[MACP.currentEfctPlyr] ~= "Saved保存的图" then
        for id = CE.efctPlyrCnt[MACP.currentEfctPlyr] , CE.efctPlyrCnt[MACP.currentEfctPlyr+1]-1 do
            self.gui:setVisible("apqButton"..tostring(id-CE.efctPlyrCnt[MACP.currentEfctPlyr]+1),true)
            self.gui:setIconImage("item"..tostring(id-CE.efctPlyrCnt[MACP.currentEfctPlyr]+1),CE.effectUUIDList[id]["origin"])
        end
        for id = CE.efctPlyrCnt[MACP.currentEfctPlyr+1] - CE.efctPlyrCnt[MACP.currentEfctPlyr] + 1 , 30 do
            self.gui:setVisible("apqButton"..tostring(id),false)
            self.gui:setIconImage("item"..tostring(id),sm.uuid.getNil())
        end
    else
        for id = 1 , 30 do
            self.gui:setVisible("apqButton"..tostring(id),false)
            self.gui:setIconImage("item"..tostring(id),sm.uuid.getNil())
        end
    end
end

function MAC.cl_chooseApplique(self,button)
    if self.gui == nil then return end
    if CE.effectPlayer[MACP.currentEfctPlyr] == "Saved保存的图" then return end
    local buttonId = tonumber(button:match("(%d+)"))
    if buttonId >= CE.efctPlyrCnt[MACP.currentEfctPlyr+1]-CE.efctPlyrCnt[MACP.currentEfctPlyr] + 1 then return end
    self.gui:setButtonState("apqButton"..tostring(MACP.currentEfctPlus+1),false)
    MACP.currentEfctPlus = buttonId-1
    self.gui:setButtonState("apqButton"..tostring(MACP.currentEfctPlus+1),true)
    MACP.currentEffectId = CE.efctPlyrCnt[MACP.currentEfctPlyr]+MACP.currentEfctPlus
    self:cl_appliqueChangedGuiRefresh()
    self:changeCurrentEffect(false)
end

function MAC.cl_setAplqType(self,button)
    if self.gui==nil then return end
    local buttonId = tonumber(button:match("(%d+)"))
    self.gui:setSliderPosition("slider1",MACP.aplqListStartIdx+buttonId-1)
    self.gui:setButtonState(button,true)
    self.gui:setButtonState("TypeButton"..tostring(CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx),false)
    self:client_onSliderChangePlayer(MACP.aplqListStartIdx+buttonId-1)
end

function MAC.cl_aplqListUp(self,button)
    if MACP.aplqListStartIdx > 0 then
        self.gui:setButtonState("TypeButton"..tostring(CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx),false)
        MACP.aplqListStartIdx = MACP.aplqListStartIdx - 1
        self:cl_MAGselectGUI_LeftList()
    end
end

function MAC.cl_aplqListDown(self,button)
    if MACP.aplqListStartIdx < #CE.abandonedList - 10 - 1 then
        self.gui:setButtonState("TypeButton"..tostring(CE.reverseToAbandonedList[MACP.currentEfctPlyr]-MACP.aplqListStartIdx),false)
        MACP.aplqListStartIdx = MACP.aplqListStartIdx + 1
        self:cl_MAGselectGUI_LeftList()
    end
end

function MAC.cl_appliqueChangedGuiRefresh(self)
    if self.gui == nil then return end
    if CE.effectPlayer[MACP.currentEfctPlyr] ~= "Saved保存的图" then 
        self.gui:setIconImage("itemPreview",CE.effectUUIDList[MACP.currentEffectId]["origin"]) 
    else
        self.gui:setIconImage("itemPreview",self.shape.uuid) 
    end
    self.gui:setText("SubTitle", CE.effectPlayer[MACP.currentEfctPlyr].." : "..CE.effectList[MACP.currentEffectId])
end

function MAC.client_onSliderChangeOffRota(self, sliderPos)
    MACP.currentRotation = sliderPos
    self.gui:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][2]..MACP.rotaTable[MACP.currentRotation]..MLines.lines["MAC"][MLines.currentLanguage][3]..MACP.scaleTable[MACP.currentScale.x]..","..MACP.scaleTable[MACP.currentScale.y]..","..MACP.scaleTable[MACP.currentScale.z])
    self.gui:setText("rText",tostring(MACP.rotaTable[MACP.currentRotation]))
    self:changeCurrentEffect(false)
end

function MAC.client_onSliderChangeScaleX(self, sliderPos)
    MACP.currentScale.x = sliderPos+1
    self.gui:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][2]..MACP.rotaTable[MACP.currentRotation]..MLines.lines["MAC"][MLines.currentLanguage][3]..MACP.scaleTable[MACP.currentScale.x]..","..MACP.scaleTable[MACP.currentScale.y]..","..MACP.scaleTable[MACP.currentScale.z])
    self.gui:setText("xText",tostring(MACP.scaleTable[MACP.currentScale.x]))
    self:changeCurrentEffect(false)
end

function MAC.client_onSliderChangeScaleY(self, sliderPos)
    MACP.currentScale.y = sliderPos+1
    self.gui:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][2]..MACP.rotaTable[MACP.currentRotation]..MLines.lines["MAC"][MLines.currentLanguage][3]..MACP.scaleTable[MACP.currentScale.x]..","..MACP.scaleTable[MACP.currentScale.y]..","..MACP.scaleTable[MACP.currentScale.z])
    self.gui:setText("yText",tostring(MACP.scaleTable[MACP.currentScale.y]))
    self:changeCurrentEffect(false)
end

function MAC.client_onSliderChangeScaleZ(self, sliderPos)
    MACP.currentScale.z = sliderPos+1
    self.gui:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][2]..MACP.rotaTable[MACP.currentRotation]..MLines.lines["MAC"][MLines.currentLanguage][3]..MACP.scaleTable[MACP.currentScale.x]..","..MACP.scaleTable[MACP.currentScale.y]..","..MACP.scaleTable[MACP.currentScale.z])
    self.gui:setText("zText",tostring(MACP.scaleTable[MACP.currentScale.z]))
    self:changeCurrentEffect(false)
end

function MAC.client_onSliderChangeAlign(self, sliderPos)
    MACP.curAlign = sliderPos + 1
end

function MAC.client_onSliderChangeColorType(self,sliderPos)
    MACP.chosenColorType = #MACP.colorList-sliderPos
    if MACP.chosenColorIdx > 10 then
        MACP.chosenColorIdx = 1
    end
    for k=1, 10 do
        self.gui:setColor("emptyColorA" .. tostring(k),sm.color.new(MACP.colorList[MACP.chosenColorType][k]))
    end
end

function MAC.cl_onResetQstate(self,button)
    MACP.currentScale.x = 10
    MACP.currentScale.y = 10
    MACP.currentScale.z = 10
    MACP.curAlign = 1
    MACP.currentScale.mirror = 1
    MACP.curAplqState = "origin"
    MACP.fixNormalFlag = false
    MACP.currentRotation = 36
    self.gui:setSliderPosition("slider1",36)
    self.gui:setSliderPosition("slider2",9)
    self.gui:setSliderPosition("slider3",9)
    self.gui:setSliderPosition("slider4",9)
    self.gui:setSliderPosition("alignSlider",0)
    self.gui:setText("SubTitle", MLines.lines["MAC"][MLines.currentLanguage][2]..MACP.rotaTable[MACP.currentRotation]..MLines.lines["MAC"][MLines.currentLanguage][3]..MACP.scaleTable[MACP.currentScale.x]..","..MACP.scaleTable[MACP.currentScale.y]..","..MACP.scaleTable[MACP.currentScale.z])
    self.gui:setText("xText",tostring(MACP.scaleTable[MACP.currentScale.x]))
    self.gui:setText("yText",tostring(MACP.scaleTable[MACP.currentScale.y]))
    self.gui:setText("zText",tostring(MACP.scaleTable[MACP.currentScale.z]))
    self.gui:setText("rText",tostring(MACP.rotaTable[MACP.currentRotation]))
    if CE.effectPlayer[MACP.currentEfctPlyr] == "Saved保存的图" and MACP.selectedMACData~=nil then
        self:cl_cleanCurrentMAC(false)
        local MacType = CE:MACexists(MACP.selectedMAC)
        if MacType == 0 then MacType = CurrentModType end -- 粘贴板 --> 本地
        MACP.selectedMACData = self:readMAC(MacType,MACP.selectedMAC)
        MACP.selectedMACEfct = {}
        for k,v in pairs(MACP.selectedMACData)do -- 读取初始化
            if v.state == nil then v.state = "origin" end
            MACP.selectedMACEfct[k] = sm.effect.createEffect("ShapeRenderable",self.interactable)
            MACP.selectedMACEfct[k]:setParameter("uuid",CE.effectUUIDList[v.id][v.state])
        end
    end
    self:changeCurrentEffect(false)
end

function MAC.cl_onMirrorQstate(self,button)
    MACP.currentScale.mirror = -1*MACP.currentScale.mirror
    SS:setMirror(MACP.selectedMACEfct,MACP.selectedMACData,sm.vec3.new(0,0,0),sm.vec3.new(1,0,0),false)
end

function MAC.cl_onGlowQstate(self,button)
    MACP.curAplqState = MACP.curAplqStateTable[MACP.curAplqState]
    if CE.effectPlayer[MACP.currentEfctPlyr] == "Saved保存的图" or CE.effectUUIDList[MACP.currentEffectId][MACP.curAplqState] == 0 then
        MACP.curAplqState = "origin"
    end
    self:changeCurrentEffect(false)
end

function MAC.cl_onFixNormalQstate(self,button)
    MACP.fixNormalFlag = not MACP.fixNormalFlag
    self.gui:setButtonState("fixNormal",MACP.fixNormalFlag)
end

function MAC.cl_onOpenControlPad(self) -- CP for control pad
    if self.gui ~= nil then return end
    self.gui = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/MAGControlPadV3.layout')
    self.controlPadStartIdx = 1
    self:cl_CP_getClearedData()
    self.gui:setVisible("EditPopup",false)
    if #self.CPdata > 12 then -- 翻页
        self.gui:setButtonCallback("TypeButtonUp","cl_CP_onUpMAC")
        self.gui:setButtonCallback("TypeButtonDown","cl_CP_onDownMAC")
        self.gui:createVerticalSlider("ScrollDown",#self.CPdata-11,(#self.CPdata-11) - (self.controlPadStartIdx-1) - 1,"cl_CP_scrollDown")
    else
        self.gui:setVisible("TypeButtonUp",false)
        self.gui:setVisible("TypeButtonDown",false)
        self.gui:setVisible("ScrollDown",false)
    end
    for i=1,12 do
        if self.CPdata[i] == nil then
            self.gui:setVisible("TypeI"..tostring(i),false)
            self.gui:setVisible("TypeButton"..tostring(i),false)
            self.gui:setVisible("Text"..tostring(i),false)
            self.gui:setVisible("Edit"..tostring(i),false)
            self.gui:setVisible("Display"..tostring(i),false)
        else
            self.gui:setButtonCallback("TypeButton"..tostring(i),"cl_CP_onSelectMAG")
            self.gui:setButtonCallback("Edit"..tostring(i),"cl_CP_onEditMAG")
            self.gui:setButtonCallback("Display"..tostring(i),"cl_CP_onHideMAG")
            if self.selectedMAGData[i] then
                self.gui:setButtonState("TypeButton"..tostring(i),true)
            end
        end
    end
    self.gui:setButtonCallback("CancelSelection","cl_CP_clearSelect")
    self.gui:setTextChangedCallback("EditText","cl_CP_onEditTextChanged")
    self.gui:setTextAcceptedCallback("EditText","cl_CP_onEditTextAccepted")
    self.gui:setTextChangedCallback("startNumber","cl_CP_onStartNumberChanged")
    self.gui:setTextChangedCallback("endNumber","cl_CP_onEndNumberChanged")
    self.gui:setText("endNumber",tostring(#self.CPdata))
    self.gui:setButtonCallback("multiSelect","cl_CP_multiSelect")
    self.gui:setButtonCallback("ESCbutton","cl_CP_escEdit")
    self:cl_CP_refreshCP()
    self.gui:setOnCloseCallback("client_onClose")
    self.gui:open()
end

function MAC.cl_CP_onStartNumberChanged(self,editBox,text)
    local stNum = tonumber(text)
    if stNum == nil then return end
    if stNum < 1 then stNum = 1 end
    self.CPparameter.startNumber = stNum
    self.gui:setText(editBox,tostring(stNum))
end

function MAC.cl_CP_onEndNumberChanged(self,editBox,text)
    local edNum = tonumber(text)
    if edNum == nil then return end
    if edNum > #self.CPdata then edNum = #self.CPdata end
    self.CPparameter.endNumber = edNum
    self.gui:setText(editBox,tostring(edNum))
end

function MAC.cl_CP_multiSelect(self,button) -- 批量选择
    for i=self.CPparameter.startNumber,self.CPparameter.endNumber do
        self:cl_addSelect(0,self.CPidx[i],true)
    end
    self:cl_CP_refreshCP()
end

function MAC.cl_CP_getClearedData(self)
    self.CPdata = {}
    self.CPidx = {}
    self.CPparameter = {startNumber=1,endNumber=1}
    for k,v in pairs(self.effectTableData)do
        if not v.cleanFlag then
            self.CPdata[#self.CPdata+1] = v
            self.CPidx[#self.CPidx+1] = k
        end
    end
    self.CPparameter.startNumber = 1
    self.CPparameter.endNumber = #self.CPidx
end

function MAC.cl_CP_checkFormattedEditStr(self,data)
    if type(data)~="table" then return 8 end
    if data.cleanFlag == nil then return 1 end
    if not pcall(function() sm.color.new(data.color) end) then return 2 end
    if not pcall(function() local t=CE.effectUUIDList[data.id][data.state] end) or (CE.effectUUIDList[data.id][data.state]==nil) then return 3 end
    if not pcall(function() sm.vec3.new(data.offsetPosition.x,data.offsetPosition.y,data.offsetPosition.z) end) then return 4 end
    if not pcall(function() sm.quat.new(data.offsetRotation.x,data.offsetRotation.y,data.offsetRotation.z,data.offsetRotation.w) end) then return 5 end
    if not pcall(function() sm.vec3.new(data.scale.x,data.scale.y,data.scale.z) end) then return 6 end
    if data.state ~= "origin" and data.state ~= "glow" then return 7 end
    return 0
end

function MAC.cl_CP_onEditTextChanged(self,editBox,text)
    local newData
    local legalText = pcall(function() newData = sm.json.parseJsonString(text) end)
    if legalText and self:cl_CP_checkFormattedEditStr(newData) == 0 then
        local i = self.editDataIdx 
        self:cl_setEffect(
            i,
            newData.id,
            sm.vec3.new(newData.offsetPosition.x,newData.offsetPosition.y,newData.offsetPosition.z),
            sm.quat.new(newData.offsetRotation.x,newData.offsetRotation.y,newData.offsetRotation.z,newData.offsetRotation.w),
            sm.color.new(newData.color),
            sm.vec3.new(newData.scale.x,newData.scale.y,newData.scale.z),
            newData.cleanFlag,
            newData.state,
            true -- 是否开启操作记录
        )
    end
    self:cl_CP_refreshCP()
end

function MAC.cl_CP_onEditTextAccepted(self,editBox,text)
    print("test")
end

function MAC.cl_CP_escEdit(self)
    self.gui:setVisible("EditPopup",false)
end

function MAC.cl_CP_onHideMAG(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    local vIdx = self.controlPadStartIdx + buttonId - 1
    vIdx = self.CPidx[vIdx]
    local isSelected = self.selectedMAGData[vIdx]
    local operateEfct = {}
    if isSelected then
        local slData,slEfct = self:cl_getSelectedAplqData()
        operateEfct = slEfct
        for k,v in pairs(self.selectedMAGData)do
            MACP:addAction(k,13,{})
        end
    else
        operateEfct[0] = self.effectTable[vIdx]
        MACP:addAction(vIdx,13,{})
    end
    for k,vEfct in pairs(operateEfct)do
        if vEfct:isPlaying() then
            vEfct:stop()
        else
            vEfct:start()
        end
    end
    self:cl_CP_refreshCP()
end

function MAC.cl_CP_onEditMAG(self,button)
    self.gui:setVisible("EditPopup",true)
    local buttonId = tonumber(button:match("(%d+)"))
    local vIdx = self.controlPadStartIdx + buttonId - 1
    local v = self.CPdata[vIdx]
    local vStr = sm.json.writeJsonString(v)
    vStr = vStr:gsub(",",",\n")
    vStr = vStr:gsub("{","{\n")
    vStr = vStr:gsub("}","\n}")
    self.editDataIdx = self.CPidx[vIdx]
    self.gui:setText("EditText",vStr)
end

function MAC.cl_CP_onSelectMAG(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    local vIdx = self.controlPadStartIdx + buttonId - 1
    vIdx = self.CPidx[vIdx]
    self:cl_addSelect(0,vIdx,true)
    self.gui:setButtonState(button,self.selectedMAGData[vIdx])
end

function MAC.cl_CP_scrollDown(self,sliderPos)
    self.controlPadStartIdx = (#self.CPdata-11) - (sliderPos+1) + 1
    self:cl_CP_refreshCP()
end

function MAC.cl_CP_refreshCP(self)
    for i=1,12 do
        local vIdx = i+self.controlPadStartIdx-1
        if self.CPdata[vIdx] == nil then return end
        local curUUID = CE.effectUUIDList[self.CPdata[vIdx].id][self.CPdata[vIdx].state]
        self.gui:setIconImage("TypeI"..tostring(i),curUUID)
        self.gui:setText("TypeButton"..tostring(i),tostring(vIdx))
        self.gui:setText("Text"..tostring(i),"#FFFFFF[#"..self.CPdata[vIdx].color:sub(1,6).."@#FFFFFF]"..sm.shape.getShapeTitle(curUUID))
        self.gui:setButtonState("TypeButton"..tostring(i),self.selectedMAGData[self.CPidx[vIdx]])
        self.gui:setButtonState("Display"..tostring(i),self.effectTable[self.CPidx[vIdx]]:isPlaying())
    end
    self.gui:setSliderPosition("ScrollDown",(#self.CPdata-11) - (self.controlPadStartIdx-1) - 1)
end

function MAC.cl_CP_onUpMAC(self,button)
    if self.controlPadStartIdx <= 1 then return end
    self.controlPadStartIdx = self.controlPadStartIdx - 1
    self:cl_CP_refreshCP()
end

function MAC.cl_CP_onDownMAC(self,button)
    if self.controlPadStartIdx >= #self.CPdata - 11 then return end
    self.controlPadStartIdx = self.controlPadStartIdx + 1
    self:cl_CP_refreshCP()
end

function MAC.cl_CP_clearSelect(self,button)
    self:cl_clearSelect()
    self:cl_CP_refreshCP()
end

function MAC.client_onClose(self)
    if self.gui then
        self.gui:close()
        self.gui:destroy()
        self.gui = nil
    end
    self:changeCurrentEffect(false)
end