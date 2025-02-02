---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the PersistentData_Model definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_PersistentData'

local persistentData_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
persistentData_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Load script to communicate with the PersistentData_Model interface and give access
-- to the PersistentData_Model object.
-- Check / edit this script to see/edit functions which eg. communicate with the UI
local setPersistentData_Model_Handle = require('Configuration/PersistentData/PersistentData_Controller')
setPersistentData_Model_Handle(persistentData_Model)

persistentData_Model.data = {} -- table to hold all relevant data
persistentData_Model.contentList = '' -- list of all available module parameters within the paramerter dataset
persistentData_Model.path = Parameters.get('DataFilePath') -- name of the parameter dataset to load
persistentData_Model.tempPath = '/ram/CSK_PersistentData_Temp.bin'
persistentData_Model.initialLoading = false -- status to check if parameter dataset was successfully loaded on app/device reboot
persistentData_Model.version = Engine.getCurrentAppVersion() -- Version of module

persistentData_Model.moduleSaveCheck = {} -- Check if modules successfully send their parameters if they all were triggered to save
persistentData_Model.currentlySelectedDataSet = '' -- Selected DataSet of parameters
persistentData_Model.currentlySelectedParameterName = '' -- Name of selected parameter within parameter set via UI
persistentData_Model.currentlySelectedParameterNameOfTable = '' -- Name of selected table within parameter
persistentData_Model.currentlySelectedParameterNameOfSubTable = '' -- Name of selected subtable within parameter
persistentData_Model.currentlySelectedParameterWithinSubTable = '' -- Name of selected parameter within subtable
persistentData_Model.currentlySelectedParameterType = '' -- Data type of selected parameter within UI
persistentData_Model.currentlySelectedParameterNameTableList = '' -- Optional list of parameter names within selected parameter table
persistentData_Model.currentlySelectedParameterValue = '' -- Value of selected parameter within UI

persistentData_Model.listOfCSKModules = {} -- List of available CSK modules
persistentData_Model.currentlySelectedModuleToLoadParameters = '' -- Selected module to trigger to load currently selected parameter

for _, value in pairs(Engine.listApps()) do
  local checkCSK = string.find(value, 'CSK_')
  if checkCSK then
    table.insert(persistentData_Model.listOfCSKModules, value)
  end
end

if #persistentData_Model.listOfCSKModules >= 1 then
  persistentData_Model.currentlySelectedModuleToLoadParameters = persistentData_Model.listOfCSKModules[1]
end
persistentData_Model.currentlySelectedModuleInstanceToLoadParameters = 0 -- Optional instance of module to load parameters

-- Handle processing to trigger other modules to load their specific parameters
Script.startScript('CSK_Module_PersistentData_AsyncLoadData') -- Additional thread needed, as otherwise the module will block itself

persistentData_Model.parameters = {}
persistentData_Model.parameters.styleForUI = 'None'
persistentData_Model.parameters.parameterNames = {} -- store table of what parameter should be loaded for what module
persistentData_Model.parameters.loadOnReboot = {} -- store table if parameter should be loaded for module on app/device reboot
persistentData_Model.parameters.totalInstances = {} -- store table of total instances to create for this module

persistentData_Model.funcs = require('Configuration/PersistentData/helper/funcs') -- Helper functions

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

local function createNewDataSet(path)
  _G.logger:fine(nameOfModule .. ": Created new, empty DataSet.")
  persistentData_Model.data = {}
  persistentData_Model.contentList = ''
  persistentData_Model.path = path or '/public/CSK_PersistentData.bin'

  persistentData_Model.parameters = {}
  persistentData_Model.parameters.styleForUI = 'None'
  persistentData_Model.parameters.parameterNames = {}
  persistentData_Model.parameters.loadOnReboot = {}
  persistentData_Model.parameters.totalInstances = {}

  _G.logger:fine(nameOfModule .. ": Path is = " .. persistentData_Model.path)

  Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)

  CSK_PersistentData.pageCalled()

end
Script.serveFunction("CSK_PersistentData.createNewDataSet", createNewDataSet)
persistentData_Model.createNewDataSet = createNewDataSet

-- Function to add values of a table into the data with given name as identifier for this data
---@param data any[] Values to add
---@param name string Name of parameter
local function addParameterTable(data, name)
  local tableContent = {}
  for key, value in pairs(data) do
    tableContent[key] = value
  end
  persistentData_Model.data[name] = tableContent
  _G.logger:fine(nameOfModule .. ": Added data: " .. name)

  persistentData_Model.contentList = persistentData_Model.funcs.createContentList(persistentData_Model.data)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)

end
persistentData_Model.addParameterTable = addParameterTable

