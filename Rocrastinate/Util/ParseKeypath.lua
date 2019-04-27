local function ParseKeypath(stringKeypath)
	local tabKeyPath = {}
	for k in stringKeypath:gmatch("[^%.]+") do
		tabKeyPath[#tabKeyPath + 1] = k
	end
	return tabKeyPath
end

return ParseKeypath