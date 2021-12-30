### ESX Imports
##### Similar to importing the ESX locale functions or MySQL-Async, there is now an import for ESX
- Define `shared_script '@es_extended/imports.lua'` above all other scripts in your fxmanifest
- This will define the ESX object for both the client and server
- You can add your own logic if there's code you need to re-use often and without overhead from function references
##### The following event handler will also be created on the client
```lua
AddEventHandler('esx:setPlayerData', function(key, val)
	if GetInvokingResource() == 'es_extended' then
		ESX.PlayerData[key] = val
		if OnPlayerData ~= nil then OnPlayerData(key, val) end
	end
end)
```


### Replacement for ESX.GetPlayers()
##### Old resources would utilise the ESX.GetPlayers() function in a loop with ESX.GetPlayerFromId() to retrieve xPlayer data
- This can be referred to as an xPlayer loop, and has been the cause for server hitches in resources such as esx_society and esx_status
- It is commonly used in robbery scripts to get the active number of cops, or for determining the number of EMS in other places
##### This method is deprecated and should be replaced for ESX Legacy
```lua
local xPlayers = ESX.GetPlayers()
for i=1, #xPlayers, 1 do
	local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
	if xPlayer.job.name == 'police' then
		TriggerClientEvent('esx:showNotification', xPlayers[i], 'You are a cop!')
	end
end
```
##### This new method retrieves all xPlayer data at once, reducing the number of function references being called
```lua
local xPlayers = ESX.GetExtendedPlayers() -- Returns all xPlayers
for _, xPlayer in pairs(xPlayers) do
	if v.job.name == 'police' then
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'You are a cop!')
	end
end

local xPlayers = ESX.GetExtendedPlayers('job', 'police') -- Returns xPlayers with the police job
for _, xPlayer in pairs(xPlayers) do
	TriggerClientEvent('esx:showNotification', xPlayer.source, 'You are a cop!')
end
```