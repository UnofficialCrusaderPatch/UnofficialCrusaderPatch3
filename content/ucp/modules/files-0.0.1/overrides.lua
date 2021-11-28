local FILE_OVERRIDES = {}
local FILE_OVERRIDE_FUNCTIONS = {}

local FILENAME_DB = {}

local function onOpenFile(file)
    for k, func in pairs(FILE_OVERRIDE_FUNCTIONS) do
      local fresult = func(file)
      if fresult ~= nil then
        print("Overriding file: " .. fresult)
        return fresult
      end
    end

    if FILE_OVERRIDES[file] ~= nil then
        print("Overriding file: " .. file)
        return FILE_OVERRIDES[file]
    end

    return nil
end

local fileopen_use_address = core.AOBScan("E8 ? ? ? ? 83 c4 0c 83 f8 ff 89 86 08 0d 08 00 89 be c4 0b 00 00 75 07 5f 33 c0 5e c2 0c 00")
local fileopen_address = core.readInteger(fileopen_use_address + 1) + fileopen_use_address + 5 -- turn into absolute address

return {
    enable = function(config)
        core.detourCode(function(registers)
            local file = core.readString(core.readInteger(registers.ESP + 4))

            if config and config.logFileAccess then
                print("Game opened file: " .. file)
            end

            local override = onOpenFile(file)
            if override ~= nil then
                print("... overridden with file: " .. override)

                if override:len() > 0 then
                    if FILENAME_DB[override] == nil then
                        FILENAME_DB[override] = core.allocate(override:len() + 1)
                        core.writeBytes(FILENAME_DB[override], table.pack(string.byte(override, 1, -1)))
                        core.writeByte(FILENAME_DB[override] + override:len(), 0)
                    end
                else
                    if FILENAME_DB[override] == nil then
                        FILENAME_DB[override] = core.allocate(1)
                        core.writeByte(FILENAME_DB[override], 0)
                    end
                end

                core.writeInteger(registers.ESP + 4, FILENAME_DB[override])
            end

        end, fileopen_address, 6)
    end,
    overrideFileWith = function(file, newFile)
        print("Registering override for: " .. file .. ": " .. newFile)
        FILE_OVERRIDES[file] = newFile
    end,
    registerOverrideFunction = function(func)
        table.insert(FILE_OVERRIDE_FUNCTIONS, func)
    end
}
