Cell = {}
Cell.__index = Cell

function Cell:new(arg)
	local self = {
		state = arg.state,
		substance = {},
		substanceMin = {},
		substanceMax = {},
		variation = {},
		neighbor = {},
		neighState = {},
	}
	for i,v in ipairs(arg.substance) do
		self.substance[i] = v.initial or 0
		self.substanceMin[i] = v.min or 0
		self.substanceMax[i] = v.max or 1/0
	end
	self.newState = copy_r(self.state),
	setmetatable(self, Cell)
	return self
end

function Cell:draw(colorCallback, i, j, tileSize)
	love.graphics.setColor(colorCallback(self.state, self.neighState, self.substance))
	love.graphics.rectangle("fill", (j-1)*tileSize, (i-1)*tileSize, tileSize, tileSize)
end

function Cell:addNeighbor(neighCell)
	self.neighbor[#self.neighbor+1] = neighCell
end

function Cell:calculateVariations(equation)
	local substance = self.substance
	local neighbor = self.neighbor
	local neighborQt = #neighbor
	local state = self.state
	local variation = self.variation
	
	for k=1,#substance do
		--diffusion
		local diffusion = -substance[k] * neighborQt
		for i=1,#neighbor do
			diffusion = diffusion + neighbor[i].substance[k]
		end
		
		--reaction-diffusion
		variation[k] = equation[k](state, diffusion, substance)
	end
end

function Cell:updateSubstances(deltaTime)
	local subsTmp
	local substance = self.substance
	local variation = self.variation
	local smin = self.substanceMin
	local smax = self.substanceMax
	
	for k=1,#substance do
		subsTmp = substance[k] + variation[k]*deltaTime
		if subsTmp<smin[k] then
			subsTmp = smin[k]
		elseif subsTmp>smax[k] then
			subsTmp = smax[k]
		end
		substance[k] = subsTmp
	end
end

function Cell:calculateNewState(rule)
	local neighbor = self.neighbor
	local neighState = self.neighState
	
	for i=1,#neighbor do
		neighState[i] = neighbor[i].state
	end
	self.newState = rule(self.state, neighState, self.substance, self.newState)
end

function Cell:updateState()
	self.state, self.newState = self.newState, self.state
end

function Cell:encode(encodeCallback)
	local neighbor = self.neighbor
	local neighState = self.neighState
	for i=1,#neighbor do
		neighState[i] = neighbor[i].state
	end
	return encodeCallback(self.state, neighState, self.substance)
end



















