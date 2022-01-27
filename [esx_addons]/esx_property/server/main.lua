function GetProperty(name)
	for i=1, #Config.Properties, 1 do
		if Config.Properties[i].name == name then
			return Config.Properties[i]
		end
	end
end

function SetPropertyOwned(name, price, rented, owner)
	MySQL.query('INSERT INTO owned_properties (name, price, rented, owner) VALUES (@name, @price, @rented, @owner)', {
		['@name']   = name,
		['@price']  = price,
		['@rented'] = (rented and 1 or 0),
		['@owner']  = owner
	}, function(rowsChanged)
		local xPlayer = ESX.GetPlayerFromIdentifier(owner)

		if xPlayer then
			TriggerClientEvent('esx_property:setPropertyOwned', xPlayer.source, name, true, rented)

			if rented then
				xPlayer.showNotification(_U('rent_for', ESX.Math.GroupDigits(price)))
			else
				xPlayer.showNotification(_U('buy_for', ESX.Math.GroupDigits(price)))
			end
		end
	end)
end

function RemoveOwnedProperty(name, owner, noPay)
	MySQL.query('SELECT id, rented, price FROM owned_properties WHERE name = ? AND owner = ?', {
		name, owner
	}, function(result)
		if result[1] then
			MySQL.update('DELETE FROM owned_properties WHERE id = @id', {
				['@id'] = result[1].id
			}, function(rowsChanged)
				local xPlayer = ESX.GetPlayerFromIdentifier(owner)

				if xPlayer then
					xPlayer.triggerEvent('esx_property:setPropertyOwned', name, false)

					if not noPay then
						if result[1].rented == 1 then
							xPlayer.showNotification(_U('moved_out'))
						else
							local sellPrice = ESX.Math.Round(result[1].price / Config.SellModifier)

							xPlayer.showNotification(_U('moved_out_sold', ESX.Math.GroupDigits(sellPrice)))
							xPlayer.addAccountMoney('bank', sellPrice)
						end
					end
				end
			end)
			MySQL.update('DELETE FROM ox_inventory WHERE owner = ? AND name = ?', {
				owner, ('%s%s'):format(owner, name)
			})
		end
	end)
end

local ox_inventory = exports.ox_inventory

MySQL.query('SELECT * FROM `properties`', {}, function(properties)
	while GetResourceState('ox_inventory') ~= 'started' do Wait(0) end
	for i=1, #properties, 1 do
		local property = properties[i]

		ox_inventory:RegisterStash(property.name, property.label, 50, 100000, true)

		local entering  = nil
		local exit      = nil
		local inside    = nil
		local outside   = nil
		local isSingle  = nil
		local isRoom    = nil
		local isGateway = nil
		local roomMenu  = nil

		if properties[i].entering then
			entering = json.decode(property.entering)
			entering = vec3(entering.x, entering.y, entering.z)
		end

		if property.exit then
			exit = json.decode(property.exit)
			exit = vec3(exit.x, exit.y, exit.z)
		end

		if property.inside then
			inside = json.decode(property.inside)
			inside = vec3(inside.x, inside.y, inside.z)
		end

		if property.outside then
			outside = json.decode(property.outside)
			outside = vec3(outside.x, outside.y, outside.z)
		end

		if property.is_single == 0 then
			isSingle = false
		else
			isSingle = true
		end

		if property.is_room == 0 then
			isRoom = false
		else
			isRoom = true
		end

		if property.is_gateway == 0 then
			isGateway = false
		else
			isGateway = true
		end

		if property.room_menu then
			roomMenu = json.decode(property.room_menu)
			roomMenu = vec3(roomMenu.x, roomMenu.y, roomMenu.z)
		end

		table.insert(Config.Properties, {
			name      = property.name,
			label     = property.label,
			entering  = entering,
			exit      = exit,
			inside    = inside,
			outside   = outside,
			ipls      = json.decode(property.ipls),
			gateway   = property.gateway,
			isSingle  = isSingle,
			isRoom    = isRoom,
			isGateway = isGateway,
			roomMenu  = roomMenu,
			price     = property.price
		})
	end

	TriggerClientEvent('esx_property:sendProperties', -1, Config.Properties)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName then
		while GetResourceState('ox_inventory') ~= 'started' do Wait(50) end
	  	for i=1, #Config.Properties do
			local property = Config.Properties[i]
			ox_inventory:RegisterStash(property.name, property.label, 50, 100000, true)
		end
	end
end)

ESX.RegisterServerCallback('esx_property:getProperties', function(source, cb)
	cb(Config.Properties)
end)

AddEventHandler('esx_ownedproperty:getOwnedProperties', function(cb)
	MySQL.query('SELECT * FROM owned_properties', {}, function(result)
		local properties = {}

		for i=1, #result, 1 do
			table.insert(properties, {
				id     = result[i].id,
				name   = result[i].name,
				label  = GetProperty(result[i].name).label,
				price  = result[i].price,
				rented = (result[i].rented == 1 and true or false),
				owner  = result[i].owner
			})
		end

		cb(properties)
	end)
end)

