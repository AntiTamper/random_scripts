
do

	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")


	local enabled1, enabled2, enabled3 = false, false, false
	local cached = {}
	local cannonToGroup = {}


	local gui, frame, button1, button2, button3


	local SelfTeamOnly = false
	local shipList = { "OrangeShip", "GreenShip" }


	local delays = {
		C1 = "0.1",
		C2 = "0",
		C2Move = "5",
		Log = "1"
	}


	local cannonGroups = {
		C1 = {
			guns = {
				["SmallCannon"] = true,
				["BigCannon"] = true,
				["Flat Cannon"] = true,
				["MainCannon2"] = true,
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
				["Single  Deck Cannon"] = true,
				["Double Deck Cannon"] = true
			},
			remotes = {
				FireCannon = { args = { "true" } }
			}
		}
	}


	local lastScan = 0
	local scanEvery = 2

	local function c(v)
		if typeof(v) ~= "string" then
			return v
		end
		local s = string.lower(v)
		if s == "true" then return true end
		if s == "false" then return false end
		local n = tonumber(v)
		if n ~= nil then return n end
		return v
	end


	local function round(n)
		return math.floor(n * 1e9 + (n >= 0 and 0.5 or -0.5)) / 1e9
	end

	local function rand(minv, maxv)
		return round(minv + (math.random() * (maxv - minv)))
	end

	-- drunk teleporting, LookVector-biased
	local function drunkVector(look)
		local drunk = Vector3.new(
			rand(-3, 3),
			rand(-1, 1),
			rand(-3, 3)
		)
		local dir = look + drunk
		if dir.Magnitude > 0 then
			dir = dir.Unit
		end
		return { dir.X, dir.Y, dir.Z }
	end


	local function getShipSet()
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

	local function rebuildCannonMap()
		local map = {}
		for groupKey, group in pairs(cannonGroups) do
			for cannonName, on in pairs(group.guns) do
				if on then
					map[cannonName] = groupKey
				end
			end
		end
		cannonToGroup = map
	end


	local function findRemote(inst, remoteName)
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

	local function scanCannons()
		local list = {}
		local shipSet = getShipSet()

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
					local fire = findRemote(inst, "FireCannon")
					local move = (groupKey == "C2") and findRemote(inst, "MoveCannon") or nil
					if fire or move then
						list[#list + 1] = {
							group = groupKey,
							fire = fire,
							move = move
						}
					end
				end
			end
		end

		cached = list
		lastScan = os.clock()
	end

	local function refreshCache()
		local alive = {}
		for _, item in ipairs(cached) do
			if (item.fire and item.fire:IsDescendantOf(workspace))
			or (item.move and item.move:IsDescendantOf(workspace)) then
				alive[#alive + 1] = item
			end
		end
		cached = alive

		if #cached == 0 or (os.clock() - lastScan) >= scanEvery then
			scanCannons()
		end
	end

	local function getItems()
		refreshCache()
		return cached
	end

	local function fireC1()
		local spec = cannonGroups.C1.remotes.FireCannon
		local args = {}
		for i, v in ipairs(spec.args) do
			args[i] = c(v)
		end

		for _, item in ipairs(getItems()) do
			if item.group == "C1" and item.fire then
				pcall(function()
					item.fire:FireServer(unpack(args))
				end)
			end
		end
	end

	local function fireC2()
		local spec = cannonGroups.C2.remotes.FireCannon
		local args = {}
		for i, v in ipairs(spec.args) do
			args[i] = c(v)
		end

		for _, item in ipairs(getItems()) do
			if item.group == "C2" and item.fire then
				pcall(function()
					item.fire:FireServer(unpack(args))
				end)
			end
		end
	end

	local function moveC2()
		for _, item in ipairs(getItems()) do
			if item.group == "C2" and item.move then
				local cannon = item.move.Parent
				if cannon and cannon:IsA("BasePart") then
					local args = drunkVector(cannon.CFrame.LookVector)
					pcall(function()
						item.move:FireServer(unpack(args))
					end)
				end
			end
		end
	end


	local function logStopControls()
		local shipSet = getShipSet()

		for shipName in pairs(shipSet) do
			local ship = workspace:FindFirstChild(shipName)
			if not ship or not ship:IsDescendantOf(workspace) then
				continue
			end

			local pieces = ship:FindFirstChild("Pieces")
			if not pieces then
				continue
			end

			local stop = pieces:FindFirstChild("StopControl")
			if not stop then
				continue
			end

			local cd = stop:FindFirstChildOfClass("ClickDetector")
			if not cd then
				continue
			end

			pcall(function()
				log(cd)
			end)
		end
	end


	local function updateButtons()
		if button1 then button1.Text = enabled1 and "test1: ON" or "test1: OFF" end
		if button2 then button2.Text = enabled2 and "test2: ON" or "test2: OFF" end
		if button3 then button3.Text = enabled3 and "test3: ON" or "test3: OFF" end
	end

	local function buildUI()
		gui = Instance.new("ScreenGui")
		gui.ResetOnSpawn = false
		gui.Parent = playerGui

		frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(140, 108)
		frame.Position = UDim2.new(0.06, 0, 0.55, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.5
		frame.Parent = gui
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

		local layout = Instance.new("UIListLayout", frame)
		layout.Padding = UDim.new(0, 6)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center

		local pad = Instance.new("UIPadding", frame)
		pad.PaddingTop = UDim.new(0, 7)
		pad.PaddingBottom = UDim.new(0, 7)
		pad.PaddingLeft = UDim.new(0, 7)
		pad.PaddingRight = UDim.new(0, 7)

		local function makeButton(text)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 26)
			b.BackgroundColor3 = Color3.new(0, 0, 0)
			b.BackgroundTransparency = 0.35
			b.TextColor3 = Color3.new(1, 1, 1)
			b.TextScaled = true
			b.Text = text
			b.Parent = frame
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
			return b
		end

		button1 = makeButton("test1: OFF")
		button2 = makeButton("test2: OFF")
		button3 = makeButton("test3: OFF")
	end

	local function wireUI()
		button1.Activated:Connect(function()
			enabled1 = not enabled1
			updateButtons()
		end)

		button2.Activated:Connect(function()
			enabled2 = not enabled2
			updateButtons()
		end)

		button3.Activated:Connect(function()
			enabled3 = not enabled3
			updateButtons()
		end)


		local dragging, dragStart, startPos = false, nil, nil

		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
			end
		end)

		frame.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end)
	end


	local function startLoops()
		task.spawn(function()
			while true do
				if enabled1 then fireC1() end
				task.wait(delays.C1)
			end
		end)

		task.spawn(function()
			while true do
				if enabled1 then fireC2() end
				task.wait(delays.C2)
			end
		end)

		task.spawn(function()
			while true do
				if enabled2 then moveC2() end
				task.wait(delays.C2Move)
			end
		end)

		task.spawn(function()
			while true do
				if enabled3 then logStopControls() end
				task.wait(delays.Log)
			end
		end)
	end

	local function init()
		math.randomseed(os.clock() * 1e6)

		for k, v in pairs(delays) do
			delays[k] = c(v)
		end

		rebuildCannonMap()
		buildUI()
		wireUI()
		scanCannons()
		updateButtons()
		startLoops()
	end

	init()
end
