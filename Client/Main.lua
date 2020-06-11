math.randomseed(tick())

local Movement = require(script.Movement)
local MoveScript = require(script.MoveScript)
local UserInputService = game:GetService("UserInputService")

local MapImage = script.Parent.Map
local Sounds = script.Sounds
local Score = MapImage.Score
local HighScore = MapImage.HighScore
local MapData = MapImage.MapData
local Pacman = MapData.Pacman
local PacmanCol = Pacman.Hitbox
local PacDots = MapData.PacDots
local Pellets = MapData.Pellets
local OneUp = MapImage["1UPLabel"]

local IterationCount = 0
local AnimCount = 0
local Lives = 3
local FrightenedValue = 0
local Playing = false
local CanStart = true
local NewGame = true
local Frightened = false

local Direction = "Right"
local DesiredDir = "Right"
local Target = Vector2.new(5, 7)
local LastTarget = Vector2.new(5, 7)
local Offset = UDim2.new(0.01, 0, 0.01, 0)
local CurrentTarget

local DirSpriteMap = {
	Right = 0,
	Left = 72,
	Up = 144,
	Down = 216
}
local OppositeDirs = {
	Right = "Left",
	Left = "Right",
	Up = "Down",
	Down = "Up"
}
local GhostBoxes = {
	Blinky = MapData.Blinky.Hitbox,
	Inky = MapData.Inky.Hitbox,
	Clyde = MapData.Clyde.Hitbox,
	Pinky = MapData.Pinky.Hitbox
}
local Ghosts = {
	Blinky = MapData.Blinky,
	Inky = MapData.Inky,
	Clyde = MapData.Clyde,
	Pinky = MapData.Pinky
}
local ModuleReferences = {
	Blinky = require(script.Blinky),
	Inky = require(script.Inky),
	Clyde = require(script.Clyde),
	Pinky = require(script.Pinky)
}

local PelletStates = {}

UserInputService.TouchSwipe:Connect(function(Swipe)
	DesiredDir = Swipe.Name
	local CurrentTarget = Movement[Target.Y][Target.X]
	if OppositeDirs[DesiredDir] == Direction then
		Direction = DesiredDir
	elseif CurrentTarget[Swipe.Name] and Pacman.Position == CurrentTarget.Position - Offset then
		Direction = DesiredDir
	end
end)

UserInputService.InputBegan:Connect(function(InputObject)
	local CurrentTarget = Movement[Target.Y][Target.X]
	for Dir, _ in pairs(DirSpriteMap) do
		if InputObject.KeyCode == Enum.KeyCode[Dir] then
			DesiredDir = Dir
			if OppositeDirs[DesiredDir] == Direction then
				Direction = DesiredDir
			elseif CurrentTarget[Dir] and Pacman.Position == CurrentTarget.Position - Offset then
				Direction = DesiredDir
			end
		end
	end
end)

game.ReplicatedStorage.CurrentHighScore.OnClientEvent:Connect(function(CurrentHighScore)
	if CurrentHighScore then
		HighScore.Text = CurrentHighScore
	end
end)

script.GetPacmanTarget.OnInvoke = function()
	return Target
end

script.GetPacmanPos.OnInvoke = function()
	return LastTarget
end

local function UpdateScoreDisplay(Amount)
	Score.Text = Score.Text + Amount
	if tonumber(Score.Text) > tonumber(HighScore.Text) then
		HighScore.Text = Score.Text
	end
end

local function Flicker()
	IterationCount = IterationCount + 1
	if IterationCount % 3 == 0 then
		for i, v in pairs(Pellets:GetChildren()) do
			if PelletStates[v] then
				v.Visible = not v.Visible
			end
		end
		if IterationCount == 6 then
			IterationCount = 0
			OneUp.Visible = not OneUp.Visible
		end
	end
end

