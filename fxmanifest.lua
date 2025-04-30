fx_version 'cerulean'
game 'gta5'

description 'Salvage Diver Job for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Only if you're using database features
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.*'
}

lua54 'yes'