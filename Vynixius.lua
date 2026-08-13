--[[
    Vynixius - DOORS Script
    UI: Obsidian (mspaint)
    Theme: Green
]]

-- PlaceId check removed for lobby compatibility
print("[Vynixius] Script starting...")

local function Base64Decode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = string.gsub(data, "[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x ~= 6 then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
        return string.char(c)
    end))
end

local function LoadB64Script(url)
    local b64 = game:HttpGet(url)
    local decoded = Base64Decode(b64)
    return loadstring(decoded)()
end

print("[Vynixius] Attempting to load UI library...")
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
end)
if not success or not Library then
    warn("[Vynixius] Failed to load UI:", Library)
    return
end
print("[Vynixius] UI library loaded successfully")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
print("[Vynixius] PlaceId: " .. tostring(game.PlaceId))
print("[Vynixius] GameId: " .. tostring(game.GameId))

print("[Vynixius] ReplicatedStorage children:")
for _, v in ipairs(ReplicatedStorage:GetChildren()) do
    print("  - " .. v.Name)
end

print("[Vynixius] Workspace children:")
for _, v in ipairs(Workspace:GetChildren()) do
    print("  - " .. v.Name)
end

local GameData = ReplicatedStorage:WaitForChild("GameData", 10)
local Bricks = ReplicatedStorage:WaitForChild("Bricks", 10)
local CurrentRooms = Workspace:WaitForChild("CurrentRooms", 10)

if not GameData or not Bricks or not CurrentRooms then
    warn("[Vynixius] Failed to load game data. Make sure you're in DOORS!")
    return
end
print("[Vynixius] Game data loaded")

local Remotes = {
    Screech = Bricks:WaitForChild("Screech", 5),
    PadlockHint = Bricks:WaitForChild("PadlockHint", 5),
    EngageMinigame = Bricks:WaitForChild("EngageMinigame", 5),
    ClutchHeartbeat = Bricks:WaitForChild("ClutchHeartbeat", 5),
    Caption = Bricks:WaitForChild("Caption", 5),
    DeathHint = Bricks:WaitForChild("DeathHint", 5),
}

local Connections = {}
local Disabled = false

local function KillAllConnections()
    Disabled = true
    for _, v in pairs(Connections) do
        if typeof(v) == "RBXScriptConnection" then pcall(function() v:Disconnect() end) end
    end
    Connections = {}
end

local Window = Library:CreateWindow({
    Title = "Vynixius",
    Center = true,
    AutoShow = true,
})

Library:OnUnload(function()
    KillAllConnections()
    pcall(function() Library.KeybindFrame:Destroy() end)
end)

-- ===================== MAIN TAB =====================
local MainTab = Window:Tab("Main")
local MainSection = MainTab:Section("General")

MainSection:Toggle("Fullbright", {Flag = "Fullbright"}, function(val)
    if val then
        _G._VynFB = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd,
        }
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 5
        Lighting.FogStart = 1e10
        Lighting.FogEnd = 1e10
    else
        local d = _G._VynFB
        if d then
            Lighting.Ambient = d.Ambient
            Lighting.OutdoorAmbient = d.OutdoorAmbient
            Lighting.Brightness = d.Brightness
            Lighting.FogStart = d.FogStart
            Lighting.FogEnd = d.FogEnd
        end
    end
end)

MainSection:Toggle("No Fog", {Flag = "NoFog"}, function(val)
    if val then
        _G._VynAtmo = _G._VynAtmo or {}
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                _G._VynAtmo[v] = v.Density
                v.Density = 0
            end
        end
    else
        if _G._VynAtmo then
            for v, d in pairs(_G._VynAtmo) do
                if v and v.Parent then v.Density = d end
            end
            _G._VynAtmo = nil
        end
    end
end)

MainSection:Toggle("No Lights Shattering", {Flag = "NoLightShatter"}, function(val)
    _G._VynNoLightShatter = val
end)

MainSection:Toggle("Body Glow", {Flag = "BodyGlow"}, function(val)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if val then
        if not root:FindFirstChild("VynGlow") then
            local pl = Instance.new("PointLight")
            pl.Name = "VynGlow"
            pl.Range = 60
            pl.Brightness = 2
            pl.Color = Color3.fromRGB(0, 255, 100)
            pl.Parent = root
            local sl = Instance.new("SurfaceLight")
            sl.Name = "VynGlow2"
            sl.Range = 200
            sl.Brightness = 1
            sl.Color = Color3.fromRGB(0, 255, 100)
            sl.Parent = root
        end
    else
        local g = root:FindFirstChild("VynGlow")
        if g then g:Destroy() end
        local g2 = root:FindFirstChild("VynGlow2")
        if g2 then g2:Destroy() end
    end
end)

