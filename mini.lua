local plrsrv = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")
local userinputservice = game:GetService("UserInputService")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local screengui = plrgui:FindFirstChild("ScreenGui")
local RunService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
print("player name is "..plr.Name)

-- Esp Blink Config
local activeHighlights = {}
local blinkConnection = nil
local blinkStartTime = os.clock()
local BLINK_FREQ_HZ = 1
local BLINK_AMPLITUDE = 0.1

local function startBlinkLoop()
	if blinkConnection then
		return
	end
	blinkConnection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - blinkStartTime
		local factor = (math.sin(2 * math.pi * BLINK_FREQ_HZ * t) + 1) * 0.5
		for highlight, base in pairs(activeHighlights) do
			if highlight and highlight.Parent then
				local fillBase = base.FillTransparency or 0
				local outlineBase = base.OutlineTransparency or 0
				highlight.FillTransparency = math.clamp(fillBase+(1-fillBase)*factor*0.8, 0, 1)
				highlight.OutlineTransparency = math.clamp(outlineBase+(1-outlineBase)*factor*0.8, 0, 1)
			else
				activeHighlights[highlight] = nil
			end
		end
	end)
end

-- Billboard ESP Config
local function createBillboard(item, color, labelText, extraContentFn)
	local root = item:FindFirstChildOfClass("Part") or item:FindFirstChildOfClass("BasePart")
	if not root and item:IsA("BasePart") then root = item end
	if not root then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "AbstractBillboard"
	bb.Adornee = root
	bb.Size = UDim2.new(0, 80, 0, 80)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 500
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.Parent = item

	local frame = Instance.new("Frame", bb)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = color
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local dot = Instance.new("Frame", frame)
	dot.Size = UDim2.new(0.25, 0, 0.25, 0)
	dot.Position = UDim2.new(0.375, 0, 0.375, 0)
	dot.BackgroundColor3 = color
	dot.BackgroundTransparency = 0.3
	dot.BorderSizePixel = 0

	local label = Instance.new("TextLabel", bb)
	label.Size = UDim2.new(2, 0, 0, 14)
	label.Position = UDim2.new(-0.5, 0, 1, 2)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextScaled = false
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Text = labelText or item.Name

	if extraContentFn then
		extraContentFn(bb, color)
	end

	return bb
end

-- Actual ESP
local itemblacklist = {
	"Chocolate",
	"ExtractionSpeedCandy",
	"Gumball",
	"Jawbreaker",
	"ProteinBar",
	"SkillCheckCandy",
	"SpeedCandy",
	"StaminaCandy",
	"StealthCandy",
	"Stopwatch",
	"Tape",
	"ResearchCapsule",
	"Pop",
	"EjectButton",
	"SmokeBomb",
}

-- Sprout Tendril ESP
local function onAdded(item)
	if item.Parent.Name == "FreeArea" and item.Name ~= "SproutTendril" then
		return
	end
	if item:FindFirstChild("AbstractHighlight") ~= nil then return end
	if item:FindFirstChild("AbstractBillboard") ~= nil then return end

	for blackidx in itemblacklist do
		if item.Name == itemblacklist[blackidx] then
			return nil
		end
	end

	local highlighteffect = Instance.new("Highlight", item)
	highlighteffect.Name = "AbstractHighlight"

	-- Generator ESP
	if item.Name == "Generator" then
		if item:FindFirstChild("Stats") and item.Stats:FindFirstChild("Completed").Value == true then
			highlighteffect:Destroy()
			return nil
		end
		highlighteffect.OutlineTransparency = 0.2
		highlighteffect.FillTransparency = 0.85
		highlighteffect.FillColor = Color3.fromRGB(255, 200, 0)
		highlighteffect.OutlineColor = Color3.fromRGB(255, 200, 0)
		createBillboard(item, Color3.fromRGB(255, 200, 0), "Generator")

		local function onGenComplete()
			if item.Stats:FindFirstChild("Completed").Value == true then
				highlighteffect:Destroy()
				local bb = item:FindFirstChild("AbstractBillboard")
				if bb then bb:Destroy() end
			end
		end
		item.Stats:FindFirstChild("Completed"):GetPropertyChangedSignal("Value"):Connect(onGenComplete)

	-- Item ESP
	elseif item.Parent.Name == "Items" then
		local color = Color3.fromRGB(30, 144, 255)
		if item.Name == "Bandage" or item.Name == "HealthKit" then
			color = Color3.fromRGB(0, 220, 100)
		end
		highlighteffect.OutlineTransparency = 0.2
		highlighteffect.FillTransparency = 0.85
		highlighteffect.FillColor = color
		highlighteffect.OutlineColor = color
		createBillboard(item, color, item.Name)

	-- Player ESP
	elseif item.Parent.Name == "InGamePlayers" then
		highlighteffect.OutlineTransparency = 0.2
		highlighteffect.FillTransparency = 0.85
		highlighteffect.FillColor = Color3.fromRGB(0, 128, 0)
		highlighteffect.OutlineColor = Color3.fromRGB(0, 128, 0)

	-- Monster/Default ESP
	else
		highlighteffect.OutlineTransparency = 0.2
		highlighteffect.FillTransparency = 0.85
		highlighteffect.FillColor = Color3.fromRGB(178, 34, 34)
		highlighteffect.OutlineColor = Color3.fromRGB(178, 34, 34)
		createBillboard(item, Color3.fromRGB(178, 34, 34), item.Name)
	end

	activeHighlights[highlighteffect] = {
		FillTransparency = highlighteffect.FillTransparency,
		OutlineTransparency = highlighteffect.OutlineTransparency,
	}
	startBlinkLoop()
