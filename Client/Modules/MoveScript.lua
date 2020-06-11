local Offset = UDim2.new(0.01, 0, 0.01, 0)

local Players = {
	Pacman = {
		CurrentTarget = nil,
		Movement = nil,
		Target = Vector2.new(5, 7),
		Direction = "Right",
		DesiredDir = "Right"
	},
	Blinky = {
		CurrentTarget = nil,
		Movement = nil,
		Target = Vector2.new(3, 3),
		Direction = "Left",
		DesiredDir = "Left"
	},
	Inky = {
		CurrentTarget = nil,
		Movement = nil,
		Target = Vector2.new(6, 3),
		Direction = "Right",
		DesiredDir = "Right"
	},
	Clyde = {
		CurrentTarget = nil,
		Movement = nil,
		Target = Vector2.new(3, 3),
		Direction = "Left",
		DesiredDir = "Left"
	},
	Pinky = {
		CurrentTarget = nil,
		Movement = nil,
		Target = Vector2.new(6, 3),
		Direction = "Right",
		DesiredDir = "Right"
	}
}

local Defaults = {
	Blinky = Vector2.new(3, 3),
	Inky = Vector2.new(6, 3),
	Clyde = Vector2.new(3, 3),
	Pinky = Vector2.new(6, 3),
	Pacman = Vector2.new(5, 7)
}

local Module = {}

local function GetNewTarget(TargetDir, Player, PlrInfo)
	local DirectionTargets = {
		Right = {nil, PlrInfo.Target.Y, PlrInfo.Target.X + 1, 10, 1},
		Left = {nil, PlrInfo.Target.Y, PlrInfo.Target.X - 1, -1, -1},
		Up = {PlrInfo.Target.X, nil, PlrInfo.Target.Y - 1, -1, -1},
		Down = {PlrInfo.Target.X, nil, PlrInfo.Target.Y + 1, 10, 1}
	}
	
	local X, Y, a, b, c = unpack(DirectionTargets[TargetDir])
	
	if X then
		for i = a, b, c do
			if PlrInfo.Movement[i][X] then
				if PlrInfo.Movement[PlrInfo.Target.Y][X][PlrInfo.DesiredDir] then
					PlrInfo.Direction = PlrInfo.DesiredDir
				end
				PlrInfo.Target = Vector2.new(X, i)
				break
			end
		end
	else
		for i = a, b, c do
			if PlrInfo.Movement[Y][i] then
				if PlrInfo.Movement[Y][PlrInfo.Target.X][PlrInfo.DesiredDir] then
					PlrInfo.Direction = PlrInfo.DesiredDir
				end
				PlrInfo.Target = Vector2.new(i, Y)
				break
			end
		end
	end
end

local function Move(NewPosition, Condition, Player, PlrInfo)
	if Condition then
		if PlrInfo.CurrentTarget[PlrInfo.Direction] or PlrInfo.CurrentTarget[PlrInfo.DesiredDir] then
			GetNewTarget(
				PlrInfo.CurrentTarget[PlrInfo.DesiredDir] and PlrInfo.DesiredDir or PlrInfo.Direction,
				Player,
				PlrInfo
			)
			Player.Position = NewPosition
		else
			Player.Position = PlrInfo.CurrentTarget.Position - Offset
		end
	else
		Player.Position = NewPosition
	end
end

function Module:Update(Player, Dir, DesDir, NewTarget)
	local PlrInfo = Players[Player.Name]
	PlrInfo.Direction = Dir
	PlrInfo.DesiredDir = DesDir
	PlrInfo.CurrentTarget = PlrInfo.Movement[PlrInfo.Target.Y][PlrInfo.Target.X]
	
	if NewTarget then
		PlrInfo.Target = NewTarget
	end
	
	if PlrInfo.Direction == "Right" then
		if Player.Position.X.Scale > 0.95 then
			Player.Position = UDim2.new(
				-0.1,
				0,
				Player.Position.Y.Scale,
				0
			)
			PlrInfo.Target = Vector2.new(2, 4)
			PlrInfo.CurrentTarget = PlrInfo.Movement[PlrInfo.Target.Y][PlrInfo.Target.X]
		end
		Move(
			UDim2.new(Player.Position.X.Scale + 0.013, 0, PlrInfo.CurrentTarget.Position.Y.Scale - Offset.Y.Scale, 0),
			Player.Position.X.Scale + 0.013 >= PlrInfo.CurrentTarget.Position.X.Scale - Offset.X.Scale,
			Player,
			PlrInfo
		)
	elseif PlrInfo.Direction == "Left" then
		if Player.Position.X.Scale < -0.05 then
			Player.Position = UDim2.new(
				1,
				0,
				Player.Position.Y.Scale,
				0
			)
			PlrInfo.Target = Vector2.new(7, 4)
			PlrInfo.CurrentTarget = PlrInfo.Movement[PlrInfo.Target.Y][PlrInfo.Target.X]
		end
		Move(
			UDim2.new(Player.Position.X.Scale - 0.013, 0, PlrInfo.CurrentTarget.Position.Y.Scale - Offset.Y.Scale, 0),
			Player.Position.X.Scale - 0.013 <= PlrInfo.CurrentTarget.Position.X.Scale + Offset.X.Scale,
			Player,
			PlrInfo
		)
		
	elseif PlrInfo.Direction == "Up" then
		Move(
			UDim2.new(PlrInfo.CurrentTarget.Position.X.Scale - Offset.X.Scale, 0, Player.Position.Y.Scale - 0.011, 0),
			Player.Position.Y.Scale - 0.011 <= PlrInfo.CurrentTarget.Position.Y.Scale + Offset.Y.Scale,
			Player,
			PlrInfo
		)	
	elseif PlrInfo.Direction == "Down" then
		Move(
			UDim2.new(PlrInfo.CurrentTarget.Position.X.Scale - Offset.X.Scale, 0, Player.Position.Y.Scale + 0.011, 0),
			Player.Position.Y.Scale + 0.011 >= PlrInfo.CurrentTarget.Position.Y.Scale - Offset.Y.Scale,
			Player,
			PlrInfo
		)
	end
	
	return PlrInfo.Direction, PlrInfo.Target
end

function Module:Reset()
	for i, v in pairs(Defaults) do
		Players[i].Target = v
	end
end

function Module:Setup(Mod, Player)
	Players[Player.Name].Movement = require(script.Parent[Mod])
end

return Module