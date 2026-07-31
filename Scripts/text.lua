text = class( nil )

function text.client_onInteract(self,character,state)
	if state then
		self.gui = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/Describe.layout')
		self.gui:open()
	end
end

function text.client_canInteract(self)
	sm.gui.setInteractionText("",sm.gui.getKeyBinding("Use"),"查看定制方式")
	return true
end