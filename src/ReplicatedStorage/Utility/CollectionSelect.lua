local CollectionService = game:GetService("CollectionService")

local function combineTables(table1, table2)
	local new = table.create(#table1 + #table2)
	table.move(table1, 1, #table1, 1, new)
	table.move(table2, 1, #table2, #table1+1, new)
	return new
end

local CollectionSelect = {}
function CollectionSelect:SelectAll(tags, validationCallback)
	local selectionToReturn = {}
	
	for i = 1,#tags do
		local collectedObjects = CollectionService:GetTagged(tags[i])
		if #collectedObjects > 0 then
			if #selectionToReturn > 0 then
				selectionToReturn = combineTables(selectionToReturn, collectedObjects)
			else
				selectionToReturn = collectedObjects
			end
		end
	end

    local adjustedSelection = {}
    if validationCallback then
        for _,object in pairs(selectionToReturn) do
            if validationCallback(object) then
                table.insert(adjustedSelection, object)
            end
        end

        return adjustedSelection
	end
	
	return selectionToReturn
end

function CollectionSelect:QuerySelect(tags)
	local currentSelect = nil
	
	for tag, status in pairs(tags) do
		if status then
			currentSelect = CollectionService:GetTagged(tag)
		end
	end
	
	if not currentSelect then return {} end
	
	local selectionToReturn = {}
	for index,object in pairs(currentSelect) do
		local fitsDescription = true
		
		for tag, status in pairs(tags) do
			if CollectionService:HasTag(object, tag) ~= status then
				fitsDescription = false
				break
			end
		end
		
		if fitsDescription then
			table.insert(selectionToReturn, object)
		end
	end

	return selectionToReturn
end

return CollectionSelect
