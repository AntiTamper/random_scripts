do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local enabled1 = false
	local enabled2 = false
	local cached = {}
	local cannonToGroup = {}
	local gui, frame, button1, button2

	local SelfTeamOnly = false

	local shipList = { "OrangeShip", "GreenShip" }

	local cannonGroups = {
		C1 = {
			guns = {
				["SmallCannon"] = false,
				["BigCannon"] = false,
				["Flat Cannon"] = false,
				["MainCannon2"] = false,
				["Mortar2"] = true,
				["MountedRocket"] = true
			},
			remotes = {
				FireCannon = { args = { "7782023531" } }
			}
		},
		C2 = {
			guns = {
				["Turret"] = true,
				["Double Turret"] = true,
				["SmallTurret"] = true,
				["Single Deck Cannon"] = true,
				["Double Deck Cannon"] = true
			},
			remotes = {
				FireCannon = { args = { "true" } },
				MoveCannon = { args = "RANDOM3" }
			}
		}
	}

	local function a()
		local set = {}

		if not SelfTeamOnly then
			for _, n in ipairs(shipList) do
				set[n] = true
			end
			return set
		end

		local teamName = (player.Team and player.Team.Name) or ""
		if teamName == "Orange Team" then
			set["OrangeShip"] = true
		elseif teamName == "Green Team" then
			set["GreenShip"] = true
		elseif teamName == "Spectators" then
			set["OrangeShip"] = true
			set["GreenShip"] = true
		else
			for _, n in ipairs(shipList) do
				set[n] = true
			end
		end

		return set
	end

	local function b()
		local map = {}
		for groupKey, group in pairs(cannonGroups) do
			for cannonName, isOn in pairs(group.guns) do
				if isOn then
					map[cannonName] = groupKey
				end
			end
		end
		cannonToGroup = map
	end

	local function c(v)
		if typeof(v) ~= "string" then
			return v
		end
		local s = string.lower(v)
		if s == "true" then
			return true
		end
		if s == "false" then
			return false
		end
		local n = tonumber(v)
		if n ~= nil then
			return n
		end
		return v
	end

	local function d(n)
		return math.floor(n * 1e6 + (n >= 0 and 0.5 or -0.5)) / 1e6
	end

	local function e()
		local base = (math.random(0, 1) == 0) and -1 or 1
		local offset = (math.random() * 2) - 1
		return d(base + offset)
	end

	local function f()
		return { e(), e(), e() }
	end

	local function g(inst, remoteName)
		if not inst or not inst:IsDescendantOf(workspace) then
			return nil
		end
		local direct = inst:FindFirstChild(remoteName)
		if direct and direct:IsA("RemoteEvent") then
			return direct
		end
		local deep = inst:FindFirstChild(remoteName, true)
		if deep and deep:IsA("RemoteEvent") then
			return deep
		end
		return nil
	end

	local function h()
		local list = {}
		local seen = {}
		local shipSet = a()

		for _, inst in ipairs(workspace:GetDescendants()) do
			local groupKey = cannonToGroup[inst.Name]
			if groupKey then
				local p = inst.Parent
				local ok = false
				while p and p ~= workspace do
					if shipSet[p.Name] then
						ok = true
						break
					end
					p = p.Parent
				end
				if ok then
					local group = cannonGroups[groupKey]
					local fire = group and group.remotes and group.remotes.FireCannon and g(inst, "FireCannon") or nil
					local move = (groupKey == "C2" and group and group.remotes and group.remotes.MoveCannon) and g(inst, "MoveCannon") or nil

					if fire or move then
						local key = (fire or move)
						if not seen[key] then
							seen[key] = true
							list[#list + 1] = { group = groupKey, fire = fire, move = move }
						end
					end
				end
			end
		end

		cached = list
	end

	local function i()
		local alive = {}
		for _, item in ipairs(cached) do
			local keep = false
			if item.fire and item.fire.Parent and item.fire:IsDescendantOf(workspace) then
				keep = true
			end
			if item.move and item.move.Parent and item.move:IsDescendantOf(workspace) then
				keep = true
			end
			if keep then
				alive[#alive + 1] = item
			end
		end
		cached = alive
		if #cached == 0 then
			h()
		end
	end

	local function j()
		i()

		if enabled1 then
			for _, item in ipairs(cached) do
				local group = cannonGroups[item.group]
				local spec = group and group.remotes and group.remotes.FireCannon
				local r = item.fire
				if r and spec and spec.args then
					local args = {}
					for idx, v in ipairs(spec.args) do
						args[idx] = c(v)
					end
					pcall(function()
						r:FireServer(unpack(args))
					end)
				end
			end
		end

		if enabled2 then
			for _, item in ipairs(cached) do
				if item.group == "C2" then
					local group = cannonGroups.C2
					local spec = group and group.remotes and group.remotes.MoveCannon
					local r = item.move
					if r and spec then
						local args = f()
						pcall(function()
							r:FireServer(unpack(args))
						end)
					end
				end
			end
		end
	end

	local function k(v1, v2)
		if v1 ~= nil then enabled1 = v1 end
		if v2 ~= nil then enabled2 = v2 end
		if button1 then button1.Text = enabled1 and "test1: ON" or "test1: OFF" end
		if button2 then button2.Text = enabled2 and "test2: ON" or "test2: OFF" end
	end

	local function l()
		gui = Instance.new("ScreenGui")
		gui.Name = "test"
		gui.ResetOnSpawn = false
		gui.Parent = playerGui

		frame = Instance.new("Frame")
		frame.Name = "test"
		frame.Size = UDim2.fromOffset(150, 78)
		frame.Position = UDim2.new(0.06, 0, 0.55, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.5
		frame.Parent = gui

		local frameCorner = Instance.new("UICorner")
		frameCorner.Name = "test"
		frameCorner.CornerRadius = UDim.new(0, 12)
		frameCorner.Parent = frame

		local layout = Instance.new("UIListLayout")
		layout.Name = "test"
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 6)
		layout.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.Name = "test"
		pad.PaddingTop = UDim.new(0, 8)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = frame

		button1 = Instance.new("TextButton")
		button1.Name = "test"
		button1.Size = UDim2.new(1, 0, 0, 28)
		button1.BackgroundColor3 = Color3.new(0, 0, 0)
		button1.BackgroundTransparency = 0.35
		button1.TextColor3 = Color3.new(1, 1, 1)
		button1.TextScaled = true
		button1.Text = "test1: OFF"
		button1.Parent = frame

		local c1 = Instance.new("UICorner")
		c1.Name = "test"
		c1.CornerRadius = UDim.new(0, 10)
		c1.Parent = button1

		button2 = Instance.new("TextButton")
		button2.Name = "test"
		button2.Size = UDim2.new(1, 0, 0, 28)
		button2.BackgroundColor3 = Color3.new(0, 0, 0)
		button2.BackgroundTransparency = 0.35
		button2.TextColor3 = Color3.new(1, 1, 1)
		button2.TextScaled = true
		button2.Text = "test2: OFF"
		button2.Parent = frame

		local c2 = Instance.new("UICorner")
		c2.Name = "test"
		c2.CornerRadius = UDim.new(0, 10)
		c2.Parent = button2
	end

	local function m()
		button1.Activated:Connect(function()
			k(not enabled1, nil)
		end)

		button2.Activated:Connect(function()
			k(nil, not enabled2)
		end)

		local dragging = false
		local dragStart
		local startPos

		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
			end
		end)

		frame.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end)
	end

	local function n()
		task.spawn(function()
			while true do
				if enabled1 or enabled2 then
					j()
				end
				task.wait(0.05)
			end
		end)
	end

	local function o()
		math.randomseed(os.clock() * 1e6)

		b()
		l()
		m()
		h()
		k(false, false)
		n()

		player:GetPropertyChangedSignal("Team"):Connect(function()
			if SelfTeamOnly then
				cached = {}
			end
		end)
	end

	o()
end
