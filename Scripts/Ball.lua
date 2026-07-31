Ball = class(nil)
Ball.maxParentCount = 1 
Ball.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power

function GetGridPosition(position)
	local GridLevel = 10
	local x = position.x
	local y = position.y
	local z = position.z
	return sm.vec3.new(math.floor(x/GridLevel),math.floor(y/GridLevel),math.floor(z/GridLevel))
end

function Reload_explotion(self)
	if sm.physics.explode_reloaded then return false end
	local Origin_Explode = sm.physics.explode

	sm.physics.explode_reloaded = true
	sm.physics.explode = function (position, level, destructionRadius, impulseRadius, magnitude, effectName, ignoreShape, parameters)
		local GridPosition = GetGridPosition(position)
		print(GridPosition)
		if GridExist(GridPosition) then return end
		print("explode")
		Origin_Explode(position, level, destructionRadius, impulseRadius, magnitude, effectName, ignoreShape, parameters)
	end

	return true
end

function CreateProtectSystem()
	if Reload_explotion() then
		ProtectSystem = {}
	end
	ProtectSystem.dirPls = {
		sm.vec3.new(-1, -1, -1),
		sm.vec3.new(-1, -1, 0),
		sm.vec3.new(-1, -1, 1),
		sm.vec3.new(-1, 0, -1),
		sm.vec3.new(-1, 0, 0),
		sm.vec3.new(-1, 0, 1),
		sm.vec3.new(-1, 1, -1),
		sm.vec3.new(-1, 1, 0),
		sm.vec3.new(-1, 1, 1),
		sm.vec3.new(0, -1, -1),
		sm.vec3.new(0, -1, 0),
		sm.vec3.new(0, -1, 1),
		sm.vec3.new(0, 0, -1),
		sm.vec3.new(0, 0, 0),
		sm.vec3.new(0, 0, 1),
		sm.vec3.new(0, 1, -1),
		sm.vec3.new(0, 1, 0),
		sm.vec3.new(0, 1, 1),
		sm.vec3.new(1, -1, -1),
		sm.vec3.new(1, -1, 0),
		sm.vec3.new(1, -1, 1),
		sm.vec3.new(1, 0, -1),
		sm.vec3.new(1, 0, 0),
		sm.vec3.new(1, 0, 1),
		sm.vec3.new(1, 1, -1),
		sm.vec3.new(1, 1, 0),
		sm.vec3.new(1, 1, 1),
	}
	ProtectSystem.Grid = {}
	ProtectSystem.worldBanFlag = false
end

function ListEmpty(list)
for k,v in pairs(list)do
	return false
end
return true
end

function GridAdd(GP) -- GridPosition
	local x=GP.x
	local y=GP.y
	local z=GP.z
	if ProtectSystem.Grid[x]==nil then ProtectSystem.Grid[x]={} end
	if ProtectSystem.Grid[x][y]==nil then ProtectSystem.Grid[x][y]={} end
	if ProtectSystem.Grid[x][y][z]==nil then
		print(GridExist(GP))
		ProtectSystem.Grid[x][y][z]=1
	else
		ProtectSystem.Grid[x][y][z]=ProtectSystem.Grid[x][y][z] + 1
	end
	print(x,y,z,"add",GridExist(GP))
end

function GridDel(GP) -- GridPosition
	local x=GP.x
	local y=GP.y
	local z=GP.z
	if ProtectSystem.Grid[x]==nil then return end
	if ProtectSystem.Grid[x][y]==nil then return end
	if ProtectSystem.Grid[x][y][z]~=nil then
		ProtectSystem.Grid[x][y][z] = ProtectSystem.Grid[x][y][z]-1
		if ProtectSystem.Grid[x][y][z]==0 then ProtectSystem.Grid[x][y][z]=nil end
	end
	if ListEmpty(ProtectSystem.Grid[x][y]) then ProtectSystem.Grid[x][y]=nil end
	if ListEmpty(ProtectSystem.Grid[x]) then ProtectSystem.Grid[x]=nil end
end

function GridExist(GP)
	if ProtectSystem.worldBanFlag then return true end
	local x=GP.x
	local y=GP.y
	local z=GP.z
	if ProtectSystem.Grid[x]==nil then return false end
	if ProtectSystem.Grid[x][y]==nil then return false end
	if ProtectSystem.Grid[x][y][z]==nil then return false end
	return true
end

function AddProtectArea(position,isG) -- vec3
	if not isG then position = GetGridPosition(position) end
	for k,v in pairs(ProtectSystem.dirPls)do
		GridAdd( position+v )
	end
end

function DelProtectArea(position,isG) -- vec3
	if not isG then position = GetGridPosition(position) end
	for k,v in pairs(ProtectSystem.dirPls)do
		GridDel( position+v )
	end
end

function Ball.server_onCreate(self)
	CreateProtectSystem()
	self.lastGP = GetGridPosition(self.shape.worldPosition)
	AddProtectArea(self.lastGP,true)
	PrintS()
end

function Ball.server_onFixedUpdate(self,dt)
	local currentGP = GetGridPosition(self.shape.worldPosition)
	if currentGP ~= self.lastGP then
		DelProtectArea(self.lastGP,true)
		AddProtectArea(currentGP,true)
		PrintS()
	end
	self.lastGP = currentGP

	local parent = self.interactable:getSingleParent()
	if parent and parent.active then
		ProtectSystem.worldBanFlag = true
	else
		ProtectSystem.worldBanFlag = false
	end
end

function Ball.server_onDestroy(self)
	ProtectSystem.worldBanFlag = false
	DelProtectArea(self.lastGP,true)
	PrintS()
	print("destroy")
end

function PrintS()
	print("Grid:")
	for k1,v1 in pairs(ProtectSystem.Grid)do
		for k2,v2 in pairs(ProtectSystem.Grid[k1])do
			local lll = {}
			for k3,v3 in pairs(ProtectSystem.Grid[k1][k2])do
				lll[#lll+1] = {k1,k2,k3,ProtectSystem.Grid[k1][k2][k3]}
			end
			print(lll)
		end
		print("\n--")
	end
end