AddEventHandler('esx_property:setPropertyOwned', function(name, price, rented, owner)
	SetPropertyOwned(name, price, rented, owner)
end)

AddEventHandler('esx_property:removeOwnedProperty', function(name, owner)
	RemoveOwnedProperty(name, owner)
end)

RegisterNetEvent('esx_property:rentProperty')
AddEventHandler('esx_property:rentProperty', function(propertyName)
	local xPlayer  = ESX.GetPlayerFromId(source)
	local property = GetProperty(propertyName)
	local rent     = ESX.Math.Round(property.price / Config.RentModifier)

	SetPropertyOwned(propertyName, rent, true, xPlayer.identifier)
end)

RegisterNetEvent('esx_property:buyProperty')
AddEventHandler('esx_property:buyProperty', function(propertyName)
	local xPlayer  = ESX.GetPlayerFromId(source)
	local property = GetProperty(propertyName)

	if property.price <= xPlayer.getMoney() then
		xPlayer.removeMoney(property.price)
		SetPropertyOwned(propertyName, property.price, false, xPlayer.identifier)
	else
		xPlayer.showNotification(_U('not_enough'))
	end
end)

RegisterNetEvent('esx_property:removeOwnedProperty')
AddEventHandler('esx_property:removeOwnedProperty', function(propertyName)
	local xPlayer = ESX.GetPlayerFromId(source)
	RemoveOwnedProperty(propertyName, xPlayer.identifier)
end)

AddEventHandler('esx_property:removeOwnedPropertyIdentifier', function(propertyName, identifier)
	RemoveOwnedProperty(propertyName, identifier)
end)

RegisterNetEvent('esx_property:saveLastProperty')
AddEventHandler('esx_property:saveLastProperty', function(property)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query('UPDATE users SET last_property = @last_property WHERE identifier = @identifier', {
		['@last_property'] = property,
		['@identifier']    = xPlayer.identifier
	})
end)

RegisterNetEvent('esx_property:deleteLastProperty')
AddEventHandler('esx_property:deleteLastProperty', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query('UPDATE users SET last_property = NULL WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	})
end)

ESX.RegisterServerCallback('esx_property:getOwnedProperties', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT name, rented FROM owned_properties WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier
	}, function(result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback('esx_property:getLastProperty', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT last_property FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(users)
		cb(users[1].last_property)
	end)
end)

ESX.RegisterServerCallback('esx_property:getPlayerDressing', function(source, cb)
	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local count  = store.count('dressing')
		local labels = {}

		for i=1, count, 1 do
			local entry = store.get('dressing', i)
			table.insert(labels, entry.label)
		end

		cb(labels)
	end)
end)

ESX.RegisterServerCallback('esx_property:getPlayerOutfit', function(source, cb, num)
	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local outfit = store.get('dressing', num)
		cb(outfit.skin)
	end)
end)

RegisterNetEvent('esx_property:removeOutfit')
AddEventHandler('esx_property:removeOutfit', function(label)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local dressing = store.get('dressing') or {}

		table.remove(dressing, label)
		store.set('dressing', dressing)
	end)
end)

function payRent(d, h, m)
	local timeStart = os.clock()
	print('[esx_property] [^2INFO^7] Paying rent cron job started')

	MySQL.query('SELECT * FROM owned_properties WHERE rented = 1', {}, function(result)
		for _,v in ipairs(result) do
			local xPlayer = ESX.GetPlayerFromIdentifier(v.owner)

			if xPlayer then
				if xPlayer.getAccount('bank').money >= v.price then
					xPlayer.removeAccountMoney('bank', v.price)
					xPlayer.showNotification(_U('paid_rent', ESX.Math.GroupDigits(v.price), GetProperty(v.name).label))
				else
					xPlayer.showNotification(_U('paid_rent_evicted', GetProperty(v.name).label, ESX.Math.GroupDigits(v.price)))
					RemoveOwnedProperty(v.name, v.owner, true)
				end
			else
				MySQL.scalar('SELECT accounts FROM users WHERE identifier = @identifier', {
					['@identifier'] = v.owner
				}, function(accounts)
					if accounts then
						local playerAccounts = json.decode(accounts)

						if playerAccounts and playerAccounts.bank then
							if playerAccounts.bank >= v.price then
								playerAccounts.bank = playerAccounts.bank - v.price

								MySQL.query('UPDATE users SET accounts = @accounts WHERE identifier = @identifier', {
									['@identifier'] = v.owner,
									['@accounts'] = json.encode(playerAccounts)
								})
							else
								RemoveOwnedProperty(v.name, v.owner, true)
							end
						end
					end
				end)
			end

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_realestateagent', function(account)
				account.addMoney(v.price)
			end)
		end

		local elapsedTime = os.clock() - timeStart
		print(('[esx_property] [^2INFO^7] Paying rent cron job took %s seconds'):format(elapsedTime))
	end)
end

TriggerEvent('cron:runAt', 22, 0, payRent)