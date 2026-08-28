--MAX666
--用于处理所有贴花列表，因为原版能共用的却被算在自己那

CE = class(nil)

MainMODuuid = "1c626c90-466c-47ec-8927-baf0fa1e7599"
LogoMODuuid = "1d30e24d-2246-4987-9ab3-ce9ba453f062"
MainPath = "$CONTENT_"..MainMODuuid.."/"
LogoPath = "$CONTENT_"..LogoMODuuid.."/"
CurrentModType = 1 -- 1->Main 2->Logo
FileMODuuid = "DATA" -- abandoned
MixMode = {Main = false,Logo = false}
MainMAC = {}
LogoMAC = {}

CE.MMMaxGenerateNewAplqFlag = false

dofile("$MOD_DATA/Scripts/crystalTech/_dofile.lua")

function CE.init(self)
    print("CE initiating---")
    self.effectPlayer = {}
    self.efctPlyrCnt = {}
    self.effectList = {}
    self.effectUUIDList = {}
    self.abandonedList = {
        1,2,3,4,5,6,7,10,11,8,12,13,14
    }
    self.reverseToAbandonedList = {} -- 1,2,3,4,5,6,7,11,0,8,9,10,12,13
    for k,v in pairs(self.abandonedList)do
        self.reverseToAbandonedList[v]=k
    end

    self.partUUIDtoID = {} -- 用于部件贴花化
    self.partIdx = -1
    self.partBoundingBox = {}
    
    self.EfctPlyrListSTR = ""
    self:create_aplq()
    self:setMixMode()
    self:checkUpdate()
end

function CE.addPartUUID(self,uuid) -- uuid是sm.uuid
    local stringUUID = tostring(uuid)
    local partIdx = self.partUUIDtoID[stringUUID]
    if partIdx ~= nil then return false end
    self.partUUIDtoID[stringUUID] = self.partIdx
    self.effectUUIDList[self.partIdx] = {
        origin = uuid,
        glow = uuid
    }
    self.partIdx = self.partIdx - 1
    return true
end

function CE.formatData(self,effectTableData)
    local partUUIDList = {}
    for k,v in pairs(effectTableData)do
        if v.id < 0 then
            partUUIDList["t"..v.id] = tostring(self.effectUUIDList[v.id]["origin"])
        end
    end
    local formattedData = {
        partUUIDList = partUUIDList,
        effectTableData = effectTableData
    }
    return formattedData
end

function CE.sortTable(self,input)
    local oup = {}
    for k,v in pairs(input)do
        local s = tonumber(string.sub(v,1,3))
        oup[s] = v
    end
    return oup
end

function CE.create_efctPlyrListStr(self)
    self.EfctPlyrListSTR = ""
    for k,v in pairs(self.effectPlayer)do
        self.EfctPlyrListSTR = self.EfctPlyrListSTR..v.."\n"
    end
end

function CE.create_aplq(self)
    -- V2 --
    local MACs = sm.json.open("$MOD_DATA/Scripts/MAG_list/MAGs.json")
    local MACs_state = sm.json.open("$MOD_DATA/Scripts/MAG_list/MAGs_state.json")
    local orderedMACs = {}
    local cnt = 0
    for type,names in pairs(MACs)do
        cnt = cnt + 1
        orderedMACs[cnt]=type
    end
    orderedMACs = self:sortTable(orderedMACs)
    cnt = 0
    self.efctPlyrCnt[1]=1
    for i,oType in pairs(orderedMACs)do
        local type = oType -- 贴花类别的名字
        local names = MACs[type] -- 该类型下所有贴花的名字
        cnt = cnt + 1
        self.effectPlayer[cnt]=type
        self.efctPlyrCnt[cnt+1]=#names + self.efctPlyrCnt[cnt]

        -- 先建贴花的总表：uuid, 贴花表
        for k,v in pairs(names)do
            -- gernerate UUID
            self.effectUUIDList[self.efctPlyrCnt[cnt]+k-1] = {
                origin = 0,
                glow = 0
            }

            self.effectList[self.efctPlyrCnt[cnt]+k-1]=v
        end

        -- 判断状态：只有原装贴花还是还有其他（发光）
        local curState = MACs_state[type]

        for k,Stype in pairs(curState) do
            local uuidType
            if Stype == "origin" then
                type = oType
                uuidType = "a"
            elseif Stype == "glow" then
                type = oType.."_glow"
                uuidType = "b"
            end
            --generate renderable

            for k,v in pairs(names)do
                local textureASG
                if i<9 then -- 009之后的asg换成.tga结尾，没有再用aseprite重导出了，直接在转换工具里加了段生成tga的代码，耶
                    textureASG = "$MOD_DATA/Objects/Textures/MAG/"..type.."/"..v.."_asg-export.tga"
                else
                    textureASG = "$MOD_DATA/Objects/Textures/MAG/"..type.."/"..v.."_asg.tga"
                end

                local tempRenderable = {lodList={}}
                tempRenderable["lodList"][1]={
                    mesh = "$MOD_DATA/Objects/Mesh/MAG/testEftFixed.obj",
                    minViewSize = 15,
                    subMeshList = {
                        {
                            custom = {
                                shadow = false
                            },
                            material = "Leaves",
                            textureList = {
                                "$MOD_DATA/Objects/Textures/MAG/_empty-export.tga",
                                textureASG,
                                "$MOD_DATA/Objects/Textures/MAG/_empty-nor.tga"
                            }
                        }
                    }
                }
                if type == "000MaxZ666" then
                    tempRenderable["lodList"][1]["subMeshList"][1]["textureList"][1]="$MOD_DATA/Objects/Textures/MAG/MaxZ666_dif.tga"
                end
                if self.MMMaxGenerateNewAplqFlag then
                    sm.json.save(tempRenderable,"$MOD_DATA/Objects/Renderable/MAG/"..type.."/"..v.."_gn.rend")
                end 
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
                    renderable = "$MOD_DATA/Objects/Renderable/MAG/"..type.."/"..v.."_gn.rend",
                    rotationSet = "Default",
                    showInInventory = false,
                    uuid = ca..cb..cc.."2359"..uuidType.."-1068-4de7-b7a0-a41682e47"..a..b..c
                } 

                self.effectUUIDList[self.efctPlyrCnt[cnt]+k-1][Stype]=sm.uuid.new(ca..cb..cc.."2359"..uuidType.."-1068-4de7-b7a0-a41682e47"..a..b..c)
            end
            if self.MMMaxGenerateNewAplqFlag then
                sm.json.save(tempTable,"$MOD_DATA/Objects/Database/ShapeSets/MAG_"..type.."_gn.json")
            end
        end
    end
    local MACfiles = {"fileOperator"}
    cnt = cnt + 1
    self.effectPlayer[cnt]="Saved保存的图"
    for k,v in pairs(MACfiles)do
        self.effectList[self.efctPlyrCnt[cnt]+k-1]=v
    end
    self.efctPlyrCnt[cnt+1]=self.efctPlyrCnt[cnt]+#MACfiles
    cnt = cnt + 1
    self.effectPlayer[cnt]="End"
    self.effectList[self.efctPlyrCnt[cnt]]="lazer"

    self:create_efctPlyrListStr()
