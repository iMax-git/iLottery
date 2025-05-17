Configuration = {
    PrefixEvent = "ADNS",
    ActiveNotificationInformations = true, -- Active Notification for all server
    CommandNameToWinner = "WinnerLottery",
    Loterie = {
        Webhook = "", -- Webhook link for announce winner
        AdminWebhook = "", -- Webhook link for Admin 
        Position = vector3(-1082.4, -247.7142, 37.75538),
        WinnerHours = "23:22", -- HH:MM cycle (24h)
        Luck = 50, -- La personne gagne 50% du prix total misez / The person wins 50% of the total price bet
        ConsoleLog = true,
        NotifIntervale = 10, -- In minutes (default: 10 minutes)
        Bots = { -- Active Bot for test
            Active = false,
            Amount = 10,
        },
        Blip = { -- Blip Config
            Sprite = 605,
            Scale = 0.8,
        },
    }
}