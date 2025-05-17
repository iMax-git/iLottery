local Settings = {
    Button = {
        Width = 225,
        Height = 34,
        Background = {
            { 0, 0, 0, 180 },
            { 240, 240, 240, 255 }
        }
    },
    Text = {
        Colors = {
            { 255, 255, 255, 255 },
            { 5, 5, 5, 255 }
        },
        X = 8.0,
        Y = 4.5,
        Scale = 0.26,
        Font = 0,
        Center = 0,
        Outline = false,
        DropShadow = false,
    },
    Title = {
        Scale = 0.35,
        Font = 6,
        Background = { 224, 146, 0, 240 },
        Text = { 255, 255, 255, 255 }
    }
}

ContextUI = {
    Entity = {
        ID = nil,
        Type = nil,
        Model = nil,
        NetID = nil,
        ServerID = nil,
    },
    Menus = {},
    Focus = false,
    Open = false,
    Position = vector2(0.0, 0.0),
    Offset = vector2(0.0, 0.0),
    Options = 0,
    Category = "main",
    CategoryID = 0,
    Description = nil,
}

function ContextUI:CloseMenu()
    ResetEntityAlpha(self.Entity.ID)
    self.Entity.ID = nil
    self.Open = false
    self.Focus = false
    self.Category = "main"
    self.Options = 0
end

local function ShowDescription(Description)
    local PosX, PosY = ContextUI.Position.x, ContextUI.Position.y
    PosY = PosY + (ContextUI.Options * Settings.Button.Height)
    local GetLineCount = Graphics.GetLineCount(Description, PosX + 110, PosY, Settings.Text.Font, 0.24, Settings.Title.Text[1], Settings.Title.Text[2], Settings.Title.Text[3], Settings.Title.Text[4], 1, false, false, 215)
    Graphics.Rectangle(PosX, PosY, Settings.Button.Width, 2, Settings.Title.Background[1], Settings.Title.Background[2], Settings.Title.Background[3], Settings.Title.Background[4])
    Graphics.Rectangle(PosX, PosY + 2, Settings.Button.Width, 1 + (GetLineCount * 17.5), 0, 0, 0, 160)
    Graphics.Text(Description, PosX + 110, PosY, Settings.Text.Font, 0.24, Settings.Title.Text[1], Settings.Title.Text[2], Settings.Title.Text[3], Settings.Title.Text[4], 1, false, false, 215)
    ContextUI.Offset = vector2(PosX, PosY + 3 +(GetLineCount * 17.5))
end

local function AddTitle(Label)
    local PosX, PosY = ContextUI.Position.x, ContextUI.Position.y
    PosY = PosY + (ContextUI.Options * Settings.Button.Height)
    -- Graphics.Rectangle(PosX, PosY, Settings.Button.Width, Settings.Button.Height, Settings.Title.Background[1], Settings.Title.Background[2], Settings.Title.Background[3], Settings.Title.Background[4])
    Graphics.Sprite("commonmenu", "interaction_bgd", PosX, PosY, Settings.Button.Width, Settings.Button.Height)
    Graphics.Text(Label, PosX + 110, PosY + 4.0, Settings.Title.Font, Settings.Title.Scale, Settings.Title.Text[1], Settings.Title.Text[2], Settings.Title.Text[3], Settings.Title.Text[4], 1, false, false)
    ContextUI.Options = ContextUI.Options + 1
    ContextUI.Offset = vector2(PosX, PosY)
end

