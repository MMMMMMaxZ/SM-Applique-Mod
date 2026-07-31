-- MAXZ666 --
MACP = class(nil)

function MACP.init(self)
    print("MACP initiating---")

    if CE == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_createEffects.lua") -- self:create_aplq()
        CE:init()
    end

    self.currentScale = {x=10,y=10,z=10,mirror=1}
    self.currentRotation = 36
    self.currentEffectId = 1
    --self.maxEffectId = #CE.effectList -- 不知道干嘛用的，忘了，反正没有用到的地方
    self.currentEfctPlyr = 1 -- 贴花类别，由于最初是假设这个仍然是投稿制的，就将类别命名为玩家，按玩家来分贴花
    self.currentEfctPlus = 0

    self.aplqListStartIdx = 0

    self.localPlayer = sm.localPlayer.getPlayer()

    self.scaleTable = {
        0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,
        1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,
        2.0,2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,
        3.0,3.1,3.2,3.3,3.4,3.5,3.6,3.7,3.8,3.9,
        4.0,4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,
        5.0
    }--0.255
    self.rotaTable = { 5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,150,155,160,165,170,175,180,185,190,195,200,205,210,215,220,225,230,235,240,245,250,255,260,265,270,275,280,285,290,295,300,305,310,315,320,325,330,335,340,345,350,355,360 }
    self.rotaTable[0]=0

    self.alignTable = {100000,100,10,5}
    self.curAlign = 1

    self.curAplqStateTable = {origin = "glow",glow = "origin"}
    self.curAplqState = "origin" -- origin , glow

    self.fixNormalFlag = false
    self.lastNormal = sm.vec3.new(0,0,0)

    self.placeOffP = sm.vec3.new(0,0,0) -- 用于按住旋转
    self.placeOffR = sm.quat.new(0,0,0,0)
    self.rotationInitialPoint = sm.vec3.new(0,0,0)

    self.mirrorVecSt = sm.vec3.new(0,0,0) -- 用于对称
    self.mirrorVecEd = sm.vec3.new(0,0,0)
    self.mirrorVecMid = sm.vec3.new(0,0,0)
    self.mirrorVecNor = sm.vec3.new(1,0,0)

    self.fileName = "Name"
    self.fileType = 1 -- 1->creation ; 2->customAplq

    self.MACfiles = CE:getMACfiles()
    self.selectedMAC = "Null"
    self.selectedMACData = {}
    self.selectedMACEfct = {}
    self.selectMode = 0 -- 0:offP找最近,1:cos找最近（可选到浮空的贴花）
    self.selectOffsetData = {}
    self.selectAxisRota = nil -- 用于识别选择的贴花是否轴相似，用于编辑工具的相对轴功能
    self.selectAxisRotaIdx = 0 -- 刷新selectAxisRota

    self.moverStartPoint = sm.vec3.new(0,0,0)
    self.moverMultiT = 1 -- 锁轴时的dir向量放大倍率
    self.rotatBasicVec = nil

    self.colorList = {
        {"eeeeeeff", "f5f071ff", "cbf66fff", "68ff88ff", "7eededff", "4c6fe3ff", "ae79f0ff", "ee7bf0ff", "f06767ff", "eeaf5cff"},
        {"7f7f7fff", "e2db13ff", "a0ea00ff", "19e753ff", "2ce6e6ff", "0a3ee2ff", "7514edff", "cf11d2ff", "d02525ff", "df7f00ff"},
        {"4a4a4aff", "817c00ff", "577d07ff", "0e8031ff", "118787ff", "0f2e91ff", "500aa6ff", "720a74ff", "7c0000ff", "673b00ff"},
        {"222222ff", "323000ff", "375000ff", "064023ff", "0a4444ff", "0a1d5aff", "35086cff", "520653ff", "560202ff", "472800ff"},

        {"eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff", "eeeeeeff","eeeeeeff"}
    }

    self.currentColor = sm.color.new("000000ff")
    self.chosenColorType = 2
    self.chosenColorIdx = 1

    self.moverType = 0 -- 0 1 2 3 4 5 6
    self.moverTypeTable = {"free",{"x"},{"y"},{"z"},{"x","y"},{"y","z"},{"x","z"}}
    self.moverTypeAxisActive = {
        {x=false,y=false,z=false},
        {x=true,y=false,z=false},
        {x=false,y=true,z=false},
        {x=false,y=false,z=true},
        {x=true,y=true,z=false},
        {x=false,y=true,z=true},
        {x=true,y=false,z=true}
    }
    self.axis = {
        x = sm.vec3.new(1,0,0),
        y = sm.vec3.new(0,1,0),
        z = sm.vec3.new(0,0,1)
    }
    self.offsetAxisFlag = false
    self.offsetAxisRotation = nil
    self.offsetAxisRotationReverse = nil
    self.moverMode = 0 -- 0:mover 1:rotate 2:scale

    self.actionTable = {}
    self.actionTableIdx = 0
    self.actionTableSize = 500

    self.lastTool = "null"
