fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 'interact'
author 'darktrovx, chatdisabled, fjamzoo, pushkart2'
description 'Interaction system'
repository 'https://github.com/darktrovx/interact'

files {
    'client/interactions.lua',
    'client/utils.lua',
    'client/entities.lua',
    'shared/settings.lua',
    'shared/log.lua',
    'bridge/init.lua',
    'bridge/**/client.lua',
    'assets/**/*.png'
}


shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/textures.lua',
    'client/interacts.lua',
    'client/raycast.lua'
}
server_scripts {
    'server/main.lua',
}