function ContextUI:Button(Label, Description, Actions, Submenu)
    local PosX, PosY = self.Position.x, self.Position.y
    PosY = PosY + (self.Options * Settings.Button.Height)
    local onHovered = Graphics.IsMouseInBounds(PosX, PosY, Settings.Button.Width, Settings.Button.Height)

    if (onHovered) then
        local Selected = false;
        SetMouseCursorSprite(5)
        if IsControlJustPressed(0, 24) then
            Selected = true
            if (Submenu) then
                self.Category = Submenu.Category
            end
            local audioName = Label == "← Retour" and "BACK" or "SELECT"
            RageUI.PlaySound("HUD_FRONTEND_DEFAULT_SOUNDSET", audioName, false)
        end
        if (Actions) then
            Actions(Selected)
        end
        self.Description = Description or nil
    end

    local Index = (not onHovered) and 1 or 2
    Graphics.Rectangle(PosX, PosY, Settings.Button.Width, Settings.Button.Height, Settings.Button.Background[Index][1], Settings.Button.Background[Index][2], Settings.Button.Background[Index][3], Settings.Button.Background[Index][4])
    Graphics.Text(Label, PosX + Settings.Text.X, PosY + Settings.Text.Y, Settings.Text.Font, Settings.Text.Scale, Settings.Text.Colors[Index][1], Settings.Text.Colors[Index][2], Settings.Text.Colors[Index][3], Settings.Text.Colors[Index][4], Settings.Text.Center, Settings.Text.Outline, Settings.Text.DropShadow)
    self.Options = self.Options + 1
    self.Offset = vector2(PosX, PosY)
end

function ContextUI:Visible()
    SetMouseCursorSprite(1)
    self.Menus[self.Entity.Type .. self.Category]()
    local X, Y = 1920, 1080
    local lastX, lastY = self.Offset.x, self.Offset.y
    if (lastY + Settings.Button.Height) >= Y then
        self.Position = vector2(self.Position.x, self.Position.y - 10.0)
    end
    if (lastX + Settings.Button.Width) >= X then
        self.Position = vector2(self.Position.x - 10.0, self.Position.y)
    end
    self.Options = 0
    self.Description = nil;
end

function ContextUI:CreateMenu(EntityType, Title)
    return { EntityType = EntityType, Category = "main", Parent = nil, Title = Title }
end

function ContextUI:CreateSubMenu(Parent, Title)
    local category = self.CategoryID + 1
    self.CategoryID = category;
    return { EntityType = Parent.EntityType, Category = category, Parent = Parent, Title = Title }
end

function ContextUI:IsVisible(Menu, Callback)
    self.Menus[Menu.EntityType .. Menu.Category] = function()
        if (Menu.Title) then
            AddTitle(Menu.Title)
        end
        Callback(self.Entity)
        if Menu.Parent then
            self:Button("              ← Retour →", nil, Menu.Parent) 
        end
        if (self.Description) then
            ShowDescription(self.Description)
        end
    end
end

CreateThread(function()
    local controls_actions = { 239, 240, 24, 25 }
    while true do
        local Timer = 250;
        if (ContextUI.Focus) then
            DisableAllControlActions(2)
            SetMouseCursorActiveThisFrame()
            for _, control in ipairs(controls_actions) do
                EnableControlAction(0, control, true)
            end
            if (not ContextUI.Open) then
                local isFound, entityCoords, surfaceNormal, entityHit, entityType, cameraDirection, mouse = Graphics.ScreenToWorld(35.0, 31)
                if (entityType ~= 0) then
                    SetMouseCursorSprite(5)
                    if ContextUI.Entity.ID ~= entityHit then
                        ResetEntityAlpha(ContextUI.Entity.ID)
                        ContextUI.Entity.ID = entityHit
                        SetEntityAlpha(ContextUI.Entity.ID, 200, false)
                    end
                    if IsControlJustPressed(0, 24) or IsDisabledControlPressed(0, 24) then
                        if (ContextUI.Menus[entityType .. ContextUI.Category] ~= nil) then
                            local posX, posY = Graphics.ConvertToPixel(mouse.x, mouse.y)
                            ContextUI.Position = vector2(posX, posY)
                            ContextUI.Entity = {
                                ID = entityHit,
                                Type = entityType,
                                Model = GetEntityModel(entityHit) or 0,
                                NetID = NetworkGetNetworkIdFromEntity(entityHit),
                                ServerID = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entityHit))
                            }
                            ContextUI.Open = true
                            RageUI.PlaySound("HUD_FRONTEND_DEFAULT_SOUNDSET", "SELECT", false)
                        end
                    end
                else
                    if (ContextUI.Entity.ID ~= nil) then
                        ResetEntityAlpha(ContextUI.Entity.ID)
                        ContextUI.Entity.ID = nil
                    end
                    SetMouseCursorSprite(1)
                end
            else
                ContextUI:Visible()
            end
            DisablePlayerFiring(PlayerPedId(), true)
            Timer = 1;
        elseif (ContextUI.Entity.ID ~= nil) then
            ContextUI:CloseMenu()
        end
        Wait(Timer)
    end
