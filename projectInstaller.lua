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

function M.install(url, path)
    local installJson = getJson(url .. "/install.json")
    if not installJson then
        print("failed to install. no JSON was found")
        return
    end

    local fileInstalls = installJson.fileInstalls or nil
    if not fileInstalls then
        print("failed to install. no install files found")
        return
    end
end

return M