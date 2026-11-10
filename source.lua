--[=[
    Created by CombineBenefactor <https://github.com/CombineBenefactor>
    Updates by forka42 <https://github.com/forka42>
]=]
assert(plugin, 'This script is meant to be ran as a plugin!')

local ChangeHistoryService = game:GetService('ChangeHistoryService')
local Selection = game:GetService('Selection')
local CoreGui = game:GetService('CoreGui')
local TweenService = game:GetService('TweenService')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting') :: any
local ReflectionService = game:GetService('ReflectionService')

--[=[
    Create the toolbar and buttons first so they always appear,
    even if something later in the script fails.
]=]
local Toolbar = plugin:CreateToolbar('Lighting Saver')
local SaveButton = Toolbar:CreateButton('Save Lighting', 'Save Lighting Settings', 'rbxassetid://103169511284697')
local LoadButton = Toolbar:CreateButton('Load Lighting', 'Load Lighting Config', 'rbxassetid://135224231319187')

SaveButton.ClickableWhenViewportHidden = false
LoadButton.ClickableWhenViewportHidden = false

-- Properties

--[=[
    Set on a config when it contains saved instances (Sky, Atmosphere, etc.).
    Configs saved by older versions don't have it, so loading them leaves
    your current Sky/Atmosphere/effects alone.
]=]
local INSTANCES_MARKER = '_SavedInstances'

--[=[
    Properties that have nothing to do with the lighting engine (Sandboxed,
    HistoryId, UniqueId, etc.) are never saved or loaded. These names are a
    safety net; every property of the Instance class itself is also looked up
    through ReflectionService and excluded automatically.
]=]
local SkippedProperties = {
    Name = true,
    Parent = true,
    Archivable = true,
    ClassName = true,
    className = true,
    Sandboxed = true,
    Capabilities = true,
    DefinesCapabilities = true,
    HistoryId = true,
    UniqueId = true,
    SourceAssetId = true,
    RobloxLocked = true,
    AttributesSerialize = true,
    Outlines = true, -- deprecated
    ExtendLightRangeTo120 = true, -- unused / not scriptable
}

--[=[
    Always attempted in addition to whatever ReflectionService returns,
    so newer properties are covered even if reflection misses them.
    Anything unreadable/unwritable from a plugin is skipped with a warning.
]=]
local ExtraPropertyNames = {
    'Ambient', 'Brightness', 'ClockTime', 'ColorShift_Bottom', 'ColorShift_Top',
    'EnvironmentDiffuseScale', 'EnvironmentSpecularScale', 'ExposureCompensation',
    'FogColor', 'FogEnd', 'FogStart', 'GeographicLatitude', 'GlobalShadows',
    'OutdoorAmbient', 'ShadowSoftness', 'TimeOfDay',
    'LightingStyle', 'PrioritizeLightingQuality',
}

local CachedPropertyNames = nil

local function TryReflect(className: string, withFilter: boolean)
    local ok, result = pcall(function()
        if withFilter then
            return ReflectionService:GetPropertiesOfClass(className, {
                Security = SecurityCapabilities.new(Enum.SecurityCapability.Plugin)
            })
        end
        return ReflectionService:GetPropertiesOfClass(className)
    end)
    if ok and typeof(result) == 'table' and #result > 0 then
        return result
    end
    return nil
end

