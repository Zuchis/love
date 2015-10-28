require 'Utils'
require 'RDCA'
require 'parameters'

Application = {}
Application.__index = Application

function Application:new(arg)
	local self = {}
	setmetatable(self, Application)
	
	self.debugMode = false --TODO remove this from the code
	self.speed = 1 --update:draw iterations proportion
	self.iteration = 1
	
	self:setInputFile(arg.inputFile)
	self:setTotalIterations(arg.totalDays)
	self:setBackgroundImage()
	self:setGrid()
	self:setBackgroundQuad()
	self:setTileSize()
	self:convertParameters()
	self:setInitialSetup()
	
	self:createRDCA()
	
	return self
end

function Application:update(dt)
	for k=1,self.speed do
		--hold space to pause program
		if love.keyboard.isDown(" ") then
			return
		end
		
		--last iteration
		if self.iteration==self.totalIterations then
			--save result
			self.rdca:save('result.png', 'result.dat')
			return true
		end
		
		self.rdca:update()
	
		self.iteration = self.iteration + 1
		io.write('\rDay: ' .. math.ceil(self.iteration/itDay))
	end
end

function Application:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(self.background.image, self.background.quad, 0, 0, 0, self.tileSize, self.tileSize)
	self.rdca:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.print(' Day: ' .. math.ceil(self.iteration/itDay) .. '/' .. self.totalIterations/itDay, 0, 0)
end

function Application:setInputFile(filename)
	io.write('Filename: ')
	if filename then
		print(filename)
	else
		filename = io.read()
	end
	self.inputFile = io.open(filename, 'r')
	if not self.inputFile then
		error('File not found.')
	end
end

function Application:setTotalIterations(totalDays)
	io.write('Total Days: ')
	if totalDays then
		self.totalIterations = tonumber(totalDays)
		print(totalDays)
	else
		self.totalIterations = tonumber(io.read())
	end
	self.totalIterations = self.totalIterations*itDay
end

function Application:setBackgroundImage()
	local imageName = self.inputFile:read()
	local imageFile = io.open(imageName, 'rb')
	local newImageName = '__img' .. imageName:sub(-4)
	local newImageFile = io.open(newImageName, 'wb')
	newImageFile:write(imageFile:read('*a'))
	imageFile:close()
	newImageFile:close()
	self.background = {
		image = love.graphics.newImage(newImageName),
	}
	os.remove(newImageName)
end

function Application:setGrid()
	local inputFile = self.inputFile
	self.grid = {
		x1 = inputFile:read('*n'),
		y1 = inputFile:read('*n'),
		x2 = inputFile:read('*n'),
		y2 = inputFile:read('*n'),
	}
	self.grid.nx = self.grid.x2 - self.grid.x1 --number of cells horizontally
	self.grid.ny = self.grid.y2 - self.grid.y1 --number of cells vertically
end

function Application:setBackgroundQuad()
	self.background.quad = love.graphics.newQuad(self.grid.x1, self.grid.y1, self.grid.nx, self.grid.ny, self.background.image:getDimensions())
end

function Application:setTileSize()
	local _,_,flags = love.window.getMode()
    local width, height = love.window.getDesktopDimensions(flags.display)
	self.tileSize = math.floor(math.min(height*0.8/self.grid.ny, width*0.8/self.grid.nx))
	love.window.setMode(self.tileSize*self.grid.nx, self.tileSize*self.grid.ny)
end

function Application:convertParameters()
	local itHour = itDay/24
	local itSec = itHour/3600
	
	--cm^2/s -> pixel^2/it
	DO = DO/(itSec*cmPixel*cmPixel)
	DG = DG/(itSec*cmPixel*cmPixel)
	DB = DB/(itSec*cmPixel*cmPixel)
	
	--s^-1 -> it^-1
	Opc = Opc/itSec
	Oqc = Oqc/itSec
	Gpc = Gpc/itSec
	Gqc = Gqc/itSec
	Bpc = Bpc/itSec
	Bqc = Bqc/itSec
	
	--mol/l/s -> amount/s
	Okv = Okv/itSec
	Gkv = Gkv/itSec
	Bkv = Bkv/itSec
	
	--mol/l -> amount
	Op = Op
	Oq = Oq
	Gt = Gt
	Ba = Ba
	Bv = Bv
	O0 = O0
	G0 = G0
	B0 = B0
	
	--h -> it
	Td = Td*itHour
	Ta = Ta*itHour
	Tn = Tn*itHour
end

function Application:setInitialSetup()
	--initial cells
	self.initialSetup = {}
	for i=1,self.grid.ny do
		self.initialSetup[i] = {}
		for j=1,self.grid.nx do
			local value = self.inputFile:read(1)
			if value=='\n' then
				value = self.inputFile:read(1)
			end
			value = tonumber(value)
			if value~=2 then
				self.initialSetup[i][j] = {
					--Cellular Automaton
					state = {
						kind = value==1 and 'proliferative' or 'empty',
						division = math.random(0,Td),
						angiogenesis = math.random(0,Ta),
						necrosis = math.random(0,Tn),
					},
					--Reaction-Diffusion
					substance = {
						{initial=O0, min=0, max=O0}, --oxygen
						{initial=G0, min=0, max=G0}, --glucose
						{initial=B0, min=0}, --bevacizumab
					},
				}
			end
		end
	end
	self.inputFile:close()
	
	--change inner core to necrotic and count empty neighbors
	for i=1,self.grid.ny do
		for j=1,self.grid.nx do
			if self.initialSetup[i][j] then
				local state = self.initialSetup[i][j].state
				state.emptyCount =
					(i>1 and self.initialSetup[i-1][j] and self.initialSetup[i-1][j].state.kind=='empty' and 1 or 0) +
					(i<self.grid.ny and self.initialSetup[i+1][j] and self.initialSetup[i+1][j].state.kind=='empty' and 1 or 0) +
					(j>0 and self.initialSetup[i][j-1] and self.initialSetup[i][j-1].state.kind=='empty' and 1 or 0) +
					(j<self.grid.nx and self.initialSetup[i][j+1] and self.initialSetup[i][j+1].state.kind=='empty' and 1 or 0)
				if state.kind=='proliferative' then
					if state.emptyCount==0 then
						state.kind = 'necrotic'
					end
				end
			end
		end
	end
	
	--initial vessels
	local amount = math.floor((self.grid.ny*self.grid.nx)^0.5/3)
	for i=1,amount do
		local x = math.random(1,self.grid.nx)
		local y = math.random(1,self.grid.ny)
		if self.initialSetup[y][x] then
			self.initialSetup[y][x].state.kind = 'vessel'
		end
	end
end

function Application:createRDCA()
	self.rdca = RDCA:new{
		nx = self.grid.nx,
		ny = self.grid.ny,
		tileSize = self.tileSize,
		cell = self.initialSetup,
		speedProportion = itRDCA,
		model = dofile('model.lua'),
		callback = dofile('callbacks.lua'),
	}
end