-- ===================== UTILITIES TAB =====================
local UtilTab = Window:Tab("Utilities")
local GenSection = UtilTab:Section("General")

GenSection:Toggle("Increased Open Door Reach", {Flag = "DoorReach"}, function(val)
    _G._VynDoorReach = val
end)

GenSection:Slider("Open Door Reach Range", {Flag = "DoorReachRange", Min = 5, Max = 30, Default = 30}, function(val)
    _G._VynDoorReachRange = val
end)

GenSection:Toggle("Fast Proximity Prompts", {Flag = "FastPrompts"}, function(val)
    _G._VynFastPrompts = val
end)

GenSection:Toggle("Clip Proximity Prompts", {Flag = "ClipPrompts"}, function(val)
    _G._VynClipPrompts = val
end)

GenSection:Toggle("No Lights Shattering", {Flag = "NoLightShatter2"}, function(val)
    _G._VynNoLightShatter = val
end)

local AuraSection = UtilTab:Section("Auras")

AuraSection:Toggle("Auto Interact", {Flag = "AutoInteract"}, function(val)
    _G._VynAutoInteract = val
end)

AuraSection:Slider("Auto Interact Range", {Flag = "AutoInteractRange", Min = 5, Max = 18, Default = 18}, function(val)
    _G._VynAutoInteractRange = val
end)

AuraSection:Toggle("Item Aura", {Flag = "ItemAura"}, function(val)
    _G._VynItemAura = val
end)

AuraSection:Toggle("Loot Aura", {Flag = "LootAura"}, function(val)
    _G._VynLootAura = val
end)

AuraSection:Toggle("Gate Lever Aura", {Flag = "LeverAura"}, function(val)
    _G._VynLeverAura = val
end)

AuraSection:Toggle("Library Book Aura", {Flag = "BookAura"}, function(val)
    _G._VynBookAura = val
end)

AuraSection:Toggle("Painting Aura", {Flag = "PaintingAura"}, function(val)
    _G._VynPaintingAura = val
end)

AuraSection:Toggle("Breaker Switch Aura", {Flag = "BreakerAura"}, function(val)
    _G._VynBreakerAura = val
end)

-- ===================== ENTITIES SECTION (in Utilities) =====================
local EntSection = UtilTab:Section("Entities")

EntSection:Toggle("Anti Screech", {Flag = "AntiScreech"}, function(val)
    _G._VynAntiScreech = val
end)

EntSection:Toggle("No Spider Jumpscare Visual", {Flag = "NoSpiderJump"}, function(val)
    _G._VynNoSpiderJump = val
end)

EntSection:Toggle("Anti Dupe", {Flag = "AntiDupe"}, function(val)
    _G._VynAntiDupe = val
end)

EntSection:Toggle("Bypass Eyes", {Flag = "BypassEyes"}, function(val)
    _G._VynBypassEyes = val
end)

EntSection:Toggle("Bypass Seek Obstruction", {Flag = "BypassSeek"}, function(val)
    _G._VynBypassSeek = val
end)

EntSection:Toggle("Anti Halt", {Flag = "AntiHalt"}, function(val)
    _G._VynAntiHalt = val
end)

EntSection:Toggle("Anti Glitch", {Flag = "AntiGlitch"}, function(val)
    _G._VynAntiGlitch = val
end)

EntSection:Toggle("Anti Void", {Flag = "AntiVoid"}, function(val)
    _G._VynAntiVoid = val
end)

EntSection:Toggle("Anti Dread", {Flag = "AntiDread"}, function(val)
    _G._VynAntiDread = val
end)

EntSection:Toggle("Bypass Snare", {Flag = "BypassSnare"}, function(val)
    _G._VynBypassSnare = val
end)

EntSection:Toggle("Bypass Hide", {Flag = "BypassHide"}, function(val)
    _G._VynBypassHide = val
end)

EntSection:Toggle("Anti Figure Hearing", {Flag = "AntiFigHearing"}, function(val)
    _G._VynAntiFigHearing = val
end)

-- ===================== GOD MODE SECTION =====================
local GodSection = UtilTab:Section("God Mode")

