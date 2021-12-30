-------------------------------------
-- Required
-------------------------------------

-- Set PlayerData into the ESX table
RegisterNetEvent('esx:playerLoaded', function(xPlayer, isNew)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

-- Reset PlayerData after the player has logged out (esx_multicharacter)
RegisterNetEvent('esx:playerLogout')
AddEventHandler('esx:playerLogout', function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)

-- Receive PlayerData from ESX
OnPlayerData = function(key, val, last)
	if type(val) == 'table' then val = json.encode(val) end
	print('PlayerData.'..key..' was set to '..val)
	if key == 'job' then
		if last.name ~= val.name then
			print('You are now in a different job')
		end
	elseif key == 'dead' then -- However, this function can be used for other PlayerData
		if val == true then
			print('You die too easily')
		end
	end
end


-------------------------------------
-- Sample ESX functions
-------------------------------------

RegisterCommand('closestobject', function()
	local result = ESX.Game.GetClosestObject(GetEntityCoords(ESX.PlayerData.ped))
	print(json.encode(result))
end)

RegisterCommand('closestped', function()
	local result = ESX.Game.GetClosestPed(GetEntityCoords(ESX.PlayerData.ped))
	print(json.encode(result))
end)

RegisterCommand('closestplayer', function()
	local result = ESX.Game.GetClosestPlayer(GetEntityCoords(ESX.PlayerData.ped))
	print(json.encode(result))
end)

RegisterCommand('closestvehicle', function()
	local result = ESX.Game.GetClosestVehicle(GetEntityCoords(ESX.PlayerData.ped))
	print(result)
end)

RegisterCommand('areaplayer', function()
	local result = ESX.Game.GetPlayersInArea(GetEntityCoords(ESX.PlayerData.ped), 20)
	print(json.encode(result))
end)

RegisterCommand('areavehicle', function()
	local result = ESX.Game.GetVehiclesInArea(GetEntityCoords(ESX.PlayerData.ped), 20)
	print(json.encode(result))
end)