end

local function Abstract_HighLight(room, foldername)
	print("Current Floor Name is "..room.Name)
	local dir = room:WaitForChild(foldername)
	local list = dir:GetChildren()
	for itemidx in list do
		onAdded(list[itemidx])
	end
	dir.ChildAdded:Connect(onAdded)
end

local function highlightmonstereffect(parent)
	local highlighteffect = Instance.new("Highlight", parent)
	highlighteffect.Name = "AbstractHighlight"
	highlighteffect.OutlineTransparency = 0.2
	highlighteffect.FillTransparency = 0.85
	highlighteffect.FillColor = Color3.fromRGB(178, 34, 34)
	highlighteffect.OutlineColor = Color3.fromRGB(178, 34, 34)
	activeHighlights[highlighteffect] = {
		FillTransparency = highlighteffect.FillTransparency,
		OutlineTransparency = highlighteffect.OutlineTransparency,
	}
	createBillboard(parent, Color3.fromRGB(178, 34, 34), parent.Name)
end

-- Blot Hands ESP
local function highlightblothand(hand)
	print("hand is "..hand.Name)
	local arm = hand:WaitForChild("Arm")
	if arm:FindFirstChild("AbstractHighlight") ~= nil then return end
	highlightmonstereffect(arm)
end

local function highlightblotzone(entity)
	if entity:IsA("Part") and string.find(entity.Name, "BlotHandZone") then
		print("find blot hand zone "..entity.Name)
		local hand = entity:FindFirstChildOfClass("Model")
		if hand == nil then
			print("blot hand not loaded")
			entity.ChildAdded:Connect(highlightblothand)
		else
			highlightblothand(hand)
		end
	end
end

-- Room highlight
local roomdir = workspace.CurrentRoom
local roomentity = roomdir:FindFirstChildOfClass("Model")

local function onRoomGen(roominstance)
	print("the room Gen is "..roominstance.Name)
	roomentity = roominstance
	for idx, instance in roominstance:GetChildren() do
		highlightblotzone(instance)
	end
	roominstance.ChildAdded:Connect(highlightblotzone)
	Abstract_HighLight(roominstance, "Monsters")
	Abstract_HighLight(roominstance, "Generators")
	Abstract_HighLight(roominstance, "Items")
	Abstract_HighLight(roominstance, "FreeArea")
end

local function onRoomDestroy(roominstance)
	roomentity = nil
	print("the room destroyed is "..roominstance.Name)
end

if roomentity ~= nil then
	onRoomGen(roomentity)
end
roomdir.ChildAdded:Connect(onRoomGen)
roomdir.ChildRemoved:Connect(onRoomDestroy)

-- Player ESP (With custom billboard)
local playerlist = workspace.InGamePlayers:GetChildren()
for playeridx in playerlist do
	if playerlist[playeridx].Name == plr.Name then
		continue
	end
	local playerentity = playerlist[playeridx]
	print("Highlight game player is "..playerentity.Name)
	onAdded(playerentity)

	createBillboard(playerentity, Color3.fromRGB(0, 128, 0), playerentity.Name, function(bb, color)
		local heartLabel = Instance.new("TextLabel", bb)
		heartLabel.Size = UDim2.new(2, 0, 0, 14)
		heartLabel.Position = UDim2.new(-0.5, 0, 1, 18)
		heartLabel.BackgroundTransparency = 1
		heartLabel.TextColor3 = color
		heartLabel.TextScaled = false
		heartLabel.TextSize = 12
		heartLabel.Font = Enum.Font.GothamBold

		local function buildHeartStr(health, maxHealth)
			local str = ""
			for i = 1, health do str = str.."🤍" end
			for i = 1, maxHealth - health do str = str.."🖤" end
			return str
		end

		heartLabel.Text = buildHeartStr(playerentity.Humanoid.Health, playerentity.Humanoid.MaxHealth)
		playerentity.Humanoid.HealthChanged:Connect(function(health)
			heartLabel.Text = buildHeartStr(health, playerentity.Humanoid.MaxHealth)
			print("new life "..health)
		end)
	end)
end

-- No More Vee Popups
function hasProperty(object, propertyName)
	local success, _ = pcall(function()
		object[propertyName] = object[propertyName]
	end)
	return success
end

if screengui ~= nil then
	print("screengui founded")
	local popup = screengui:FindFirstChild("PopUp")
	if popup ~= nil then
		print(popup.Name.." Founded")
		local list = popup:GetChildren()
		for itemidx in list do
			if hasProperty(list[itemidx], "Visible") then
				print("hide "..list[itemidx].Name)
				list[itemidx].Visible = false
			end
		end
	end
end

-- Inf Stam
local sprintevent = replicated.Events:WaitForChild("SprintEvent")
local updateLoop = nil
local updateEnabled = false
l