GodSection:Toggle("Enabled", {Flag = "GodMode"}, function(val)
    _G._VynGodMode = val
end)

GodSection:Keybind("God Mode Keybind", {Flag = "GodModeKey", Default = "G"}, function() end)

GodSection:Slider("Entity Detection Range", {Flag = "EntityDetectRange", Min = 20, Max = 500, Default = 125}, function(val)
    _G._VynEntityDetectRange = val
end)

-- ===================== VISUALS TAB =====================
local VisTab = Window:Tab("Visuals")
local ESPSection = VisTab:Section("ESP")

ESPSection:Toggle("Item ESP", {Flag = "ItemESP"}, function(val)
    _G._VynItemESP = val
end)

ESPSection:Toggle("Key ESP", {Flag = "KeyESP"}, function(val)
    _G._VynKeyESP = val
end)

ESPSection:Toggle("Door ESP", {Flag = "DoorESP"}, function(val)
    _G._VynDoorESP = val
end)

ESPSection:Toggle("Wardrobe ESP", {Flag = "WardrobeESP"}, function(val)
    _G._VynWardrobeESP = val
end)

ESPSection:Toggle("Figure ESP", {Flag = "FigureESP"}, function(val)
    _G._VynFigureESP = val
end)

ESPSection:Toggle("Entity Highlight", {Flag = "EntityHL"}, function(val)
    _G._VynEntityHL = val
end)

ESPSection:Toggle("Rush/Ambush Notifier", {Flag = "RushNotif"}, function(val)
    _G._VynRushNotif = val
end)

ESPSection:Toggle("Screech Notifier", {Flag = "ScreechNotif"}, function(val)
    _G._VynScreechNotif = val
end)

ESPSection:Toggle("Eyes Notifier", {Flag = "EyesNotif"}, function(val)
    _G._VynEyesNotif = val
end)

ESPSection:Toggle("Figure Notifier", {Flag = "FigureNotif"}, function(val)
    _G._VynFigureNotif = val
end)

ESPSection:Toggle("Seek Notifier", {Flag = "SeekNotif"}, function(val)
    _G._VynSeekNotif = val
end)

ESPSection:Toggle("Halt Notifier", {Flag = "HaltNotif"}, function(val)
    _G._VynHaltNotif = val
end)

ESPSection:Toggle("Sound Alert", {Flag = "SoundAlert"}, function(val)
    _G._VynSoundAlert = val
end)

-- ===================== FLOOR TAB =====================
local FloorTab = Window:Tab("Floor")
local PuzzleSection = FloorTab:Section("Puzzles")

PuzzleSection:Toggle("Breaker Auto-Solve (Room 100)", {Flag = "BreakerAuto"}, function(val)
    _G._VynBreakerAuto = val
end)

PuzzleSection:Toggle("Padlock Code Display (Room 50)", {Flag = "PadlockCode"}, function(val)
    _G._VynPadlock = val
end)

PuzzleSection:Toggle("Library Book ESP", {Flag = "BookESP"}, function(val)
    _G._VynBookESP = val
end)

-- ===================== SETTINGS TAB =====================
local SettingsTab = Window:Tab("Settings")

pcall(function()
    local TM = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
    TM:SetLibrary(Library)
    TM:SetFolder("Vynixius")
    TM:ApplyToTab(SettingsTab)
    TM:SetTheme({
        Name = "Vynixius Green",
        Accent = Color3.fromRGB(0, 200, 80),
        Outline = Color3.fromRGB(25, 30, 25),
        OutlineLight = Color3.fromRGB(35, 45, 35),
        FontColor = Color3.fromRGB(200, 255, 200),
        MainColor = Color3.fromRGB(18, 22, 18),
        SideColor = Color3.fromRGB(14, 17, 14),
        GeometryColor = Color3.fromRGB(20, 26, 20),
        ToggleColor = Color3.fromRGB(30, 40, 30),
        ToggleActiveColor = Color3.fromRGB(0, 180, 70),
        SliderColor = Color3.fromRGB(30, 40, 30),
        SliderActiveColor = Color3.fromRGB(0, 180, 70),
        DropdownColor = Color3.fromRGB(30, 40, 30),
        SectionColor = Color3.fromRGB(20, 26, 20),
        TextColor = Color3.fromRGB(200, 255, 200),
    })
    TM:LoadTheme("Vynixius Green")
end)

