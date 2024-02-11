local settings = require 'shared.settings'
local textures = settings.Textures
local txd = CreateRuntimeTxd('interactions_txd')

for _, v in pairs(textures) do
    CreateRuntimeTextureFromImage(txd, tostring(v), "assets/"..settings.Style.."/"..v..".png")
end