end)

function math.round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

local function StringToArray(str)
    local charCount = #str
    local strCount = math.ceil(charCount / 99)
    local strings = {}

    for i = 1, strCount do
        local start = (i - 1) * 99 + 1
        local clamp = math.clamp(#string.sub(str, start), 0, 99)
        local finish = ((i ~= 1) and (start - 1) or 0) + clamp

        strings[i] = string.sub(str, start, finish)
    end

    return strings
end

local function AddText(str)
    local str = tostring(str)
    local charCount = #str

    if charCount < 100 then
        AddTextComponentSubstringPlayerName(str)
    else
        local strings = StringToArray(str)
        for s = 1, #strings do
            AddTextComponentSubstringPlayerName(strings[s])
        end
    end
end

local function RText(text, x, y, font, scale, r, g, b, a, alignment, dropShadow, outline, wordWrap)
    local Text, X, Y = text, (x or 0) / 1920, (y or 0) / 1080
    SetTextFont(font or 0)
    SetTextScale(1.0, scale or 0)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    if dropShadow then
        SetTextDropShadow()
    end
    if outline then
        SetTextOutline()
    end
    if alignment ~= nil then
        if alignment == 1 or alignment == "Center" or alignment == "Centre" then
            SetTextCentre(true)
        elseif alignment == 2 or alignment == "Right" then
            SetTextRightJustify(true)
        end
    end
    if wordWrap and wordWrap ~= 0 then
        if alignment == 1 or alignment == "Center" or alignment == "Centre" then
            SetTextWrap(X - ((wordWrap / 1920) / 2), X + ((wordWrap / 1920) / 2))
        elseif alignment == 2 or alignment == "Right" then
            SetTextWrap(0, X)
        else
            SetTextWrap(X, X + (wordWrap / 1920))
        end
    else
        if alignment == 2 or alignment == "Right" then
            SetTextWrap(0, X)
        end
    end
    return Text, X, Y
end

Graphics = {};

function Graphics.MeasureStringWidth(str, font, scale)
    BeginTextCommandGetWidth("CELL_EMAIL_BCON")
    AddTextComponentSubstringPlayerName(str)
    SetTextFont(font or 0)
    SetTextScale(1.0, scale or 0)
    return EndTextCommandGetWidth(true) * 1920
end

function Graphics.Rectangle(x, y, width, height, r, g, b, a)
    local X, Y, Width, Height = (x or 0) / 1920, (y or 0) / 1080, (width or 0) / 1920, (height or 0) / 1080
    DrawRect(X + Width * 0.5, Y + Height * 0.5, Width, Height, r or 255, g or 255, b or 255, a or 255)
end

function Graphics.Sprite(dictionary, name, x, y, width, height, heading, r, g, b, a)
    local X, Y, Width, Height = (x or 0) / 1920, (y or 0) / 1080, (width or 0) / 1920, (height or 0) / 1080

    if not HasStreamedTextureDictLoaded(dictionary) then
        RequestStreamedTextureDict(dictionary, true)
    end

    DrawSprite(dictionary, name, X + Width * 0.5, Y + Height * 0.5, Width, Height, heading or 0, r or 255, g or 255, b or 255, a or 255)
end

function Graphics.GetLineCount(text, x, y, font, scale, r, g, b, a, alignment, dropShadow, outline, wordWrap)
    local Text, X, Y = RText(text, x, y, font, scale, r, g, b, a, alignment, dropShadow, outline, wordWrap)
    BeginTextCommandLineCount("CELL_EMAIL_BCON")
    AddText(Text)
    return EndTextCommandLineCount(X, Y)
end

function Graphics.Text(text, x, y, font, scale, r, g, b, a, alignment, dropShadow, outline, wordWrap)
    local Text, X, Y = RText(text, x, y, font, scale, r, g, b, a, alignment, dropShadow, outline, wordWrap)
    BeginTextCommandDisplayText("CELL_EMAIL_BCON")
    AddText(Text)
    EndTextCommandDisplayText(X, Y)
end

function Graphics.IsMouseInBounds(X, Y, Width, Height)
    local MX, MY = math.round(GetControlNormal(2, 239) * 1920) / 1920, math.round(GetControlNormal(2, 240) * 1080) / 1080
    X, Y = X / 1920, Y / 1080
    Width, Height = Width / 1920, Height / 1080
    return (MX >= X and MX <= X + Width) and (MY > Y and MY < Y + Height)
end

function Graphics.ConvertToPixel(x, y)
    return (x * 1920), (y * 1080)
end

function Graphics.ScreenToWorld(distance, flags)
    local camRot = GetGameplayCamRot(0)
    local camPos = GetGameplayCamCoord()
    local mouse = vector2(GetControlNormal(2, 239), GetControlNormal(2, 240))
    local cam3DPos, forwardDir = Graphics.ScreenRelToWorld(camPos, camRot, mouse)
    local direction = camPos + forwardDir * distance
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, flags, 0, 0)
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    return (hit == 1 and true or false), endCoords, surfaceNormal, entityHit, (entityHit >= 1 and GetEntityType(entityHit) or 0), direction, mouse
end

