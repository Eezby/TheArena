local AbilityData = {
	["Fireball"] = {
		name = "Fireball",
		id = 1,
		
		damage = 25,
		cooldown = 0,
		castTime = 2.25,
		range = 40,
		projectileSpeed = 50,
		
		targetType = "enemy",
		
		image = "1993195573",
		animations = {
			
		}
	},
	
	["Pyroblast"] = {
		name = "Pyroblast",
		id = 2,

		damage = 50,
		cooldown = 0,
		castTime = 4.5,
		range = 40,
		projectileSpeed = 50,

		targetType = "enemy",
		effects = {
			["Burn"] = {duration = 8, damagePercentage = 0.15}
		},

		image = "30276856",
		animations = {

		}
	},
	
	["Scorch"] = {
		name = "Scorch",
		id = 3,

		damage = 10,
		cooldown = 0,
		castTime = 1.5,
		range = 30,
		projectileSpeed = 50,
		movingCast = true,

		targetType = "enemy",

		image = "1532844973",
		animations = {

		}
	},
	
	["Fear"] = {
		name = "Fear",
		id = 4,

		cooldown = 0,
		castTime = 1.7,
		range = 40,
		effects = {
			["Fear"] = {duration = 8}
		},

		targetType = "enemy",

		image = "36697080",
		animations = {

		}
	},
	
	["Meteor"] = {
		name = "Meteor",
		id = 5,
		
		damage = 30,
		cooldown = 20,
		castTime = 0,
		placement = true,
		area = 8,
		range = 40,
		projectileSpeed = 25,
		
		targetType = "none",

		image = "5202266900",
		animations = {

		}
	},
	
	["Fire Blast"] = {
		name = "Fire Blast",
		id = 6,

		damage = 10,
		cooldown = 4,
		maxCharge = 2,
		castTime = 0,
		range = 40,
		critChance = 100,

		targetType = "enemy",

		image = "1853127779",
		animations = {

		}
	},
	
	["Blazing Barrier"] = {
		name = "Blazing Barrier",
		id = 7,
		
		shield = 25,
		duration = 20,
		cooldown = 20,
		castTime = 0,

		targetType = "none",

		image = "2060910441",
		animations = {

		}
	},
	
	["Flamestrike"] = {
		name = "Flamestrike",
		id = 8,

		damage = 30,
		cooldown = 0,
		castTime = 4,
		placement = true,
		area = 8,
		range = 40,

		targetType = "none",

		image = "6822003583",
		animations = {

		}
	},
}
return AbilityData
