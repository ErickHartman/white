//Firebot

#define SPEECH_INTERVAL 300  // Time between idle speeches
#define DETECTED_VOICE_INTERVAL 300  // Time between fire detected callouts
#define FOAM_INTERVAL 50  // Time between deployment of fire fighting foam

/mob/living/simple_animal/bot/firebot
	name = "пожарный бот"
	desc = "Маленький бот для тушения пожаров. Он выглядит довольно встревоженным."
	icon = 'icons/mob/aibots.dmi'
	icon_state = "firebot"
	density = FALSE
	anchored = FALSE
	health = 25
	maxHealth = 25

	radio_key = /obj/item/encryptionkey/headset_eng
	radio_channel = RADIO_CHANNEL_ENGINEERING
	bot_type = FIRE_BOT
	model = "Firebot"
	bot_core = /obj/machinery/bot_core/firebot
	window_id = "autoextinguisher"
	window_name = "Автоматизированная противопожарная система J0-2"
	path_image_color = "#FFA500"

	var/atom/target_fire
	var/atom/old_target_fire

	var/obj/item/extinguisher/internal_ext

	var/last_found = 0

	var/speech_cooldown = 0
	var/detected_cooldown = 0
	COOLDOWN_DECLARE(foam_cooldown)

	var/extinguish_people = TRUE
	var/extinguish_fires = TRUE
	var/stationary_mode = FALSE

/mob/living/simple_animal/bot/firebot/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	update_icon()

	// Doing this hurts my soul, but simplebot access reworks are for another day.
	var/datum/id_trim/job/engi_trim = SSid_access.trim_singletons_by_path[/datum/id_trim/job/station_engineer]
	access_card.add_access(engi_trim.access + engi_trim.wildcard_access)
	prev_access = access_card.access.Copy()

	create_extinguisher()

/mob/living/simple_animal/bot/firebot/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/atmos_sensitive)

/mob/living/simple_animal/bot/firebot/bot_reset()
	create_extinguisher()

/mob/living/simple_animal/bot/firebot/proc/create_extinguisher()
	internal_ext = new /obj/item/extinguisher(src)
	internal_ext.safety = FALSE
	internal_ext.precision = TRUE
	internal_ext.max_water = INFINITY
	internal_ext.refill()

/mob/living/simple_animal/bot/firebot/UnarmedAttack(atom/A)
	if(!on)
		return
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	if(internal_ext)
		internal_ext.afterattack(A, src)
	else
		return ..()

/mob/living/simple_animal/bot/firebot/RangedAttack(atom/A)
	if(!on)
		return
	if(internal_ext)
		internal_ext.afterattack(A, src)
	else
		return ..()

/mob/living/simple_animal/bot/firebot/turn_on()
	. = ..()
	update_icon()

/mob/living/simple_animal/bot/firebot/turn_off()
	..()
	update_icon()

/mob/living/simple_animal/bot/firebot/bot_reset()
	..()
	target_fire = null
	old_target_fire = null
	ignore_list = list()
	anchored = FALSE
	update_icon()

/mob/living/simple_animal/bot/firebot/proc/soft_reset()
	QDEL_LIST(path)
	path = list()
	target_fire = null
	mode = BOT_IDLE
	last_found = world.time
	update_icon()

/mob/living/simple_animal/bot/firebot/set_custom_texts()
	text_hack = "Взламываю протоколы безопасности [name]."
	text_dehack = "Замечаю ошибки в коде [name] и удаляю их."
	text_dehack_fail = "[name] не отвечает на команды сброса!"

