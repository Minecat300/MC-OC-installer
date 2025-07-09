local filesystem = require("filesystem")
local seri = require("serialization")
local computer = require("computer")
local shell = require("shell")
local uinutils = require("uinutils")

local M = {}

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

        local fullPath = filesystem.concat(installPath, subPath, name)

        if type == "file" then
            uinutils.ensureDirs(fullPath)
            uinutils.installFile(uinutils.url_concat(baseUrl, name), fullPath)
        end

        if type == "dir" then
            local fileInstalls = value.fileInstalls
            if not fileInstalls then
                print("Failed to install. No files found in dir: " .. name)
                return
            end

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
            uinutils.deleteRecursive(fullPath)
        end
    end
end

local function addPackageData(packageName, installJson, url, fileInstalls, installPath, autoUpdate, runOnBoot, programPath)
    local packageData = uinutils.getPackageData()
    packageData[packageName] = {}
    packageData[packageName].url = url
    packageData[packageName].installedFiles = seri.serialize(fileInstalls)
    packageData[packageName].installPath = installPath
    packageData[packageName].description = installJson.description
    packageData[packageName].autoUpdate = autoUpdate
    packageData[packageName].runOnBoot = runOnBoot
    packageData[packageName].programPath = programPath
    packageData[packageName].version = installJson.version or "1.0"
    uinutils.savePackageData(packageData)
end

local function removePackageData(packageName)
    local packageData = uinutils.getPackageData()
    packageData[packageName] = nil
    uinutils.savePackageData(packageData)
end

function M.update(packageName, forcedReboot)
    local packageData = uinutils.getPackageData()
    if not packageData[packageName] then
        print("No package named (" .. packageName .. ") was found")
        return
    end

    print("Updating package: " .. packageName)

    local rawUrl = packageData[packageName].url
    local autoUpdate = packageData[packageName].autoUpdate or false

    local installJson, newPackageName, fileInstalls, installPath = uinutils.getPackageInstallJson(rawUrl)
    if not installJson then
        return
    end

    installFileArray(rawUrl, fileInstalls, installPath)
    removePackageData(packageName)
    addPackageData(newPackageName, installJson, rawUrl, fileInstalls, installPath, autoUpdate, installJson.runOnBoot or false, installJson.programPath or false)
    if packageName == newPackageName then
        print(packageName .. " was updated to newest version!")
    else
        print(packageName .. " was updated with new name: " .. newPackageName)
    end
    print("Note: Some packages might need a reboot for the update to take into effect")

    if installJson.rebootAfterUpdate then
        if forcedReboot then
            computer.shutdown(true)
        end
        io.write("Want to reboot now? y or n: ")
        local answer = io.read()

        if answer == "y" then
            computer.shutdown(true)
        end
    end
end

function M.autoUpdate(packageName, forcedReboot)
    local packageData = uinutils.getPackageData()
    if not packageData[packageName] then
        print("No package named (" .. packageName .. ") was found")
        return
    end

    local oldVersion = packageData[packageName].version
    local rawUrl = packageData[packageName].url

    local installJson = uinutils.getJson(rawUrl .. "/install.json")
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
    M.update(packageName, forcedReboot)
end

function M.autoUpdateAll(forcedReboot)
    local packageData = uinutils.getPackageData()
    for key, value in pairs(packageData) do
        if value.autoUpdate then
            print("Check update for: " .. key)
            M.autoUpdate(key, forcedReboot)
        end
    end
end

function M.uninstall(packageName)
    local packageData = uinutils.getPackageData()
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

    local installJson, packageName, fileInstalls, installPath = uinutils.getPackageInstallJson(url)
    if not installJson then
        return
    end

    --print(seri.serialize(installJson))

    local dependencies = installJson.dependencies
    if dependencies then
        for _, packageUrl in ipairs(dependencies) do
            if not uinutils.isPackageInstalledByUrl(packageUrl) then
                M.install(packageUrl)
            end
        end
    end

    installFileArray(url, fileInstalls, installPath)
    addPackageData(packageName, installJson, url, fileInstalls, installPath, installJson.autoUpdate or false, installJson.runOnBoot or false, installJson.programPath or false)
    print(packageName .. " was installed!")

    local runOnInstall = installJson.runOnInstall
    if runOnInstall then
        shell.execute(runOnInstall)
    end
end
return M