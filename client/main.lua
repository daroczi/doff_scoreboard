--  AUTHOR: DoFF - https://github.com/daroczi/doff_scoreboard
-- 
-- /$$$$$$$          /$$$$$$$$/$$$$$$$$        /$$$$$$                                     /$$                                       /$$
-- | $$__  $$        | $$_____| $$_____/       /$$__  $$                                   | $$                                      | $$
-- | $$  \ $$ /$$$$$$| $$     | $$            | $$  \__/ /$$$$$$$ /$$$$$$  /$$$$$$  /$$$$$$| $$$$$$$  /$$$$$$  /$$$$$$  /$$$$$$  /$$$$$$$
-- | $$  | $$/$$__  $| $$$$$  | $$$$$         |  $$$$$$ /$$_____//$$__  $$/$$__  $$/$$__  $| $$__  $$/$$__  $$|____  $$/$$__  $$/$$__  $$
-- | $$  | $| $$  \ $| $$__/  | $$__/          \____  $| $$     | $$  \ $| $$  \__| $$$$$$$| $$  \ $| $$  \ $$ /$$$$$$| $$  \__| $$  | $$
-- | $$  | $| $$  | $| $$     | $$             /$$  \ $| $$     | $$  | $| $$     | $$_____| $$  | $| $$  | $$/$$__  $| $$     | $$  | $$
-- | $$$$$$$|  $$$$$$| $$     | $$            |  $$$$$$|  $$$$$$|  $$$$$$| $$     |  $$$$$$| $$$$$$$|  $$$$$$|  $$$$$$| $$     |  $$$$$$$
-- |_______/ \______/|__/     |__/             \______/ \_______/\______/|__/      \_______|_______/ \______/ \_______|__/      \_______/
-- 

ESX = nil

if Config.legacy then
	ESX = exports["es_extended"]:getSharedObject()
else
	Citizen.CreateThread(function()
		while ESX == nil do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(0)
		end
	
		while ESX.GetPlayerData().job == nil do
			Citizen.Wait(10)
		end
		ESX.PlayerData = ESX.GetPlayerData()
	
	end)
end

local showPlayerId, isScoreboardActive = true, false
local setupStatus = false

Citizen.CreateThread(function()
	Citizen.Wait(1000)
	ESX.TriggerServerCallback('doff_scoreboard:getConnectedPlayers', function(connectedPlayers, maxPlayers)
		UpdatePlayerTable(connectedPlayers)

		SendNUIMessage({
			action = 'updateServerInfo',
			maxPlayers = maxPlayers,
			uptime = "Unkown",
			playTime = '00h 00m'
		})
	end)
end)

RegisterNetEvent('doff_scoreboard:updateConnectedPlayers')
AddEventHandler('doff_scoreboard:updateConnectedPlayers', function(connectedPlayers)
	UpdatePlayerTable(connectedPlayers)
end)


RegisterNetEvent('doff_scoreboard:setUptime')
AddEventHandler('doff_scoreboard:setUptime', function(uptime)
	SendNUIMessage({
		action = 'uptime',
		uptime = uptime
	})
end)

RegisterNetEvent('doff_scoreboard:updatePing')
AddEventHandler('doff_scoreboard:updatePing', function(connectedPlayers)
	SendNUIMessage({action = 'updatePing', players = connectedPlayers})
end)

RegisterNetEvent('uptime:tick')
AddEventHandler('uptime:tick', function(uptime)
	SendNUIMessage({action = 'updateServerInfo', uptime = uptime})
end)

function UpdatePlayerTable(connectedPlayers)
	local formattedPlayerList = {}
	local jobList = {}
	local players = 0

	for k,v in pairs(Config.jobList) do
		_G[""..k] = 0
	end

	for k,v in pairs(connectedPlayers) do
		local lvl = math.floor((v.uptime / Config.lvlDivider))
		if lvl > Config.maxLvl then
			lvl = Config.maxLvl
		end

		if #v.name < 26 then		
			table.insert(formattedPlayerList, ('<div class="player-item"><div class="player-id">%s</div><div class="player-name">%s</div><div class="player-lvl" style="display: none;">lvl %s</div><div class="player-ping">%s ms</div></div>'):format(v.playerId, v.name, lvl, v.ping))
		else
			table.insert(formattedPlayerList, ('<div class="player-item"><div class="player-id">%s</div><div class="player-name extra-long">%s</div><div class="player-lvl" style="display: none;">lvl %s</div><div class="player-ping">%s ms</div></div>'):format(v.playerId, v.name, lvl, v.ping))
		end
		players = players + 1

		for l,p in pairs(Config.jobList) do
			if v.job == l then
				_G[""..l] = _G[""..l] + 1
			end
		end
	end

	for k,v in pairs(Config.jobList) do
		jobList[k] = _G[""..k]
	end

	SendNUIMessage({action = 'updatePlayerList', players = table.concat(formattedPlayerList)})

	SendNUIMessage({
		action = 'updatePlayerJobs',
		jobs = jobList,
		player_count = players,
		shop = Config.shopRobbery,
		mshop = Config.minimumShop,
		bank = Config.bankRobbery,
		mbank = Config.minimumBank
	})

	if setupStatus == false then
		StarterSetup()
		print('Bement az if ágba')
		setupStatus = true
	end
end

function StarterSetup() 
	SendNUIMessage({
		action = 'setupScoreboard',
		bg = Config.backgroundColor,
		top = Config.backgroundTopColor,
		frame = Config.frameColor,
		list = Config.listElementBackgroundColor,
		heading = Config.headingBackgroundColor,
		radius = Config.globalRadius,
		serverName = Config.serverName,
		jobColumns = Config.jobList,
		shop = Config.shopRobbery,
		mshop = Config.minimumShop,
		bank = Config.bankRobbery,
		mbank = Config.minimumBank
	})

	SendNUIMessage({
		action = 'langSetup',
		playerlang = Config.playerLang,
		playtimelang = Config.playerTimeLang,
		uptimelang = Config.uptimeLang,
		playernamelang = Config.playerNameLang,
		lvlpinglang = Config.lvlPingLang
	})
end

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() and isScoreboardActive then
		SetNuiFocus(false)
	end
end)


RegisterCommand('scoreboard', function()
    if not isScoreboardActive then
		isScoreboardActive = true
		SetNuiFocus(true, true)
		SendNUIMessage({action = 'enable'})
		Citizen.Wait(1000)
	else
		isScoreboardActive = false
		SendNUIMessage({action = 'close'})
		SetNuiFocus(false, false)
	end
end, false)

RegisterKeyMapping('scoreboard', 'Scoreboard', 'keyboard', Config.keymap)

Citizen.CreateThread(function()
	local playMinute, playHour = 0, 0

	while true do
		Citizen.Wait(60000)
		playMinute = playMinute + 1

		if playMinute == 60 then
			playMinute = 0
			playHour = playHour + 1
		end

		SendNUIMessage({
			action = 'updateServerInfo',
			playTime = string.format("%02dh %02dm", playHour, playMinute)
		})
	end
end)

local firstSpawn = false

AddEventHandler('esx:playerLoaded', function()
	if firstSpawn == false then
		TriggerServerEvent('doff_scoreboard:loggedIn', GetPlayerName(PlayerId()))
		firstSpawn = true
	end
end)