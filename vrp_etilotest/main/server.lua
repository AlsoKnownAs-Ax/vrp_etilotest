--/////////// vRP bind \\\\\\\\\\\--

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","alcohol_system")

vRPCax = Tunnel.getInterface("alcohol_system","alcohol_system")

vRPSax = {}
Tunnel.bindInterface("alcohol_system",vRPSax)
Proxy.addInterface("alcohol_system",vRPSax)

--===============================================--

local requests = {}
local users_alch = {}

function vRPSax.sync_alcohol(drunk_level)
  local user_id = vRP.getUserId{source}
  if user_id then
    users_alch[user_id] = drunk_level
  end
end

use_etilotest = function(source)
  local choices = {}

  choices["Foloseste"] = {function(player,choice,mod)
      local user_id = vRP.getUserId{player}
      if user_id then
        vRPCax.ActivateEtilotestNUI(player,{})
      end
  end}
  return choices
end

function vRPSax.useEtilotest()
  local user_id = vRP.getUserId{source}
  if user_id then
    vRPclient.getNearestPlayer(source,{Config.etilotest.radius},function(nplayer)
      local source = source
      local target_id = vRP.getUserId{nplayer}
      if not nplayer then
        return vRPclient.notify(source,{NotifyConfig["no_player_nearby"]})
      end

      if requests[target_id] then
        return vRPclient.notify(source,{NotifyConfig["spam_request"]:format(GetPlayerName(nplayer))})
      end

      requests[target_id] = true

      vRP.request({nplayer, NotifyConfig["etilotest_request_msg"], 30, function(nplayer, ok)
        if not ok then
          requests[target_id] = false
          vRPclient.notify(source,{NotifyConfig["target_refused"]:format(GetPlayerName(nplayer))})
          vRPclient.notify(nplayer,{NotifyConfig["player_refused"]})
          return
        else
          requests[target_id] = false
          local source = source
          vRPCax.getDrunkLevel(nplayer,{},function(drunk_level)
            vRPCax.ActivateEtilotestNUI(nplayer,{true})
            vRPCax.ActivateTest(source,{drunk_level})
            vRPCax.ActivateTest(nplayer,{drunk_level,true})
            SetTimeout(7000, function ()
              drunk_level = math.abs(drunk_level)
              if drunk_level < 100 and drunk_level >= 10 then    --// 2 digits
                vRPclient.notify(nplayer,{NotifyConfig["drunk_level"]:format("0."..drunk_level)})
              elseif drunk_level >= 0 and drunk_level < 10 then  --// 1 digit
                vRPclient.notify(nplayer,{NotifyConfig["drunk_level"]:format("0.0"..drunk_level)})
              else
                vRPclient.notify(nplayer,{NotifyConfig["drunk_level"]:format("1.0")})
              end
            end)
          end)
        end
    end})

    end)
  end
end


local function play_eat(player)
    local seq = {
        {"mp_player_inteat@burger", "mp_player_int_eat_burger_enter",1},
        {"mp_player_inteat@burger", "mp_player_int_eat_burger",1},
        {"mp_player_inteat@burger", "mp_player_int_eat_burger_fp",1},
        {"mp_player_inteat@burger", "mp_player_int_eat_exit_burger",1}
    }

    vRPclient.playAnim(player,{true,seq,false})
end
  
local function play_drink(player)
    local seq = {
      {"mp_player_intdrink","intro_bottle",1},
      {"mp_player_intdrink","loop_bottle",1},
      {"mp_player_intdrink","outro_bottle",1}
    }

    vRPclient.playAnim(player,{true,seq,false})
end

local use_choice = function(args)
      local idname = args[1]
      local choices = {}
      local act = "Unknown"
      local ftype = nil

      if Config.items[idname].drink then
        ftype = "drink"
        act = "Drink"
      else
        ftype = "eat"
        act = "Eat"
      end

      local name = Config.items[idname].item_name
  
      choices[act] = {function(player,choice)
        local user_id = vRP.getUserId({player})
        if user_id ~= nil then
          if vRP.tryGetInventoryItem({user_id,idname,1,false}) then
            local vary_hunger = Config.items[idname].vary_hunger or Config.WhitelistItems[idname].vary_hunger
            local vary_thirst = Config.items[idname].vary_thirst or Config.WhitelistItems[idname].vary_thirst
            if vary_hunger ~= 0 then vRP.varyHunger({user_id,vary_hunger}) end
            if vary_thirst ~= 0 then vRP.varyThirst({user_id,vary_thirst}) end
  
            if ftype == "drink" then
              vRPclient.notify(player,{NotifyConfig["drinking"]:format(name)})
  
              play_drink(player)
            elseif ftype == "eat" then
              vRPclient.notify(player,{NotifyConfig["eating"]:format(name)})
              play_eat(player)
            end
            local drunk_to_add = Config.items[idname].alch_level
            vRPCax.addDrunk(player,{drunk_to_add})
            
  
            vRP.closeMenu({player})
  
          end
        end
      end}
  
      return choices
end

for i,v in pairs(Config.items) do
    vRP.defInventoryItem({i,v.item_name,v.item_desc,use_choice,v.item_weight})
end

if Config.etilotest.use then
  local setting = Config.etilotest.item_settings
  vRP.defInventoryItem({setting.item_id,setting.item_name,setting.item_desc,use_etilotest,setting.item_weight})
end


AddEventHandler('vRP:playerSpawn', function(user_id,source,first_spawn)
  if first_spawn then
      exports[Config.Database_export]:execute('SELECT alcohol FROM vrp_users WHERE id = ?',{user_id},function(rows)    
        local alcohol = tonumber(rows[1].alcohol)
        if alcohol ~= 0 then
          vRPCax.addDrunk(source,{alcohol})
          users_alch[user_id] = alcohol
        end
      end)
  else
    vRPCax.makeSober(source,{})
  end
end)

AddEventHandler("vRP:playerLeave",function(user_id,source)
  if user_id then
    local db_save = users_alch[user_id]
    if not db_save then
      db_save = 0
    elseif db_save < 0 then
      db_save = 0
    end
    exports[Config.Database_export]:execute('UPDATE vrp_users SET alcohol = ? WHERE id = ?',{db_save,user_id},function() end)
    requests[user_id] = nil
    users_alch[user_id] = nil
  end
    
end)

---------------------- DEBUG COMMANDS ------------------


-- RegisterCommand('testalch',function(source)
--   vRPCax.ActivateEtilotestNUI(source,{true})
--   vRPCax.ActivateTest(source,{50,true})
-- end)