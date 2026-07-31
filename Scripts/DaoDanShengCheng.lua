DDSC = class(nil)
DDSC.maxParentCount = 1
DDSC.connectionInput = sm.interactable.connectionType.logic
DDSC.poseWeightCount = 1

function DDSC.server_onCreate(self)
	self.targetUuid = "a6d16258-887c-44aa-8e8c-5609b83e2911"                      --激活器的uuid
	--self.savedMissile = self.storage:load()
	--print(self.savedMissile)
end

function DDSC.server_saveMissile(self,targetShapes)
	self.savedMissile=targetShapes
	--[[for k,v in pairs(targetShapes) do
		self.savedMissile[tostring(v.id)] = {
		shape = v
		uuid = v.uuid
		SzAxis = v.zAxis
		SxAxis = v.xAxis
		SlocalPosition = v:getLocalPosition()
	}
		--v.destroyPart(v,0)
		print(self.savedMissile[k].uuid)
	end]]--
	self.storage:save(self.savedMissile)
	print("已保存")
end

function DDSC.server_onFixedUpdate( self,dt)
	
	 self.input = self.interactable:getSingleParent()
	if self.input then
		if self.input:isActive() then
			if self.savedMissile == nil then return end
			for k,v in pairs(self.savedMissile)do
				--print(v)
				local spawnPosition = self.shape.at*2+v.localPosition
				self.shape.body.createPart(self.shape.body,v.uuid,spawnPosition,v.zAxis,v.xAxis,false)
				
				print("生成")
			end
		end
	end
end

function DDSC.client_onInteract(self, character, state)
	if not state then return end
	local creationBodies = self.shape.body.getCreationBodies(self.shape.body)           --得到整个作品的所有body
	local targetBodyIndex=-1                           --要保存的目标body（即导弹）
	for k,v in pairs(creationBodies)do    --在每个body中搜索每个shape查找激活器所在的body
		for i,j in pairs(v:getShapes())do   --i为shape的编号 ； j为shape的table
			if tostring(j.uuid) == self.targetUuid then
				targetBodyIndex = k   --记录下激活器所在body的编号
			end
		end
	end
	if targetBodyIndex == -1 then return end --判断是否含激活器
	--print(creationBodies[targetBodyIndex])
	local targetShapes = creationBodies[targetBodyIndex].getShapes(creationBodies[targetBodyIndex])
	
	self.network:sendToServer("server_saveMissile", targetShapes)
end