pcall(function()
    local SM = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()
    SM:SetLibrary(Library)
    SM:SetFolder("Vynixius/Settings")
    SM:IgnoreThemeSettings()
    SM:BuildConfigSection(SettingsTab)
    SM:LoadAutoloadConfig()
end)

-- ===================== ESP SYSTEM =====================
local function CreateBillboard(part, text, color, offset)
    offset = offset or Vector3.new(0, 3, 0)
    local bb = Instance.new("BillboardGui")
    bb.Name = "VynESP"
    bb.Adornee = part
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = offset
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 100

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = text
    tl.TextColor3 = color
    tl.TextStrokeTransparency = 0.3
    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14
    tl.Parent = bb

    bb.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return bb
end

local function CreateHighlight(part, color)
    local hl = Instance.new("Highlight")
    hl.Name = "VynHL"
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Adornee = part
    hl.Parent = part
    return hl
end

-- ===================== ROOM SCANNER =====================
local function ScanRoom(room)
    task.spawn(function()
        pcall(function()
            for _, desc in ipairs(room:GetDescendants()) do
                if Disabled then return end

                if desc.Name == "Main" and desc.Parent then
                    local pname = desc.Parent.Name
                    if pname == "Lighter" or pname == "Vitamins" or pname == "Lockpick" or pname == "Bandage" or pname == "Flashlight" or pname == "Shakelight" or pname == "Straplock" or pname == "AlarmClock" then
                        if _G._VynItemESP then
                            CreateBillboard(desc, pname, Color3.fromRGB(0, 255, 100))
                        end
                    elseif pname == "LeverForGate" then
                        if _G._VynLeverAura or _G._VynItemESP then
                            CreateBillboard(desc, "Lever", Color3.fromRGB(255, 200, 0))
                        end
                    end
                end

                if desc.Name == "Hitbox" and desc.Parent and desc.Parent.Name == "KeyObtain" then
                    if _G._VynKeyESP then
                        CreateBillboard(desc, "Key", Color3.fromRGB(255, 255, 0))
                        CreateHighlight(desc, Color3.fromRGB(255, 255, 0))
                    end
                end

                if desc.Name == "Door" and desc:IsA("MeshPart") and desc.Parent and desc.Parent.Name == "Door" then
                    if _G._VynDoorESP then
                        local roomNum = desc.Parent:FindFirstChild("RoomNumber")
                        local label = roomNum and ("Door " .. tostring(roomNum.Value)) or "Door"
                        CreateBillboard(desc, label, Color3.fromRGB(0, 150, 255), Vector3.new(0, 4, 0))
                    end
                end

                if desc.Name == "Wardrobe" then
                    if _G._VynWardrobeESP then
                        local main = desc:FindFirstChild("Main")
                        if main then
                            local hidden = desc:FindFirstChild("HiddenPlayer")
                            local occupied = hidden and hidden.Value ~= nil
                            local label = occupied and "Wardrobe (Taken)" or "Wardrobe"
                            CreateBillboard(main, label, Color3.fromRGB(255, 150, 0))
                        end
                    end
                end

                -- Library books
                if desc.Name == "LiveHintBook" and _G._VynBookESP then
                    local base = desc:FindFirstChild("Base")
                    if base then
                        CreateBillboard(base, "Book", Color3.fromRGB(200, 100, 255))
                    end
                end

                -- Breaker switches
                if desc.Name == "Breaker" and desc:IsA("BasePart") and _G._VynBreakerAura then
                    CreateBillboard(desc, "Breaker", Color3.fromRGB(0, 200, 255))
                end

                -- Paintings
                if (desc.Name == "Painting" or desc.Name == "LiveHintBook") and desc:IsA("BasePart") and _G._VynPaintingAura then
                    CreateBillboard(desc, "Painting", Color3.fromRGB(255, 200, 100))
                end
            end
        end)
    end)
end

table.insert(Connections, CurrentRooms.ChildAdded:Connect(function(room)
    task.wait(0.5)
    ScanRoom(room)
end))

for _, room in ipairs(CurrentRooms:GetChildren()) do
    ScanRoom(room)
end

-- ===================== ENTITY DETECTION =====================
local alertSound = Instance.new("Sound")
alertSound.SoundId = "rbxassetid://6026984224"
alertSound.Volume = 5
alertSound.Parent = SoundService

local function NotifyEntity(text)
    Library:Notify(text, 5)
    if _G._VynSoundAlert then
        alertSound.TimePosition = 0.25
        alertSound:Play()
    end