function Graphics.ScreenRelToWorld(camPos, camRot, cursor)
    local camForward = Graphics.RotationToDirection(camRot)
    local rotUp = vector3(camRot.x + 1.0, camRot.y, camRot.z)
    local rotDown = vector3(camRot.x - 1.0, camRot.y, camRot.z)
    local rotLeft = vector3(camRot.x, camRot.y, camRot.z - 1.0)
    local rotRight = vector3(camRot.x, camRot.y, camRot.z + 1.0)
    local camRight = Graphics.RotationToDirection(rotRight) - Graphics.RotationToDirection(rotLeft)
    local camUp = Graphics.RotationToDirection(rotUp) - Graphics.RotationToDirection(rotDown)
    local rollRad = -(camRot.y * math.pi / 180.0)
    local camRightRoll = camRight * math.cos(rollRad) - camUp * math.sin(rollRad)
    local camUpRoll = camRight * math.sin(rollRad) + camUp * math.cos(rollRad)
    local point3DZero = camPos + camForward * 1.0
    local point3D = point3DZero + camRightRoll + camUpRoll
    local point2D = Graphics.World3DToScreen2D(point3D)
    local point2DZero = Graphics.World3DToScreen2D(point3DZero)
    local scaleX = (cursor.x - point2DZero.x) / (point2D.x - point2DZero.x)
    local scaleY = (cursor.y - point2DZero.y) / (point2D.y - point2DZero.y)
    local point3Dret = point3DZero + camRightRoll * scaleX + camUpRoll * scaleY
    local forwardDir = camForward + camRightRoll * scaleX + camUpRoll * scaleY
    return point3Dret, forwardDir
end

function Graphics.RotationToDirection(rotation)
    local x, z = (rotation.x * math.pi / 180.0), (rotation.z * math.pi / 180.0)
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

function Graphics.World3DToScreen2D(pos)
    local _, sX, sY = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
    return vector2(sX, sY)
end