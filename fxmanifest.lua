fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54        'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/textures.lua',
    'client/interacts.lua',
    'client/utils.lua',
    'client/raycast.lua',
}
server_scripts {
    'server/main.lua',
}

files {
    'client/interactions.lua',
    'client/utilities.lua',
    'config/settings.lua',
    'assets/**/*.png'
} 