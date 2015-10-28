require 'Utils'

local root = '../../'

local background, id, initialGrid, finalGrid, initialQuad, finalQuad, nx, ny, diff, cell, outputFile, metricFile, sizeDiff, finalSizeMetric, finalPosMetric, runs
function love.load()
	math.randomseed(os.time())
	love.graphics.setBackgroundColor(127, 127, 127)
	id = 1
	--[[
	diff = {
		{x=324, y=0}, --1
		{x=224, y=-2}, --2
		{x=277, y=0}, --3
		{x=174, y=1}, --4
		{x=335, y=0}, --5
		{x=269, y=1}, --6
		{x=220, y=-2}, --7
		{x=202, y=0}, --8
		{x=132, y=3}, --9
		{x=94, y=0}, --10
		{x=52, y=-1}, --11
		{x=57, y=0}, --12
		{x=100, y=0}, --13
		{x=181, y=4}, --14
	}
	]]
	cell = {
		input = {},
		expected = {},
		output = {},
	}
	runs = 0
	metricFile = io.open(root .. 'result/metric.txt', 'w')
	sizeDiff = 0
	finalSizeMetric = 0
	finalPosMetric = 0
end

function love.update(dt)
	--open output file
	outputFile = io.open(root .. 'result/' .. id .. '.dat', 'r')
	if not outputFile then
		return
	end
	runs = runs + 1
	
	--open input file
	local inputFile = io.open(root .. 'data/' .. id .. '.dat', 'r')
	
	--open expected file
	local expectedFile = io.open(root .. 'data/expected/' .. id .. '.dat', 'r')
	expectedFile:read() --image path
	
	--open background image
	local imageName = inputFile:read()
	local imageFile = io.open(root .. imageName, 'rb')
	local newImageName = '__img' .. imageName:sub(-4)
	local newImageFile = io.open(newImageName, 'wb')
	newImageFile:write(imageFile:read('*a'))
	imageFile:close()
	newImageFile:close()
	background = love.graphics.newImage(newImageName)
	os.remove(newImageName)
	
	--set grids
	initialGrid = {
		x1 = inputFile:read('*n'),
		y1 = inputFile:read('*n'),
		x2 = inputFile:read('*n'),
		y2 = inputFile:read('*n'),
	}
	finalGrid = {
		x1 = expectedFile:read('*n'),
		y1 = expectedFile:read('*n'),
		x2 = expectedFile:read('*n'),
		y2 = expectedFile:read('*n'),
	}
	nx = initialGrid.x2 - initialGrid.x1 --number of cells horizontally
	ny = initialGrid.y2 - initialGrid.y1 --number of cells vertically
	love.window.setMode(nx*3, ny)
	
	--set quads
	initialQuad = love.graphics.newQuad(initialGrid.x1, initialGrid.y1, nx, ny, background:getDimensions())
	finalQuad = love.graphics.newQuad(finalGrid.x1, finalGrid.y1, nx, ny, background:getDimensions())
	
	--set cells
	local expectedTumor = 0
	local outputTumor = 0
	local intersection = 0
	local union = 0
	for i=1,ny do
		cell.input[i] = {}
		cell.expected[i] = {}
		cell.output[i] = {}
		for j=1,nx do
			local inputValue = inputFile:read(1)
			local expectedValue = expectedFile:read(1)
			local outputValue = outputFile:read(1)
			if inputValue=='\n' then
				inputValue = inputFile:read(1)
				expectedValue = expectedFile:read(1)
				outputValue = outputFile:read(1)
			end
			inputValue = tonumber(inputValue)
			expectedValue = tonumber(expectedValue)
			outputValue = tonumber(outputValue)
			cell.input[i][j] = inputValue
			cell.expected[i][j] = expectedValue
			cell.output[i][j] = outputValue
			
			--counts for metrics
			if outputValue==1 then
				outputTumor = outputTumor + 1
			end
			if expectedValue==1 then
				expectedTumor = expectedTumor + 1
			end
			if outputValue==1 and expectedValue==1 then
				intersection = intersection + 1
			end
			if outputValue==1 or expectedValue==1 then
				union = union + 1
			end
		end
	end
	inputFile:close()
	expectedFile:close()
	outputFile:close()
	
	--calculate metrics
	local sizeMetric, posMetric
	if union>0 then
		sizeMetric = math.min(outputTumor, expectedTumor)/math.max(outputTumor, expectedTumor)
		posMetric = intersection/union
	else
		sizeMetric = 1
		posMetric = 1
	end
	metricFile:write('Case ' .. id .. '\n')
	metricFile:write('Size: ' .. sizeMetric .. '\n')
	metricFile:write('Pos:  ' .. posMetric .. '\n')
	metricFile:write('\n')
	sizeDiff = sizeDiff + (outputTumor - expectedTumor)/union
	finalSizeMetric = finalSizeMetric + sizeMetric
	finalPosMetric = finalPosMetric + posMetric
end

function love.draw()
	if not outputFile then
		id = id + 1
		if id>14 then
			metricFile:write('Conclusion:\n')
			metricFile:write('Runs: ' .. runs .. '\n')
			metricFile:write('Size: ' .. finalSizeMetric/runs .. '\n')
			metricFile:write('Pos: ' .. finalPosMetric/runs .. '\n')
			if sizeDiff>0 then
				metricFile:write('Bigger than expected (factor=' .. sizeDiff/runs .. ')\n')
			else
				metricFile:write('Smaller than expected. Factor=' .. sizeDiff/runs .. ')\n')
			end
			metricFile:close()
			love.event.quit()
		end
		return
	end
	
	--draw
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background, initialQuad)
	love.graphics.draw(background, finalQuad, nx)
	love.graphics.draw(background, finalQuad, nx*2)
	love.graphics.setColor(255, 0, 0, 127)
	for i=1,ny do
		for j=1,nx do
			if cell.input[i][j]==1 then
				love.graphics.point(j, i)
			end
			if cell.expected[i][j]==1 then
				love.graphics.point(j + nx, i)
			end
			if cell.output[i][j]==1 then
				love.graphics.point(j + nx*2, i)
			end
		end
	end
	
	--save
	local imageName = id .. '.png'
	local path = root .. 'result/' .. imageName
	if os.rename(path, path) then
		os.remove(path)
	end
	local screenshot = love.graphics.newScreenshot()
	screenshot:encode(imageName)
	os.rename(love.filesystem.getAppdataDirectory() .. '/LOVE/' .. love.filesystem.getIdentity() .. '/' .. imageName, path)
	
	id = id + 1
end




























