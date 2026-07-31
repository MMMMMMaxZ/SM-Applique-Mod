-- MAXZ666
-- for customized appliques back up!
CBK = class(nil)

CBK.colorRed = "FFA600FF"

function CBK.server_onCreate(self)
    if CE == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_createEffects.lua") -- self:create_aplq()
        CE:init()
    end
    self:sv_onCheckStorage()

    self.shape:setColor(sm.color.new(self.colorRed))
end

function CBK.sv_onCheckStorage(self)
    self.st = self.storage:load()
    if self.st == nil then
        self:sv_onBackUp()
        return
    end
    local st_List = self.st["_List"]
    local local_List = CE:getMACfiles()
    if #st_List<=#local_List then -- 当前增添了贴花 / 当前有修改覆盖 / 当前没变化
        
    else -- 当前贴花数少于所储存的
        local deltaList = self:getDeltaList(st_List) -- 修改的列表
        self:sv_onSaveMissedMAC(deltaList)
        
    end
    self:sv_onBackUp()
end

function CBK.getDeltaList(self,svList) -- 获得差异列表
    local tempList = {}
    local oupList = {}
    for k,v in pairs(svList)do
        local vType = CE:MACexists(v)
        if vType == 0 or vType == CurrentModType then -- 即使存在也重存一遍，用来覆盖成新版
            tempList[v] = true
        end
    end
    for k,v in pairs(tempList)do
        oupList[#oupList+1]=k
    end
    return oupList
end

function CBK.sv_onBackUp(self)
    -- local MainList = CE:fileOpen(1,"__List") -- Main
    -- local LogoList = CE:fileOpen(2,"__List") -- Logo
    local saveData = {}
    saveData["_List"] = CE:getMACfiles()
    for k,v in pairs(saveData["_List"])do
        saveData[v] = self:sv_onOpenMAC(v)
    end
    self.storage:save(saveData)
end

function CBK.sv_onOpenMAC(self,fileName)
    local oup
    local MacType = CE:MACexists(fileName)
    oup = CE:fileOpen(MacType,fileName)
    return oup
end

function CBK.sv_onSaveMissedMAC(self,deltaList)
    local newList = CE:fileOpen(CurrentModType,"__List")
    local existedList = {}
    for k,v in pairs(newList)do existedList[v]=true end
    for k,v in pairs(deltaList)do
        if existedList[v] == nil then newList[#newList+1] = v end
        local curMAC = self.st[v]
        sm.json.save(curMAC,"$CONTENT_"..FileMODuuid.."/Appliques/"..v..".json")
    end
    sm.json.save(newList,"$CONTENT_"..FileMODuuid.."/Appliques/__List.json")
end

--------------------------------------------client-----------------------------------------
function CBK.client_onCreate(self)
    if MLines == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_MLines.lua")
        MLines:init()
    end
end
function CBK.client_canInteract(self,character)
    sm.gui.setInteractionText(MLines.lines["CBK"][MLines.currentLanguage][1])
	return false
end