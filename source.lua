assert(plugin, "This script is meant to be ran as a plugin!")

-- / SERVICES
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- / CREATE TOOLBAR SECTION
local Toolbar = plugin:CreateToolbar("Lighting Saver")

-- / ADD BUTTONS
local SaveButton = Toolbar:CreateButton("Save Lighting", "Save Lighting Settings", "rbxassetid://103169511284697")
local LoadButton = Toolbar:CreateButton("Load Lighting", "Load Lighting Config", "rbxassetid://135224231319187")

-- / TABLES
local LightingProperties = {
	"Ambient",
	"Brightness",
	"ColorShift_Bottom",
	"ColorShift_Top",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
	"ExposureCompensation",
	"FogColor",
	"FogEnd",
	"FogStart",
	"GeographicLatitude",
	"GlobalShadows",
	"LightingStyle",
	"OutdoorAmbient",
	"ShadowSoftness",
	"TimeOfDay",
	"ClockTime",
	"PrioritizeLightingQuality",
}

-- / FUNCTIONS
local function ShowMessage(Message:string)
	assert(Message, "Must specify a message!")
	
	local MessageGui = Instance.new("ScreenGui")
	MessageGui.Name = string.format("Message%d", DateTime.now().UnixTimestamp)
	MessageGui.Parent = CoreGui
	
	local TextLabel:TextLabel = Instance.new("TextLabel")
	TextLabel.Parent = MessageGui
	TextLabel.Size = UDim2.new(1,0,0,50)
	--TextLabel.Position = UDim2.new(0,0,0.5,-25)
	TextLabel.Position = UDim2.new(0,0,0,-50)
	TextLabel.TextSize = 20
	TextLabel.Text = Message
	TextLabel.BorderColor3 = Color3.fromRGB(222,222,222)
	
	TweenService:Create(TextLabel, TweenInfo.new(0.5), {Position = UDim2.new(0,0,0.5,-25)}):Play()
	
	task.delay(0.5+(string.len(Message)/20), function()
		TweenService:Create(TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0,0,1,0)}):Play()
		task.wait(0.5)
		MessageGui:Destroy()
	end)
end

SaveButton.ClickableWhenViewportHidden = false
LoadButton.ClickableWhenViewportHidden = false

SaveButton.Click:Connect(function()
	
	local LightCount:number = 0
	
	for _,v in pairs(Lighting:GetChildren()) do
		if string.sub(v.Name, 1, 17) == "OldLightingConfig" then
			LightCount += 1
		end
	end

	local ConfigNew:Configuration = Instance.new("Configuration")
	ConfigNew.Name = LightCount == 0 and "OldLightingConfig" or string.format("OldLightingConfig%d", LightCount)
	ConfigNew.Parent = Lighting

	for _, Property:string in pairs(LightingProperties) do
		ConfigNew:SetAttribute(Property, Lighting[Property])
	end
	
	Selection:Set({ConfigNew})
	ChangeHistoryService:SetWaypoint("Saved Lighting to Object")
end)

LoadButton.Click:Connect(function()
	local CurrentSelection:{} = Selection:Get()
	
	-- // SELECTION VALIDATION
	-- / CHECK AMOUNT OF SELECTED OBJECTS
	if #CurrentSelection ~= 1 then
		if #CurrentSelection == 0 then
			ShowMessage("Select the Config you want to load!")
			return
		else
			ShowMessage("Please only select one object!")
			return
		end
	end
	
	-- / CHECK IF SELECTED OBJECT IS A PROPER CONFIG
	local Selected:Configuration = CurrentSelection[1]
	local Attributes = Selected:GetAttributes()
	
	if Selected.ClassName ~= "Configuration" then
		ShowMessage("Not a valid configuration object!")
		return
	end
	
	for _,Property:string in pairs(LightingProperties) do
		if typeof(Attributes[Property]) ~= typeof(Lighting[Property]) then
			ShowMessage("Not a valid lighting config!")
			return
		end
	end
	
	-- // LOAD CONFIG
	for Property:string, Value in pairs(Attributes) do
		Lighting[Property] = Value
	end
	
	ChangeHistoryService:SetWaypoint("Loaded Lighting")
end)
