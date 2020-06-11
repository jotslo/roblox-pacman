--[[
	
	Please note:
	
	Allowing players to save their score directly with a remote event can be very dangerous,
	as any exploiter can fire this event with whatever values they wish, in order to trick
	your game.
	
	I am only storing information like this for the sake of simplicity, and due to the fact
	that their high score will only be visible to themselves and not shared with other users.
	
	Read these articles for more information on keeping your game secure:
	 - https://developer.roblox.com/articles/Game-Security
	 - https://developer.roblox.com/articles/Remote-Functions-and-Events
		
--]]

local DataStore = game:GetService("DataStoreService")

game.Players.PlayerAdded:Connect(function(Player)
	game.ReplicatedStorage.CurrentHighScore:FireClient(
		Player,
		DataStore:GetDataStore("player-" .. Player.UserId):GetAsync("HighScore")
	)
end)

game.ReplicatedStorage.SaveHighScore.OnServerEvent:Connect(function(Player, Score)
	if typeof(Score) == "number" then
		if Score % 10 == 0 then
			DataStore:GetDataStore("player-" .. Player.UserId):UpdateAsync("HighScore", function(OldScore)
				if OldScore then
					return Score > OldScore and Score or OldScore
				else
					return Score
				end
			end)
		end
	end
end)