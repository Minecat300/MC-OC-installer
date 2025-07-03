local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")
local seri = require("serialization")
local json = require("dkjson")
local uinutils = require("uinutils")

local M = {}

local function getJson(url)
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

local function installFile(url, path)
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

local function deleteRecursive(path)
    if filesystem.isDirectory(path) then
        for file in filesystem.list(path) do
            local fullPath = filesystem.concat(path, file)
            deleteRecursive(fullPath)
        end
    end
    filesystem.remove(path)
end

local function installFileArray(baseUrl, urlArray, installPath)
    for index, value in ipairs(urlArray) do
        local name = value.name
        if not name then
            print("Failed to install. No file/dir name was found")
            return
        end

        local subPath = value.subPath or ""

        local type = value.type
        if not type then
            print("Failed to install. No file/dir type was found")
            return
        end

        if type == "file" then
            installFile(uinutils.url_concat(baseUrl, name), filesystem.concat(installPath, subPath, name))
        end

        if type == "dir" then
            local fileInstalls = value.fileInstalls
            if not fileInstalls then
                print("Failed to install. No files found in dir: " .. name)
                return
            end

            local fullPath = filesystem.concat(installPath, subPath, name)

            if not filesystem.isDirectory(fullPath) then
                filesystem.makeDirectory(fullPath)
            end

            installFileArray(uinutils.url_concat(baseUrl, name), fileInstalls, fullPath)
        end
    end
end

local function uninstallFileArray(fileArray, installpath)
    for index, value in ipairs(fileArray) do
        local name = value.name
        if not name then
            print("Failed to uninstall. No file/dir name was found")
            return
        end

        local subPath = value.subPath or ""

        local type = value.type
        if not type then
            print("Failed to uninstall. No file/dir type was found")
            return
        end

        local fullPath = filesystem.concat(installpath, subPath, name)

        if type == "file" then
            filesystem.remove(fullPath)
        end

        if type == "dir" then
            deleteRecursive(fullPath)
        end
    end
end

local function addPackageData(packageName, installJson, url, fileInstalls, installPath, autoUpdate)
    local packageData = uinutils.readFile("/Uinstall/packageData")
    packageData[packageName] = {}
    packageData[packageName].url = url
    packageData[packageName].installedFiles = seri.serialize(fileInstalls)
    packageData[packageName].installPath = installPath
    packageData[packageName].description = installJson.description
    packageData[packageName].autoUpdate = autoUpdate
    packageData[packageName].version = installJson.version or "1.0"
    uinutils.writeFile("/Uinstall/packageData", packageData)
end

local function removePackageData(packageName)
    local packageData = uinutils.readFile("/Uinstall/packageData")
    packageData[packageName] = nil
    uinutils.writeFile("/Uinstall/packageData", packageData)
end

function M.update(packageName)
    local packageData = uinutils.readFile("/Uinstall/packageData")
    if not packageData[packageName] then
        print("No package named (" .. packageName .. ") was found")
        return
    end

    print("Updating package: " .. packageName)

    local rawUrl = packageData[packageName].url
    local autoUpdate = packageData[packageName].autoUpdate or false

    local installJson = getJson(rawUrl .. "/install.json")
    if not installJson then
        print ("Failed to update. No install JSON was found")
        return
    end

    local newPackageName = installJson.packageName
    if not newPackageName then
        print("Failed to update. No package name was found")
        return
    end

    local fileInstalls = installJson.fileInstalls
    if not fileInstalls then
        print("Failed to update. No install files found")
        return
    end
    
    local installpath = installJson.installPath
    if not installpath then
        print("Failed to update. No install path found")
        return
    end

    installFileArray(rawUrl, fileInstalls, installpath)
    removePackageData(packageName)
    addPackageData(newPackageName, installJson, rawUrl, fileInstalls, installpath, autoUpdate)
    if packageName == newPackageName then
        print(packageName .. " was updated to newest version!")
    else
        print(packageName .. " was updated with new name: " .. newPackageName)
    end
    print("Note: Some packages might need a reboot for the update to take into effect")
end

function M.autoUpdate(packageName)
    local packageData = uinutils.readFile("/Uinstall/packageData")
    if not packageData[packageName] then
        print("No package named (" .. packageName .. ") was found")
        return
    end

    local oldVersion = packageData[packageName].version
    local rawUrl = packageData[packageName].url

    local installJson = getJson(rawUrl .. "/install.json")
    if not installJson then
        print("Failed to install. No install JSON was found")
        return
    end

    local newVersion = installJson.version or "1.0"

    if newVersion == oldVersion then
        print("No newer version then " .. newVersion .. " was found")
        return
    end
    print("new version found: " .. oldVersion .. " -> " .. newVersion)
    M.update(packageName)
end

function M.autoUpdateAll()
    local packageData = uinutils.readFile("/Uinstall/packageData")
    for key, value in pairs(packageData) do
        if value.autoUpdate then
            print("Check update for: " .. key)
            M.autoUpdate(key)
        end
    end
end

function M.uninstall(packageName)
    local packageData = uinutils.readFile("/Uinstall/packageData")
    if not packageData[packageName] then
        print("No package named (" .. packageName .. ") was found")
        return
    end

    print("Uninstalling package: " .. packageName)

    local installedFiles = seri.unserialize(packageData[packageName].installedFiles)
    if not installedFiles then
        print("Failed to uninstall. No installed files found")
        return
    end

    local installPath = packageData[packageName].installPath
    if not installPath then
        print("Failed to uninstall. No install path was found")
        return
    end

    uninstallFileArray(installedFiles, installPath)
    removePackageData(packageName)
    print(packageName .. " was uninstalled!")
end

function M.install(url)
    print("Installing package from url: " .. url)

    local installJson = getJson(url .. "/install.json")
    if not installJson then
        print("Failed to install. No install JSON was found")
        return
    end

    --print(seri.serialize(installJson))

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

    installFileArray(url, fileInstalls, installPath)
    addPackageData(packageName, installJson, url, fileInstalls, installPath, installJson.autoUpdate or false)
    print(packageName .. " was installed!")
end
return M