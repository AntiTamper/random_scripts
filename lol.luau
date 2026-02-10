while true do
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name == "HelicopterCommand" then
			v:FireServer({[1] = "JumpedOutOfSeat"})
		end
	end
	task.wait(0.5)
end
