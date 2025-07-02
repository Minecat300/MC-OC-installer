package.path = "/Uinstall/?.lua;" .. package.path
local packInstaller = require("packageInstaller")
packInstaller.autoUpdateAll()