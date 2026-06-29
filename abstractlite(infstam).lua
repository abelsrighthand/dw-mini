local plrsrv = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")
local userinputservice = game:GetService("UserInputService")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local screengui = plrgui:FindFirstChild("ScreenGui")

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
end

local walkspeed = 0
function disablelooprunspeed()
	updateEnabled = false
	if walkspeed ~= 0 and serversidesprint == false then
		localcharacter.Humanoid.WalkSpeed = walkspeed
	end
	sprinting.Value = updateEnabled
end

-- Kill sprint when client event yes
for i, connection in pairs(getconnections(sprintevent.OnClientEvent)) do
	connection:Disable()
end

sprintevent.OnClientEvent:Connect(function(arg1)
	serversidesprint = false
	walkspeed = localcharacter.Humanoid.WalkSpeed
	enablelooprunspeed()
end)

for i, connection in pairs(getconnections(screengui.MobileRun.Activated)) do
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

	end
end)

userinputservice.InputEnded:Connect(function(inputobj, processevent)
	if processevent then return end
	if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then
		disablelooprunspeed()
		sprintevent:FireServer(false)
		serversidesprint = false
		isprocessed = false
	end
end)

-- PC support methinks?
userinputservice.InputBegan:Connect(function(inputobj, processevent)
	if processevent then return end
	if inputobj.KeyCode == Enum.KeyCode.LeftShift then
		enablelooprunspeed()
		serversidesprint = true
		sprintevent:FireServer(true)
	end
end)

userinputservice.InputEnded:Connect(function(inputobj, processevent)
	if processevent then return end
	if inputobj.KeyCode == Enum.KeyCode.LeftShift then
		disablelooprunspeed()
		sprintevent:FireServer(false)
		serversidesprint = false
	end
end)
