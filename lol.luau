local args = {
	[1] = "JumpedOutOfSeat"
}

while true do
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name == "HelicopterCommand" then
			v:FireServer(unpack(args))
		end
	end
	task.wait(0.5)
end
