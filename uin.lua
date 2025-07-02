#!/usr/bin/env lua
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
end