end

function MACP.clear_action_table(self)
    for k,act in pairs(self.actionTable)do
        self.actionTable[k] = nil
    end
    self.actionTableIdx = 0
end

function MACP.addAction(self,idx,actionType,parameters)--int,int,{}
    local curHash = actionType.."_"..MAC:tableToString(parameters)
    local lstHash
    if self.actionTable[self.actionTableIdx]~=nil then
        lstHash = self.actionTable[self.actionTableIdx].actionType.."_"..MAC:tableToString(self.actionTable[self.actionTableIdx].parameters)
    else
        lstHash = "Null"
    end
    if curHash == lstHash then --相同操作合并id
        local idxList = self.actionTable[self.actionTableIdx].idxs
        idxList[#idxList+1] = idx
    else
        self.actionTableIdx = (self.actionTableIdx+1)%self.actionTableSize
        self.actionTable[self.actionTableIdx] = {
            idxs = {idx},
            actionType = actionType,
            parameters = parameters
        }
    end
    --print(self.actionTable)
end

--[[
0 -> place
1 -> delete
2 -> add select
3 -> del select
4 -> set mirror
5 -> move
6 -> rotate
7 -> scale
8 -> color
9 -> resetID&state
10 -> resetPosition
11 -> resetRotation
12 -> resetScale
13 -> hideAplq
--------------------
parameters::
    place = {},
    delete = {},
    add_select = {},
    del_select = {}, -- flag
    set_mirror = {Cx,Cy,Cz,Nx,Ny,Nz},
    move = {x,y,z},
    rotate = {x1,y1,z1,x2,y2,z2},
    scale = {type,x,y,z,o={x,y,z,w}} or {type,T},
    color = {c1,c2}
    reset = {id1,state1,id2,state2}
    resetPosition = {x1,y1,z1,x2,y2,z2}
    resetRotation = {x1,y1,z1,w1,x2,y2,z2,w2}
    resetScale = {x1,y1,z1,x2,y2,z2}
    hideAplq = {}
]]

function MACP.getLastAction(self)
    return self.actionTable[self.actionTableIdx]
end

function MACP.undoAction(self,MAC)
    local cpyAction = self.actionTable[self.actionTableIdx]
    if cpyAction == nil then return end
    local idxs = cpyAction.idxs
    local parameters = cpyAction.parameters

    self.fullActionInverse[cpyAction.actionType](self,idxs,parameters,MAC,false)
    
    self.actionTableIdx = (self.actionTableIdx+self.actionTableSize-1)%self.actionTableSize
end

function MACP.redoAction(self,MAC)
    self.actionTableIdx = (self.actionTableIdx+1)%self.actionTableSize
    local cpyAction = self.actionTable[self.actionTableIdx]
    if cpyAction == nil then
        self.actionTableIdx = (self.actionTableIdx+self.actionTableSize-1)%self.actionTableSize
        return
    end
    local idxs = cpyAction.idxs
    local parameters = cpyAction.parameters
    
    self.fullActionInverse[cpyAction.actionType](self,idxs,parameters,MAC,true)
end

MACP.fullActionInverse = {
    [0] = function(self,idxs,parameters,MAC,ivFlag)
        for k,v in pairs(idxs)do
            if not ivFlag then
                MAC.effectTableData[v].cleanFlag = true
                MAC.effectTable[v]:stop()
            else
                MAC.effectTableData[v].cleanFlag = false
                if not MAC.effectTable[v]:isPlaying() then MAC.effectTable[v]:start() end
            end
            
        end
    end,
    [1] = function(self,idxs,parameters,MAC,ivFlag)
        for k,v in pairs(idxs)do
            if ivFlag then
                MAC.effectTableData[v].cleanFlag = true
                MAC.effectTable[v]:stop()
            else
                MAC.effectTableData[v].cleanFlag = false
                if not MAC.effectTable[v]:isPlaying() then MAC.effectTable[v]:start() end
            end
        end
    end,
    [2] = function(self,idxs,parameters,MAC,ivFlag)
        for k,v in pairs(idxs)do
            MAC:cl_addSelect(0,v,false)
        end
    end,
    [3] = function(self,idxs,parameters,MAC,ivFlag)
        for k,v in pairs(idxs)do
            MAC:cl_addSelect(0,v,false)
        end
    end,
    [4] = function(self,idxs,parameters,MAC,ivFlag)
        local centerP = sm.vec3.new(parameters.Cx,parameters.Cy,parameters.Cz)
        local centerN = sm.vec3.new(parameters.Nx,parameters.Ny,parameters.Nz)
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        SS:setMirror(slEfct,slData,centerP,centerN)
        -- 重新绘制选择框
        MAC:cl_redrawSelectedBox(slData)
    end,
    [5] = function (self,idxs,parameters,MAC,ivFlag)
        local inversedMove = sm.vec3.new(-parameters.x,-parameters.y,-parameters.z)
        if ivFlag then inversedMove = inversedMove*-1 end
        for k,v in pairs(idxs)do
            local vP = sm.vec3.new(MAC.effectTableData[v].offsetPosition.x,MAC.effectTableData[v].offsetPosition.y,MAC.effectTableData[v].offsetPosition.z)+inversedMove
            MAC.effectTableData[v].offsetPosition = {x=vP.x,y=vP.y,z=vP.z}
            MAC.effectTable[v]:setOffsetPosition(vP)
        end
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        -- 重新绘制选择框
        MAC:cl_redrawSelectedBox(slData)
    end,
    [6] = function (self,idxs,parameters,MAC,ivFlag)
        local inverseV1 = sm.vec3.new(parameters.x1,parameters.y1,parameters.z1)
        local inverseV2 = sm.vec3.new(parameters.x2,parameters.y2,parameters.z2)
        local moverStartPoint = sm.vec3.new(parameters.x3,parameters.y3,parameters.z3)
        local rota = sm.vec3.getRotation(inverseV2,inverseV1)
        if ivFlag then rota = sm.quat.inverse(rota) end
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        for k,v in pairs(slData)do
            local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
            local vR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            vR = rota*vR
            vP = rota*(vP-moverStartPoint) + moverStartPoint
            v.offsetPosition = {x=vP.x,y=vP.y,z=vP.z}
            v.offsetRotation = {x=vR.x,y=vR.y,z=vR.z,w=vR.w}
            slEfct[k]:setOffsetPosition(vP)
            slEfct[k]:setOffsetRotation(vR)
        end
        -- 重新绘制选择框
        MAC:cl_redrawSelectedBox(slData)
    end,
    [7] = function (self,idxs,parameters,MAC,ivFlag)
        if parameters.type == "axis" then
            local oRota = sm.quat.new(parameters.o.x,parameters.o.y,parameters.o.z,parameters.o.w)
            local Ox,Oy,Oz = oRota*sm.vec3.new(1,0,0),oRota*sm.vec3.new(0,1,0),oRota*sm.vec3.new(0,0,1)
            local deltaS = sm.vec3.new(parameters.x,parameters.y,parameters.z)
            local deltaST = {x=parameters.x,y=parameters.y,z=parameters.z}
            local slData,slEfct = MAC:cl_getSelectedAplqData()
            local SelectedCenterP,SScaleP = SS:getSelectedBox(slData,false)
            for k,v in pairs(idxs)do
                local vData,vEfct = MAC.effectTableData[v],MAC.effectTable[v]
                local NRota = sm.quat.new(vData.offsetRotation.x,vData.offsetRotation.y,vData.offsetRotation.z,vData.offsetRotation.w)
                local Nx,Ny,Nz = NRota*sm.vec3.new(1,0,0),NRota*sm.vec3.new(0,1,0),NRota*sm.vec3.new(0,0,1)
                local NdeltaS = nil
                local NdeltaST = {}
                local vScale = sm.vec3.new(vData.scale.x,vData.scale.y,vData.scale.z)
                for Nk,NAxis in pairs({x=Nx,y=Ny,z=Nz})do
                    for Ok,OAxis in pairs({x=Ox,y=Oy,z=Oz})do
                        if math.abs(NAxis:dot(OAxis))>=1-0.05 then
                            NdeltaST[Nk] = deltaST[Ok]
                        end
                    end
                end
                NdeltaS = sm.vec3.new(1+NdeltaST.x,1+NdeltaST.y,1+NdeltaST.z)
                local opScale = NdeltaS
                if not ivFlag then opScale = sm.vec3.new(1/opScale.x,1/opScale.y,1/opScale.z) end
                local vP = sm.vec3.new(vData.offsetPosition.x,vData.offsetPosition.y,vData.offsetPosition.z)
                local oP = vP - SelectedCenterP
                local ONX,ONY,ONZ = oP:dot(Nx),oP:dot(Ny),oP:dot(Nz)
                ONX = ONX*opScale.x
                ONY = ONY*opScale.y
                ONZ = ONZ*opScale.z
                local newOffsetP = SelectedCenterP + Nx*ONX + Ny*ONY + Nz*ONZ
                if not ivFlag then vScale = vScale / NdeltaS
                else vScale = vScale * NdeltaS end
                vData.scale = {x = vScale.x,y = vScale.y,z = vScale.z}
                vData.offsetPosition = {x = newOffsetP.x,y = newOffsetP.y,z = newOffsetP.z}
                vEfct:setScale(vScale*0.255)
                vEfct:setOffsetPosition(newOffsetP)
            end
            -- 重新绘制选择框
            MAC:cl_redrawSelectedBox(slData)
        else
            local deltaS = parameters.T
            local slData,slEfct = {},{}
            for k,v in pairs(idxs)do
                slData[#slData+1] = MAC.effectTableData[v]
                slEfct[#slEfct+1] = MAC.effectTable[v]
            end
            local SelectedCenterP,SScaleP = SS:getSelectedBox(slData,false)
            for k,v in pairs(slData)do
                local newScale = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
                local originP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
                local delta = originP - SelectedCenterP
                if not ivFlag then
                    newScale = newScale/(deltaS*4)
                    delta = delta/(deltaS*4)
                else
                    newScale = newScale*(deltaS*4)
                    delta = delta*(deltaS*4)
                end
                local newOffsetP = SelectedCenterP + delta
                v.scale = {x=newScale.x,y=newScale.y,z=newScale.z}
                v.offsetPosition = {x=newOffsetP.x,y=newOffsetP.y,z=newOffsetP.z}
                slEfct[k]:setOffsetPosition(newOffsetP)
                slEfct[k]:setScale(newScale*0.255)
            end
            -- 重新绘制选择框
            MAC:cl_redrawSelectedBox(slData)
        end
    end,
    [8] = function (self,idxs,parameters,MAC,ivFlag)
        local oldColor = parameters.c1
        if ivFlag then oldColor = parameters.c2 end
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        for k,v in pairs(slData)do
            v.color = oldColor
            slEfct[k]:setParameter("color",sm.color.new(oldColor))
        end
    end,
    [9] = function(self,idxs,parameters,MAC,ivFlag)
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        local type
        if ivFlag then type=2 else type=1 end
        for k,v in pairs(slData)do
            v.id = parameters["id"..type]
            v.state = parameters["state"..type]
            slEfct[k]:setParameter("uuid",CE.effectUUIDList[v.id][v.state])
            slEfct[k]:stop()
            slEfct[k]:start()
        end
    end,
    [10] = function(self,idxs,parameters,MAC,ivFlag)
        local oldP = sm.vec3.new( parameters.x1,parameters.y1,parameters.z1)
        if ivFlag then oldP = sm.vec3.new( parameters.x2,parameters.y2,parameters.z2) end
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        for k,v in pairs(slData)do
            v.offsetPosition = {x=oldP.x,y=oldP.y,z=oldP.z}
            slEfct[k]:setOffsetPosition(oldP)
        end
    end,
    [11] = function( self,idxs,parameters,MAC,ivFlag)
        local oldR = sm.quat.new( parameters.x1,parameters.y1,parameters.z1,parameters.w1)
        if ivFlag then oldR = sm.quat.new( parameters.x2,parameters.y2,parameters.z2,parameters.w2) end
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        for k,v in pairs(slData)do
            v.offsetRotation = {x=oldR.x,y=oldR.y,z=oldR.z,w=oldR.w}
            slEfct[k]:setOffsetRotation(oldR)
        end
    end,
    [12] = function( self,idxs,parameters,MAC,ivFlag)
        local oldS = sm.vec3.new( parameters.x1,parameters.y1,parameters.z1)
        if ivFlag then oldS = sm.vec3.new( parameters.x2,parameters.y2,parameters.z2) end
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        for k,v in pairs(slData)do
            v.scale = {x=oldS.x,y=oldS.y,z=oldS.z}
            slEfct[k]:setScale(oldS*0.255)
        end
    end,
    [13] = function( self,idxs,parameters,MAC,ivFlag)
        local slData,slEfct = {},{}
        for k,v in pairs(idxs)do
            slData[#slData+1] = MAC.effectTableData[v]
            slEfct[#slEfct+1] = MAC.effectTable[v]
        end
        for k,v in pairs(slData)do
            if slEfct[k]:isPlaying() then
                slEfct[k]:stop()
            else
                slEfct[k]:start()
            end
        end
    end
}