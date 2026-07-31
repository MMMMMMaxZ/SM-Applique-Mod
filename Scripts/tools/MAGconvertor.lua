--- MaxZ666 --- 
--- MAG的手控部件 --- 
MAGCo = class( nil )

function MAGCo.client_onCreate(self)
    if localPlayer == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_localPlayer.lua")
    end
    if MLines == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_MLines.lua")
        MLines:init()
    end
    self.name = "MAGconvertor"
    if self.tool:isLocal()then
        sm.gui.chatMessage(MLines.lines["Mtools"][MLines.currentLanguage]["ConvertorDes"])
    end
end

function MAGCo.client_onEquip(self,ani)
    
end

function MAGCo.client_onEquippedUpdate(self,leftState,rightState)
    if localPlayer.state.deviceOn == false then
        sm.gui.setInteractionText(
            "",
            MLines.lines["Mtools"][MLines.currentLanguage]["deviceOn"],
            ""
        )
        return false,false
    end


    sm.gui.setInteractionText(
        sm.gui.getKeyBinding( "Create", true )..MLines.lines["Mtools"][MLines.currentLanguage]["ConvertorLc"],
        sm.gui.getKeyBinding( "Attack", true )..MLines.lines["Mtools"][MLines.currentLanguage]["ConvertorRc"],
        ""
    )

    if leftState == 2 then
        localPlayer.state.left = true
    end
    if rightState == 2 then
        localPlayer.state.right = true
    end
    localPlayer.tool = self.name
    return true,true
end

function MAGCo.client_onToggle(self)
    localPlayer.tool = self.name
    localPlayer.state.q = true
    return true
end

function MAGCo.client_onReload(self)
    localPlayer.tool = self.name
    localPlayer.state.r = true
    return true
end