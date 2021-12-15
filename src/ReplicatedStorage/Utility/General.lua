local General = {}

function General:GetServerType()
	if game.PlaceId == 7472450623 then
		return "Real"
	else
		return "Test"
	end
end

General.PlayerStats = {
	Killstreak = 0,
}

General.CharacterStats = {
	BreakJointsOnDeath = false,
	WalkSpeed = 20,
}

General.CharacterGunAnimations = {
	Idle = 7936433229,
	Move = 7936464529,
	Shoot = 7936516078
}

General.DATASTORE_NAME = "PlayerData1"
General.TESTERSTORE_NAME = "TesterData1"
return General