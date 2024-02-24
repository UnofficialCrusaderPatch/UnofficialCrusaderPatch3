TRUE = 1
FALSE = 0

---@module core
local core = {}

---Converts integer `value` to a table of 4 bytes.
function core.itob(value)
  return {
    (value >> 0) & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  }
end

---Converts short `value` to a table of 2 bytes.
function core.stob(value)
  return {
      (value >> 0) & 0xFF,
      (value >> 8) & 0xFF,
  }
end

---Converts byte `value` to an unsigned byte (0-255).
function core.btoub(value)
  if value < 0 then
      return 256 + value -- (256 + -1 = 255)
  else
      return value
  end
end

---Read integer from memory at a specified address.
---@param address number the address of the memory to read the integer from
---@return number the integer
function core.readInteger(address)
    return ucp.internal.readInteger(address)
end

---Read short from memory at a specified address.
---@param address number the address of the memory to read the short from
---@return number the short
function core.readSmallInteger(address)
    return ucp.internal.readSmallInteger(address)
end

---Read byte from memory at a specified address.
---@param address number the address of the memory to read the byte from
---@return number the byte
function core.readByte(address)
    return ucp.internal.readByte(address)
end

---Read bytes from memory at a specified address.
---@param address number the address of the memory to read the bytes from
---@param size number the number of bytes to read
---@return table Returns the bytes in the form of a table.
function core.readBytes(address, size)
    return ucp.internal.readBytes(address, size)
end

---Read a string from memory at a specified address. Expects the string to be 0-terminated.
---@param address number the address of the memory to read the string from
---@return string Returns the string at the address.
function core.readString(address)
    return ucp.internal.readString(address)
end

---Write a integer to memory at a specified address
---@param address number the address of the read and write memory to write the integer to
---@param value number a integer value
function core.writeInteger(address, value)
    return ucp.internal.writeInteger(address, value)
end

---Write a short to memory at a specified address
---@param address number the address of the read and write memory to write the short to
---@param value number a short value
function core.writeSmallInteger(address, value)
    return ucp.internal.writeSmallInteger(address, value)
end

---Write a byte to memory at a specified address
---@param address number the address of the read and write memory to write the byte to
---@param value number a byte value
function core.writeByte(address, value)
    return ucp.internal.writeByte(address, value)
end

---Write bytes to memory at a specified address
---@param address number the address of the read and write memory to write the bytes to
---@param value table a table of byte values
function core.writeBytes(address, value)
    return ucp.internal.writeBytes(address, value)
end

---Write string to memory at a specified address
---@param address number the address of the read and write memory to write the string to
---@param value string a string to write
function core.writeString(address, value)
    return ucp.internal.writeString(address, value)
end

---Allocate a piece of memory for data
---@param size number The size of the memory block
---@return number The address of the new memory block
function core.allocate(size, zero)
    if zero == nil or zero == true then 
      return ucp.internal.allocate(size, true)
    else
      return ucp.internal.allocate(size)
    end
end

---Deallocate a piece of memory
---@param address number The address of the memory block
---@return nil
function core.deallocate(address)
    if type(address) == "number" then
      return ucp.internal.deallocate(address)
    else
      error("unsupported argument type for address: " .. type(address))
    end
end

---Writes `code` to `address` in executable memory. If the memory has write-protection, this will be temporarily lifted.
---@param address number the address to make the changes
---@param code table the code to write to memory
---@param compile boolean default is false, if true, the code will be compiled with `compile`
---@see core.compile
function core.writeCode(address, code, compile)
    if compile == nil or compile == true then
        return ucp.internal.writeCode(address, core.compile(code, address))
    else
        return ucp.internal.writeCode(address, code)
    end
end

---Write a byte to executable memory at a specified address
---@param address number the address of the executable memory to write the byte to
---@param value number a byte value
function core.writeCodeByte(address, value)
  core.writeCode(address, { core.btoub(value) }, false)
end

---Write bytes to executable memory at a specified address
---@param address number the address of the executable memory to write the bytes to
---@param value table a table of byte values
function core.writeCodeBytes(address, value)
  core.writeCode(address, value, false)
end

---Write a integer to executable memory at a specified address
---@param address number the address of the executable memory to write the integer to
---@param value number a integer value
function core.writeCodeInteger(address, value)
  core.writeCode(address, core.itob(value), false)
