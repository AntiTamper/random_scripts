while true do
	for _, v in ipairs(game:GetDescendants()) do
		if v.Name == "HelicoperCommand" then
			if v:IsA("RemoteEvent") then
				v:FireServer("JumpedOutOfSeat")
			elseif v:IsA("RemoteFunction") then
				pcall(function()
					v:InvokeServer("JumpedOutOfSeat")
				end)
			end
		end
	end
	task.wait(0.5)
end