end

function checkMainExists(self)
    local MainExist = sm.json.fileExists(MainPath.."Appliques/__List.json")
end

function checkLogoExists(self)
    local LogoExist = sm.json.fileExists(LogoPath.."Appliques/__List.json")
end

function fileError(self,error)
    print("ERROR : ",error)
end

function CE.setMixMode(self)
    local MAINstatus = xpcall(checkMainExists,fileError)
    local LOGOstatus = xpcall(checkLogoExists,fileError)
    --尝试读取，若没有订阅模组则会报错，所以xpcall来尝试读取

    --接下来就是两个模组都订阅时：①两者都是最新版 ②Main是旧版

    --尝试后，没法跨模组保存，判断时间戳的办法失败了呢
    --那么显然的，我们得搞一个混合模式
    MixMode = {
        Main = MAINstatus,
        Logo = LOGOstatus
    }
end

function CE.getMACfiles(self) -- 获取合并的双列表
    local fullList = {}
    local copyExist = false
    if MixMode.Main then
        MainMAC = sm.json.open("$CONTENT_"..MainMODuuid.."/Appliques/__List.json")
        for k,v in pairs(MainMAC)do
            fullList[#fullList+1] = v
            if v=="MaxCopy_079685746352413" then
                copyExist = true
            end
        end
    end
    if MixMode.Logo then
        LogoMAC = sm.json.open("$CONTENT_"..LogoMODuuid.."/Appliques/__List.json")
        for k,v in pairs(LogoMAC)do
            if not(v=="MaxCopy_079685746352413" and copyExist) then
                fullList[#fullList+1] = v
            end
        end
    end
    return fullList
end

function CE.MACexists(self,name) -- check from MACList
    if name=="MaxCopy_079685746352413" then
        return CurrentModType
    end
    -- return 0->Doesnt exist yet 1->Main , 2-> Logo
    for k,v in pairs(MainMAC)do
        if name == v then
            return 1
        end
    end
    for k,v in pairs(LogoMAC)do
        if name == v then
            return 2
        end
    end
    return 0 
end

function CE.fileExists(self,type,name) -- type->Main or Logo
    local oup = false
    local oupType=type
    if type==1 then -- used MACexists so it wont meet the situation when player didnt subscribe MainMod
        oup = sm.json.fileExists("$CONTENT_"..MainMODuuid.."/Appliques/"..name..".json")
    elseif type==2 then
        oup = sm.json.fileExists("$CONTENT_"..LogoMODuuid.."/Appliques/"..name..".json")
    else -- 0->search both --> 因为第一次补丁导致保存的自定义贴花不再显示在List中
        if MixMode.Main then
            oup = sm.json.fileExists("$CONTENT_"..MainMODuuid.."/Appliques/"..name..".json")
            oupType = 1
        end
        if MixMode.Logo and oup == false then
            oup = sm.json.fileExists("$CONTENT_"..LogoMODuuid.."/Appliques/"..name..".json")
            oupType = 2
        end
    end
    return oup,oupType
end

function CE.fileOpen(self,type,name)
    --if type ~= CurrentModType then return false end -- i hope it'll work
    local openedFile
    if type == 1 then
        openedFile = sm.json.open("$CONTENT_"..MainMODuuid.."/Appliques/"..name..".json")
    else -- type==2
        openedFile = sm.json.open("$CONTENT_"..LogoMODuuid.."/Appliques/"..name..".json")
    end
    return openedFile
end

function CE.checkUpdate()
    local updated = sm.json.fileExists("$MOD_DATA/Max666.zzz")
    if updated then return true end
    local updateContent = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/Describe.layout')
    updateContent:setText("Title",MLines.lines["UpdateContent"][MLines.currentLanguage]["Title"])
    updateContent:setText("Content",MLines.lines["UpdateContent"][MLines.currentLanguage]["Content"])
    updateContent:open()
    sm.json.save({EAT=0.125,GAME=0.25,SLEEP=0.375,REST=0.25,REPEAT=true},"$MOD_DATA/Max666.zzz")
    return false
end