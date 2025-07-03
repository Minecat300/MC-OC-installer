package.path = "/Uinstall/?.lua;" .. package.path
local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")
local seri = require("serialization")
local packInstaller = require("packageInstaller")
local uinutils = require("uinutils")

local function makeRawURL(repoURL)
    local user, repo, branch, folder = repoURL:match("github.com/([^/]+)/([^/]+)/tree/([^/]+)/(.*)")
    if not user or not repo then
        user, repo = repoURL:match("github.com/([^/]+)/([^/]+)")
        branch = "main"
    end
    branch = branch or "main"
    folder = folder and folder ~= "" and folder or nil

    if folder then
        return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", user, repo, branch, folder)
    else
        return string.format("https://raw.githubusercontent.com/%s/%s/%s", user, repo, branch)
    end
end

local args = {...}
local command = args[1]

if command == "install" then
    local url = args[2]
    if not url then
        print("No Github repository was given")
        return
    end
    local rawUrl = makeRawURL(url)
    packInstaller.install(rawUrl)
end

if command == "list" then
    local packageData = uinutils.readFile("/Uinstall/packageData")
    local packageNames = uinutils.getSortedPackageNames(packageData)
    local col = 20
    for index, name in ipairs(packageNames) do
        local description = packageData[name].description or ""
        local padding = string.rep(" ", math.max(1, col - #name))
        print(name .. padding .. description)
    end
end

if command == "version" then
    local packageData = uinutils.readFile("/Uinstall/packageData")
    local packageNames = uinutils.getSortedPackageNames(packageData)
    local col = 20

    local packageName = args[2]
    if not packageName then
        for index, name in ipairs(packageNames) do
            local version = packageData[name].version or "1.0"
            local padding = string.rep(" ", math.max(1, col - #name))
            print(name .. padding .. version)
        end
    else
        local name = packageName
        local version = packageData[name].version or "1.0"
        local padding = string.rep(" ", math.max(1, col - #name))
        print(name .. padding .. version)
    end
end

if command == "checkUpdate" then
    local packageName = args[2]
    if not packageName then
        packInstaller.autoUpdateAll()
        return
    end
    packInstaller.autoUpdate(packageName)
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

if command == "autoUpdate" then
    local packageName = args[2]
    if not packageName then
        print("No package was provided")
        return
    end

    local state = uinutils.toStrictBool(args[3])
    if not (state == false or state == true) then
        print("No bool value was provided")
        return
    end
    local packageData = uinutils.readFile("/Uinstall/packageData")
    print("Past value: autoUpdate = " .. tostring(packageData[packageName].autoUpdate))
    packageData[packageName].autoUpdate = state
    print("New value: autoUpdate = " .. tostring(packageData[packageName].autoUpdate))
    uinutils.writeFile("/Uinstall/packageData", packageData)
end

if command == "help" or command == "h" or command == "?" or not command then
    print('help:        shows this menu                                  "help"')
    print('install:     installs a package                               "install [repository]"')
    print('uninstall:   uninstalls the selected package                  "uninstall [package]"')
    print('update:      updates selected package to newest version       "update [package]"')
    print('list:        lists all installed packages                     "list"')
    print('version:     lists the version of installed packages          "version [?package]')
    print('checkUpdate: checks and updates all or one autoupdate package "checkUpdate [?package]"')
    print('autoUpdate:  turn on or off auto update for a package         "autoUpdate [package] [bool]"')
end