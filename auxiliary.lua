--auxiliary functions
function isProliferative(state)
	return state.kind=='proliferative'
end

function isQuiescent(state)
	return state.kind=='quiescent'
end

function isNecrotic(state)
	return state.kind=='necrotic'
end

function isCancer(state)
	local kind = state.kind
	return kind=='proliferative' or kind=='quiescent' or kind=='necrotic'
end

function isVessel(state)
	return state.kind=='vessel'
end

function isEmpty(state)
	return state.kind=='empty' and not state.change --TODO Take a look at that change after the CA is ready
end
