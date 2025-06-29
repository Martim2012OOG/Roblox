local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local AimbotEnabled = false
local AimParts = {"Head", "UpperTorso", "Down"}
local AimPartIndex = 1
local ProjectileSpeed = 500
local Smoothness = 0.15
local MaxFOV = math.rad(35)

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SmoothPredictiveAimbot"

local frame = Instance.new("Frame", gui)
frame.Position = UDim2.new(0, 20, 0, 180)
frame.Size = UDim2.new(0, 180, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0.3, 0)
title.BackgroundTransparency = 1
title.Text = "SMOOTH AIMBOT"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Position = UDim2.new(0.1, 0, 0.35, 0)
toggleButton.Size = UDim2.new(0.8, 0, 0.25, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "AIMBOT: OFF"

toggleButton.MouseButton1Click:Connect(function()
	AimbotEnabled = not AimbotEnabled
	toggleButton.Text = AimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF"
end)

local partButton = Instance.new("TextButton", frame)
partButton.Position = UDim2.new(0.1, 0, 0.65, 0)
partButton.Size = UDim2.new(0.8, 0, 0.25, 0)
partButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
partButton.TextColor3 = Color3.new(1, 1, 1)
partButton.Font = Enum.Font.SourceSansBold
partButton.TextSize = 16
partButton.Text = "TARGET: HEAD"

partButton.MouseButton1Click:Connect(function()
	AimPartIndex = AimPartIndex + 1
	if AimPartIndex > #AimParts then
		AimPartIndex = 1
	end
	partButton.Text = "TARGET: " .. string.upper(AimParts[AimPartIndex])
end)

-- Detectar time corretamente
local function isEnemy(player)
	if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
		return false
	end
	if player.TeamColor and LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor then
		return false
	end
	local myTeam = LocalPlayer:GetAttribute("Team") or (LocalPlayer:FindFirstChild("Team") and LocalPlayer.Team.Value)
	local otherTeam = player:GetAttribute("Team") or (player:FindFirstChild("Team") and player.Team.Value)
	if myTeam and otherTeam and myTeam == otherTeam then
		return false
	end
	return true
end

-- Prever posição futura
local function getPredictedPosition(part, humanoid)
	local distance = (part.Position - Camera.CFrame.Position).Magnitude
	local travelTime = distance / ProjectileSpeed
	return part.Position + (humanoid.MoveDirection * humanoid.WalkSpeed * travelTime)
end

-- Obter ponto alvo baseado no AimPart selecionado e offsets atualizados
local function getAimPosition(character)
	local partName = AimParts[AimPartIndex]
	
	if partName == "Down" then
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if torso then
			return torso.Position - Vector3.new(0, 2.5, 0) -- 2.5 studs para baixo (2x e meia)
		end
	elseif partName == "UpperTorso" then
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if torso then
			return torso.Position - Vector3.new(0, 0.5, 0) -- meio stud para baixo
		end
	elseif partName == "Head" then
		local head = character:FindFirstChild("Head")
		if head then
			return head.Position
		end
	end
	return nil
end

-- Obter inimigo mais próximo dentro do FOV
local function getClosestEnemy()
	local closest = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and isEnemy(player) then
			local char = player.Character
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local aimPos = getAimPosition(char)
				if aimPos then
					local predicted = getPredictedPosition({Position = aimPos}, humanoid)
					local dirToTarget = (predicted - Camera.CFrame.Position).Unit
					local angle = math.acos(Camera.CFrame.LookVector:Dot(dirToTarget))

					if angle < MaxFOV then
						local distance = (Camera.CFrame.Position - aimPos).Magnitude
						if distance < shortestDistance then
							shortestDistance = distance
							closest = predicted
						end
					end
				end
			end
		end
	end

	return closest
end

-- Movimento suave da câmera
RunService.RenderStepped:Connect(function()
	if AimbotEnabled then
		local target = getClosestEnemy()
		if target then
			local current = Camera.CFrame.Position
			local desiredLook = (target - current).Unit
			local currentLook = Camera.CFrame.LookVector
			local smoothedLook = currentLook:Lerp(desiredLook, Smoothness)
			Camera.CFrame = CFrame.new(current, current + smoothedLook)
		end
	end
end)
