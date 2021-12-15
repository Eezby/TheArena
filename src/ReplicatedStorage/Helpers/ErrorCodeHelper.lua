local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RepData = ReplicatedStorage.Data
local ErrorCodes = require(RepData:WaitForChild("ErrorCodes"))

local ErrorCodeHelper = {}

function ErrorCodeHelper.FormatCode(id)
	return "Code: "..id.."\n"..ErrorCodes[id]
end
return ErrorCodeHelper