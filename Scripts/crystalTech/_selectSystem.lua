-- MAXZ666
-- 用于选择贴花
SS = class(nil)

function SS.init(self)
    print("SS initiating---")
end

function SS.getSelectedBox(self,selectedMACData,pointsFlag)
    if #selectedMACData == 0 then return nil end
    local centerP
    local scaleP
    local sP = selectedMACData[1].offsetPosition -- 起点
    local axisX = {Max=sP.x,Min=sP.x}
    local axisY = {Max=sP.y,Min=sP.y}
    local axisZ = {Max=sP.z,Min=sP.z}
    local allSwaps = {
        sm.vec3.new(1,0.2,1),
        sm.vec3.new(1,0.2,-1),
        sm.vec3.new(1,-0.2,1),
        sm.vec3.new(1,-0.2,-1),
        sm.vec3.new(-1,0.2,1),
        sm.vec3.new(-1,0.2,-1),
        sm.vec3.new(-1,-0.2,1),
        sm.vec3.new(-1,-0.2,-1),
    }
    local partFix = sm.vec3.new(1,5,1)
    local pointList = {}
    for k,v in pairs(selectedMACData)do
        local PoffP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
        if not pointsFlag then -- 添加贴花所在立方的八个顶点
            local PoffR = sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
            local PoffS = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
            local isPart = v.id<0
            for k,v in pairs(allSwaps)do
                local tS = PoffS*v*0.13
                if isPart then tS = tS*partFix end
                tS = PoffR*tS
                pointList[#pointList+1] = PoffP + tS
            end
        else
            pointList[#pointList+1] = PoffP
        end
        
    end
    for k,v in pairs(pointList)do
        local PoffP = v
        axisX.Max = math.max( axisX.Max,PoffP.x )
        axisX.Min = math.min( axisX.Min,PoffP.x )
        axisY.Max = math.max( axisY.Max,PoffP.y )
        axisY.Min = math.min( axisY.Min,PoffP.y )
        axisZ.Max = math.max( axisZ.Max,PoffP.z )
        axisZ.Min = math.min( axisZ.Min,PoffP.z )
    end
    centerP = sm.vec3.new((axisX.Max+axisX.Min)/2,(axisY.Max+axisY.Min)/2,(axisZ.Max+axisZ.Min)/2)
    scaleP = (sm.vec3.new(axisX.Max,axisY.Max,axisZ.Max)-centerP)*2
    if scaleP.x<=0.1 then scaleP=scaleP+sm.vec3.new(0.1,0,0) end
    if scaleP.y<=0.1 then scaleP=scaleP+sm.vec3.new(0,0.1,0) end
    if scaleP.z<=0.1 then scaleP=scaleP+sm.vec3.new(0,0,0.1) end
    return centerP,scaleP
end

function SS.getFreeSelectApplique(self,centerP,scaleP,efctTableData) -- rtn selected appliques' indexes
    if efctTableData == nil then return end
    local oupT = {}
    local st = centerP - scaleP/2
    local ed = centerP + scaleP/2
    for k,v in pairs(efctTableData)do
        local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
        if st.x<vP.x and st.y<vP.y and st.z<vP.z and vP.x<ed.x and vP.y<ed.y and vP.z<ed.z and v.cleanFlag == false then
            oupT[#oupT+1] = k
        end
    end
    return oupT
end

function SS.setMirrorDot(self,dotP,centerP,centerN)
    centerN = centerN:normalize() -- in case
    local vP = sm.vec3.new(dotP.x,dotP.y,dotP.z)
    local dis = centerP-vP
    local dot = dis:dot(centerN)
    local pls = centerN*dot*2
    vP = vP+pls
    return vP
end

function SS.setMirror(self,efctTable,efctTableData,centerP,centerN,actionFlag)--position and normal
    centerN = centerN:normalize() -- in case
    local fixR1 = sm.vec3.getRotation(sm.vec3.new(1,0,0),centerN)
    local fixR2 = sm.vec3.getRotation(centerN,sm.vec3.new(1,0,0))
    if efctTable == nil then return end
    for k,v in pairs(efctTableData)do
        local vP = sm.vec3.new(v.offsetPosition.x,v.offsetPosition.y,v.offsetPosition.z)
        local vR = fixR2*sm.quat.new(v.offsetRotation.x,v.offsetRotation.y,v.offsetRotation.z,v.offsetRotation.w)
        vR = fixR1*sm.quat.new(vR.x*-1,vR.y,vR.z,vR.w*-1) -- 突然想到旋转的翻转可不可以和拉伸scale一样
        local vS = sm.vec3.new(v.scale.x,v.scale.y,v.scale.z)
        -- process position
        vP = self:setMirrorDot(vP,centerP,centerN)
        vS = vS*sm.vec3.new(-1,1,1) -- 反转x轴
        v.offsetPosition = {x=vP.x,y=vP.y,z=vP.z}
        v.offsetRotation = {x=vR.x,y=vR.y,z=vR.z,w=vR.w}
        v.scale = {x=vS.x,y=vS.y,z=vS.z}
        efctTable[k]:setOffsetPosition(vP)
        efctTable[k]:setOffsetRotation(vR)
        efctTable[k]:setScale(vS*0.255)
        if actionFlag then MACP:addAction(k,4,{Cx=centerP.x,Cy=centerP.y,Cz=centerP.z,Nx=centerN.x,Ny=centerN.y,Nz=centerN.z}) end
    end
end