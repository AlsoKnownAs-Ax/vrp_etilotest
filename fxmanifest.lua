fx_version 'adamant'

game 'gta5'

author '--Ax-#0018'

ui_page 'html/index.html'

files{
    'html/index.html',
    'html/main.js',
    'html/style.css',
    'html/reset.css',
    'html/assets/*.*',
}

client_scripts {
    "lib/Tunnel.lua",
	"lib/Proxy.lua",
    "config.lua",
    "lang.lua",
    'main/client.lua',
}

server_scripts{
    "@vrp/lib/utils.lua",
    "config.lua",
    "lang.lua",
    'main/server.lua',
}