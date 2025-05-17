TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)

local iLottery = {}

iLottery.getLicenseType = function(_src, typelicence)
    local source = tonumber(_src);
    for index, identifier in pairs(GetPlayerIdentifiers(source)) do
         if typelicence == "discord" or typelicence == "steam" or typelicence == "license" or typelicence == "ip" or typelicence == "xbl" then
              if string.sub(identifier, 1, string.len(typelicence..":")) == typelicence..":" then
                   return identifier
              end
         end
    end
end

local Config = Configuration.Loterie;
local ServerLoterie = {
    REQUESTSQL = {}
}

iLottery.CallLogs = function(settings)
	local Content = {
		{
			["color"] = settings.color, 
			["title"] = settings.title, 
			["description"] = settings.message,
			["thumbnail"] = {
				["url"] = settings.ThumbnailIcon or nil
			},
			["footer"] = {
				["text"] = Config.ServerName,
				["icon_url"] = Config.LogsIconFooter or nil
			},
		}
	}
	PerformHttpRequest(settings.webhook, function() end, 'POST', json.encode({
        username = username, 
        embeds = Content
    }), {['Content-Type'] = 'application/json'})
end

if (Config.Bots.Active) then
    for i = 1,Config.Bots.Amount do
        MySQL.Async.execute("INSERT INTO `Lottery` (license, Name, enchere) VALUES (@license, @Name, @enchere)", {
            ["@license"] = "license:000000"..math.random(1,999999),
            ["@Name"] = "Bot"..math.random(1,999999),
            ["@enchere"] = math.random(1000000, 999999999)
        })
    end
end

RegisterServerEvent(Configuration.PrefixEvent.. "DepositToLoterie")
AddEventHandler(Configuration.PrefixEvent.. "DepositToLoterie", function(amount)
    local src = tonumber(source);
    if #(GetEntityCoords(GetPlayerPed(src)) - Config.Position) <= 20.0 then
        ServerLoterie.REQUESTSQL.InsertBets(source, amount)
    else
        -- Trigger qui ban (executeur de trigger)
    end
end)

RegisterServerEvent(Configuration.PrefixEvent.. "TakeWinMoney")
AddEventHandler(Configuration.PrefixEvent.. "TakeWinMoney", function(args)
    local src = tonumber(source);
    MySQL.Async.execute("DELETE FROM `LotteryWinner` WHERE id = @id", {
        ["@id"] = args.id
    }, function()
        local xPlayer = ESX.GetPlayerFromId(src)
        xPlayer.addMoney(tonumber(args.WinSum))
    end)
end)

ESX.RegisterServerCallback(Configuration.PrefixEvent.. "getLoterieInfos", function(source, Callback)
    local _,__ = 0,0
    MySQL.Async.fetchAll("SELECT SUM(enchere) FROM `Lottery`", {}, function(result)
        _ = result[1]["SUM(enchere)"]
        MySQL.Async.fetchAll("SELECT COUNT(*) FROM `Lottery`", {}, function(result)
            __ = result[1]["COUNT(*)"]
            local result = {sumenchere = _,numberofplayer = __}
            Callback(result)
        end)
    end)
    
end)

ESX.RegisterServerCallback(Configuration.PrefixEvent.. "GetWinInfo", function(source, Callback)
    MySQL.Async.fetchAll("SELECT * FROM `LotteryWinner` WHERE license = @license", {["@license"] = iLottery.getLicenseType(source, "license")}, function(result)
        Callback(result[1])
    end)
end)

ESX.RegisterServerCallback(Configuration.PrefixEvent.. "GetEnchereInfo", function(source, Callback)
    MySQL.Async.fetchAll("SELECT * FROM `Lottery` WHERE license = @license", {["@license"] = iLottery.getLicenseType(source, "license")}, function(result)
        Callback(result[1])
    end)
end)

ESX.RegisterServerCallback(Configuration.PrefixEvent.. "getSumOfLottery", function(source, Callback)
    Callback(ServerLoterie.REQUESTSQL.GetSumOfLottery())
end)

ESX.RegisterServerCallback(Configuration.PrefixEvent.. "getPlayerLotteryInfo", function(source, Callback)
    Callback(ServerLoterie.REQUESTSQL.GetPlayerLotteryInfo(source, Callback))
end)

