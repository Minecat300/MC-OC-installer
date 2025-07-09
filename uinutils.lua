local filesystem = require("filesystem")
local seri = require("serialization")
local component = require("component")
local json = require("dkjson")
local internet = component.internet

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

function M.ensureDirs(path)
    if filesystem.exists(path) then return end

    local targetPath = path

    if not path:match("/$") then
        targetPath = filesystem.path(path) or "/"
    end

    local parts = {}
    for part in string.gmatch(targetPath, "[^/]+") do
        table.insert(parts, part)
    end

    local current = "/"
    for i = 1, #parts do
        current = filesystem.concat(current, parts[i])
        if not filesystem.exists(current) then
            filesystem.makeDirectory(current)
        end
    end
end

function M.sortByWeight(obj)
  local keys = {}
  for key in pairs(obj) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    if obj[a] == obj[b] then
      return a < b
    else
      return obj[a] < obj[b]
    end
  end)

  return keys
end

function M.getJson(url)
    local handle, err = internet.request(url)
    if not handle then
        print("Failed to request URL:", err)
        return
    end

    local jsonInstall = ""
    while true do
        local chunk = handle.read(8192)
        if not chunk then break end
        jsonInstall = jsonInstall .. chunk
    end

    local obj, pos, decode_err = json.decode(jsonInstall, 1, nil)
    if decode_err then
        print("JSON decode error:", decode_err)
        return
    end

    return obj
end

function M.installFile(url, path)
    local handle, err = internet.request(url)
    if not handle then
        print("Failed to request URL:", err)
        return
    end

    local file = io.open(path, "w")
    if not file then
        print("Failed to create file")
        return
    end

    while true do
        local chunk = handle.read(8192)
        if not chunk then break end
        file:write(chunk)
    end

    file:close()
end

function M.deleteRecursive(path)
    if filesystem.isDirectory(path) then
        for file in filesystem.list(path) do
            local fullPath = filesystem.concat(path, file)
            M.deleteRecursive(fullPath)
        end
    end
    filesystem.remove(path)
end

function M.getPackageInstallJson(packageUrl)
    local installJson = M.getJson(packageUrl .. "/install.json")
    if not installJson then
        print("Failed to install. No install JSON was found")
        return
    end

    local packageName = installJson.packageName
    if not packageName then
        print("Failed to install. No package name was found")
        return
    end

    local fileInstalls = installJson.fileInstalls
    if not fileInstalls then
        print("Failed to install. No install files found")
        return
    end

    local installPath = installJson.installPath
    if not installPath then
        print("Failed to install. No install path found")
        return
    end

    return installJson, packageName, fileInstalls, installPath
end

function M.getPackageData()
    local packageData = M.readFile("/Uinstall/packageData")
    return packageData
end

function M.savePackageData(packageData)
    M.writeFile("/Uinstall/packageData", packageData)
end

function M.isPackageInstalled(packageName)
    local packageData = M.getPackageData()
    if packageData[packageName] then
        return true
    end
    return false
end

function M.isPackageInstalledByUrl(packageUrl)
    local _, packageName = M.getPackageInstallJson(packageUrl)
    return M.isPackageInstalled(packageName)
end

return M