/mob/living/simple_animal/bot/firebot/get_controls(mob/user)
	var/dat
	dat += hack(user)
	dat += showpai(user)
	dat += "<TT><B>Автоматизированная противопожарная система J0-2</B></TT><BR><BR>"
	dat += "Состояние: <A href='?src=[REF(src)];power=1'>[on ? "Вкл" : "Выкл"]</A><BR>"
	dat += "Техническая панель [open ? "открыта" : "закрыта"]<BR>"

	dat += "Управление поведением [locked ? "заблокировано" : "разблокировано"]<BR>"
	if(!locked || issilicon(user) || isAdminGhostAI(user))
		dat += "Тушить пожары: <A href='?src=[REF(src)];operation=extinguish_fires'>[extinguish_fires ? "Да" : "Нет"]</A><BR>"
		dat += "Тушить людей: <A href='?src=[REF(src)];operation=extinguish_people'>[extinguish_people ? "Да" : "Нет"]</A><BR>"
		dat += "Патрулировать станцию: <A href='?src=[REF(src)];operation=patrol'>[auto_patrol ? "Да" : "Нет"]</A><BR>"
		dat += "Стационарный режим: <a href='?src=[REF(src)];operation=stationary_mode'>[stationary_mode ? "Да" : "Нет"]</a><br>"

	return dat

