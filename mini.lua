local plrsrv = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")
local userinputservice = game:GetService("UserInputService")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local screengui = plrgui:FindFirstChild("ScreenGui")
local RunService = game:GetService("RunService")
local lighting=game:GetService("Lighting")
print("player name is "..plr.Name)

-- Esp Blink
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

local function onAdded(item)
	-- Sprout Tendril Highlight
	if item.Parent.Name=="FreeArea" and item.Name~="SproutTendril" then
	    return
	end
	local isHighlight = item:FindFirstChild("AbstractHighlight")
	if isHighlight ~= nil then
	    return
	end

	for blackidx in itemblacklist do
		if item.Name == itemblacklist[blackidx] then
			return nil
		end
	end
	local highlighteffect = Instance.new("Highlight", item)
	highlighteffect.Name = "AbstractHighlight"
	if item.Name == "Generator" then
		if item:FindFirstChild("Stats") and item.Stats:FindFirstChild("Completed").Value == true then
		    highlighteffect:Destroy()
			return nil
		end
		highlighteffect.OutlineTransparency = 0.8
		highlighteffect.FillTransparency=1
		local function onGenComplete()
			if item.Stats:FindFirstChild("Completed").Value == true then
				highlighteffect:Destroy()
			end
		end
		item.Stats:FindFirstChild("Completed"):GetPropertyChangedSignal("Value"):Connect(onGenComplete)
	elseif item.Parent.Name == "Items" then
		highlighteffect.FillTransparency=0.7
		highlighteffect.FillColor = Color3.fromRGB(30, 144, 255)
		if item.Name=="Bandage" or item.Name=="HealthKit" then
			highlighteffect.OutlineTransparency=0.1
		else
			highlighteffect.OutlineTransparency=1
		end
	elseif item.Parent.Name == "InGamePlayers" then
		highlighteffect.FillTransparency=0.7
		highlighteffect.OutlineTransparency = 0.1
		highlighteffect.FillColor = Color3.fromRGB(0, 128, 0)
		highlighteffect.OutlineColor = Color3.fromRGB(0, 100, 0)
	else
		highlighteffect.OutlineColor = Color3.fromRGB(178,34,34)
		highlighteffect.FillColor = Color3.fromRGB(178,34,34)
		highlighteffect.OutlineTransparency=0.3
		highlighteffect.FillTransparency = 0.7
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
    highlighteffect.OutlineColor = Color3.fromRGB(178,34,34)
    highlighteffect.FillColor = Color3.fromRGB(178,34,34)
    highlighteffect.OutlineTransparency=0.3
    highlighteffect.FillTransparency = 0.7
    activeHighlights[highlighteffect] = {
        FillTransparency = highlighteffect.FillTransparency,
        OutlineTransparency = highlighteffect.OutlineTransparency,
    }
end

-- Blot Hands Highlight
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
local roomdir=workspace.CurrentRoom
local roomentity=roomdir:FindFirstChildOfClass("Model")

local function onRoomGen(roominstance)
	print("the room Gen is "..roominstance.Name)
	roomentity = roominstance
    for idx,instance in roominstance:GetChildren() do
        highlightblotzone(instance)
    end
    roominstance.ChildAdded:Connect(highlightblotzone)
	Abstract_HighLight(roominstance,"Monsters")
	Abstract_HighLight(roominstance,"Generators")
	Abstract_HighLight(roominstance,"Items")
	Abstract_HighLight(roominstance,"FreeArea")
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

