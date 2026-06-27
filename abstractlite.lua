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
	"ResearchCapsule",
	"Pop",
	"EjectButton",
	"SmokeBomb",
}

	-- Sprout Tendril ESP
local function onAdded(item)
	if item.Parent.Name=="FreeArea" and item.Name~="SproutTendril" then
		return
	end
	local isHighlight = item:FindFirstChild("AbstractHighlight")
	if isHighlight ~= nil then
		return
	end

	-- Item Blacklist Handler
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
		highlighteffect.OutlineTransparency = 1
		highlighteffect.FillTransparency = 0.5
		highlighteffect.OutlineColor = Color3.fromRGB(255, 200, 0)
		highlighteffect.FillColor = Color3.fromRGB(255, 200, 0)
		local function onGenComplete()
			if item.Stats:FindFirstChild("Completed").Value == true then
				highlighteffect:Destroy()
			end
		end
		item.Stats:FindFirstChild("Completed"):GetPropertyChangedSignal("Value"):Connect(onGenComplete)

		-- Item ESP
	elseif item.Parent.Name == "Items" then
		local color = Color3.fromRGB(30, 144, 255)
		if item.Name == "Bandage" or item.Name == "HealthKit" then
			color = Color3.fromRGB(0, 220, 100)
		end
		highlighteffect.OutlineTransparency = 1
		highlighteffect.FillTransparency = 0.5
		highlighteffect.OutlineColor = color
		highlighteffect.FillColor = color

		--Player ESP
	elseif item.Parent.Name == "InGamePlayers" then
		highlighteffect.OutlineTransparency = 1
		highlighteffect.FillTransparency = 0.5
		highlighteffect.OutlineColor = Color3.fromRGB(0, 128, 0)
		highlighteffect.FillColor = Color3.fromRGB(0, 128, 0)

	else
		highlighteffect.OutlineTransparency = 1
		highlighteffect.FillTransparency = 0.5
		highlighteffect.OutlineColor = Color3.fromRGB(178, 34, 34)
		highlighteffect.FillColor = Color3.fromRGB(178, 34, 34)
	end
end

	-- Room ESP Handler
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
	highlighteffect.OutlineTransparency = 1
	highlighteffect.FillTransparency = 0.5
	highlighteffect.OutlineColor = Color3.fromRGB(178, 34, 34)
	highlighteffect.FillColor = Color3.fromRGB(178, 34, 34)
end

-- Blot Hands ESP
local function highlightblothand(hand)
	print("hand is "..hand.Name)
	local arm = hand:WaitForChild("Arm")
	local isHighlight = arm:FindFirstChild("AbstractHighlight")
	if isHighlight ~= nil then
		return
	end
	highlightmonstereffect(arm)
end

local function highlightblotzone(entity)
	if entity:IsA("Part") and string.find(entity.Name,"BlotHandZone") then
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

-- Room Highlight
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

-- Player ESP Handler
local playerlist = workspace.InGamePlayers:GetChildren()
for playeridx in playerlist do
	if playerlist[playeridx].Name == plr.Name then
		continue
	end
	local playerentity = playerlist[playeridx]
	print("Highlight game player is "..playerentity.Name)
	onAdded(playerentity)
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
local sprinting = localcharacter.Stats.Sprinting

local serversidesprint = nil

function looprunspeed()
	localcharacter.Humanoid.WalkSpeed = plr:GetAttribute("KM_MAX_PLAYER_SPEED")
	sprinting.Value = updateEnabled
	if not updateLoop then
		updateLoop = coroutine.create(function()
			while updateEnabled do
				localcharacter.Humanoid.WalkSpeed = plr:GetAttribute("KM_MAX_PLAYER_SPEED")
				sprinting.Value = updateEnabled
				task.wait()
			end
		end)
	end
	coroutine.resume(updateLoop)
end

function enablelooprunspeed()
	updateEnabled = true
	localcharacter.Humanoid.WalkSpeed = plr:GetAttribute("KM_MAX_PLAYER_SPEED")
	sprinting.Value = updateEnabled
	print("enablelooprunspeed:done")
end

local walkspeed = 0
function disablelooprunspeed()
	updateEnabled = false
	if walkspeed ~= 0 and serversidesprint == false then
		localcharacter.Humanoid.WalkSpeed = walkspeed
	end
	sprinting.Value = updateEnabled
	print("disablelooprunspeed:done")
end

-- Kill sprint when client event yes
for i, connection in pairs(getconnections(sprintevent.OnClientEvent)) do
	print("disable sprintevent.OnClientEvent")
	connection:Disable()
end

sprintevent.OnClientEvent:Connect(function(arg1)
	print("sprintevent.OnClientEvent, server is false")
	serversidesprint = false
	walkspeed = localcharacter.Humanoid.WalkSpeed
	enablelooprunspeed()
end)

for i, connection in pairs(getconnections(screengui.MobileRun.Activated)) do
	print("disable screengui.MobileRun.Activated")
	connection:Disable()
end

