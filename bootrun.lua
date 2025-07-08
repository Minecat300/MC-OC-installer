package.path = "/Uinstall/?.lua;" .. package.path
local packInstaller = require("packageInstaller")
local uinutils = require("uinutils")
local term = require("term")
local shell = require("shell")
local keyboard = require("keyboard")
local seri = require("serialization")

term.clear()
term.setCursor(1, 1)
packInstaller.autoUpdateAll()

local packageData = uinutils.readFile("/Uinstall/packageData")

local packageWeights = {}
for name, value in pairs(packageData) do
    if value.runOnBoot then
        packageWeights[name] = value.runOnBoot.weight or 1
    end
end

--print(seri.serialize(packageWeights))

packageWeights = uinutils.sortByWeight(packageWeights)

os.sleep(2)
if keyboard.isAltDown() and keyboard.isControlDown() then
    return
end

--print(seri.serialize(packageWeights))

for _, name in ipairs(packageWeights) do
    shell.execute(packageData[name].runOnBoot.path)
end