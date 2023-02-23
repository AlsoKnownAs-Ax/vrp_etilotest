if not Config then Config = {} end

Config.debug = false                    --// Helpful debugging prints (no reason to leave it ON unless you know what are u doing)

Config.Database_export = "oxmysql"
Config.sv_sync_timer = 45                   --// Sync to server-side timer ( i recommand leaving it at 45 secs)

Config.Drunk_driver = {
    use = true,         --// while true the car will randomly go left/right/fowards/backwards and much more
    change = 6          --// 6 = 60%
}
Config.etilotest = {
    use = true,
    radius = 5,
    -------------------
    item_settings = {
        item_id = "etilotest",
        item_name = "Etilotest",
        item_desc = "Etilotest",
        item_weight = 0.5,
    },
}
Config.FallChance = 5       --// 5 = 50%

Config.levels = {
    {
        anim = "MOVE_M@DRUNK@SLIGHTLYDRUNK",
        percentage = 20,
        random_fall = false
    },
    {
        anim = "MOVE_M@DRUNK@MODERATEDRUNK_HEAD_UP",
        percentage = 40,
        random_fall = false
    },
    {
        anim = "MOVE_M@DRUNK@MODERATEDRUNK",
        percentage = 60,
        random_fall = false
    },
    {
        anim = "MOVE_M@DRUNK@VERYDRUNK",
        percentage = 80,
        random_fall = true              --// while true the player will randomly fall if he`s at this drunk level
    }
}

Config.items = {
    ["vodka"] = {
        drink = true,
        alch_level = 40,
        item_name = "Vodka",
        item_desc = "O vodka nebuna",
        item_weight = 0.5,
        vary_hunger = 5,
        vary_thirst = -10
    },
    ["beer"] = {
        drink = true,
        alch_level = 5,
        item_name = "Bere",
        item_desc = "O Bere",
        item_weight = 0.3,
        vary_hunger = 5,
        vary_thirst = -10
    },
    ["water"] = {
        drink = true,
        alch_level = -math.random(5),
        item_name = "Apa",
        item_desc = "O Apa",
        item_weight = 0.2,
        vary_hunger = 5,
        vary_thirst = -20
    }
}
