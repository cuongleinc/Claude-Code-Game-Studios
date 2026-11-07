class_name BuildingData
extends RefCounted

static var BUILDINGS: Dictionary = {
	"house": {
		"name": "House",
		"cost": {"wood": 50},
		"build_time": 4.0,
		"hp": 250,
		"pop_bonus": 5,
		"size": Vector3(2.5, 2.2, 2.5),
		"color": Color(0.75, 0.65, 0.52),
		"age_req": GameManager.Age.STONE_AGE,
		"description": "+5 Max Population"
	},
	"farm": {
		"name": "Farm",
		"cost": {"wood": 60},
		"build_time": 5.0,
		"hp": 200,
		"pop_bonus": 0,
		"size": Vector3(3.5, 0.4, 3.5),
		"color": Color(0.82, 0.72, 0.35),
		"age_req": GameManager.Age.STONE_AGE,
		"description": "Produces food continuously"
	},
	"lumber_camp": {
		"name": "Lumber Camp",
		"cost": {"wood": 80},
		"build_time": 6.0,
		"hp": 350,
		"pop_bonus": 0,
		"size": Vector3(3.0, 2.5, 3.0),
		"color": Color(0.55, 0.38, 0.22),
		"age_req": GameManager.Age.STONE_AGE,
		"description": "Nearby drop-off for Wood and Stone"
	},
	"barracks": {
		"name": "Barracks",
		"cost": {"wood": 120, "stone": 60},
		"build_time": 8.0,
		"hp": 500,
		"pop_bonus": 0,
		"size": Vector3(4.0, 3.2, 4.0),
		"color": Color(0.68, 0.32, 0.25),
		"age_req": GameManager.Age.STONE_AGE,
		"description": "Trains Spearmen and Archers"
	},
	"harbor": {
		"name": "Harbor",
		"cost": {"wood": 150, "stone": 80},
		"build_time": 10.0,
		"hp": 600,
		"pop_bonus": 0,
		"size": Vector3(4.5, 2.5, 5.0),
		"color": Color(0.35, 0.52, 0.75),
		"age_req": GameManager.Age.STONE_AGE,
		"description": "Constructs transport ships for sea travel"
	},
	"town_center": {
		"name": "Town Center",
		"cost": {"wood": 250, "stone": 150},
		"build_time": 15.0,
		"hp": 1200,
		"pop_bonus": 10,
		"size": Vector3(5.5, 4.0, 5.5),
		"color": Color(0.8, 0.75, 0.65),
		"age_req": GameManager.Age.STONE_AGE,
		"description": "Empire hub; trains villagers"
	},
	"guard_tower": {
		"name": "Guard Tower",
		"cost": {"wood": 100, "stone": 80},
		"build_time": 7.0,
		"hp": 650,
		"pop_bonus": 0,
		"size": Vector3(2.5, 5.5, 2.5),
		"color": Color(0.62, 0.62, 0.68),
		"age_req": GameManager.Age.BRONZE_AGE,
		"description": "Defensive tower that shoots arrows at intruders"
	},
	"stone_wall": {
		"name": "Stone Wall",
		"cost": {"stone": 25},
		"build_time": 2.5,
		"hp": 800,
		"pop_bonus": 0,
		"size": Vector3(3.0, 2.5, 1.2),
		"color": Color(0.5, 0.5, 0.55),
		"age_req": GameManager.Age.BRONZE_AGE,
		"description": "Solid stone barrier"
	},
	"catapult_workshop": {
		"name": "Siege Workshop",
		"cost": {"wood": 180, "stone": 120, "gold": 60},
		"build_time": 12.0,
		"hp": 700,
		"pop_bonus": 0,
		"size": Vector3(4.5, 3.5, 4.5),
		"color": Color(0.48, 0.35, 0.28),
		"age_req": GameManager.Age.IRON_AGE,
		"description": "Constructs siege Catapults and War Galleons"
	}

}
