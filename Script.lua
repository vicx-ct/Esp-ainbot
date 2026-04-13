local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local aimOn = false
local espOn = false

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))

-- BOTÕES
local aimBtn = Instance.new("TextButton", gui)
aimBtn.Size = UDim2.new(0,150,0,50)
aimBtn.Position = UDim2.new(0.5,-75,0.5,-25)
aimBtn.Text = "AIMBOT OFF"
aimBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
aimBtn.TextScaled = true
aimBtn.Active = true

local espBtn = Instance.new("TextButton", gui)
espBtn.Size = UDim2.new(0,150,0,50)
espBtn.Position = UDim2.new(0.5,-75,0.5,40)
espBtn.Text = "ESP OFF"
espBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
espBtn.TextScaled = true
espBtn.Active = true

-- DRAG
local function dragify(btn)
	local dragging, dragInput, startPos, startFramePos
	
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
	
	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
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

-- CROSSHAIR
local cam = workspace.CurrentCamera

local dot = Instance.new("Frame", gui)
dot.Size = UDim2.new(0,8,0,8)
dot.Position = UDim2.new(0.5,-4,0.5,-4)
dot.BackgroundColor3 = Color3.fromRGB(255,0,0)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

local fov = Instance.new("Frame", gui)
fov.Size = UDim2.new(0,150,0,150)
fov.Position = UDim2.new(0.5,-75,0.5,-75)
fov.BackgroundTransparency = 1

local fovStroke = Instance.new("UIStroke", fov)
fovStroke.Thickness = 2
Instance.new("UICorner", fov).CornerRadius = UDim.new(1,0)

-- ESP STORAGE
local visuals = {}

local function createESP(p)
	if p == player or visuals[p] then return end
	
	local box = Instance.new("Frame", gui)
	box.BackgroundTransparency = 1
	
	local stroke = Instance.new("UIStroke", box)
	stroke.Thickness = 2
	
	local hp = Instance.new("Frame", box)
	hp.Size = UDim2.new(0,4,1,0)
	hp.Position = UDim2.new(0,-6,0,0)
	
	local name = Instance.new("TextLabel", box)
	name.Size = UDim2.new(1,0,0,14)
	name.Position = UDim2.new(0,0,0,-16)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	
	visuals[p] = {
		box = box,
		stroke = stroke,
		hp = hp,
		name = name,
		lastPos = Vector2.new(0,0)
	}
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		if espOn then
			task.wait(0.5)
			createESP(p)
		end
	end)
end)

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
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	
	local t = tick()
	local pulse = math.sin(t*3)*2
	dot.Size = UDim2.new(0,8+pulse,0,8+pulse)
	
	-- AIMBOT
	if aimOn then
		local target = getClosest()
		
		if target and target.Character then
			local root = target.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local pos, onScreen = cam:WorldToViewportPoint(root.Position)
				if onScreen then
					dot.Position = UDim2.new(0,pos.X-4,0,pos.Y-4)
					
					local targetCF = CFrame.new(cam.CFrame.Position, root.Position)
					cam.CFrame = cam.CFrame:Lerp(targetCF, 0.15)
					
					dot.BackgroundColor3 = Color3.fromRGB(0,255,0)
					fovStroke.Color = Color3.fromRGB(0,255,0)
				end
			end
		end
	else
		dot.Position = UDim2.new(0.5,-4,0.5,-4)
		dot.BackgroundColor3 = Color3.fromRGB(255,0,0)
		fovStroke.Color = Color3.fromRGB(255,0,0)
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
				v.box.Visible = false
				continue
			end
			
			local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
			local headPos = cam:WorldToViewportPoint(head.Position)
			
			if onScreen then
				local dist = (myRoot.Position - root.Position).Magnitude
				
				-- COR POR DISTÂNCIA
				local color
				if dist <= 110 then
					color = Color3.fromRGB(0,255,0)
				else
					color = Color3.fromRGB(255,0,0)
				end
				
				local height = math.abs(headPos.Y - rootPos.Y) * 2
				local width = height / 2
				
				local targetPos = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
				v.lastPos = v.lastPos:Lerp(targetPos, 0.2)
				
				v.box.Position = UDim2.new(0,v.lastPos.X,0,v.lastPos.Y)
				v.box.Size = UDim2.new(0,width,0,height)
				v.box.Visible = true
				
				v.stroke.Color = color
				
				local hpPercent = hum.Health / hum.MaxHealth
				v.hp.Size = UDim2.new(0,4,hpPercent,0)
				v.hp.Position = UDim2.new(0,-6,1-hpPercent,0)
				v.hp.BackgroundColor3 = Color3.fromRGB(0,255,0)
				
				v.name.Text = p.Name.." | "..math.floor(dist)
				v.name.TextColor3 = color
				
				-- OTIMIZAÇÃO
				if dist > 500 then
					v.box.Visible = false
				end
			else
				v.box.Visible = false
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
