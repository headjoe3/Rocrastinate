local function DeepCopyTable(tab)
	local newTab = {}
	
	for k, v in pairs(tab) do
		if type(v) == "table" then
			newTab[k] = DeepCopyTable(v)
		else
			newTab[k] = v
		end
	end
	
	return newTab
end

return DeepCopyTable