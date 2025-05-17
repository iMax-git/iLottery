fx_version "adamant"
game "gta5"

author "iMax & Reworking by DakoM"
description "ADN'S Lottery"
version "1.0.0"
purchase_only_in "https://adns-fivem.fr"

escrow_ignore {
    "Lottery.sql",
    "Config.lua",  -- Only ignore one file
    "RageUI/RMenu.lua",
    "RageUI/menu/RageUI.lua",
    "RageUI/menu/Menu.lua",
    "RageUI/menu/MenuController.lua",
    "RageUI/components/*.lua",
    "RageUI/menu/elements/*.lua",
    "RageUI/menu/items/*.lua",
    "RageUI/menu/panels/*.lua",
    "RageUI/menu/windows/*.lua",
}

shared_script "Config.lua"

lua54 "yes"

client_scripts {
    "RageUI/RMenu.lua",
    "RageUI/menu/RageUI.lua",
    "RageUI/menu/Menu.lua",
    "RageUI/menu/MenuController.lua",
    "RageUI/components/*.lua",
    "RageUI/menu/elements/*.lua",
    "RageUI/menu/items/*.lua",
    "RageUI/menu/panels/*.lua",
    "RageUI/menu/windows/*.lua",

    "client.lua"
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    "server.lua"
}