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
        print(seri.serialize(value))
        local name = value.name
        if not name then
            print("failed to install. no file/dir name was found")
            return
        end

        local type = value.type
        if not type then
            print("failed to install. no file/dir type was found")
            return
        end
        print(name, type)
        if (type == "file") then
            installFile(baseUrl .. "/" .. name, installPath .. name)
        end
        if (type == "dir") then
            local fileInstalls = value.fileInstalls
            if not fileInstalls then
                print("failed to install. no files found in dir: " .. name)
                return
            end

            if not filesystem.isDirectory(installPath .. "/" .. name) then
                filesystem.makeDirectory(installPath .. "/" .. name)
            end

            installFileArray(baseUrl .. "/" .. name, fileInstalls, installPath .. "/" .. name)
        end
    end
end

function M.install(url)
    print("installing project from url: " .. url)

    local installJson = getJson(url .. "/install.json")
    if not installJson then
        print("failed to install. no JSON was found")
        return
    end

    print(seri.serialize(installJson))

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

end
return M