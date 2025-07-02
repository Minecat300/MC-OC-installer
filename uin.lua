local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")
local seri = require("serialization")
package.path = "/Uinstall/?.lua;" .. package.path
local packInstaller = require("packageInstaller")

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
    packInstaller.install(rawUrl)
end

if command == "list" then
    local packageData = readFile("/Uinstall/packageData")
    for key, value in pairs(packageData) do
        local description = value.description or ""
        print(key, description)
    end
end

if command == "checkUpdate" then
    
end

if command == "update" then
    local packageName = args[2]
    if not packageName then
        print("No package was provided")
        return
    end
    packInstaller.update(packageName)
end

if command == "uninstall" then
    local packageName = args[2]
    if not packageName then
        print("No package was provided")
        return
    end
    packInstaller.uninstall(packageName)
end

if command == "help" or command == "h" or command == "?" then
    print('help:        shows this menu                                  "help"')
    print('install:     installs a package                               "install [repository] [?branch]"')
    print('uninstall:   uninstalls the selected package                  "uninstall [package]"')
    print('update:      updates selected package to newest version       "update [package]"')
    print('list:        lists all installed packages                     "list"')
    print('checkUpdate: checks and updates all or one autoupdate package "checkUpdate [?package]"')
end