--Player Highlights
local playerlist = workspace.InGamePlayers:GetChildren()
for playeridx in playerlist do
	if playerlist[playeridx].Name == plr.Name then
		continue
	end
	local playerentity = playerlist[playeridx]
	print("Highlight game player is "..playerentity.Name)
	onAdded(playerentity)
	local billboard = Instance.new("BillboardGui", playerentity)
	billboard.Size = UDim2.new(10,0,10,0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.StudsOffset = Vector3.new(0, -3, 0)
	local frame = Instance.new("Frame", billboard)
	frame.Size = UDim2.new(0.3,0,0.4,0)
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.new(0.35,0,0.6,0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

	--新建垂直布局
	local mainLayout = Instance.new("UIListLayout", frame)
	mainLayout.FillDirection = Enum.FillDirection.Vertical
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0, 0)
	--上行：心和体力
	local heartRow = Instance.new("Frame", frame)
	heartRow.Size = UDim2.new(1,0,0.5,0)
	heartRow.BackgroundTransparency = 1
	heartRow.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	--上行：间隔
	local layout = Instance.new("UIListLayout", heartRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.05, 0)
	--下行：slot
	local slotRow = Instance.new("Frame", frame)
	slotRow.Size = UDim2.new(1,0,0.5,0)
	slotRow.BackgroundTransparency = 1
	slotRow.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
	
	--心的显示
	local textlabel = Instance.new("TextLabel", heartRow)
	textlabel.Size=UDim2.new(1.5,0,1.5,0)
	textlabel.Position=UDim2.new(-0.25,0,0,0)
	textlabel.TextScaled = true
	textlabel.TextSize = 21
	textlabel.TextColor3 = Color3.new(0,1,0)
	textlabel.BackgroundTransparency = 1
	local healthstr=""
	for i = 1, playerentity.Humanoid.Health do
		healthstr = healthstr.."🤍"
	end
	textlabel.Text = healthstr
	playerentity.Humanoid.HealthChanged:Connect(function(health)
		local healthstrnew = ""
		for i = 1, health do
			healthstrnew = healthstrnew.."🤍"
		end
		for i = 1, playerentity.Humanoid.MaxHealth-health do
			healthstrnew = healthstrnew.."🖤"
		end
		textlabel.Text = healthstrnew
		print("new life "..health)
	end)
	
	--体力数值显示
    local Staminatextlabel = Instance.new("TextLabel", heartRow)
	Staminatextlabel.Size=UDim2.new(1,0,1,0)
	Staminatextlabel.Position=UDim2.new(-0.25,0,0,0)
	Staminatextlabel.TextScaled = true
	Staminatextlabel.TextSize = 18
	Staminatextlabel.TextColor3 = Color3.new(0,1,0)
	Staminatextlabel.BackgroundTransparency = 1
	Staminatextlabel.Font = Enum.Font.LuckiestGuy
	local function UpdateStamina()
	    local CurrentStamina=playerentity.Stats.CurrentStamina
	    local MaxStamina=playerentity.Stats.Stamina
	    local ratio=CurrentStamina.Value/MaxStamina.Value
	    if ratio>=0.5 then
	        Staminatextlabel.TextColor3 = Color3.new(2-2*ratio,1,0)
	    else
	        Staminatextlabel.TextColor3 = Color3.new(1,ratio*2,0)
	    end
	    local staminastr=math.floor(CurrentStamina.Value).."/"..MaxStamina.Value
	    Staminatextlabel.Text=staminastr
	end
	UpdateStamina()
	playerentity.Stats.CurrentStamina:GetPropertyChangedSignal("Value"):Connect(UpdateStamina)

	--slot的显示
	local playerslotlist=playerentity.Inventory:GetChildren()
	-- 横向居中布局（只建一次）
	local layout = Instance.new("UIListLayout", slotRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)

	for slotidx, slotValue in ipairs(playerslotlist) do
	    -- 每个 slot 的圆形底
	    local slotCircle = Instance.new("ImageLabel", slotRow)
	    slotCircle.Size = UDim2.new(0.5, 0, 1, 0)
	    slotCircle.BackgroundTransparency = 1
	    slotCircle.Image = "rbxassetid://3570695787"
	    slotCircle.ImageColor3 = Color3.fromRGB(55, 55, 55)
		slotCircle.ScaleType = Enum.ScaleType.Fit

	    -- 物品图标
	    local icon = Instance.new("ImageLabel", slotCircle)
	    icon.Size = UDim2.new(1, 0, 1, 0)
	    icon.Position = UDim2.new(0, 0, 0, 0)
	    icon.BackgroundTransparency = 1
	    icon.Image = ""
	    icon.Visible = false
	    icon.ScaleType = Enum.ScaleType.Fit

	    local function updateSlotIcon()
	        local itemname = slotValue.Value
			print(playerlist[playeridx].Name .. " slot " .. slotidx .. " has " .. itemname)

	        slotCircle.ImageColor3 = Color3.fromRGB(55, 55, 55)
	        icon.Visible = false
	        icon.Image = ""

	        if itemname == "None" then
	            return
	        end

	        local itemscript = replicated.ItemModules:FindFirstChild(itemname)
	        if not itemscript then
	            return
	        end

	        local itemarray = require(itemscript)
	        local ItemIcon = itemarray.Icon
	        if ItemIcon and ItemIcon ~= "" then
	            icon.Image = ItemIcon
	            icon.Visible = true
	        end
	    end

	    updateSlotIcon()
	    slotValue:GetPropertyChangedSignal("Value"):Connect(updateSlotIcon)
	end
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
    local popup= screengui:FindFirstChild("PopUp")
    if popup ~= nil then
        print(popup.Name.." Founded")
        local list = popup:GetChildren()
	    for itemidx in list do
		    if hasProperty(list[itemidx],"Visible") then
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

local walkspeed=0
function disablelooprunspeed()
	updateEnabled = false
	if walkspeed ~= 0 and serversidesprint == false then
	    localcharacter.Humanoid.WalkSpeed = walkspeed
	end
	sprinting.Value = updateEnabled
	print("disablelooprunspeed:done")
end

--remove sprint event on client event
for i, connection in pairs(getconnections(sprintevent.OnClientEvent)) do
    print("disable sprintevent.OnClientEvent")
    connection:Disable()
end

sprintevent.OnClientEvent:Connect(function(arg1)
    print("sprintevent.OnClientEvent, server is false")
    serversidesprint=false
    walkspeed=localcharacter.Humanoid.WalkSpeed
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
		serversidesprint=true
		screengui.SprintIcon.Visible = false
		enablelooprunspeed()
		return
	end
	disablelooprunspeed()
	screengui.MobileRun.TextLabel.Text = "SPRINT: OFF"
	screengui.MobileRun.Image = "rbxassetid://11866517702"
	screengui.SprintIcon.Visible = false
	--[[
	if serversidesprint == false then
	    sprintevent:FireServer(true)
	    task.wait(0.05)
	end
	--]]
	sprintevent:FireServer(false)
	serversidesprint=false
end)

local isprocessed = false
userinputservice.InputBegan:Connect(function(inputobj, processevent)
    if processevent then
        return
    end
    if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then
        if isprocessed then
            return
        end
        enablelooprunspeed()
        serversidesprint=true
        isprocessed = true
        print("in r1 input begin, send server true")
    end
end)

userinputservice.InputEnded:Connect(function(inputobj, processevent)
    if processevent then
        return
    end
    if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then
        disablelooprunspeed()
        --[[
        if serversidesprint == false then
            task.wait(0.05)
            print("in r1 input end ,server is false, send true then false")
	        sprintevent:FireServer(true)
	        task.wait(0.05)
	    end
	    --]]
	    print("in r1 input end ,send false ")
	    sprintevent:FireServer(false)
	    serversidesprint=false
	    isprocessed=false
    end
end)

--auto skillcheck（hook remote function method）
--local TreadmillTapSkillCheck_upvr_2 = require(game.ReplicatedStorage.Modules.TreadmillTapSkillCheck)
--local CircleSkillCheckHandler_upvr = require(ReplicatedStorage_upvr.Modules.CircleSkillCheckHandler)
--local RF = game:GetService("ReplicatedStorage").Events.SkillcheckUpdate
--local cb = getcallbackvalue(RF, "OnClientInvoke");
local skillcheckupdate = replicated.Events:WaitForChild("SkillcheckUpdate")
local oriskillcheckupdate = nil
print("Fjone: try Hooking SkillcheckUpdate...")
local retry=5
while oriskillcheckupdate == nil and retry>0 do
    if getcallbackvalue ~= nil then
        oriskillcheckupdate = getcallbackvalue(skillcheckupdate, "OnClientInvoke")
    end
    task.wait(1)
    retry=retry-1
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

	--for normal and circle machine, it should be supercomplete
	--for treadmill tap, it should be true
	local arg2 = select(2, ...)
	print("arg2 typeof is "..typeof(arg2))
	if arg2 and typeof(arg2) == "table" then
	    if arg2.type == "treadmill" then
		    print("it is treadmill, return true")
		    return true
		elseif arg2.type == "circle" then
		    print("it is circle machine, return supercomplete")
		    return "supercomplete"
		else
		    print("arg2.type is "..arg2.type)
		    return true
		end
	else
		print("it is normal machine, return supercomplete")
		return "supercomplete"
	end
end
print("Fjone: Hooking SkillcheckUpdate Success...")

local function getsiblings(part)
    if part.Parent then
        return part.Parent:GetChildren()
    end
end

--open all the light
local function setLightRange(root, range)
    if not root then return end
    for _, inst in ipairs(root:GetDescendants()) do
        if inst:IsA("Light") then
            inst.Range = range
            for _, lightpart in ipairs(getsiblings(inst.Parent)) do
                if lightpart.Material == Enum.Material.Neon then
                    lightpart.Color = Color3.fromRGB(255, 255, 204)
                end
            end
        end
    end
end

local function OpenLight()
    if lighting.FogEnd == 250 then
        print("light back")
        return
    end
    task.wait(5)
    if roomentity ~= nil then
        lighting.FogEnd=250
        local roomlights=roomentity:WaitForChild("Lights")
        --open all the light
        setLightRange(roomlights, 45)
        print("set All Light to normal")
    end
end

lighting:GetPropertyChangedSignal("FogEnd"):Connect(OpenLight)


-- auto struggle from riddance club
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
