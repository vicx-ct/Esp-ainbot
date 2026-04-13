local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local cam = workspace.CurrentCamera

local aimOn = false
local espOn = false
local lockedTarget = nil

-- GUI
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

-- BOTÕES
local function createBtn(text, posY)
	local b = Instance.new("TextButton", gui)
	b.Size = UDim2.new(0,150,0,50)
	b.Position = UDim2.new(0.5,-75,0.5,posY)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(150,0,0)
	b.TextScaled = true
	b.Active = true
	return b
end

local aimBtn = createBtn("AIMBOT OFF",-25)
local espBtn = createBtn("ESP OFF",40)

-- DRAG
local function dragify(btn)
	local dragging, startPos, startFramePos
	
	btn.InputBegan:Connect(function(input)
		if input.UserInputType.Name:find("Mouse") or input.UserInputType.Name:find("Touch") then
			dragging = true
			startPos = input.Position
			startFramePos = btn.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	UIS.InputChanged:Connect(function(input)
		if dragging then
			local delta = input.Position - startPos
			btn.Position = UDim2.new(
				startFramePos.X.Scale,
				startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale,
				startFramePos.Y.Offset + delta.Y
			)
		end
	end)
end

dragify(aimBtn)
dragify(espBtn)

-- CROSSHAIR + FOV
local dot = Instance.new("Frame", gui)
dot.Size = UDim2.new(0,8,0,8)
dot.BackgroundColor3 = Color3.fromRGB(255,0,0)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

local fov = Instance.new("Frame", gui)
fov.Size = UDim2.new(0,150,0,150)
fov.BackgroundTransparency = 1
local stroke = Instance.new("UIStroke", fov)
stroke.Thickness = 2
Instance.new("UICorner", fov).CornerRadius = UDim.new(1,0)

-- ESP
local visuals = {}

local function createESP(p)
	if p == player or visuals[p] then return end
	
	local box = Instance.new("Frame", gui)
	box.BackgroundTransparency = 1
	
	local s = Instance.new("UIStroke", box)
	s.Thickness = 2
	
	local name = Instance.new("TextLabel", box)
	name.Size = UDim2.new(1,0,0,14)
	name.Position = UDim2.new(0,0,0,-16)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	
	visuals[p] = {box=box,stroke=s,name=name}
end

local function getClosest()
	local closest, dist = nil, math.huge
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	
	for _,p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local root = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			
			if root and hum and hum.Health > 0 then
				local d = (myRoot.Position - root.Position).Magnitude
				if d < dist then
					dist = d
					closest = p
				end
			end
		end
	end
	
	return closest
end

-- LOOP
RunService.RenderStepped:Connect(function()
	local viewport = cam.ViewportSize
	
	-- CENTRALIZAÇÃO REAL
	dot.Position = UDim2.new(0,viewport.X/2-4,0,viewport.Y/2-4)
	fov.Position = UDim2.new(0,viewport.X/2-75,0,viewport.Y/2-75)
	
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	
	-- AIMBOT
	if aimOn then
		if not lockedTarget
		or not lockedTarget.Character
		or lockedTarget.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
			
			lockedTarget = getClosest()
		end
		
		if lockedTarget and lockedTarget.Character then
			local head = lockedTarget.Character:FindFirstChild("Head")
			if head then
				cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
				dot.BackgroundColor3 = Color3.fromRGB(0,255,0)
				stroke.Color = Color3.fromRGB(0,255,0)
			end
		end
	else
		lockedTarget = nil
		dot.BackgroundColor3 = Color3.fromRGB(255,0,0)
		stroke.Color = Color3.fromRGB(255,0,0)
	end
	
	-- ESP
	if espOn then
		for _,p in ipairs(Players:GetPlayers()) do
			createESP(p)
		end
		
		for p,v in pairs(visuals) do
			local char = p.Character
			if not char then v.box.Visible=false continue end
			
			local root = char:FindFirstChild("HumanoidRootPart")
			local head = char:FindFirstChild("Head")
			local hum = char:FindFirstChildOfClass("Humanoid")
			
			if not root or not head or not hum then
				v.box.Visible=false
				continue
			end
			
			local pos, onScreen = cam:WorldToViewportPoint(root.Position)
			
			if onScreen then
				local dist = (myRoot.Position - root.Position).Magnitude
				
				local color = dist <= 110 and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
				
				v.box.Position = UDim2.new(0,pos.X-25,0,pos.Y-50)
				v.box.Size = UDim2.new(0,50,0,100)
				v.box.Visible = true
				
				v.stroke.Color = color
				v.name.Text = p.Name.." | "..math.floor(dist)
				v.name.TextColor3 = color
			else
				v.box.Visible=false
			end
		end
	end
end)

-- BOTÕES
aimBtn.MouseButton1Click:Connect(function()
	aimOn = not aimOn
	aimBtn.Text = aimOn and "AIMBOT ON" or "AIMBOT OFF"
	aimBtn.BackgroundColor3 = aimOn and Color3.fromRGB(0,170,0) or Color3.fromRGB(150,0,0)
end)

espBtn.MouseButton1Click:Connect(function()
	espOn = not espOn
	espBtn.Text = espOn and "ESP ON" or "ESP OFF"
	espBtn.BackgroundColor3 = espOn and Color3.fromRGB(0,170,0) or Color3.fromRGB(150,0,0)
end)