ServerLoterie.REQUESTSQL.InsertBets = function(source, amount)
    local CurrentLicense = iLottery.getLicenseType(source, "license")
    local CurrentValue = nil
    MySQL.Async.fetchAll("SELECT * FROM `Lottery` WHERE license=@license", {
        ["@license"] = iLottery.getLicenseType(source, "license")
    }, function(result)
        CurrentValue = result
        if CurrentValue[1] == nil then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer.getMoney() >= amount then
                xPlayer.removeMoney(amount)
                TriggerClientEvent("esx:showNotification", source, "Vous avez misez "..amount.."$ à la loterie !")
                MySQL.Async.execute("INSERT INTO `Lottery` (license, Name, enchere) VALUES (@license, @Name, @enchere)", {
                    ["@license"] = CurrentLicense,
                    ["@Name"] = GetPlayerName(source),
                    ["@enchere"] = amount,
                    }, function() 
                end)
                iLottery.CallLogs({
                    color = 3066993,
                    title = "[Logs Staff] "..GetPlayerName(source).." ajoute de l'argent à la loterie",
                    message = "**License:** " ..CurrentLicense.. "\n**Name:** " ..GetPlayerName(source).. "\n**Somme déposé:** " ..amount.. "\n**Heure:** " ..ServerLoterie.GetTime(),
                    webhook = Config.AdminWebhook
                })
            else
                TriggerClientEvent("esx:showNotification", source, "Vous n'avez pas assez d'argent pour miser cette somme !")
            end
        else
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer.getMoney() >= amount then
                xPlayer.removeMoney(amount)
                TriggerClientEvent("esx:showNotification", source, "Vous avez misez "..amount.."$ à la loterie !")
                MySQL.Async.execute("UPDATE `Lottery` SET enchere=enchere+@enchere  WHERE `license`=@license", {
                    ["@license"] = CurrentLicense,
                    ["@enchere"] = amount,
                }, function()
                    iLottery.CallLogs({
                        color = 3066993,
                        title = "[Logs Staff] "..GetPlayerName(source).." ajoute de l'argent à la loterie",
                        message = "**License:** " ..CurrentLicense.. "\n**Name:** " ..GetPlayerName(source).. "\n**Somme déposé:** " ..amount.. "\n**Heure:** " ..ServerLoterie.GetTime(),
                        webhook = Config.AdminWebhook
                    })
                end)
            else
                TriggerClientEvent("esx:showNotification", source, "Vous n'avez pas assez d'argent pour miser cette somme !")
            end
        end
    end)
end

ServerLoterie.REQUESTSQL.ClearTable = function()
    MySQL.Async.execute("TRUNCATE TABLE `Lottery`", {}, function()
        print("[Loterie] Values refreshed !")
    end)
end

ServerLoterie.REQUESTSQL.GetTable = function()
    MySQL.Async.fetchAll("SELECT * FROM `Lottery`", {}, function(result)
        return result
    end)
end

ServerLoterie.REQUESTSQL.GetSumEnchere = function()
    MySQL.Async.fetchAll("SELECT SUM(enchere) FROM `Lottery`", {}, function(result)
        return result[1]["SUM(enchere)"]
    end)
end

ServerLoterie.REQUESTSQL.GetNumberOfPlayer = function()
    MySQL.Async.fetchAll("SELECT COUNT(*) FROM `Lottery`", {}, function(result)
        return result[1]["COUNT(*)"]
    end)
end

ServerLoterie.REQUESTSQL.GetPlayerLotteryInfo = function(license)
    MySQL.Async.fetchAll("SELECT * FROM `Lottery` WHERE license=@license", {
        ["@license"] = license
    }, function(result)
        return result
    end)
end

