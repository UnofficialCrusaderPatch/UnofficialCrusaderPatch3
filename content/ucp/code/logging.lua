

FATAL = -3
ERROR = -2
WARNING = -1
INFO = 0
DEBUG = 1
VERBOSE = 2

LOG_LEVELS = {
  FATAL = -3,
  ERROR = -2,
  WARNING = -1,
  INFO = 0,
  DEBUG = 1,
  VERBOSE = 2,
}

LOG_LEVEL_NAME = {
  [-3] = "FATAL",
  [-2] = "ERROR",
  [-1] = "WARNING",
  [0] = "INFO",
  [1] = "DEBUG",
  [2] = "VERBOSE",
  [3] = "VVERBOSE",
}

---Log a message to the console and log file
---@type fun(logLevel: number, msg1: string, ...: string): void
log = ucp.internal.log

function traceLog(logLevel, ...)
  
  local info = debug.getinfo(2, 'nSl')

  ucp.internal.log(logLevel, "[" .. tostring(info.source) .. ":" .. tostring(info.currentline) .. "]: (" .. tostring(info.name) .. "): ", ...)
end

local cv = tonumber(os.getenv("UCP_CONSOLE_VERBOSITY"))
local c = tonumber(os.getenv("UCP_VERBOSITY"))

if (cv ~= nil and cv > 0) or (c ~= nil and c > 0) then
  log = traceLog
end
