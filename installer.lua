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
installFile(repoUrl .. "/projectInstaller.lua", installpath .. "/projectInstaller.lua")
print("[MAIN] installed required files")

os.sleep(0.2)

package.path = installpath .. "/?.lua;" .. package.path
print("[MAIN] package.path updated")

package.loaded["projectInstaller"] = nil


local ok, proInstaller = pcall(require, "projectInstaller")
if not ok then
    print("[ERROR] Failed to require projectInstaller:", proInstaller)
else
    print("[MAIN] Required projectInstaller module")

    print("[DEBUG] type of proInstaller:", type(proInstaller))

    if type(proInstaller.install) == "function" then
        print("[MAIN] install function found, running it...")
        proInstaller.install(repoUrl)
    else
        print("[ERROR] install function not found in module!")
    end
end

print("[MAIN] Done")