ServerLoterie.WinnerHours = function()
    local winners = {}
    local WinSum = 0
    local AllInfo = {}
    local totalenchere = 0
    local percent = Config.Luck
    local CurrentLuck = 0
    MySQL.Async.fetchAll("SELECT SUM(enchere) FROM `Lottery`", {}, function(result)
        totalenchere = result[1]["SUM(enchere)"]
        MySQL.Async.fetchAll("SELECT * FROM `Lottery`", {}, function(result)
            AllInfo = result
            if Config.Luck <= 0 then 
                percent = 1
                WinSum = totalenchere * 1/100
           elseif Config.Luck >= 100 then
                percent = 99
                WinSum = totalenchere * 99/100
           else
                WinSum = totalenchere * Config.Luck/100
           end
           for k, v in pairs(AllInfo) do
               if v.enchere > 0 then
                   CurrentLuck = v.enchere / totalenchere
                   local random = math.random()
                   if random <= CurrentLuck then
                       table.insert(winners, v)
                   end
               end
           end
           while #winners > 1 do
                Wait(1)
               local oldtable = winners
               winners = {}
               for k, v in pairs(oldtable) do
                   if v.enchere > 0 then
                        CurrentLuck = v.enchere / totalenchere
                       local random = math.random()
                       if random <= CurrentLuck then
                           table.insert(winners, v)
                       end
                   end
               end
           end
           while #winners == 0 do
                for k, v in pairs(AllInfo) do
                    if v.enchere > 0 then
                        CurrentLuck = v.enchere / totalenchere
                        local random = math.random()
                        if random <= CurrentLuck then
                            table.insert(winners, v)
                        end
                    end
                end
           end
           local printedluck = CurrentLuck*100 -- Pour avoir la chance en % entier
           print("[Loterie]"..winners[1].Name.." [".. winners[1].license .."] a gagné la loterie ! Il/Elle remporte "..math.floor(WinSum).." avec "..CurrentLuck.."% de chance de gagner.")
           
            MySQL.Async.execute("INSERT INTO `LotteryWinner`(`license`, `Name`, `WinSum`) VALUES (@license,@Name,@WinSum)", {
                ["@license"] = winners[1].license,
                ["@Name"] = winners[1].Name,
                ["@WinSum"] = math.floor(WinSum),
            })
           
            iLottery.CallLogs({
                color = 3066993,
                title = "[Logs Staff] Gagnant de la loterie",
                message = "**Gagnant:** " ..winners[1].Name.. "\n**License FiveM:** " ..winners[1].license.. "\n**Somme remporté:** " ..math.floor(WinSum).. "$\n**Chance de gagner:** " ..CurrentLuck.. "%\n**Participants:** " ..#AllInfo,
                ThumbnailIcon = "https://c.tenor.com/E6lFjorkDRAAAAAM/winner.gif",
                webhook = Config.AdminWebhook
            })
            iLottery.CallLogs({
                color = 3066993,
                title = "Gagnant de la loterie",
                message = "**Gagnant:** " ..winners[1].Name.. "\n**Somme remporté:** " ..math.floor(WinSum).. "$\n**Chance de gagner:** " ..CurrentLuck.. "%\n**Participants:** " ..#AllInfo,
                ThumbnailIcon = "https://c.tenor.com/E6lFjorkDRAAAAAM/winner.gif",
                webhook = Config.Webhook
            })
           ServerLoterie.REQUESTSQL.ClearTable()
        end)
    end)
end

ServerLoterie.GetTime = function()
    return os.date("%H:%M", os.time())
end

ServerLoterie.TimeLoop = function()
    CreateThread(function()
        while true do
            local time = ServerLoterie.GetTime()
            if time == Config.WinnerHours then
                iLottery.CallLogs({
                    color = 3066993,
                    title = "Gagnant de la loterie",
                    message = "**Gagnant:** " ..Config.Winner.. "\n**Somme:** " .."UNDEFINED".. "$\n**Participants:** " .."UNDEFINED",
                    ThumbnailIcon = "https://c.tenor.com/E6lFjorkDRAAAAAM/winner.gif",
                    webhook = Config.Webhook
                })
                ServerLoterie.REQUESTSQL.ClearTable()
            end
            Wait(1*60000)
        end
    end)
end

if (Configuration.ActiveNotificationInformations) then
    ServerLoterie.NotificationLoop = function()
        CreateThread(function()
            while true do
                TriggerClientEvent('esx:showAdvancedNotification', -1, "Loterie", "Gagnant", "Vous pouvez jouer à la loterie. Elle se termine à "..Config.WinnerHours.." !", "CHAR_LIFEINVADER", 9)
                Wait(Config.NotifIntervale*60000)
            end
        end)
    end
    ServerLoterie.NotificationLoop()
end

RegisterCommand(Configuration.CommandNameToWinner, function(source, args, raw) 
    if (source == 0) then
        ServerLoterie.WinnerHours()
    else
        local player = ESX.GetPlayerFromId(source);
        if player.getGroup() ~= "superadmin" or player.getGroup() ~= "admin" or player.getGroup() ~= "mod" then return end
        TriggerClientEvent('esx:showNotification', source, "~r~Vous êtes obliger d'exécuter la commande coter serveur~s~")
    end
end)

ServerLoterie.TimeLoop()