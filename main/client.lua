--/////////// vRP bind \\\\\\\\\\\--

vRPCax = {}
Tunnel.bindInterface("alcohol_system",vRPCax)
Proxy.addInterface("alcohol_system",vRPCax)
vRP = Proxy.getInterface("vRP")
vRPSax = Tunnel.getInterface("alcohol_system","alcohol_system")

--===============================================--

local drunk_level = 0
local random_fall = false
local drunk_loop = false
local anim_level = 0
local firstspawn = false

local function Debug(...)
	if Config.debug then
		local args = {...}
		print(json.encode(args))
	end
end

local function playMovement(clipset)
	local ped = PlayerPedId()
	RequestAnimSet(clipset)
	while not HasAnimSetLoaded(clipset) do
		Citizen.Wait(0)
	end
	SetTimecycleModifier("spectator5")
	SetPedMotionBlur(ped, true) 
	SetPedMovementClipset(ped, clipset, true)
	SetPedIsDrunk(ped, true)
end

local function resetMovement()
	local ped = PlayerPedId()
	random_fall = false
	ClearTimecycleModifier()
	ResetScenarioTypesEnabled()
	ResetPedMovementClipset(ped, 0)
	SetPedIsDrunk(ped, false)
	SetPedMotionBlur(ped, false)
end

local function choose_walking()
	local walking = nil
	random_fall = false
	for i,v in pairs(Config.levels) do
		if drunk_level >= v.percentage*10 then
			walking = v.anim
			random_fall = v.random_fall
			anim_level = i
		end
	end
	return walking
end

function vRPCax.addDrunk(_lvl)
	if _lvl < 0 then
		if drunk_level - _lvl*10 < 0 then
			drunk_level = 1
		end
	end
	if drunk_level+(_lvl*10) > 1000 then
		drunk_level = 1000
	else
		drunk_level = drunk_level + _lvl*10
	end
	local walking = choose_walking()
	playMovement(walking)
	if not drunk_loop then
		Citizen.CreateThread(function ()
			local shake = false
			drunk_loop = true
			local vehicle_notifed = false
			while drunk_level > 0 do

				local ped = PlayerPedId()			--// Leave this like that , else the first spawn restore will break your script

				if IsPedInAnyVehicle(ped, false) and not vehicle_notifed then
					vRP.notify{NotifyConfig["entered_vehicle"]}
					vehicle_notifed = true
				elseif not IsPedInAnyVehicle(ped, false) then
					vehicle_notifed = false
				end

				if drunk_level > 100 and Config.Drunk_driver.use and IsPedInAnyVehicle(ped, false) then
					local sansa = math.random(10)
					if sansa <= Config.Drunk_driver.change then
						local task = math.random(32)
						while task == 16 or task == 17 or task == 18 or task == 15 do	--// These tasks will crash the user
							Debug("blacklisted Task")
							Wait(200)
							task = math.random(32)
						end
						Debug("task: ",task)
						TaskVehicleTempAction(ped,GetVehiclePedIsIn(ped, false),task,500)
					end
				end
				
				Citizen.Wait(5000)
				Debug("random_fall: ",random_fall)
				if random_fall then
					if not shake then
						ShakeGameplayCam("DRUNK_SHAKE",0.8)
						shake = true
					end
					local change = math.random(10)
					if change <= Config.FallChance then
						SetPedToRagdollWithFall(ped, 1500, 2000, 1, GetEntityForwardVector(ped))
					end
				elseif shake then
					StopGameplayCamShaking(false)
					shake = false
				end
				drunk_level = drunk_level - 2
				Debug("lowered drunk_level: ",drunk_level)
				if drunk_level < Config.levels[anim_level].percentage*10 and walking then
					walking = choose_walking()
					if walking then
						playMovement(walking)
					end
				end

				if not firstspawn then
					firstspawn = true
					walking = choose_walking()
					if walking then
						playMovement(walking)
					end
					Debug("FIRST SPAWN DETECTED, WALKING RESTORED")
				end
				
				if drunk_level <= Config.levels[1].percentage*10 then
					resetMovement()
				end
				if drunk_level <= 0 then
					drunk_loop = false
				end
			end
		end)
		Citizen.CreateThread(function ()
			while drunk_loop do
				Citizen.Wait(Config.sv_sync_timer*1000)
				if drunk_level < 0 then
					drunk_level = 0
				end
				vRPSax.sync_alcohol({math.floor(drunk_level/10)})
				Debug("SYNCED: ",math.floor(drunk_level/10))
			end
		end)
	else
		Debug("drunk loop already ongoing")
	end
end

function vRPCax.getDrunkLevel()
	return math.floor(drunk_level/10)
end

function vRPCax.lowerDrunk(_lvl)
	if drunk_level-(_lvl*10) < 0 then
		drunk_level = 0
	else
		drunk_level = drunk_level - _lvl*10
	end
end

function vRPCax.makeSober()
	drunk_level = 0
	resetMovement()
	drunk_loop = false
end

function vRPCax.ActivateEtilotestNUI(target)
	if not target then
		SetNuiFocus(true, true)
	end
	SendNUIMessage({
		open = true,
	})
end

function vRPCax.ActivateTest(drunk_level,target)
	SendNUIMessage({
		test = true,
		drunk_level = drunk_level,
		target = target
	})
end

RegisterNUICallback("action", function (data,cb)
	local type = data.type
    if type == "close" then
		SetNuiFocus(false, false)
		cb('ok')
	elseif type == "use" then
		vRPSax.useEtilotest({})
	end
end)


---====================== DEBUG COMMANDS =============================--

if Config.debug then
	RegisterCommand('zzz', function ()
		resetMovement()
		drunk_level = 0
		ShakeGameplayCam("DRUNK_SHAKE",0.8)
	end)

	RegisterCommand('xxx', function ()
		StopGameplayCamShaking(false)
		SetEntityHealth(PlayerPedId(), 200)
	end)
end

