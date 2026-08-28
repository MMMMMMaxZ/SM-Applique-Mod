--- MaxZ666 --- 
--- MAG的手控部件 --- 
MAGP = class( nil )

dofile("$MOD_DATA/Scripts/crystalTech/_dofile.lua")

function MAGP.client_onCreate(self)
    self.name = "MAGpainter"
    if self.tool:isLocal()then
        sm.gui.chatMessage(MLines.lines["Mtools"][MLines.currentLanguage]["PaintDes"])
    end
end

function MAGP.client_onEquip(self,ani)
    
end

function MAGP.client_onEquippedUpdate(self,leftState,rightState)
    if localPlayer.state.deviceOn == false then
        sm.gui.setInteractionText(
            "",
            MLines.lines["Mtools"][MLines.currentLanguage]["deviceOn"],
            ""
        )
        return false,false
    end

    local hitColorHexStr = MACP.currentColor:getHexStr()
    hitColorHexStr = hitColorHexStr:sub(1,6)
    sm.gui.setInteractionText(
        sm.gui.getKeyBinding( "Create", true )..MLines.lines["Mtools"][MLines.currentLanguage]["PaintLc"],
        sm.gui.getKeyBinding( "Attack", true )..MLines.lines["Mtools"][MLines.currentLanguage]["PaintRc"].." ( #"..hitColorHexStr.."##"..hitColorHexStr.."#ffffff ) ",
        ""
    )
    sm.gui.setInteractionText(
        "",
        sm.gui.getKeyBinding( "NextCreateRotation", true )..MLines.lines["Mtools"][MLines.currentLanguage]["PaintQ"],
        ""
    )

    if leftState == 1 then
        localPlayer.state.left = true
    end
    if rightState == 2 then
        localPlayer.state.right = true
    end
    localPlayer.tool = self.name
    return true,true
end

function MAGP.client_onToggle(self)
    localPlayer.tool = self.name
    localPlayer.state.q = true
    return true
end