require 'Utils'

local weakKeysMt = {__mode = 'k'}
local constructorMap = {}
setmetatable(constructorMap, weakKeysMt)
local privateMap = {}
setmetatable(privateMap, weakKeysMt)
local classMap = {}
setmetatable(classMap, weakKeysMt)

local function getStackFunction(n)
	return debug.getinfo(n+2, 'f').func
end

function Class(arg)
	local parent = arg.parent
	local constructor = arg.constructor or (function()end)
	
	--create class
	local class = {}
	
	--add constructor to class functions
	classMap[constructor] = class
	
	--inheritance
	if type(parent)=='table' then
		if #parent==0 then --single inheritance
			if not constructorMap[parent] then
				error('parent is not a class', 2)
			end
			parent = {parent} --make a list of parents (unitary)
		else --multiple inheritance
			for i,p in ipairs(parent) do
				if not constructorMap[p] then
					error('parent #' .. i .. ' is not a class', 2)
				end
			end
			--parent is already a list in this case
		end
	else --no inheritance
		if type(parent)=='nil' then
			parent = {} --make a list of parents (empty)
		else
			error('parent is not a class', 2)
		end
	end
	
	local classMt = {
		__metatable = false,
		__newindex = function(class, key, value)
			if type(value)=='function' then
				classMap[value] = class
			end
			rawset(class, key, value)
		end,
		__index = function(class, key)
			--if method is not on the class, search on it's parents
			for i,p in ipairs(parent) do
				local method = p[key]
				if method then
					return method
				end
			end
		end,
	}
	
	--constructor
	local objectMt = {
		__metatable = false,
		__newindex = function(object, key, value)
			local privateObject = privateMap[object]
			--check if modification is happening inside a class method
			local f = getStackFunction(1)
			local classF = classMap[f]
			if classF and classMap[privateObject][classF] then --inside the class
				if type(class[key])=='function' then --method
					error("'" .. key .. "' is a method and can't be overwritten", 2)
				else --attribute
					rawset(privateObject, key, value)
				end
			else --outside the class
				error("'" .. key .. "' can only be modified within class methods", 2)
			end
		end,
		__index = function(object, key)
			local privateObject = privateMap[object]
			if type(class[key])=='function' then --method
				return class[key]
			else --attribute
				--check if access is happening inside a class method
				local f = getStackFunction(1)
				local classF = classMap[f]
				if classF and classMap[privateObject][classF] then --inside the class
					local value = rawget(privateObject, key)
					if value==nil then
						value = rawget(class, key)
					end
					return value
				else --outside the class
					error("'" .. key .. "' can only be accessed within class methods", 2)
				end
			end
		end,
	}
	function classMt:__call(...)
		--create object and private object
		local object = {}
		setmetatable(object, objectMt)
		local privateObject = {}
		privateMap[object] = privateObject
		classMap[privateObject] = {}
		
		--call parents constructors
		for i,p in ipairs(parent) do
			classMap[privateObject][p] = true
			constructorMap[p](object, ...)
		end
		
		classMap[privateObject][class] = true
		constructor(object, ...)
		return object
	end
	
	setmetatable(class, classMt)
	constructorMap[class] = function(object, ...)
		local privateObject = privateMap[object]
		for i,p in ipairs(parent) do
			classMap[privateObject][p] = true
			constructorMap[p](object, ...)
		end
		
		constructor(object, ...)
	end
	return class
end

function isClass(object, class)
	return not not classMap[privateMap[object]][class]
end






















