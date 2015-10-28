require 'Cell'

RDCA = {}
RDCA.__index = RDCA

function RDCA:new(arg)
	local self = {
		tileSize = arg.tileSize,
		speedProportion = arg.speedProportion,
		deltaTime = 1/arg.speedProportion,
		model = arg.model,
		callback = arg.callback,
	}
	setmetatable(self, RDCA)
	
	--create cells
	self.cell = {}
	self.nx = arg.nx
	self.ny = arg.ny
	for i,ci in pairs(arg.cell) do
		self.cell[i] = {}
		for j,cij in pairs(ci) do
			self.cell[i][j] = Cell:new(cij)
		end
	end
	
	--Neumann Neighborhood
	local neighborhood = {
		{dj=-1, di= 0}, --left
		{dj= 0, di=-1}, --up
		{dj= 1, di= 0}, --right
		{dj= 0, di= 1}, --down
	}
	
	--create neighborhood
	for i,ci in pairs(self.cell) do
		for j,cij in pairs(ci) do
			for k,neigh in ipairs(neighborhood) do
				local neighCell = self.cell[i+neigh.di] and self.cell[i+neigh.di][j+neigh.dj]
				if neighCell then
					cij:addNeighbor(neighCell)
				end
			end
		end
	end
	
	return self
end

function RDCA:update()
	local equation = self.model.equation
	local rule = self.model.rule
	local deltaTime = self.deltaTime
	local cell = self.cell
	local nx = self.nx
	local ny = self.ny
	
	--update substances
	for m=1,self.speedProportion do
		for i=1,ny do
			local ci = cell[i]
			for j=1,nx do
				local cij = ci[j]
				if cij then
					cij:calculateVariations(equation)
				end
			end
		end
		
		for i=1,ny do
			local ci = cell[i]
			for j=1,nx do
				local cij = ci[j]
				if cij then
					cij:updateSubstances(deltaTime)
				end
			end
		end
	end
	
	--update cellular automaton
	for i=1,ny do
		local ci = cell[i]
		for j=1,nx do
			local cij = ci[j]
			if cij then
				cij:calculateNewState(rule)
			end
		end
	end
	
	for i=1,ny do
		local ci = cell[i]
		for j=1,nx do
			local cij = ci[j]
			if cij then
				cij:updateState()
			end
		end
	end
end

function RDCA:draw()
	local cell = self.cell
	local colorCallback = self.callback.color
	local tileSize = self.tileSize
	local nx = self.nx
	local ny = self.ny
	
	for i=1,ny do
		local ci = cell[i]
		for j=1,nx do
			local cij = ci[j]
			if cij then
				cij:draw(colorCallback, i, j, tileSize)
			end
		end
	end
end

function RDCA:save(imageName, textName)
	--save final image
	if os.rename(imageName, imageName) then
		os.remove(imageName)
	end
	local screenshot = love.graphics.newScreenshot()
	screenshot:encode(imageName)
	os.rename(love.filesystem.getAppdataDirectory() .. '/LOVE/' .. love.filesystem.getIdentity() .. '/' .. imageName, imageName)
	
	--save final data
	local dataFile = io.open(textName, 'w')
	local emptyTable = {}
	local encodeCallback = self.callback.encode
	for i=1,self.ny do
		local ci = self.cell[i]
		for j=1,self.nx do
			local cij = ci[j]
			dataFile:write(cij and cij:encode(encodeCallback) or encodeCallback(nil, emptyTable, emptyTable))
		end
		dataFile:write('\n')
	end
end


















