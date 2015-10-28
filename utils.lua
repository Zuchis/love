function random(...)
	local arg = {...}
	if #arg==1 and type(arg[1])=='table' then
		arg = arg[1]
	end
	return arg[math.random(#arg)]
end

function assertArgs(...)
	arg = {...}
	local functionName = debug.getinfo(2, 'n').name
	local maxI = 1
	while arg[maxI] do
		maxI = maxI+2
	end
	maxI = (maxI-1)/2
	
	for i=1,maxI do
		local expected = arg[2*i-1]
		local provided = type(arg[2*i])
		if type(expected)=='table' then
			local typeName = ''
			local errorFlag = true
			local datatype
			for j=1,#expected-1 do
				datatype = expected[j]
				if datatype==provided then
					errorFlag = false
					break
				end
				typeName = typeName .. datatype .. '/'
			end
			
			datatype = expected[#expected]
			if datatype==provided then
				errorFlag = false
			end
			typeName = typeName .. datatype
			
			if errorFlag then
				error("bad argument #" .. i .. " to '" .. functionName .. "' (" .. typeName .. " expected, got " .. provided .. ")", 3)
			end
		else --string
			if expected~=provided then
				error("bad argument #" .. i .. " to '" .. functionName .. "' (" .. expected .. " expected, got " .. provided .. ")", 3)
			end
		end
	end
end

function tostring2(elem)
	if type(elem)=='string' then
		return "'" .. elem .. "'"
	else
		return tostring(elem)
	end
end

function print_r(elem, hist, tabs)
	hist = hist or {}
	tabs = tabs or 0
	if type(elem)~='table' then
		print(tostring2(elem))
	else
		if not hist[elem] then
			hist[elem] = true
			print(tostring2(elem) .. ' {')
			tabs = tabs + 1
			for i,e in pairs(elem) do
				io.write(string.rep('\t', tabs) .. '[' .. tostring2(i) .. '] ')
				print_r(e, hist, tabs)
			end
			tabs = tabs - 1
			print(string.rep('\t', tabs) .. '}')
		else
			print(tostring2(elem) .. ' {...}')
		end
	end
end

function copy_r(t, hist)
	hist = hist or {}
	if type(t)~='table' then
		return t
	end
	if hist[t] then
		return hist[t]
	end
	local c = {}
	setmetatable(c, getmetatable(t))
	hist[t] = c
	for i,value in pairs(t) do
		c[i] = copy_r(value, hist)
	end
	return c
end

function compare_r(elem1, elem2, hist)
	hist = hist or {}
	if type(elem1)~=type(elem2) then
		return false
	end
	if type(elem1)~='table' then
		return elem1==elem2
	end
	hist[elem1] = hist[elem1] or {}
	if not hist[elem1][elem2] then
		hist[elem1][elem2] = true
		for i, e1 in pairs(elem1) do
			local e2 = elem2[i]
			if not compare_r(e1, e2, hist) then
				return false
			end
		end
		for i, e2 in pairs(elem2) do
			local e1 = elem1[i]
			if not compare_r(e1, e2, hist) then
				return false
			end
		end
	end
	return true
end

function make_backup(t, hist)
	hist = hist or {}
	if type(t)~='table' then
		return t
	end
	if hist[t] then
		return hist[t]
	end
	local c = {
		address = t,
		data = {},
	}
	setmetatable(c.data, getmetatable(t))
	hist[t] = c
	for i,value in pairs(t) do
		c.data[i] = make_backup(value, hist)
	end
	return c
end

function restore_backup(t, hist)
	hist = hist or {}
	if type(t)~='table' then
		return t
	end
	if hist[t] then
		return hist[t]
	end
	local c = t.address
	hist[t] = c
	for i in pairs(c) do
		c[i] = nil
	end
	for i,value in pairs(t.data) do
		c[i] = restore_backup(value, hist)
	end
	return c
end

function scandir(directory)
    local i = 0
    local t = {}
    local tmp = io.popen('dir /B "'..directory..'"')
    for filename in tmp:lines() do
        i = i + 1
        t[i] = filename
    end
    tmp:close()
    return t
end

function print_v(v)
	for i,vi in ipairs(v) do
		io.write(tostring(vi) .. ' ')
	end
	print()
end

function print_m(m)
	for i,mi in ipairs(m) do
		print_v(mi)
	end
end
