local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")
local seri = require("serialization")

local repoUrl = "https://raw.githubusercontent.com/Minecat300/MC-OC-installer/main"
local installpath = "/Uinstall";

if not filesystem.isDirectory(installpath) then
    filesystem.makeDirectory(installpath)
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

installFile(repoUrl .. "/dkjson.lua", installpath .. "/dkjson.lua")

local json = require("dkjson")

local url = repoUrl .. "/install.json"
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

print(jsonInstall)
print(seri.serialize(obj))