--M piston controller
MPC = class(nil)
MPC.maxParentCount = -1
MPC.maxChildCount = -1
MPC.connectionInput = sm.interactable.connectionType.logic+sm.interactable.connectionType.power
MPC.connectionOutput = sm.interactable.connectionType.piston
MPC.Ctable = {
    [true] = 1,
    [false] = 0
}

function MPC.server_onFixedUpdate(self,dt)
    local parents = self.interactable:getParents()
    local power = 0
    for idx,parent in pairs(parents)do
        if parent.power ~= 0 then 
            power = power + self.Ctable[parent.active]*parent.power 
        else
            power = power + self.Ctable[parent.active]
        end
    end
    power = power
    local children = self.interactable:getJoints()
    for idx,child in pairs(children)do
        child:setTargetLength(power,(power+1)*3)
    end
end