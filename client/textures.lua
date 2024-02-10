local Settings = require 'config.settings'
local Textures = Settings.Textures
local txd = CreateRuntimeTxd('interactions_txd')

for k,v in pairs(Textures) do
    CreateRuntimeTextureFromImage(txd, tostring(v), "assets/"..Settings.Style.."/"..v..".png")
end