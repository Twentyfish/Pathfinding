local pathfindingService = game:GetService("PathfindingService")
local humanoid = script.Parent:WaitForChild("Humanoid")
local humanoidRootPart = script.Parent:WaitForChild("HumanoidRootPart")
local destinationPart = game.Workspace:WaitForChild("SpawnLocation")
local recalculating = false
local currentPath = ""

local function computePath(destination)
	local path = pathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = humanoid.JumpHeight,
		AgentMaxSlope = humanoid.MaxSlopeAngle,
	})
	path:ComputeAsync(humanoidRootPart.Position, destination)
	return path
end

local function followPath(path)
	if path.Status ~= Enum.PathStatus.Success then
		warn("Path not valid. Retrying...")
		return false
	end

	local waypoints = path:GetWaypoints()
	for _, waypoint in ipairs(waypoints) do
		local part = Instance.new("Part")
		part.Size = Vector3.new(1, 1, 1)
		part.Material = Enum.Material.Neon
		part.Color = Color3.new(0, 1, 0)
		part.Position = waypoint.Position + Vector3.new(0, 3, 0)
		part.CanCollide = false
		part.Anchored = true
		part.Parent = workspace
	end
	for _, waypoint in ipairs(waypoints) do
		if recalculating then
			return false
		end
		local oldposition = destinationPart.Position
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		humanoid:MoveTo(waypoint.Position)
		local reached = humanoid.MoveToFinished:Wait()
		local newPosition = destinationPart.Position
		if not reached then
			warn("Waypoint not reached. Recomputing path...")
			return false
		end
	end
	return true
end

local function startPathfinding()
	while true do
		if recalculating then
		else
			local path = computePath(destinationPart.Position)
			currentPath = path
			local success = followPath(path)
			if not success then
				warn("Recomputing path due to obstacle or interruption...")
			end
		end
	end
end
destinationPart:GetPropertyChangedSignal("Position"):Connect(function()
	recalculating = true
	if currentPath then
		currentPath:Destroy() 
	end
	recalculating = false
end)

startPathfinding()
