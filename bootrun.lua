package.path = "/Uinstall/?.lua;" .. package.path
local packInstaller = require("packageInstaller")
local term = require("term")
term.clear()
term.setCursor(1, 1)
packInstaller.autoUpdateAll()