Citizen.CreateThread(function()
	Citizen.Wait(3000)
	print('^1Do not run this resource in a live environment, it is solely intended for showcasing ESX functions^0')
end)

-- When a player loads in, we can store some basic information about them locally
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer, isNew)
	ESX.Players[playerId] = xPlayer.job.name

	if isNew then
		-- do stuff for new players only
		print(playerid..' is new')
	end
end)

-- The stored data does not sync with the framework unless we tell it to
AddEventHandler('esx:setJob', function(playerId, job, lastJob)
	ESX.Players[playerId].jobName = job.name
end)

-- Remove any cached data once the player no longer exists
AddEventHandler('esx:playerDropped', function(playerId, reason)
	ESX.Players[playerId] = nil
end)

-- The resource just restarted and we've received a fresh copy of the ESX table
AddEventHandler('onServerResourceStart', function(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		if not ESX.Players or not next(ESX.Players) then
			ESX.Players = ESX.GetExtendedPlayers()
		end

		local xPlayers = {}
		for _, xPlayer in pairs(ESX.Players) do
			xPlayers[xPlayer.source] = {
				identifier = xPlayer.identifier,
				jobName = xPlayer.job.name
			}
		end

		-- We don't need the full entry of ESX.Players
		ESX.Players = xPlayers
	end
end)

-- xPlayer loop, with the ability to only return players with specific data
-- Job and any non-table variable will work, ie. name, group, identifier, source
ESX.RegisterCommand('get', 'user', function(xPlayer, args, showError)
	local xPlayers = ESX.GetExtendedPlayers(args.key, args.val)

	for _, xPlayer in pairs(xPlayers) do
		print(xPlayer.source, xPlayer[args.key], json.encode(xPlayer.job))
	end
end, true, {help = 'Display all online players with specific player data', validate = false, arguments = {
	{name = 'key', help = 'Variable to check (ie. job)', type = 'string'},
	{name = 'val', help = 'Value required (ie. police)', type = 'any'}
}})
