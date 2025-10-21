local _, pResourceManager = utils.AOBExtract("A1 I( ? ? ? ? ) 89 46 74 33 C0 39 ? ? ? ? ? 7E 16")
local pGetDocumentsFolderString = core.AOBScan("6A FF 68 ? ? ? ? 64 A1 00 00 00 00 50 83 EC 40 A1 ? ? ? ? 33 C4 89 44 24 3C 53 55 56 57 A1 ? ? ? ? 33 C4 50 8D 44 24 54 64 A3 00 00 00 00 8B 7C 24 64 33 DB 6A 15")

local pFree = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 8B 75 08")
local free = core.exposeCode(pFree, 1, 0)

local _getDocumentsFolderString = core.exposeCode(pGetDocumentsFolderString, 3, 1)

local addr = core.AOBScan("8D 44 24 ? 50 B9 ? ? ? ? E8 ? ? ? ? BE 10 00 00 00 39 70 18 72 05 8b 48 04 eb 03 8d 48 04 8d 94 24 ? ? ? ? 8b ff")
local StringSize = core.readByte(addr + 3) + 4

local function getDocumentsFolderPath()
	local StackString = core.allocateGarbageCollectedObject(StringSize)
	local pStackString = StackString.address
	local str = _getDocumentsFolderString(pResourceManager, pStackString, 1)
	local pString = str + 0x04
	local result
	if core.readInteger(str + (StringSize - 4)) > 0xF then
		pString = core.readInteger(pString)
		result = core.readString(pString)
		free(pString)
		return result
	end
	
	result = core.readString(pString)
	
	return result
end

return {
	getDocumentsFolderPath = getDocumentsFolderPath,
}