screengui.MobileRun.Activated:Connect(function()
	if screengui.MobileRun.TextLabel.Text == "SPRINT: OFF" then
		screengui.MobileRun.TextLabel.Text = "SPRINT: ON"
		screengui.MobileRun.Image = "rbxassetid://11866539249"
		sprintevent:FireServer(true)
		serversidesprint = true
		screengui.SprintIcon.Visible = false
		enablelooprunspeed()
		return
	end
	disablelooprunspeed()
	screengui.MobileRun.TextLabel.Text = "SPRINT: OFF"
	screengui.MobileRun.Image = "rbxassetid://11866517702"
	screengui.SprintIcon.Visible = false
	sprintevent:FireServer(false)
	serversidesprint = false
end)

local isprocessed = false
userinputservice.InputBegan:Connect(function(inputobj, processevent)
	if processevent then return end
	if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then
		if isprocessed then return end
		enablelooprunspeed()
		serversidesprint = true
		isprocessed = true
		print("in r1 input begin, send server true")
	end
end)

userinputservice.InputEnded:Connect(function(inputobj, processevent)
	if processevent then return end
	if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then
		disablelooprunspeed()
		print("in r1 input end ,send false ")
		sprintevent:FireServer(false)
		serversidesprint = false
		isprocessed = false
	end
end)

-- Anti-Fail Skillcheck
	-- Old AutoSC modules for later reference
		--local TreadmillTapSkillCheck_upvr_2 = require(game.ReplicatedStorage.Modules.TreadmillTapSkillCheck)
		--local CircleSkillCheckHandler_upvr = require(ReplicatedStorage_upvr.Modules.CircleSkillCheckHandler)
		--local RF = game:GetService("ReplicatedStorage").Events.SkillcheckUpdate
		--local cb = getcallbackvalue(RF, "OnClientInvoke");

local skillcheckupdate = replicated.Events:WaitForChild("SkillcheckUpdate")
local oriskillcheckupdate = nil
print("Abstract: try Hooking SkillcheckUpdate...")
local retry = 5
while oriskillcheckupdate == nil and retry > 0 do
	if getcallbackvalue ~= nil then
		oriskillcheckupdate = getcallbackvalue(skillcheckupdate, "OnClientInvoke")
	end
	task.wait(1)
	retry = retry - 1
end

skillcheckupdate.OnClientInvoke = function(...)
	local args = { ... }
	local result
	print("[SkillcheckUpdate] args:", unpack(args))
	if oriskillcheckupdate ~= nil then
		result = oriskillcheckupdate(...)
		print("[SkillcheckUpdate] return:", result)
	else
		print("[SkillcheckUpdate] oriskillcheckupdate is still nil")
	end
	local arg2 = select(2, ...)
	print("arg2 typeof is "..typeof(arg2))
	if arg2 and typeof(arg2) == "table" then
		if arg2.type == "treadmill" then
			print("it is treadmill, return true")
			return true
		elseif arg2.type == "circle" then
			print("it is circle machine, return autoskillcheck")
			return "autoskillcheck"
		else
			print("arg2.type is "..arg2.type)
			return true
		end
	else
		print("it is normal machine, return autoskillcheck")
		return "autoskillcheck"
	end
end
print("Abstract: Hooking SkillcheckUpdate Success...")

local function getsiblings(part)
	if part.Parent then
		return part.Parent:GetChildren()
	end
end

-- Barnaby Machine Autoskillcheck (thx qwel)
loadstring(game:HttpGet("https://raw.githubusercontent.com/christmas-cookie/extensions/refs/heads/main/arcademachine", true))()

-- Fullbright
local function SetFullbright(enabled)
	if enabled then
		lighting.Ambient = Color3.fromRGB(255, 255, 255)
		lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		lighting.Brightness = 10
		lighting.FogEnd = 100000
		lighting.FogStart = 100000
		for _, effect in ipairs(lighting:GetChildren()) do
			if effect:IsA("Atmosphere") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
				effect.Enabled = false
			end
		end
	else
		lighting.Ambient = Color3.fromRGB(0, 0, 0)
		lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
		lighting.Brightness = 1
		lighting.FogEnd = 100000
	end
end

SetFullbright(true)

lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
	if lighting.FogEnd ~= 100000 then
		SetFullbright(true)
	end
end)

lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
	if lighting.Ambient ~= Color3.fromRGB(255, 255, 255) then
		SetFullbright(true)
	end
end)

-- Auto Struggle (totally didn't rip from Riddance what I would never do that)
local TwistedSquirmGrabremote = replicated:WaitForChild("Events"):WaitForChild("TwistedSquirmGrab")

local autostrugglerunning = false
local squirmdir = "left"

TwistedSquirmGrabremote.OnClientEvent:Connect(function(action)
	if action == "GrabStart" then
		autostrugglerunning = true
	elseif action == "GrabEnd" then
		autostrugglerunning = false
	end
end)

task.spawn(function()
	while true do
		task.wait(0.06)
		if autostrugglerunning then
			if squirmdir == "left" then
				TwistedSquirmGrabremote:FireServer("Struggle", "left")
				squirmdir = "right"
			else
				TwistedSquirmGrabremote:FireServer("Struggle", "right")
				squirmdir = "left"
			end
		end
	end
end)

-- Anti-Lag
local function applyAntiLag(part)
    if part:IsA("BasePart") then
        part.Material = Enum.Material.SmoothPlastic
    elseif part:IsA("Decal") or part:IsA("Texture") then
        part:Destroy()
    end
end

for _, part in ipairs(workspace:GetDescendants()) do
    applyAntiLag(part)
end

workspace.DescendantAdded:Connect(applyAntiLag)