end

-- Rush / Ambush
table.insert(Connections, Workspace.ChildAdded:Connect(function(child)
    if Disabled then return end
    if child.Name == "RushMoving" then
        NotifyEntity("Rush spawned - hide!")
        if _G._VynEntityHL then
            local part = child.PrimaryPart or child:WaitForChild("RushNew", 3)
            if part then CreateHighlight(part, Color3.fromRGB(255, 0, 0)) end
        end
    elseif child.Name == "AmbushMoving" then
        NotifyEntity("Ambush spawned - hide and stay hidden!")
        if _G._VynEntityHL then
            local part = child.PrimaryPart or child:WaitForChild("RushNew", 3)
            if part then CreateHighlight(part, Color3.fromRGB(255, 100, 0)) end
        end
    elseif child.Name == "Lookman" then
        NotifyEntity("Eyes spawned - look away!")
        if _G._VynBypassEyes then
            pcall(function() child:Destroy() end)
        end
    elseif child.Name == "SeekMoving" then
        NotifyEntity("Seek chase started!")
    elseif child.Name == "Void" then
        if _G._VynAntiVoid then
            NotifyEntity("Void detected - avoiding!")
        end
    elseif child.Name == "Dread" then
        if _G._VynAntiDread then
            NotifyEntity("Dread detected!")
        end
    end
end))

-- Screech
table.insert(Connections, Remotes.Screech.OnClientEvent:Connect(function()
    if Disabled then return end
    if _G._VynScreechNotif then
        NotifyEntity("Screech - look at it!")
    end
end))

-- Figure
table.insert(Connections, CurrentRooms.ChildAdded:Connect(function(room)
    if Disabled then return end
    task.spawn(function()
        local figure = room:WaitForChild("FigureSetup", 5)
        if figure then
            if _G._VynFigureNotif then
                NotifyEntity("Figure in room " .. room.Name)
            end
            if _G._VynFigureESP then
                task.spawn(function()
                    local ragdoll = figure:WaitForChild("FigureRagdoll", 5)
                    if ragdoll then
                        local root = ragdoll:WaitForChild("Root", 3)
                        if root then
                            CreateHighlight(figure, Color3.fromRGB(255, 0, 0))
                            CreateBillboard(root, "FIGURE", Color3.fromRGB(255, 0, 0), Vector3.new(0, 5, 0))
                        end
                    end
                end)
            end
        end
    end)
end))

-- Halt
table.insert(Connections, CurrentRooms.ChildAdded:Connect(function(room)
    if Disabled then return end
    task.spawn(function()
        local halt = room:WaitForChild("Halt", 5)
        if halt then
            if _G._VynHaltNotif then
                NotifyEntity("Halt in room " .. room.Name .. " - turn around!")
            end
            if _G._VynAntiHalt then
                pcall(function() halt:Destroy() end)
            end
        end
    end)
end))

-- Chase detection
table.insert(Connections, GameData:WaitForChild("LatestRoom").Changed:Connect(function(roomNum)
    if Disabled then return end
    pcall(function()
        local chaseStart = GameData:WaitForChild("ChaseStart")
        local delta = chaseStart.Value - roomNum
        if delta > 0 and delta < 3 then
            NotifyEntity("Event in " .. tostring(delta) .. " rooms!")
        end
    end)
end))

-- ===================== NOCLIP =====================
table.insert(Connections, RunService.Stepped:Connect(function()
    if _G._VynNoclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end))

-- ===================== INFINITE JUMP =====================
table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if _G._VynInfJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end))

-- ===================== SINGLE HOOK (ALL REMOTES) =====================
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
            if self == Remotes.Screech and _G._VynAntiScreech then
                local args = {...}
                args[1] = true
                return oldNamecall(self, unpack(args))
            end
            if self == Remotes.ClutchHeartbeat and _G._VynAutoHeartbeat then
                local args = {...}
                if not args[2] then args[2] = true end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- ===================== FAST / CLIP PROMPTS =====================
table.insert(Connections, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if _G._VynFastPrompts then
        task.spawn(fireproximityprompt, prompt)
    end
end))

table.insert(Connections, ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    if _G._VynClipPrompts then
        task.spawn(fireproximityprompt, prompt)
    end
end))

