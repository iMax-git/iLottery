local Lottery = {}

Lottery.Notification = function(msg)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName(msg or "NULL")
	DrawNotification(0, 1)
end

Lottery.HelpNotification = function(msg, sound, time)
	BeginTextCommandDisplayHelp('STRING')
	AddTextComponentSubstringPlayerName(msg or "NULL")
	EndTextCommandDisplayHelp(0, false, sound or true, time or -1)
end

Lottery.BoardInput = function(title, text, textInBox, maxCaracters)
	AddTextEntry(title, text)
	DisplayOnscreenKeyboard(1, tostring(title), "", textInBox or "", "", "", "", tonumber(maxCaracters))

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do Wait(0) end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Wait(200)
		return result
	else
		Wait(200)
		return nil
	end
end

Lottery.LoadRequire = function(actif)
    local TimeWait = 0;
    CreateThread(function()
        local LoterieBlips = AddBlipForCoord(Configuration.Loterie.Position.x, Configuration.Loterie.Position.y, Configuration.Loterie.Position.z)
        SetBlipSprite(LoterieBlips, Configuration.Loterie.Blip.Sprite)
        SetBlipDisplay(LoterieBlips, 4)
        SetBlipScale(LoterieBlips, Configuration.Loterie.Blip.Scale)
        SetBlipAsShortRange(LoterieBlips, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Loterie")
        EndTextCommandSetBlipName(LoterieBlips)
        while actif do
            TimeWait = 800;
            local dst = #(GetEntityCoords(PlayerPedId()) - Configuration.Loterie.Position);
            if (dst <= 5.0 and dst >= 2.0) then
                TimeWait = 0
                DrawMarker(29, Configuration.Loterie.Position, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 241, 245, 2, 255, 1, 1, 2, 1, nil, nil, 0)
            end
            if (dst <= 2.0) then
                TimeWait = 0
                Lottery.HelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accèder a la loterie")
                if IsControlJustPressed(0, 38) then
                    Lottery.openLoterie()
                end
            end
            Wait(TimeWait)
        end
    end)
end

CreateThread(function()
    TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
    while ESX == nil do Wait(5) end
    while not ESX.IsPlayerLoaded() do Wait(5) end
end)

local LoterieOpened = false;
local MainLoterie = RageUI.CreateMenu("Loterie", "Enchérissez", 10, 100)
MainLoterie.Closed = function() LoterieOpened = false end;

Lottery.getInformations = function()
    ESX.TriggerServerCallback(Configuration.PrefixEvent.. "getLoterieInfos", function(result)
        Lottery.Informations = {}
        while result == {} or result == nil do Wait(5) end
        Lottery.Informations = result
    end)
end

Lottery.GetWinInfo = function()
    ESX.TriggerServerCallback(Configuration.PrefixEvent.. "GetWinInfo", function(result)
        Lottery.WinInformations = {}
        while result == {} or result == nil do Wait(5) end
        Lottery.WinInformations = result
    end)
end

Lottery.openLoterie = function()
    if LoterieOpened == false then
        if LoterieOpened then
            LoterieOpened = false
        else
            LoterieOpened = true
            RageUI.Visible(MainLoterie, true)
            Lottery.getInformations()
            Lottery.GetWinInfo()
            CreateThread(function()
                while LoterieOpened do
                    Wait(1.0)
                    RageUI.IsVisible(MainLoterie, function()
                        if (Lottery.Informations ~= nil) then
                            if Lottery.Informations["sumenchere"] == nil or Lottery.Informations["sumenchere"] == 0 then
                                RageUI.Separator("~r~ La cagnotte est vide !~s~")
                            else
                                RageUI.Separator("~g~" ..tostring(ESX.Math.GroupDigits(Lottery.Informations["sumenchere"])).. "$~s~")
                            end
                            if Lottery.Informations["numberofplayer"] == nil or Lottery.Informations["numberofplayer"] == 0 then
                                RageUI.Separator("~r~ Personne ne participe !~s~")
                            else
                                RageUI.Separator("~o~" ..tostring(Lottery.Informations["numberofplayer"]).. "~s~ Participants")
                            end
                            RageUI.Button("Déposer de l'argent", "Déposer seulement de l'argent liquide", {}, true, {
                                onSelected = function()
                                    local LoterieDeposit = Lottery.BoardInput("DEPOSIT_AMOUT_LOTERIE", "Combien souhaitez vous déposer dans la loterie", "", 10)
                                    if LoterieDeposit == nil or LoterieDeposit == "" or not tonumber(LoterieDeposit) then
                                        Lottery.Notification("~r~<C>Attention</C>\n~o~Veuillez entrez un nombre que vous souhaitez déposer~s~")
                                        RageUI.CloseAll()
                                        LoterieOpened = false
                                    else
                                        if tonumber(LoterieDeposit) > 0 then
                                            TriggerServerEvent(Configuration.PrefixEvent.."DepositToLoterie", tonumber(LoterieDeposit))
                                            RageUI.CloseAll()
                                            LoterieOpened = false
                                        end
                                    end
                                end
                            })
                            
                            RageUI.Separator("")
                            if Lottery.WinInformations == nil or Lottery.WinInformations == {} or Lottery.WinInformations.WinSum == nil then
                                RageUI.Separator("~r~Vous n'avez rien gagnez.")
                            else
                                RageUI.Separator("~w~Vous avez gagnez ~g~"..Lottery.WinInformations.WinSum.."~w~$.")
                                RageUI.Button("Prendre l'argent", "Prendre l'argent gagner à la loterie.", {}, true, {
                                    onSelected = function()
                                        TriggerServerEvent(Configuration.PrefixEvent.."TakeWinMoney",Lottery.WinInformations)
                                        RageUI.CloseAll()
                                        LoterieOpened = false;
                                    end
                                })
                            end
                        end
                    end)
                end
            end)
        end
    end
end

Lottery.LoadRequire(true)