local callback = {}

function callback.color(state, neighState, substance)
	local O = substance[1]
	local G = substance[2]
	local B = substance[3]
	local kind = state and state.kind
	local r,g,b,a
	local debugMode = love.keyboard.isDown('lctrl') or love.keyboard.isDown("1") or love.keyboard.isDown("2") or love.keyboard.isDown("3") or love.keyboard.isDown("4")
	if debugMode then
		--CA
		if kind=='vessel' then
			r = 255
			g = 255
			b = 0
		elseif kind=='proliferative' then
			r = 255
			g = 255
			b = 255
		elseif kind=='quiescent' then
			r = 170
			g = 170
			b = 170
		elseif kind=='necrotic' then
			r = 0
			g = 0
			b = 0
		else
			--RD
			if love.keyboard.isDown("1") then
				r = O/O0*255
				g = 0
				b = 0
			elseif love.keyboard.isDown("2") then
				r = 0
				g = G/G0*255
				b = 0
			elseif love.keyboard.isDown("3") then
				r = 0
				g = 0
				b = B/Bv*255
			elseif love.keyboard.isDown("4") then
				r = O/O0*255
				g = G/G0*255
				b = B/Bv*255
			else
				r = 0
				g = 0
				b = 0
				a = 0
			end
			r = math.min(r, 255)
			g = math.min(g, 255)
			b = math.min(b, 255)
		end
	else --non-debugMode
		local kind2 = neighState[1] and neighState[1].kind
		if kind=='proliferative' or kind=='quiescent' or kind=='necrotic' or
		(kind=='vessel' and (kind2=='proliferative' or kind2=='quiescent' or kind2=='necrotic')) then
			r = 255
			g = 0
			b = 0
			a = 127
		else
			r = 0
			g = 0
			b = 0
			a = 0
		end
	end
	return r,g,b,a
end

function callback.encode(state, neighState, substance)
	local kind = state and state.kind
	local kind2 = neighState[1] and neighState[1].kind
	if kind=='proliferative' or kind=='quiescent' or kind=='necrotic' or
	(kind=='vessel' and (kind2=='proliferative' or kind2=='quiescent' or kind2=='necrotic')) then
		return '1'
	else
		return '0'
	end
end

return callback
