ChangeColor = class(nil)
ChangeColor.poseWeightCount = 3

----------------------------------server
function ChangeColor.server_onCreate( self )
	self.colorIndex = self.storage:load()
	if self.colorIndex == nil then
		self.colorIndex = 1
		self.storage:save(self.colorIndex)
	end
end

function ChangeColor.server_ColorChange(self)
	self.storage:save(self.colorIndex)
end
-------------------------------------client

function ChangeColor.client_onInteract(self,chatacter,state)
	if not state then return end
		if self.colorIndex == 4 then
			self.colorIndex = 1
		else
			self.colorIndex = self.colorIndex + 1
		end
	newColor = self.colorIndex
	print(newColor)
	self.interactable:setPoseWeight(0,newColor)
	self.network:sendToServer("server_ColorChange")
end

function ChangeColor.client_canInteract(self)
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "切换 Change")
	return true
end