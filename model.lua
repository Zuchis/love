require 'auxiliary'
require 'parameters'

local model = {}

--Reaction-Diffusion
model.equation = {
	--oxygen
	function(state, diffusion, substance)
		local O = substance[1]
		local G = substance[2]
		local B = substance[3]
		return DO*diffusion + (isVessel(state) and 1 or 0)*Okv - O*((isProliferative(state) and 1 or 0)*Opc + (isQuiescent(state) and 1 or 0)*Oqc)
	end,
	
	--glucose
	function(state, diffusion, substance)
		local O = substance[1]
		local G = substance[2]
		local B = substance[3]
		return DG*diffusion + (isVessel(state) and 1 or 0)*Gkv - G*((isProliferative(state) and 1 or 0)*Gpc + (isQuiescent(state) and 1 or 0)*Gqc)
	end,
	
	--bevacizumab
	function(state, diffusion, substance)
		local O = substance[1]
		local G = substance[2]
		local B = substance[3]
		return DB*diffusion + (isVessel(state) and 1 or 0)*Bkv - B*((isProliferative(state) and 1 or 0)*Bpc + (isQuiescent(state) and 1 or 0)*Bqc)
	end,
}

--Cellular Automaton
function model.rule(state, neighbor, substance)
	local O = substance[1]
	local G = substance[2]
	local B = substance[3]
	
	--count empty neighbors
	state.emptyCount = 0
	local emptyNeighbor = {}
	for i,n in ipairs(neighbor) do
		if isEmpty(n) then
			emptyNeighbor[#emptyNeighbor+1] = n
			state.emptyCount = state.emptyCount + 1
		end
	end
	
	if state.kind=='proliferative' then
		--increase counters
		state.division = state.division + 1
		state.angiogenesis = state.angiogenesis + 1
		
		--become quiescent
		if O < Op then
			state.kind = 'quiescent'
			return state
		end
		
		--divide
		if state.division > Td then
			state.division = 0
			if #emptyNeighbor>0 then
				--there is an empty neighbor
				local choice = math.random(1,#emptyNeighbor)
				emptyNeighbor[choice].change = {
					kind = 'proliferative',
				}
			end
			return state
		end
		
		--create vessel
		if state.angiogenesis > Ta and B < Ba then
			state.angiogenesis = 0
			if state.emptyCount>0 then
				--there is an empty neighbor
				local choice = math.random(1,#emptyNeighbor)
				emptyNeighbor[choice].change = {
					kind = 'vessel',
				}
			end
			return state
		end
		
		--become necrotic
		if G < Gt then
			state.kind = 'necrotic'
			return state
		end
		
		--[[
		--migrate (coesion)
		if state.emptyCount>0 then
			--there is an empty neighbor
			local minEmpty = 5
			local bestNeighbor = {}
			for i,n in ipairs(emptyNeighbor) do
				if n.emptyCount<=minEmpty then
					if n.emptyCount<minEmpty then
						bestNeighbor = {}
						minEmpty = n.emptyCount
					end
					bestNeighbor[#bestNeighbor+1] = n
				end
			end
			if minEmpty+1<state.emptyCount then
				local choice = math.random(1,#bestNeighbor)
				bestNeighbor[choice].change = {
					kind = state.kind,
					division = state.division,
					angiogenesis = state.angiogenesis,
					necrosis = state.necrosis,
				}
				state.kind = 'empty'
				state.division = 0
				state.angiogenesis = 0
				state.necrosis = 0
				return state
			end
		end]]
		
	elseif state.kind=='quiescent' then
		--increase counters
		state.division = state.division + 1
		state.angiogenesis = state.angiogenesis + 1
		
		--become proliferative
		if O > Op then
			state.kind = 'proliferative'
			return state
		end
		
		--create vessel
		if state.angiogenesis > Ta and B < Ba then
			state.angiogenesis = 0
			if state.emptyCount>0 then
				--there is an empty neighbor
				local choice = math.random(1,#emptyNeighbor)
				emptyNeighbor[choice].change = {
					kind = 'vessel',
				}
			end
			return state
		end
		
		--become necrotic
		if G < Gt or O < Oq then
			state.kind = 'necrotic'
			return state
		end
		
	elseif state.kind=='necrotic' then
		--get removed
		local empty = 0
		for i,n in ipairs(neighbor) do
			if isEmpty(n) then
				empty = empty + 1
			end
		end
		if empty>0 then
			state.necrosis = state.necrosis + 1
			if state.necrosis > Tn then
				state.kind = 'empty'
				state.division = 0
				state.angiogenesis = 0
				state.necrosis = 0
				return state
			end
		end
		
	elseif state.kind=='vessel' then
		--get removed
		if B > Bv then
			local empty = 0
			for i,n in ipairs(neighbor) do
				if isEmpty(n) then
					empty = empty + 1
				end
			end
			if empty==0 then
				--if surrounded, becomes necrotic instead of empty
				state.kind = 'necrotic'
			else
				state.kind = 'empty'
				state.division = 0
				state.angiogenesis = 0
				state.necrosis = 0
			end
			return state
		end
		
	elseif state.kind=='empty' then
		--check change
		if state.change then
			state.kind = state.change.kind or 0
			state.division = state.change.division or 0
			state.angiogenesis = state.change.angiogenesis or 0
			state.necrosis = state.change.necrosis or 0
			state.change = nil
		end
	end
	
	return state
end

return model
