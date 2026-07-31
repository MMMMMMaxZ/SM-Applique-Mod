--- MaxZ666 --- 
--- MAG的手控部件 --- 
MAGMo = class( nil )

function MAGMo.client_onCreate(self)
    if localPlayer == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_localPlayer.lua")
    end
    if MLines == nil then
        dofile("$MOD_DATA/Scripts/crystalTech/_MLines.lua")
        MLines:init()
    end
    self.name = "MAGmover"
    if self.tool:isLocal()then
        sm.gui.chatMessage(MLines.lines["Mtools"][MLines.currentLanguage]["MoverDes"])
    end
end

function MAGMo.client_onEquip(self,ani)
    
end

function MAGMo.client_onEquippedUpdate(self,leftState,rightState)
    if localPlayer.state.deviceOn == false then
        sm.gui.setInteractionText(
            "",
            MLines.lines["Mtools"][MLines.currentLanguage]["deviceOn"],
            ""
        )
        return false,false
    end


    sm.gui.setInteractionText(
        sm.gui.getKeyBinding( "Create", true ).."["..MLines.lines["Mtools"][MLines.currentLanguage]["MoverMode"..MACP.moverMode].."]"..MLines.lines["Mtools"][MLines.currentLanguage]["MoverLc"],
        sm.gui.getKeyBinding( "Attack", true )..MLines.lines["Mtools"][MLines.currentLanguage]["MoverRc"],
        ""
    )
    sm.gui.setInteractionText(
        sm.gui.getKeyBinding( "NextCreateRotation", true )..MLines.lines["Mtools"][MLines.currentLanguage]["MoverQ"],
        sm.gui.getKeyBinding( "Reload", true )..MLines.lines["Mtools"][MLines.currentLanguage]["MoverR"],
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

function MAGMo.client_onToggle(self)
    localPlayer.tool = self.name
    localPlayer.state.q = true
    return true
end

function MAGMo.client_onReload(self)
    localPlayer.tool = self.name
    localPlayer.state.r = true
    return true
end