--[=[
    Returns a list of property names. Reflection results are cached once they
    succeed; if reflection fails we still return the extra list and retry next time.
]=]
local function GetPropertyNames(): {string}
    if CachedPropertyNames then
        return CachedPropertyNames
    end

    -- Everything declared on Instance is not a lighting property
    local skipped = {}
    for name in pairs(SkippedProperties) do
        skipped[name] = true
    end
    local instanceProps = TryReflect('Instance', true) or TryReflect('Instance', false)
    if instanceProps then
        for _, descriptor in ipairs(instanceProps) do
            skipped[descriptor.Name] = true
        end
    end

    local names, seen = {}, {}
    local function add(name)
        if type(name) == 'string' and not seen[name] and not skipped[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    local reflected = TryReflect('Lighting', true) or TryReflect('Lighting', false)
    if reflected then
        for _, descriptor in ipairs(reflected) do
            add(descriptor.Name)
        end
    else
        warn('Lighting Saver: ReflectionService returned no properties, using built-in list only.')
    end
    for _, name in ipairs(ExtraPropertyNames) do
        add(name)
    end

    if reflected then
        CachedPropertyNames = names
    end
    return names
end

local function ReadProperty(name: string)
    local ok, value = pcall(function()
        return Lighting[name]
    end)
    return ok, value
end

--[=[
    Attributes can't store enums, so enum values are saved as strings
    like 'Enum.LightingStyle.Soft' and converted back on load.
]=]
local function Encode(value)
    if typeof(value) == 'EnumItem' then
        return tostring(value)
    end
    return value
end

local function Decode(saved, current)
    if typeof(current) == 'EnumItem' then
        if typeof(saved) ~= 'string' then
            return nil
        end
        local itemName = string.match(saved, '([^%.]+)$')
        local ok, item = pcall(function()
            return current.EnumType[itemName]
        end)
        if ok and typeof(item) == 'EnumItem' then
            return item
        end
        return nil
    end
    if typeof(saved) == typeof(current) then
        return saved
    end
    return nil
end

-- Instances (Sky, Atmosphere, post effects, Clouds)

local function IsSupportedInstance(instance: Instance): boolean
    return instance:IsA('Sky')
        or instance:IsA('Atmosphere')
        or instance:IsA('PostEffect')
        or instance:IsA('ColorGradingEffect')
        or instance:IsA('Clouds')
end

-- Clouds live under Terrain; everything else lives directly under Lighting.
local function GetTerrain()
    return Workspace:FindFirstChildOfClass('Terrain')
end

local function SaveInstances(ConfigNew: Instance)
    local count = 0
    local function saveFrom(container: Instance?)
        if not container then
            return
        end
        for _, child in ipairs(container:GetChildren()) do
            if IsSupportedInstance(child) then
                local copy = child:Clone()
                if copy then
                    copy.Parent = ConfigNew
                    count += 1
                else
                    warn(string.format('Lighting Saver: could not clone %s (not Archivable?)', child:GetFullName()))
                end
            end
        end
    end
    saveFrom(Lighting)
    saveFrom(GetTerrain())
    ConfigNew:SetAttribute(INSTANCES_MARKER, true)
    return count
end

local function LoadInstances(Config: Instance)
    local terrain = GetTerrain()

    -- Remove what's currently active...
    for _, child in ipairs(Lighting:GetChildren()) do
        if IsSupportedInstance(child) then
            child:Destroy()
        end
    end
    if terrain then
        for _, child in ipairs(terrain:GetChildren()) do
            if child:IsA('Clouds') then
                child:Destroy()
            end
        end
    end

    -- ...then restore the saved ones.
    for _, saved in ipairs(Config:GetChildren()) do
        if IsSupportedInstance(saved) then
            local target = saved:IsA('Clouds') and terrain or Lighting
            if target then
                local copy = saved:Clone()
                if copy then
                    copy.Parent = target
                end
            else
                warn('Lighting Saver: no Terrain found, skipped ' .. saved.Name)
            end
        end
    end
end

-- UI

local function ShowMessage(Message:string)
    assert(Message, 'Must specify a message!')
    local MessageGui = Instance.new('ScreenGui')
    MessageGui.Name = string.format('Message%d', DateTime.now().UnixTimestamp)
    MessageGui.Parent = CoreGui
    local TextLabel:TextLabel = Instance.new('TextLabel')
    TextLabel.Parent = MessageGui
    TextLabel.Size = UDim2.new(1,0,0,50)
    TextLabel.Position = UDim2.new(0,0,0,-50)
    TextLabel.TextSize = 20
    TextLabel.Text = Message
    TextLabel.BorderColor3 = Color3.new(.87,.87,.87)
    TweenService:Create(TextLabel, TweenInfo.new(0.5), {Position = UDim2.new(0,0,0.5,-25)}):Play()
    task.delay(.5 + (string.len(Message)/20), function()
        TweenService:Create(TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0,0,1,0)}):Play()
        task.wait(0.5)
        MessageGui:Destroy()
    end)
end

-- Buttons

SaveButton.Click:Connect(function()
    local LightCount = 0
    for _, v in pairs(Lighting:GetChildren()) do
        if string.sub(v.Name, 1, 17) == 'OldLightingConfig' then
            LightCount += 1
        end
    end

    local ConfigNew = Instance.new('Configuration')
    ConfigNew.Name = LightCount == 0 and 'OldLightingConfig' or string.format('OldLightingConfig%d', LightCount)

    -- Properties
    for _, name in ipairs(GetPropertyNames()) do
        local ok, value = ReadProperty(name)
        if ok then
            local saveOk, err = pcall(function()
                ConfigNew:SetAttribute(name, Encode(value))
            end)
            if not saveOk then
                warn(string.format('Lighting Saver: skipped %s (%s)', name, tostring(err)))
            end
        else
            warn(string.format('Lighting Saver: could not read %s (%s)', name, tostring(value)))
        end
    end

    -- Instances (parent the config last so it isn't picked up while cloning)
    local InstanceCount = SaveInstances(ConfigNew)

    ConfigNew.Parent = Lighting
    Selection:Set({ConfigNew})
    ChangeHistoryService:SetWaypoint('Saved Lighting to Object')
    ShowMessage(string.format('Saved lighting (%d instances)', InstanceCount))
end)

LoadButton.Click:Connect(function()
    local CurrentSelection = Selection:Get()
    if #CurrentSelection ~= 1 then
        if #CurrentSelection == 0 then
            ShowMessage('Select the Config you want to load!')
            return
        end
        ShowMessage('Please only select one object!')
        return
    end

    local Selected = CurrentSelection[1]
    if typeof(Selected) ~= 'Instance' or not Selected:IsA('Configuration') then
        ShowMessage('Not a valid configuration object!')
        return
    end

    local Attributes = Selected:GetAttributes()
    local Names = GetPropertyNames()

    --[=[
        Validate: saved values must match the live property type,
        and at least one lighting property must be present.
    ]=]
    local Matched = 0
    for _, name in ipairs(Names) do
        local saved = Attributes[name]
        if saved ~= nil then
            local ok, current = ReadProperty(name)
            if ok then
                if Decode(saved, current) == nil then
                    ShowMessage('Not a valid lighting config!')
                    return
                end
                Matched += 1
            end
        end
    end
    if Matched == 0 then
        ShowMessage('Not a valid lighting config!')
        return
    end

    -- Properties
    for _, name in ipairs(Names) do
        local saved = Attributes[name]
        if saved ~= nil then
            local ok, current = ReadProperty(name)
            if ok then
                local value = Decode(saved, current)
                if value ~= nil then
                    local setOk, err = pcall(function()
                        Lighting[name] = value
                    end)
                    if not setOk then
                        warn(string.format('Lighting Saver: could not set %s (%s)', name, tostring(err)))
                    end
                end
            end
        end
    end

    -- Instances (only if this config was saved with them)
    if Attributes[INSTANCES_MARKER] then
        LoadInstances(Selected)
    end

    ChangeHistoryService:SetWaypoint('Loaded Lighting')
end)

print('Lighting Saver: toolbar created')