end

---Write a short to executable memory at a specified address
---@param address number the address of the executable memory to write the short to
---@param value number a short value
function core.writeCodeSmallInteger(address, value)
  core.writeCode(address, core.stob(value), false)
end

---Allocates an executable memory section to store code
---@param data table|number data can be a number or a table. If a number, these bytes are allocated. If a table, the code is also written to this location
---@return number returns the address of the allocated memory.
function core.allocateCode(data)
    if type(data) == "number" then
        return ucp.internal.allocateCode(data)
    elseif type(data) == "table" then
        local addr = ucp.internal.allocateCode(#data)
        ucp.internal.writeCode(addr, data)
        return addr
    else
        error("unsupported argument type: " .. type(data))
    end
end

---Deallocates an executable memory section
---@param address number address is a pointer to the memory section returned by a allocateCode call
---@return nil
function core.deallocateCode(address)
    if type(address) == "number" then
        return ucp.internal.deallocateCode(address)
    else
        error("unsupported argument type: " .. type(address))
    end
end

---Copy a chunk of memory with `memcpy` internally.
---@param dst number The destination address
---@param src number The source address
---@param length number The amount of bytes to copy
function core.copyMemory(dst, src, length)
    return ucp.internal.copyMemory(dst, src, length)
end

---Scan memory for an Array of Bytes (AOB)
---@param target string A string of hex representations of bytes, `?` can be used as wildcards. Example: "FF 00 ? AA BB"
---@param min number|nil The minimal address of the memory to start searching from
---@param max number|nil The maximum address of the memory to stop searching
---@return number The first address of the memory where `target` matches, 0 if `target` could not be found.
function core.scanForAOB(target, min, max)
    if type(target) ~= "string" then error("invalid argument: " .. target) end
    if target:len() < 2 then error("target AOB too short: " .. target) end
    if min == nil and max == nil then
        return ucp.internal.scanForAOB(target, 0x400000, 0x7FFFFFFF)
    elseif max == nil then
        return ucp.internal.scanForAOB(target, min, 0x7FFFFFFF)
    else
        return ucp.internal.scanForAOB(target, min, max)
    end
end

---Search through the memory for an array of bytes expressed as a hex string (where `?` can be used as wildcards: "FF 00 ? AA").
---If the target is not found in memory, an error will be raised.
---@param target string the hex string to search for
---@param start number the starting address of the memory to start searching from
---@param stop number the last address of the memory to stop searching at
---@result number the address of target in memory
function core.AOBScan(target, start, stop)
    local result
    if start == nil and stop ~= nil then
        error("start value cannot be nil")
    end
    
    if start == nil and stop == nil then
      -- Consider using the cache
      return data.cache.AOB.retrieve(target)
    end
    
    result = core.scanForAOB(target, start, stop)

    if not result then
        error("AOB not found: " .. target)
    end
    return result
end

---Hook game code execution to a lua function, and expose the original game code with a function (returned).
---The hooked function will be called with `argCount` arguments, all numbers (integers).
---The lua function that allows calling the original function is returned
---@param hookedFunction function the function to be called
---@param address number the address of the memory of the game code to be hooked
---@param argCount number the amount of arguments the original game code function has
---@param callingConvention number the calling convention of the original game code function (0 => cdecl, 1 => thiscall, 2 => stdcall (not implemented))
---@param hookSize number number of bytes required in game memory to create the hook
---@return function a lua function to call the original code with. It expects `argCount` arguments.
function core.hookCode(hookedFunction, address, argCount, callingConvention, hookSize)
    return ucp.internal.hookCode(hookedFunction, address, argCount, callingConvention, hookSize)
end

---Detours game code execution into a lua function.
---The lua function will be called with one parameter `registers`, containing a hash table populated with the values of the
---EAX, EBX, ECX, EDX, ESP, EBP, EDI, ESI registers.
---The lua function should return this `registers` variable.
---
---@alias DetourFunction fun(registers: table):table
---
---@param detourFunction DetourFunction | "function(registers) return registers end" the function that is called when the game code is detoured
---@param address number the location of the memory to detour execution
---@param detourSize number the amount of bytes to overwrite with the jump
function core.detourCode(detourFunction, address, detourSize)
    return ucp.internal.detourCode(detourFunction, address, detourSize)
end

---Calling this function will return a function which allows to call game code.
---This returned function expects argCount arguments. If it has callingConvention 1 (thiscall), the first argument is interpreted as 'this' (ECX register)
---The result of the function is returned as a number. Note that 1 means TRUE, and 0 means FALSE in case a boolean was returned by the game.
---@param address number address of the function
---@param argCount number number of arguments (including 'this' if a thiscall)
---@param callingConvention number the type of calling convention (0 -> cdecl, 1 -> thiscall, 2 -> stdcall (not implemented))
---@return function a function expecting `argCount` arguments, of which the first is interpreted as `this` if `callingConvention` is 1
function core.exposeCode(address, argCount, callingConvention)
    return ucp.internal.exposeCode(address, argCount, callingConvention)
end

---This class provides a way to define a function that will return a table with a size known beforehand.
---Example: Lambda:new(function(a,b,c) return {a, b*c} end, 2)(1,2,3) => 1, 6
---
---@class core.Lambda
---@field public new function The constructor expecting two arguments, the lambda function, and size.
---@param f function the function that is to be called
---@param size number the size of the output of the function
core.Lambda = {
    new = function(self, f, size)
        local o = setmetatable({ size = size, f = f }, self)
        self.__index = self
        return o
    end,
    __call = function(self, ...)
        return self.f(...)
    end
}

---A shorthand function for Lambda:new(f, 1)
function core.ByteLambda(f)
    return core.Lambda:new(f, 1)
end

---A shorthand function for Lambda:new(f, 2)
function core.SmallIntegerLambda(f)
    return core.Lambda:new(f, 2)
end

---A shorthand function for Lambda:new(f, 4)
function core.IntegerLambda(f)
    return core.Lambda:new(f, 4)
end

function core.AssemblyLambda(script, valueMapping)
    local s = core.assemble(script, valueMapping, 0)
    return core.Lambda:new(function(address)
        local s2 = core.assemble(script, valueMapping, address)
        if #s2 ~= #s then
            error("error in compilation of Assembly, differing sizes: " .. script:sub(-20))
        end
        return s2
    end, #s)
end

---Utility function to compute a distance between two addresses, offset by an offset
---@param from number
---@param to number
---@param offset number
---@return number the resulting distance expressed as a 4-byte number
function core.getRelativeAddress(from, to, offset)
    if offset == nil then
        offset = 0
    end
    return ((to - from) + offset) & 0xFFFFFFFF
end

---Creates a lambda function to compute the distance to a label in a code table.
---@param label string the label to compute the distance to
---@param offset number the offset
---@return function a function that can be used in a code table
function core.relToLabel(label, offset)
    local offset = offset or 0
    return function(address, index, labels)
        if not labels[label] then
            error("label does not exist: " .. label)
        end
        -- return itob((address - labels[label]) + offset)
        return utils.itob((labels[label] - address) + offset)
    end
end

---Creates a lambda function to compute the relative distance to a location in memory.
---@param dst number the address to compute the relative distance to
---@param offset number an offset that is added to the result
---@return function a function that can be used in a code table
function core.relTo(dst, offset)
    if type(dst) == "string" then
        return core.relToLabel(dst, offset)
    end
    local offset = offset or 0
    return function(address)
        return utils.itob((dst - address) + offset)
    end
end

---Creates a byte sized lambda function to compute the relative distance to a location in memory.
---@param dst number the address to compute the relative distance to
---@param offset number an offset that is added to the result
---@return function a function that can be used in a code table
function core.byteRelTo(dst, offset)
    return core.Lambda:new(function(address, index, labels)
        return { table.unpack(core.relTo(dst, offset)(address, index, labels), 1, 1) }
    end, 1)
end

---Creates a short sized lambda function to compute the relative distance to a location in memory.
---@param dst number the address to compute the relative distance to
---@param offset number an offset that is added to the result
---@return function a function that can be used in a code table
function core.shortRelTo(dst, offset)
    return core.Lambda:new(function(address, index, labels)
        return { table.unpack(core.relTo(dst, offset)(address, index, labels), 1, 2) }
    end, 2)
end

---Creates a lambda function to compute the relative distance to a call in memory (doing the necessary offset of -4 to adjust).
---@param dst number the address to compute the relative distance to
---@param offset number an offset that is added to the result
---@return function a function that can be used in a code table
function core.relToCall(dst)
    return core.relTo(dst, -4)
end

function core.jeTo(dst)
  return core.Lambda:new(function(address, index, labels)
    return { 0x0F, 0x84, table.unpack(core.relTo(dst, -6)(address), 1, 4) }
  end, 6)
end

core.jzTo = jeTo

---Creates a lambda function to represent in machine code a call to a function.
---@param dst number the address to compute the relative distance to
---@param offset number an offset that is added to the result
---@return function a function that can be used in a code table
function core.callTo(dst)
  return core.Lambda:new(function(address, index, labels)
    return { 0xE8, table.unpack(core.relTo(dst, -5)(address), 1, 4) }
  end, 5)
end

---Creates a lambda function to represent in machine code a jmp to a function.
---@param dst number the address to compute the relative distance to
---@param offset number an offset that is added to the result
---@return function a function that can be used in a code table
function core.jmpTo(dst)
  return core.Lambda:new(function(address, index, labels)
    return { 0xE9, table.unpack(core.relTo(dst, -5)(address), 1, 4) }
  end, 5)
end


---Calculates the size of `code` if it would be compiled. It does not call functions or Lambda's,
---but determines their size by assuming 4 bytes, or looking at the `size` property of a Lambda.
---@param code table the code to compile. Can contain byte values, integers, tables, labels (strings), functions and Lambda's.
---@return table, table Returns two tables, the first being the compiled code, the second being a hash table of the relative location of labels
---@see core.Lambda
---@see core.compile
function core.calculateCodeSize(code)
    local result = 0
    local labels = {}
    for k, v in pairs(code) do
        if type(v) == "number" then
            if v < 0 or v > 0xFF then
                result = result + 4
            else
                result = result + 1
            end
        elseif type(v) == "function" or getmetatable(v) == core.Lambda then
            if getmetatable(v) == core.Lambda then
                result = result + v.size -- Lambda functions always return 'size' values
            else
                result = result + 4 -- functions always return 4 values
            end
        elseif type(v) == "string" then
            -- pass, strings are just labels, no data
            labels[v] = result
        elseif type(v) == "table" then
			local r, l = core.calculateCodeSize(v)
            result = result + r
        end
    end
    return result, labels
end

---Compiles a table of bytes, functions, and labels to a table of bytes that can be written to executable memory.
---
---The table `code` can contain 4 types of elements:
---
---1. an integer in the range 0x00-0xFF
---
---2. an integer outside the range 0x00-0xFF. This number will be converted to a 4-byte integer representation
---
---3. a table of integers. These integers will be inserted in the resulting table.concat.
---
---4. a string. This acts as a label can only marks the current location. See the explanation of lambda functions.
---
---5. a (`Lambda`) function that returns a table of bytes (default is 4).
---
---Elements of `code` that are functions (or of type `Lambda`) will be called with the following arguments:
---address, index, labels, code. The function is expected to return a table of bytes.
---
---If it is a normal function, a table of 4 bytes are expected.
---
---If a `Lambda`, then the `size` property determines the expected byte count.
---
---The `address` parameter indicates the current location in the code when the function is called offset by the baseAddress.
---
---The 'index' parameter is the current location in the code, relative to the start of the code.
---
---The `labels` parameter contains a hash table of labels defined in this code and their addresses.
---
---@param code table The code to compile. Elements can be of type number, string, function, Lambda, or table
---@param baseAddress number The base address to compile this code with. This can be considered the target memory location of the code.
---@return table A table of bytes, which is ready for `core.writeCode(baseAddress, false)`
---@see Lambda
function core.compile(code, baseAddress)
    local result = {}
    local labels = {}

    local precompiled, labels_relative = core.calculateCodeSize(code)

    baseAddress = baseAddress or 0

    local labels = {}
    for k, v in pairs(labels_relative) do
        labels[k] = baseAddress + v
    end

    local address = baseAddress

    for k, v in pairs(code) do
        if type(v) == "number" then
            if v < 0 or v > 0xFF then
                for j, w in ipairs(utils.itob(v)) do
                    table.insert(result, w)
                    address = address + 1
                end
            else
                table.insert(result, v)
                address = address + 1
            end
        elseif type(v) == "function" or getmetatable(v) == core.Lambda then
            local vfr = {}
            -- 'v' or 'v.f' is a lambda function, we are expecting 4 byte values to be returned if 'function' and v.size byte values if 'Lambda'
            if getmetatable(v) == core.Lambda then
                vfr = v.f(address, address - baseAddress, labels)
                if #vfr ~= v.size then
                    error("Lambda function (size " .. v.size .. ") returned too many values" .. #vfr)
                end
            else
                vfr = v(address, address - baseAddress, labels)
                if #vfr ~= 4 then
                    error("lambda function: unexpected number of values returned: " .. #vfr)
                end
            end
            if not vfr then
                error("Invalid result from lambda function: " .. vfr)
            end

            for j, w in ipairs(vfr) do
                table.insert(result, w)
                address = address + 1
            end

        elseif type(v) == "table" then
			local vc = core.compile(v, address)
            for j, w in ipairs(vc) do
                table.insert(result, w)
                address = address + 1
            end
        elseif type(v) == "string" then
            if labels[v] ~= address then
                error("runtime error, label'" .. v .. "' (" .. labels[v] .. ") not found at the expected address: " .. address)
            end
        end
    end

    if #result ~= precompiled then
        error("final size of code (" .. #result .. ") is not equal to the precompilation (" .. precompiled .. ")")
    end

    return result
end

---Insert code into memory by jumping at `address` to `code` and returning to `address+patchSize` after executing `code`,
---unless an explicit `returnTo` is specified.
---`code` is compiled before it is written to memory.
---It returns the address of `code` of the memory.
---@param address number Location to create a jump at
---@param patchSize number number of byte code bytes to overwrite
---@param code table code to be executed
---@param returnTo number|nil optional value indicating the address to return to after `code` has been executed. If omitted, the return location will be address + patchSize
---@param original "before"|"after"|nil optional value indicating the overwritten bytes at `address` should be put before, or at the end of `code` before jumping back. Values: "before","after"
---@return number address of the new memory location where `code` lives.
function core.insertCode(address, patchSize, code, returnTo, original)
    if original then
        local originalCode = core.readBytes(address, patchSize)
        if original == "before" then
            table.insert(code, 1, originalCode)
        elseif original == "after" then
            table.insert(code, originalCode)
        else
            error("Unknown argument 'original': " .. original)
        end
    end

    local nopArray = {}
    for i = 1, patchSize do
        table.insert(nopArray, 0x90)
    end
    core.writeCode(address, nopArray)

    if returnTo == nil then
        returnTo = address + patchSize
    end

    local codeSize = core.calculateCodeSize(code)
    local codeAddress = core.allocateCode(codeSize + 5)
    -- code = core.compile(code, codeAddress) -- This is not necessary because writeCode also compiles if necessary: code = core.compile(code, codeAddress)

    core.writeCode(codeAddress, code)

    core.writeCode(address, { 0xE9, core.getRelativeAddress(address, codeAddress, -5) })

    core.writeCode(codeAddress + codeSize, { 0xE9, core.getRelativeAddress(codeAddress + codeSize, returnTo, -5) })

    return codeAddress
end

---Assembles the string script into assembly
---To use variables inside the script, supply them via valueMapping. For example, if you want to use DAT_TileMap1 = 0x400000, as in: mov eax, DWORD[DAT_TileMap1], then specify valueMapping = {DAT_TileMap1 = 0x400000}
---@param script string String script
---@param valueMapping table A table of required variables at assembly time
---@param origin number The location in memory to compile the script for (only relevant when using jumps and calls to outside of the script)
function core.assemble(script, valueMapping, origin)
  if not origin then origin = 0 end
  if not valueMapping then valueMapping = {} end

  for k, v in pairs(valueMapping) do
    script = k .. " = " .. string.format("0x%X", v) .. "\n" .. script
  end
  
  script = "org " .. string.format("0x%X", origin) .. "\n" .. script
  script = "use32" .. "\n" .. script
  
  return table.pack(ucp.internal.assemble(script):byte(1, -1))
end

---Assembles the string script into assembly and writes it to a new memory location
function core.allocateAssembly(script, valueMapping)
    local pass1 = core.assemble(script, valueMapping, 0)
    local address = core.allocateCode(#pass1)
    core.writeCode(address, core.assemble(script, valueMapping, address))
    return address
end

return core