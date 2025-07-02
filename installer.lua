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
installFile(repoUrl .. "/packageInstaller.lua", installpath .. "/packageInstaller.lua")
print("installed required files")

os.sleep(0.2)

package.path = installpath .. "/?.lua;" .. package.path

package.loaded["packageInstaller"] = nil
local packInstaller = require("packageInstaller")
packInstaller.install(repoUrl)
print("installed")