-- ===================== AUTO INTERACT / AURAS =====================
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if Disabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local range = _G._VynAutoInteractRange or 18

    -- Auto Interact / Item Aura / Loot Aura
    if _G._VynAutoInteract or _G._VynItemAura or _G._VynLootAura then
        for _, room in ipairs(CurrentRooms:GetChildren()) do
            for _, desc in ipairs(room:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local adornee = desc.AttachedTo or desc.Parent
                    if adornee and adornee:IsA("BasePart") then
                        local dist = (root.Position - adornee.Position).Magnitude
                        if dist <= range then
                            pcall(function() fireproximityprompt(desc) end)
                        end
                    end
                end
            end
        end
    end

    -- Gate Lever Aura
    if _G._VynLeverAura then
        for _, room in ipairs(CurrentRooms:GetChildren()) do
            for _, desc in ipairs(room:GetDescendants()) do
                if desc.Name == "LeverForGate" then
                    local main = desc:FindFirstChild("Main")
                    if main then
                        local dist = (root.Position - main.Position).Magnitude
                        if dist <= range then
                            local prompt = desc:FindFirstChildWhichIsA("ProximityPrompt")
                            if prompt then pcall(function() fireproximityprompt(prompt) end) end
                        end
                    end
                end
            end
        end
    end

    -- Breaker Switch Aura
    if _G._VynBreakerAura then
        for _, room in ipairs(CurrentRooms:GetChildren()) do
            for _, desc in ipairs(room:GetDescendants()) do
                if desc.Name == "Breaker" and desc:IsA("BasePart") then
                    local dist = (root.Position - desc.Position).Magnitude
                    if dist <= range then
                        pcall(function()
                            firetouchinterest(root, desc, 0)
                            task.wait(0.05)
                            firetouchinterest(root, desc, 1)
                        end)
                    end
                end
            end
        end
    end
end))

-- ===================== DOOR REACH =====================
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if _G._VynDoorReach then
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local range = _G._VynDoorReachRange or 30
        for _, room in ipairs(CurrentRooms:GetChildren()) do
            for _, desc in ipairs(room:GetDescendants()) do
                if desc.Name == "UnlockPrompt" and desc:IsA("ProximityPrompt") and desc.Enabled then
                    local adornee = desc.AttachedTo or desc.Parent
                    if adornee and adornee:IsA("BasePart") then
                        local dist = (root.Position - adornee.Position).Magnitude
                        if dist <= range then
                            pcall(function() fireproximityprompt(desc) end)
                        end
                    end
                end
            end
        end
    end
end))

-- ===================== GOD MODE =====================
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not _G._VynGodMode then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Restore health if damaged
    if hum.Health < hum.MaxHealth then
        hum.Health = hum.MaxHealth
    end

    -- Detect nearby entities and notify
    local detectRange = _G._VynEntityDetectRange or 125
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == "RushMoving" or child.Name == "AmbushMoving" or child.Name == "SeekMoving" or child.Name == "Lookman" then
            local part = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (root.Position - part.Position).Magnitude
                if dist <= detectRange then
                    -- Entity in range, ensure health stays full
                    hum.Health = hum.MaxHealth
                end
            end
        end
    end
end))

-- ===================== JUMPSCARE BLOCK =====================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    pcall(function()
        if CurrentCamera.CameraType == Enum.CameraType.Scriptable then
            CurrentCamera.CameraType = Enum.CameraType.Custom
        end
    end)
end))

-- ===================== CHARACTER RESPAWN =====================
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local ws = Library.Flags.WalkSpeed
    local jp = Library.Flags.JumpPower
    pcall(function()
        if ws and ws ~= 16 then char.Humanoid.WalkSpeed = ws end
        if jp and jp ~= 50 then char.Humanoid.JumpPower = jp end
    end)
    -- Reapply glow
    if _G._VynBodyGlow then
        local root = char:WaitForChild("HumanoidRootPart", 3)
        if root then
            if not root:FindFirstChild("VynGlow") then
                local pl = Instance.new("PointLight")
                pl.Name = "VynGlow"
                pl.Range = 60
                pl.Brightness = 2
                pl.Color = Color3.fromRGB(0, 255, 100)
                pl.Parent = root
                local sl = Instance.new("SurfaceLight")
                sl.Name = "VynGlow2"
                sl.Range = 200
                sl.Brightness = 1
                sl.Color = Color3.fromRGB(0, 255, 100)
                sl.Parent = root
            end
        end
    end
end))

Library:Notify("Vynixius loaded!", 3)
