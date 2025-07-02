local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")
local seri = require("serialization")
local json = require("dkjson")

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

    while true do
        local chunk = handle.read(8192)
        if not chunk then break end
        file:write(chunk)
    end

    file:close()
end

local function installFileArray(baseUrl, urlArray, installPath)
    for index, value in ipairs(urlArray) do
        local name = value.name
        if not name then
            print("failed to install. no file/dir name was found")
            return
        end

        local subPath = value.subPath or ""

        local type = value.type
        if not type then
            print("failed to install. no file/dir type was found")
            return
        end
        if (type == "file") then
            installFile(baseUrl .. "/" .. name, installPath .. subPath .. name)
        end
        if (type == "dir") then
            local fileInstalls = value.fileInstalls
            if not fileInstalls then
                print("failed to install. no files found in dir: " .. name)
                return
            end

            if not filesystem.isDirectory(installPath .. subPath .. name) then
                filesystem.makeDirectory(installPath .. subPath .. name)
            end

            installFileArray(baseUrl .. "/" .. name, fileInstalls, installPath .. subPath .. name)
        end
    end
end

local function writeFile(filePath, data)
    local serializedData = seri.serialize(data)
    file = io.open(filePath, "w")
    if file then
        file:write(serializedData)
        file:close()
    else
        print("Error: Failed to open file for writing")
    end
end

local function readFile(filePath)
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
        file:close()
    end
    return data
end

function M.update(package)
    print("updating package: " .. package)
end

function M.install(url)
    print("installing package from url: " .. url)

    local installJson = getJson(url .. "/install.json")
    if not installJson then
        print("failed to install. no JSON was found")
        return
    end

    --print(seri.serialize(installJson))

    local packageName = installJson.packageName
    if not packageName then
        print("failed to install. no package name was found")
        return
    end

    local fileInstalls = installJson.fileInstalls
    if not fileInstalls then
        print("failed to install. no install files found")
        return
    end

    local installPath = installJson.installPath
    if not installPath then
        print("failed to install. no install path found")
        return
    end

    installFileArray(url, fileInstalls, installPath)

    local packageData = readFile("/Uinstall/packageData")
    packageData[packageName] = {}
    packageData[packageName].url = url
    packageData[packageName].installedFiles = seri.serialize(fileInstalls)
    packageData[packageName].description = installJson.description
    packageData[packageName].autoUpdate = installJson.autoUpdate or false
    packageData[packageName].version = installJson.version or "1.0"
    writeFile("/Uinstall/packageData", packageData)
end
return M