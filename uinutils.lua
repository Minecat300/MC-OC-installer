local filesystem = require("filesystem")
local seri = require("serialization")

local M = {}

function M.readFile(filePath)
    local file = io.open(filePath, "r")
    local data = {}

    if file then
        local fileContent = file:read("*all")
        file:close()

        data = seri.unserialize(fileContent)
        if not data then
            print("Error: failed to unserialize the file content")
            data = {}
        end
    else
        file = io.open(filePath, "w")
        if file then
            file:close()
        else
            print("Error: unable to create file")
        end
    end
    return data
end

function M.writeFile(filePath, data)
    local serializedData = seri.serialize(data)
    local file = io.open(filePath, "w")
    if file then
        file:write(serializedData)
        file:close()
    else
        print("Error: Failed to open file for writing")
    end
end

function M.url_concat(...)
  local parts = {...}
  local result = ""

  for i, part in ipairs(parts) do
    if i == 1 then
      result = part
    else
      result = result:gsub("/+$", "")
      part = part:gsub("^/+", "")
      result = result .. "/" .. part
    end
  end

  return result
end

function M.toStrictBool(str)
  str = tostring(str):lower()
  if str == "true" or str == "1" then
    return true
  elseif str == "false" or str == "0" then
    return false
  else
    return nil
  end
end

function M.getSortedPackageNames(packageData)
    local names = {}
    for name in pairs(packageData) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

return M