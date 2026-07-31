
----MaxZ666
--dev

JZYX = class(nil)
JZYX.maxParentCount = 1
JZYX.maxChildCount = -1
JZYX.connectionInput = sm.interactable.connectionType.logic
JZYX.connectionOutput = sm.interactable.connectionType.logic


function JZYX.client_onFixedUpdate( self )
	--if self.interactable.active == true  then
		self.playerList = sm.player.getAllPlayers()
			self.input = self.interactable:getSingleParent()
			if self.input then
				self.inputActive = self.input:isActive()
				if self.inputActive == true then
					self.display = true
				else
					self.display = false
				end
			else
				self.display = false
			end

			self.currentPos = sm.shape.getWorldPosition(self.shape)
			nearestDistance = server_getNearestDistance(self.currentPos)
			sm.gui.displayAlertText("nearestDis: ".."#ff0000"..nearestDistance,2.0)
			if nearestDistance < 20.0 then
				self.interactable:setActive(true)
				sm.gui.displayAlertText("<", 2)
			else
				self.interactable:setActive(false)
				sm.gui.displayAlertText(">", 2)
			end
	--end
end

function server_getNearestDistance( position )
	local nearestPlayer = nil
	local nearestDistance = nil
	for id,Player in pairs(sm.player.getAllPlayers()) do
		if Player.character then
			local length2 = sm.vec3.length2(position - Player.character:getWorldPosition())
			if nearestDistance == nil or length2 < nearestDistance then
				nearestDistance = length2
				nearestPlayer = Player
			end
			--print(nearestPlayer)
		end
	end
	return nearestDistance
end