local function removeParameter(name)

  _G.logger:fine(nameOfModule .. ": Remove data (if exist): " .. name)
  persistentData_Model.data[name] = nil

  persistentData_Model.contentList = persistentData_Model.funcs.createContentList(persistentData_Model.data)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)
  CSK_PersistentData.pageCalled()

end
Script.serveFunction("CSK_PersistentData.removeParameter", removeParameter)
persistentData_Model.removeParameter = removeParameter

local function saveData()
  local fileExists = File.exists(persistentData_Model.path)
  _G.logger:fine(nameOfModule .. ": File to save data already exists = " .. tostring(fileExists))

  local file = File.open(persistentData_Model.path, "wb")
  if (file ~= nil) then
    local fullData = Container.create()

    for key, value in pairs(persistentData_Model.data) do
      local subContainer = persistentData_Model.funcs.convertTable2Container(value)
      fullData:add(key, subContainer, nil)
    end

    local binaryContainer = Object.serialize(fullData, "JSON")
    local success = File.write(file, binaryContainer)
    _G.logger:info(nameOfModule .. ": Data save success = " .. tostring(success))
    File.close(file)
    Parameters.set('DataFilePath', persistentData_Model.path)
    Parameters.savePermanent()
    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'OK')
    Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)

    return true
  else
    _G.logger:warning(nameOfModule .. ": Write did not work")
    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'ERR')
    return false
  end
end
Script.serveFunction("CSK_PersistentData.saveData", saveData)
persistentData_Model.saveData = saveData

local function loadContent(noModuleUpdate)
  local file = File.open(persistentData_Model.path, "rb")
  if (file ~= nil) then
    local fileContent = File.read(file)
    local cont = Object.deserialize(fileContent, "JSON")

    persistentData_Model.data = {}
    persistentData_Model.parameters = {}
    persistentData_Model.parameters.styleForUI = 'None'
    persistentData_Model.parameters.parameterNames = {}
    persistentData_Model.parameters.loadOnReboot = {}
    persistentData_Model.parameters.totalInstances = {}

    local containerList = Container.list(cont)
    persistentData_Model.contentList = table.concat(Container.list(cont), ',')
    Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)
    Script.notifyEvent('PersistentData_OnNewStatusCSKStyle', persistentData_Model.parameters.styleForUI)

    for i=1, #containerList do
      local valueKey = containerList[i]

      local subContainer = Container.get(cont, valueKey)

      local subTable = persistentData_Model.funcs.convertContainer2Table(subContainer)

      persistentData_Model.data[valueKey] = subTable
    end
    _G.logger:info(nameOfModule .. ": Loading of PersistentData from " .. persistentData_Model.path .. " did work.")

    File.close(file)

    if persistentData_Model.data['PersistentData_InitialParameterNames'] then
      persistentData_Model.parameters = persistentData_Model.data['PersistentData_InitialParameterNames']
    end

    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'OK')

    if persistentData_Model.initialLoading then
      CSK_PersistentData.pageCalled()
    end

    if noModuleUpdate == false or noModuleUpdate == nil then
      CSK_PersistentData.resetAllModules()
      Script.notifyEvent('PersistentData_OnNewDataToLoad', persistentData_Model.funcs.convertTable2Container(persistentData_Model.parameters))
    end

    return true
  else
    _G.logger:info(nameOfModule .. ": No persistent data file available")
    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'ERR')

    if persistentData_Model.initialLoading then
      CSK_PersistentData.pageCalled()
    end
    return false
  end

end
Script.serveFunction("CSK_PersistentData.loadContent", loadContent)
persistentData_Model.loadContent = loadContent

-- Try to load latest parameters
persistentData_Model.initialLoading = persistentData_Model.loadContent(true)

local function setPath(path)
  persistentData_Model.path = path
  _G.logger:fine(nameOfModule .. ': Changed path to ' .. path .. '. Try to load data if already existing...')
  Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)
  local suc = persistentData_Model.loadContent(true)

  if not suc then
    createNewDataSet(persistentData_Model.path)
  end

  CSK_PersistentData.pageCalled()

end
Script.serveFunction("CSK_PersistentData.setPath", setPath)
persistentData_Model.setPath = setPath

local function overwriteData()
  if(File.copy(persistentData_Model.tempPath, persistentData_Model.path)) then
  _G.logger:fine(nameOfModule .. ': Persistent data overwritten, deleting the temporary file ...')
    File.del(persistentData_Model.tempPath)
    loadContent(true)
  else
    _G.logger:warning(nameOfModule .. ': Could not overwrite persistent data')
  end
end
Script.serveFunction("CSK_PersistentData.overwriteData", overwriteData)
persistentData_Model.overwriteData = overwriteData

local function removeCurrentData()
  _G.logger:fine(nameOfModule .. ': Remove current data.')
  persistentData_Model.data = {}
  persistentData_Model.contentList = ''
end
persistentData_Model.removeCurrentData = removeCurrentData

return persistentData_Model

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

