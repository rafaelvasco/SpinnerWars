extends Node2D

# Sword Properties

var game_version = "0.1"

var sword_props = {
	
	"fire": {
		
		0: {
			"texture": preload("res://Assets/sword_lvl1_fire.png"),
			"weight": 1,
			"scale": 0.5,
		},
		1: {
			"texture": preload("res://Assets/sword_lvl2_fire.png"),
			"weight": 3,
			"scale": 0.5
		},
		2: {
			"texture": preload("res://Assets/sword_lvl3_fire.png"),
			"weight": 7,
			"scale": 0.4
		},
		3: {
			"texture": preload("res://Assets/sword_lvl4_fire.png"),
			"weight": 12,
			"scale": 0.25
		}
	},
	"ice": {
		
	
		
		0: {
			"texture": preload("res://Assets/sword_lvl1_ice.png"),
			"weight": 1,
			"scale": 1
		},
		1: {
			"texture": preload("res://Assets/sword_lvl2_ice.png"),
			"weight": 3,
			"scale": 1
		},
		2: {
			"texture": preload("res://Assets/sword_lvl3_ice.png"),
			"weight": 7,
			"scale": 0.8
		},
		3: {
			"texture": preload("res://Assets/sword_lvl4_ice.png"),
			"weight": 12,
			"scale": 0.5
		}
	},
	"light": {
		
	
		
		0: {
			"texture": preload("res://Assets/sword_lvl1_light.png"),
			"weight": 1,
			"scale": 1
		},
		1: {
			"texture": preload("res://Assets/sword_lvl2_light.png"),
			"weight": 3,
			"scale": 1
		},
		2: {
			"texture": preload("res://Assets/sword_lvl3_light.png"),
			"weight": 7,
			"scale": 0.8
		},
		3: {
			"texture": preload("res://Assets/sword_lvl4_light.png"),
			"weight": 12,
			"scale": 0.5
		}
	},
	"magic": {
		
	
		
		0: {
			"texture": preload("res://Assets/sword_lvl1_magic.png"),
			"weight": 1,
			"scale": 1
		},
		1: {
			"texture": preload("res://Assets/sword_lvl2_magic.png"),
			"weight": 3,
			"scale": 1
		},
		2: {
			"texture": preload("res://Assets/sword_lvl3_magic.png"),
			"weight": 7,
			"scale": 0.8
		},
		3: {
			"texture": preload("res://Assets/sword_lvl4_magic.png"),
			"weight": 12,
			"scale": 0.5
		}
	},
	"poison": {
		
		
		
		0: {
			"texture": preload("res://Assets/sword_lvl1_poison.png"),
			"weight": 1,
			"scale": 1
		},
		1: {
			"texture": preload("res://Assets/sword_lvl2_poison.png"),
			"weight": 3,
			"scale": 1
		},
		2: {
			"texture": preload("res://Assets/sword_lvl3_poison.png"),
			"weight": 7,
			"scale": 0.8
		},
		3: {
			"texture": preload("res://Assets/sword_lvl4_poison.png"),
			"weight": 12,
			"scale": 0.5
		}
	}
}


func _ready():
	pass



#func _process(delta):
#	pass
