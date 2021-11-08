/obj/effect/landmark/ctf
	name = "CTF Map Spawner"

/obj/effect/landmark/ctf/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, .proc/load_map)

/obj/effect/landmark/ctf/proc/load_map()

	var/list/map_options = subtypesof(/datum/map_template/ctf)
	var/turf/spawn_area = get_turf(src)
	var/datum/map_template/ctf/current_map

	current_map = pick(map_options)
	current_map = new current_map

	if(!spawn_area)
		CRASH("No spawn area detected for CTF!")
	else if(!current_map)
		CRASH("No map prepared")
	var/list/bounds = current_map.load(spawn_area, TRUE)
	if(!bounds)
		CRASH("Loading CTF map failed!")

/datum/map_template/ctf
	var/description = ""

/datum/map_template/ctf/classic
	name = "Classic"
	description = "The original CTF map."
	mappath = "_maps/map_files/CTF/classic.dmm"

/datum/map_template/ctf/fourSide
	name = "Four Side"
	description = "A CTF map created to demonstrate 4 team CTF, features a single centred flag rather than one per team."
	mappath = "_maps/map_files/CTF/fourSide.dmm"

/datum/map_template/ctf/downtown
	name = "Downtown"
	description = "A CTF map that takes place in a terrestrial city."
	mappath = "_maps/map_files/CTF/downtown.dmm"

/datum/map_template/ctf/limbo
	name = "Limbo"
	description = "A KOTH map that takes place in a wizard den with looping hallways"
	mappath = "_maps/map_files/CTF/limbo.dmm"

/datum/map_template/ctf/cruiser
	name = "Crusier"
	description = "A CTF map that takes place across multiple space ships, one carring a powerful device that can accelerate those who obtain it"
	mappath = "_maps/map_files/CTF/cruiser.dmm"

/datum/map_template/ctf/miniwarfare
	name = "Mini-Warfare"
	description = "Две стороны, одна на юге, другая на севере. Сможет ли кто-то из них одержать победу?"
	mappath = "_maps/map_files/CTF/miniwarfare.dmm"