/mob/living/simple_animal/bot/firebot/emag_act(mob/user)
	..()
	if(emagged == 2)
		if(user)
			to_chat(user, "<span class='danger'>[capitalize(src.name)] жужжит и шипит.</span>")
		audible_message("<span class='danger'>[capitalize(src.name)] громко жужжит!</span>")
		playsound(src, "sparks", 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		if(user)
			old_target_fire = user
		extinguish_fires = FALSE
		extinguish_people = TRUE

		internal_ext = new /obj/item/extinguisher(src)
		internal_ext.chem = /datum/reagent/clf3 //Refill the internal extinguisher with liquid fire
		internal_ext.power = 3
		internal_ext.safety = FALSE
		internal_ext.precision = FALSE
		internal_ext.max_water = INFINITY
		internal_ext.refill()

/mob/living/simple_animal/bot/firebot/Topic(href, href_list)
	if(..())
		return TRUE

	switch(href_list["operation"])
		if("extinguish_fires")
			extinguish_fires = !extinguish_fires
		if("extinguish_people")
			extinguish_people = !extinguish_people
		if("stationary_mode")
			stationary_mode = !stationary_mode

	update_controls()
	update_icon()

/mob/living/simple_animal/bot/firebot/proc/is_burning(atom/target)
	if(ismob(target))
		var/mob/living/M = target
		if(M.on_fire || (emagged == 2 && !M.on_fire))
			return TRUE

	else if(isturf(target))
		var/turf/open/T = target
		if(T.active_hotspot)
			return TRUE

	return FALSE

/mob/living/simple_animal/bot/firebot/handle_automated_action()
	if(!..())
		return

	if(IsStun() || IsParalyzed())
		old_target_fire = target_fire
		target_fire = null
		mode = BOT_IDLE
		return

	if(prob(1) && target_fire == null)
		var/list/messagevoice = list("Пожаров не обнаружено." = 'sound/voice/firebot/nofires.ogg',
		"Только ты можешь предотвратить пожары на станции." = 'sound/voice/firebot/onlyyou.ogg',
		"Температура номинальна." = 'sound/voice/firebot/tempnominal.ogg'/*,
		"Сохраняйте это прохладным." = 'sound/voice/firebot/keepitcool.ogg'*/) //непереводимая игра слов.
		var/message = pick(messagevoice)
		speak(message)
		playsound(src, messagevoice[message], 50)

	// Couldn't reach the target, reset and try again ignoring the old one
	if(frustration > 8)
		old_target_fire = target_fire
		soft_reset()

	// We extinguished our target or it was deleted
	if(QDELETED(target_fire) || !is_burning(target_fire) || isdead(target_fire))
		target_fire = null
		var/scan_range = (stationary_mode ? 1 : DEFAULT_SCAN_RANGE)

		if(extinguish_people)
			target_fire = scan(/mob/living, old_target_fire, scan_range) // Scan for burning humans first

		if(target_fire == null && extinguish_fires)
			target_fire = scan(/turf/open, old_target_fire, scan_range) // Scan for burning turfs second

		old_target_fire = target_fire

	// Target reached ENGAGE WATER CANNON
	if(target_fire && (get_dist(src, target_fire) <= (emagged == 2 ? 1 : 2))) // Make the bot spray water from afar when not emagged
		if((speech_cooldown + SPEECH_INTERVAL) < world.time)
			if(ishuman(target_fire))
				speak("Падай и катись!")//падение подразумевает остановку. На английском полная фраза Stop, drop and roll звучит лаконичней из-за краткости всех слов.
				playsound(src, 'sound/voice/firebot/stopdropnroll.ogg', 50, FALSE)
			else
				speak("Тушу!")
				playsound(src, 'sound/voice/firebot/extinguishing.ogg', 50, FALSE)
			speech_cooldown = world.time

			flick("firebot1_use", src)
			spray_water(target_fire, src)

		soft_reset()

	// Target ran away
	else if(target_fire && path.len && (get_dist(target_fire,path[path.len]) > 2))
		path = list()
		mode = BOT_IDLE
		last_found = world.time

	else if(target_fire && stationary_mode)
		soft_reset()
		return

	if(target_fire && (get_dist(src, target_fire) > 2))

		path = get_path_to(src, target_fire, 30, 1, id=access_card)
		mode = BOT_MOVING
		if(!path.len)
			soft_reset()

	if(path.len > 0 && target_fire)
		if(!bot_move(path[path.len]))
			old_target_fire = target_fire
			soft_reset()
		return

	// We got a target but it's too far away from us
	if(path.len > 8 && target_fire)
		frustration++

	if(auto_patrol && !target_fire)
		if(mode == BOT_IDLE || mode == BOT_START_PATROL)
			start_patrol()

		if(mode == BOT_PATROL)
			bot_patrol()


//Look for burning people or turfs around the bot
/mob/living/simple_animal/bot/firebot/process_scan(atom/scan_target)
	var/result

	if(scan_target == src)
		return result

	if(is_burning(scan_target))
		if((detected_cooldown + DETECTED_VOICE_INTERVAL) < world.time)
			speak("Обнаружен открытый огонь!")
			playsound(src, 'sound/voice/firebot/detected.ogg', 50, FALSE)
			detected_cooldown = world.time
		result = scan_target

	return result

/mob/living/simple_animal/bot/firebot/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return (exposed_temperature > T0C + 200 || exposed_temperature < BODYTEMP_COLD_DAMAGE_LIMIT)

/mob/living/simple_animal/bot/firebot/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	if(COOLDOWN_FINISHED(src, foam_cooldown))
		new /obj/effect/particle_effect/foam/firefighting(loc)
		COOLDOWN_START(src, foam_cooldown, FOAM_INTERVAL)

/mob/living/simple_animal/bot/firebot/proc/spray_water(atom/target, mob/user)
	if(stationary_mode)
		flick("firebots_use", user)
	else
		flick("firebot1_use", user)
	internal_ext.afterattack(target, user, null)

/mob/living/simple_animal/bot/firebot/update_icon()
	if(!on)
		icon_state = "firebot0"
		return
	if(IsStun() || IsParalyzed())
		icon_state = "firebots1"
	else if(stationary_mode) //Bot has yellow light to indicate stationary mode.
		icon_state = "firebots1"
	else
		icon_state = "firebot1"


/mob/living/simple_animal/bot/firebot/explode()
	on = FALSE
	visible_message("<span class='boldannounce'>[capitalize(src.name)] взрывается!</span>")

	var/atom/Tsec = drop_location()

	new /obj/item/assembly/prox_sensor(Tsec)
	new /obj/item/clothing/head/hardhat/red(Tsec)

	var/turf/T = get_turf(Tsec)

	if(isopenturf(T))
		var/turf/open/theturf = T
		theturf.MakeSlippery(TURF_WET_WATER, min_wet_time = 10 SECONDS, wet_time_to_add = 5 SECONDS)

	if(prob(50))
		drop_part(robot_arm, Tsec)

	do_sparks(3, TRUE, src)
	..()

/obj/machinery/bot_core/firebot
	req_one_access = list(ACCESS_CONSTRUCTION, ACCESS_ROBOTICS)

#undef SPEECH_INTERVAL
#undef DETECTED_VOICE_INTERVAL
#undef FOAM_INTERVAL