local function Died()
	for i, v in pairs(Ghosts) do
		v.Visible = false
	end
	MoveScript:Reset()
	Sounds.Death:Play()
	for i = 1, 10 do
		Pacman.ImageRectOffset = Vector2.new(12 + (i + 3) * 72, i)
		wait(0.12)
	end
	Pacman.Visible = false
	Pacman.ImageRectOffset = Vector2.new(156, 0)
	if Lives == 0 then
		wait(1)
		MapImage.GameOverLabel.Visible = true
		CanStart = false
		game.ReplicatedStorage.SaveHighScore:FireServer(tonumber(HighScore.Text))
	end
end

local function IsColliding(Obj1, Obj2)
	return (Obj1.AbsolutePosition.X < Obj2.AbsolutePosition.X + Obj2.AbsoluteSize.X and
			Obj1.AbsolutePosition.X + Obj1.AbsoluteSize.X > Obj2.AbsolutePosition.X and
			Obj1.AbsolutePosition.Y < Obj2.AbsolutePosition.Y + Obj2.AbsoluteSize.Y and
			Obj1.AbsoluteSize.Y + Obj1.AbsolutePosition.Y > Obj2.AbsolutePosition.Y)
end

local function CheckGhostCollision()
	for i, v in pairs(GhostBoxes) do
		if IsColliding(PacmanCol, v) then
			if Frightened then
				ModuleReferences[i]:Reset(true)
				Pacman.Visible = false
				v.Parent.Visible = false
				wait(1)
				Pacman.Visible = true
				v.Parent.Visible = true
			else
				Playing = false
				for i, v in pairs(ModuleReferences) do
					v:Reset(false)
				end
				wait(1)
				Died()
				break
			end
		end
	end
end

local function CheckDotCollision()
	for i, v in pairs(PacDots:GetChildren()) do
		if v.Visible then
			if IsColliding(PacmanCol, v) then
				v.Visible = false
				UpdateScoreDisplay(10)
			end
		end
	end
	for i, v in pairs(Pellets:GetChildren()) do
		if PelletStates[v] then
			if IsColliding(PacmanCol, v) then
				local RecentValue = FrightenedValue + 1
				FrightenedValue = RecentValue
				PelletStates[v] = nil
				v.Visible = false
				UpdateScoreDisplay(50)
				Frightened = true
				for i, v in pairs(ModuleReferences) do
					v:Frightened()
				end
				coroutine.wrap(function()
					wait(8)
					Frightened = RecentValue ~= FrightenedValue
				end)()
			end
		end
	end
end

local function UpdateLives()
	Lives = Lives - 1
	MapImage.Lives["Life" .. Lives + 1].Visible = false
end

local function GetReady()
	if NewGame then
		PelletStates = {}
		for i, v in pairs(Pellets:GetChildren()) do
			PelletStates[v] = true
		end
	end
	wait(2)
	for i, v in pairs(Ghosts) do
		v.Visible = true
	end
	Pacman.Visible = true
	MapImage.ReadyLabel.Visible = true
	MapImage.Plr1Label.Visible = false
	wait(2)
	MapImage.ReadyLabel.Visible = false
	UpdateLives()
	Playing = true
	for i, v in pairs(ModuleReferences) do
		v:Run()
	end
end

local function Animation()
	AnimCount = AnimCount + 1
	local AnimValues = {84, 12, 84, 156}
	local Value = AnimValues[AnimCount]
	Pacman.ImageRectOffset = Vector2.new(
		Value,
		Value == 156 and 0 or DirSpriteMap[Direction]
	)
	if AnimCount == 4 then
		AnimCount = 0
	end
end

local function ResetPlayer()
	Pacman.Position = UDim2.new(0.465, 0, 0.708, 0)
	Direction = "Right"
	DesiredDir = "Right"
end

while CanStart do
	GetReady()
	NewGame = false
	MoveScript:Setup("Movement", Pacman)
	while Playing do
		wait(.04)
		Animation()
		local NewTarget
		Direction, NewTarget = MoveScript:Update(Pacman, Direction, DesiredDir)
		if NewTarget ~= Target then
			LastTarget = Target
			Target = NewTarget
		end
		Flicker()
		CheckGhostCollision()
		CheckDotCollision()
	end
	ResetPlayer()
end