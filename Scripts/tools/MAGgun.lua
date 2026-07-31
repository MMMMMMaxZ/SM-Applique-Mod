--- MaxZ666 --- 
--- MAG的手控部件 --- 
MAGG = class( nil )

function MAGG.client_onCreate(self)
    if localPlayer == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_localPlayer.lua")
    end
    if MLines == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_MLines.lua")
        MLines:init()
    end
    self.name = "MAGgun"
    if self.tool:isLocal()then
        sm.gui.chatMessage(MLines.lines["Mtools"][MLines.currentLanguage]["GunDes"])
    end
end

function MAGG.client_onEquip(self,ani)
    
end

function MAGG.client_onEquippedUpdate(self,leftState,rightState)
    if localPlayer.state.deviceOn == false then
        sm.gui.setInteractionText(
            "",
            MLines.lines["Mtools"][MLines.currentLanguage]["deviceOn"],
            ""
        )
        return false,false
    end

    sm.gui.setInteractionText(
        sm.gui.getKeyBinding( "Create", true )..MLines.lines["Mtools"][MLines.currentLanguage]["GunLc"],
        sm.gui.getKeyBinding( "Attack", true )..MLines.lines["Mtools"][MLines.currentLanguage]["GunRc"],
        ""
    )
    if localPlayer.state.sameBody == true then
        sm.gui.setInteractionText(
            sm.gui.getKeyBinding( "NextCreateRotation", true )..MLines.lines["Mtools"][MLines.currentLanguage]["GunQ"],
            sm.gui.getKeyBinding( "Reload", true )..MLines.lines["Mtools"][MLines.currentLanguage]["GunR"],
            ""
        )
    else
        sm.gui.setInteractionText(
            "",
            MLines.lines["Mtools"][MLines.currentLanguage]["GunWarning"],
            ""
        )
        
    end
    

    if leftState == 2 then
        localPlayer.state.left = true
    end
    if rightState == 2 then
        localPlayer.state.right = true
    end
    localPlayer.tool = self.name
    return true,true
end

function MAGG.client_onToggle(self)
    localPlayer.tool = self.name
    localPlayer.state.q = true
    return true
end

function MAGG.client_onReload(self)
    localPlayer.tool = self.name
    localPlayer.state.r = true
    return true
end