local Inky = {}

local Source = script.Parent

local Ghost = Source.Parent.Map.MapData.Inky
local Movement = require(Source.GhostMovement)
local MoveScript = require(Source.MoveScript)

local Running = false
local Target = Vector2.new(3, 3)
local OverallTarget = Vector2.new(9, 9)
local Offset = UDim2.new(0.01, 0, 0.01, 0)
local CurrentTarget

local IterationCount = 0
local TimeInMode = 0
local AnimOffset = 12

local Mode = "Scatter"
local Direction = "Left"
local MostRecentDir = "Left"
local DesiredDir = "Down"

local DirSpriteMap = {
	Up = 288,
	Down = 432,
	Right = 0,
	Left = 144
}
local MoveDirections = {
	Up = Vector2.new(0, -1),
	Down = Vector2.new(0, 1),
	Right = Vector2.new(1, 0),
	Left = Vector2.new(-1, 0)
}
local OppositeDirs = {
	Up = "Down",
	Down = "Up",
	Right = "Left",
	Left = "Right"
}

local CheckOrder = {"Down", "Up", "Right", "Left"}

local function Animation()
	IterationCount = IterationCount + 1
	if IterationCount == 3 then
		IterationCount = 0
		if Mode == "Frightened" then
			AnimOffset = AnimOffset == 660 and 588 or 660
			Ghost.ImageRectOffset = Vector2.new(
				AnimOffset,
				288
			)
		else
			AnimOffset = AnimOffset == 12 and 84 or 12
			Ghost.ImageRectOffset = Vector2.new(
				AnimOffset + DirSpriteMap[Direction],
				432
			)
		end
	end
end

local function ChangeMode()
	TimeInMode = TimeInMode + 1
	if TimeInMode == 175 and (Mode == "Scatter" or Mode == "Frightened") then
		Mode = "Chase"
		TimeInMode = 0
		OverallTarget = Source.GetPacmanTarget:Invoke()
	elseif TimeInMode == 500 then
		Mode = "Scatter"
		TimeInMode = 0
		OverallTarget = Vector2.new(9, 9)
	elseif TimeInMode > 500 then
		Mode = "Chase"
		TimeInMode = 0
	end
end

local function GetRandomDir(CurrentTarget)
	local Choices = {}
	for i, _ in pairs(DirSpriteMap) do
		if CurrentTarget[i] then
			Choices[#Choices + 1] = i
		end
	end
	return Choices[math.random(#Choices)]
end

local function Pathfind()
	if DesiredDir == Direction then
		if Mode == "Chase" then
			OverallTarget = Source.GetPacmanTarget:Invoke()
		end
		
		local BestDirection = {"Right", math.huge}
		local CurrentTarget = Movement[Target.Y][Target.X]
		
		for _, i in pairs(CheckOrder) do
			if CurrentTarget[i] and OppositeDirs[i] ~= Direction then
				local NewTarget = Target + MoveDirections[i]
				local Distance = math.abs(NewTarget.X - OverallTarget.X) + math.abs(NewTarget.Y - OverallTarget.Y)
				if Distance < BestDirection[2] then
					BestDirection = {i, Distance}
				end
			end
		end
		
		DesiredDir = Mode == "Frightened" and GetRandomDir(CurrentTarget) or BestDirection[1]
	end
end

function Inky:Run()
	Running = true
	MoveScript:Setup("GhostMovement", Ghost)
	coroutine.wrap(function()
		Animation()
		wait(3)
		Ghost:TweenPosition(
			UDim2.new(0.467, 0, 0.342, 0),
			"Out",
			"Linear"
		)
		wait(1)
		MoveScript:Update(Ghost, "Right", "Right", Vector2.new(3, 3))
		while Running do
			wait(0.04)
			local NewDir
			NewDir, Target = MoveScript:Update(Ghost, Direction, DesiredDir)
			if NewDir ~= Direction then
				MostRecentDir = Direction
				Direction = NewDir
			end
			Animation()
			ChangeMode()
			Pathfind()
		end
	end)()
end

function Inky:Reset(CanContinue)
	Running = false
	coroutine.wrap(function()
		wait(1)
		Ghost.Position = UDim2.new(0.393, 0, 0.427, 0)
		Direction = "Left"
		MostRecentDir = "Left"
		DesiredDir = "Down"
		Target = Vector2.new(3, 3)
		OverallTarget = Vector2.new(9, 9)
		Mode = "Scatter"
		TimeInMode = 0
		if CanContinue then
			Mode = "Scatter"
			Running = true
			Inky:Run()
		end
	end)()
end

function Inky:Frightened()
	coroutine.wrap(function()
		Mode = "Frightened"
		Direction = OppositeDirs[Direction]
		DesiredDir = OppositeDirs[Direction]
		TimeInMode = 0
	end)()
end

return Inky