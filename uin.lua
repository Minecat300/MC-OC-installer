local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")
local seri = require("serialization")
package.path = "/Uinstall/?.lua;" .. package.path
local proInstaller = require("projectInstaller")

local function makeRawURL(repoURL, branch)
    branch = branch or "main"
    local user, repo = repoURL:match("github.com/([^/]+)/([^/]+)")
    if not user or not repo then
        return nil, "Invalid GitHub URL"
    end
    return string.format("https://raw.githubusercontent.com/%s/%s/%s", user, repo, branch)
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

local args = {...}
local command = args[1]

if command == "install" then
    local url = args[2]
    if not url then
        print("No Github repository was given")
        return
    end
    local rawUrl = makeRawURL(url, args[3] or "main")
    proInstaller.install(rawUrl)
    print("installed!")
end

if command == "list" then
    local appData = readFile("/Uinstall/appData")
    for key, value in pairs(appData) do
        local desciption = value.desciption or ""
        print(key, desciption)
    end
end