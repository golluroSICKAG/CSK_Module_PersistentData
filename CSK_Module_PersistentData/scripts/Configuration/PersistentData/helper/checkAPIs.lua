---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- Load all relevant APIs for this module
--**************************************************************************

local availableAPIs = {}

-- Function to load all default APIs
local function loadAPIs()
  CSK_PersistentData = require 'API.CSK_PersistentData'

  Log = require 'API.Log'
  Log.Handler = require 'API.Log.Handler'
  Log.SharedLogger = require 'API.Log.SharedLogger'

  Container = require 'API.Container'
  Engine = require 'API.Engine'
  File = require 'API.File'
  Object = require 'API.Object'
  Parameters = require 'API.Parameters'
  Timer = require 'API.Timer'

  -- Check if related CSK modules are available to be used
  local appList = Engine.listApps()
  for i = 1, #appList do
    if appList[i] == 'CSK_Module_UserManagement' then
      CSK_UserManagement = require 'API.CSK_UserManagement'
    end
  end
end

availableAPIs.default = xpcall(loadAPIs, debug.traceback) -- TRUE if all default APIs were loaded correctly

return availableAPIs
--**************************************************************************