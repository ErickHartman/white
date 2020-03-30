#define TRAIT_STATUS_EFFECT(effect_id) "[effect_id]-trait"

//Largely negative status effects go here, even if they have small benificial effects
//STUN EFFECTS
/datum/status_effect/incapacitating
	tick_interval = 0
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()
	if(.)
		if(updating_canmove)
			owner.update_mobility()
			if(needs_update_stat || issilicon(owner))
				owner.update_stat()

/datum/status_effect/incapacitating/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	owner.update_mobility()
	if(needs_update_stat || issilicon(owner)) //silicons need stat updates in addition to normal canmove updates
		owner.update_stat()
	return ..()

//STUN
/datum/status_effect/incapacitating/stun
	id = "stun"

//KNOCKDOWN
/datum/status_effect/incapacitating/knockdown
	id = "knockdown"

//IMMOBILIZED
/datum/status_effect/incapacitating/immobilized
	id = "immobilized"

/datum/status_effect/incapacitating/paralyzed
	id = "paralyzed"

//UNCONSCIOUS
/datum/status_effect/incapacitating/unconscious
	id = "unconscious"
	needs_update_stat = TRUE

/datum/status_effect/incapacitating/unconscious/tick()
	if(owner.getStaminaLoss())
		owner.adjustStaminaLoss(-0.3) //reduce stamina loss by 0.3 per tick, 6 per 2 seconds

//SLEEPING
/datum/status_effect/incapacitating/sleeping
	id = "sleeping"
	alert_type = /obj/screen/alert/status_effect/asleep
	needs_update_stat = TRUE
	var/mob/living/carbon/carbon_owner
	var/mob/living/carbon/human/human_owner

/datum/status_effect/incapacitating/sleeping/on_creation(mob/living/new_owner, updating_canmove)
	. = ..()
	if(.)
		if(iscarbon(owner)) //to avoid repeated istypes
			carbon_owner = owner
		if(ishuman(owner))
			human_owner = owner

/datum/status_effect/incapacitating/sleeping/Destroy()
	carbon_owner = null
	human_owner = null
	return ..()

/datum/status_effect/incapacitating/sleeping/tick()
	if(owner.maxHealth)
		var/health_ratio = owner.health / owner.maxHealth
		var/healing = -0.2
		if((locate(/obj/structure/bed) in owner.loc))
			healing -= 0.3
		else if((locate(/obj/structure/table) in owner.loc))
			healing -= 0.1
		for(var/obj/item/bedsheet/bedsheet in range(owner.loc,0))
			if(bedsheet.loc != owner.loc) //bedsheets in your backpack/neck don't give you comfort
				continue
			healing -= 0.1
			break //Only count the first bedsheet
		if(health_ratio > 0.8)
			owner.adjustBruteLoss(healing)
			owner.adjustFireLoss(healing)
			owner.adjustToxLoss(healing * 0.5, TRUE, TRUE)
		owner.adjustStaminaLoss(healing)
	if(human_owner && human_owner.drunkenness)
		human_owner.drunkenness *= 0.997 //reduce drunkenness by 0.3% per tick, 6% per 2 seconds
	if(prob(20))
		if(carbon_owner)
			carbon_owner.handle_dreams()
		if(prob(10) && owner.health > owner.crit_threshold)
			owner.emote("snore")

/obj/screen/alert/status_effect/asleep
	name = "Сон"
	desc = "Я сплю. Скоро проснусь, надеюсь."
	icon_state = "asleep"

//STASIS
/datum/status_effect/grouped/stasis
	id = "stasis"
	duration = -1
	tick_interval = 10
	alert_type = /obj/screen/alert/status_effect/stasis
	var/last_dead_time

/datum/status_effect/grouped/stasis/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.tod = station_time_timestamp(wtime=new_timeofdeath)
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/grouped/stasis/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	if(.)
		update_time_of_death()
		owner.reagents?.end_metabolization(owner, FALSE)
		owner.update_mobility()

/datum/status_effect/grouped/stasis/tick()
	update_time_of_death()

/datum/status_effect/grouped/stasis/on_remove()
	owner.update_mobility()
	update_time_of_death()
	return ..()

/obj/screen/alert/status_effect/stasis
	name = "Стазис"
	desc = "Мои биологические функции остановились. Я могу так жить вечно, но это довольно скучно."
	icon_state = "stasis"

//GOLEM GANG

//OTHER DEBUFFS
/datum/status_effect/strandling //get it, strand as in durathread strand + strangling = strandling hahahahahahahahahahhahahaha i want to die
	id = "strandling"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /obj/screen/alert/status_effect/strandling

/datum/status_effect/strandling/on_apply()
	ADD_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/datum/status_effect/strandling/on_remove()
	REMOVE_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/obj/screen/alert/status_effect/strandling
	name = "Choking strand"
	desc = "Волшебная прядь протектора дюраткань обернута вокруг шеи, препятствуя дыханию! Щелкните этот значок, чтобы удалить прядь."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/obj/screen/alert/status_effect/strandling/Click(location, control, params)
	. = ..()
	if(usr != owner)
		return
	to_chat(owner, "<span class='notice'>Я пытаюсь снять прядь дюраткани с моей шеи.</span>")
	if(do_after(owner, 35, null, owner))
		if(isliving(owner))
			var/mob/living/L = owner
			to_chat(owner, "<span class='notice'>Я успешно удаляю прядь дюраткани.</span>")
			L.remove_status_effect(STATUS_EFFECT_CHOKINGSTRAND)


/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "status_effect")
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "status_effect")

//OTHER DEBUFFS
/datum/status_effect/pacify
	id = "pacify"
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	duration = 100
	alert_type = null

/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "status_effect")
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "status_effect")

/datum/status_effect/his_wrath //does minor damage over time unless holding His Grace
	id = "his_wrath"
	duration = -1
	tick_interval = 4
	alert_type = /obj/screen/alert/status_effect/his_wrath

/obj/screen/alert/status_effect/his_wrath
	name = "Его Гнев"
	desc = "Я бежал от Его милости вместо того, чтобы накормить Его, и теперь страдаю."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/datum/status_effect/his_wrath/tick()
	for(var/obj/item/his_grace/HG in owner.held_items)
		qdel(src)
		return
	owner.adjustBruteLoss(0.1)
	owner.adjustFireLoss(0.1)
	owner.adjustToxLoss(0.2, TRUE, TRUE)

/datum/status_effect/cultghost //is a cult ghost and can't use manifest runes
	id = "cult_ghost"
	duration = -1
	alert_type = null

/datum/status_effect/cultghost/on_apply()
	owner.see_invisible = SEE_INVISIBLE_OBSERVER
	owner.see_in_dark = 2

/datum/status_effect/cultghost/tick()
	if(owner.reagents)
		owner.reagents.del_reagent(/datum/reagent/water/holywater) //can't be deconverted

/datum/status_effect/crusher_mark
	id = "crusher_mark"
	duration = 300 //if you leave for 30 seconds you lose the mark, deal with it
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/mutable_appearance/marked_underlay
	var/obj/item/kinetic_crusher/hammer_synced

/datum/status_effect/crusher_mark/on_creation(mob/living/new_owner, obj/item/kinetic_crusher/new_hammer_synced)
	. = ..()
	if(.)
		hammer_synced = new_hammer_synced

/datum/status_effect/crusher_mark/on_apply()
	if(owner.mob_size >= MOB_SIZE_LARGE)
		marked_underlay = mutable_appearance('icons/effects/effects.dmi', "shield2")
		marked_underlay.pixel_x = -owner.pixel_x
		marked_underlay.pixel_y = -owner.pixel_y
		owner.underlays += marked_underlay
		return TRUE
	return FALSE

/datum/status_effect/crusher_mark/Destroy()
	hammer_synced = null
	if(owner)
		owner.underlays -= marked_underlay
	QDEL_NULL(marked_underlay)
	return ..()

/datum/status_effect/crusher_mark/be_replaced()
	owner.underlays -= marked_underlay //if this is being called, we should have an owner at this point.
	..()

/datum/status_effect/stacking/saw_bleed
	id = "saw_bleed"
	tick_interval = 6
	delay_before_decay = 5
	stack_threshold = 10
	max_stacks = 10
	overlay_file = 'icons/effects/bleed.dmi'
	underlay_file = 'icons/effects/bleed.dmi'
	overlay_state = "bleed"
	underlay_state = "bleed"
	var/bleed_damage = 200

/datum/status_effect/stacking/saw_bleed/fadeout_effect()
	new /obj/effect/temp_visual/bleed(get_turf(owner))

/datum/status_effect/stacking/saw_bleed/threshold_cross_effect()
	owner.adjustBruteLoss(bleed_damage)
	var/turf/T = get_turf(owner)
	new /obj/effect/temp_visual/bleed/explode(T)
	for(var/d in GLOB.alldirs)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, d)
	playsound(T, "desceration", 100, TRUE, -1)

/datum/status_effect/stacking/saw_bleed/bloodletting
	id = "bloodletting"
	stack_threshold = 7
	max_stacks = 7
	bleed_damage = 20

/datum/status_effect/neck_slice
	id = "neck_slice"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = -1

/datum/status_effect/neck_slice/tick()
	var/mob/living/carbon/human/H = owner
	if(H.stat == DEAD || H.bleed_rate <= 8)
		H.remove_status_effect(/datum/status_effect/neck_slice)
	if(prob(10))
		H.emote(pick("gasp", "gag", "choke"))

/mob/living/proc/apply_necropolis_curse(set_curse)
	var/datum/status_effect/necropolis_curse/C = has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE)
	if(!set_curse)
		set_curse = pick(CURSE_BLINDING, CURSE_SPAWNING, CURSE_WASTING, CURSE_GRASPING)
	if(QDELETED(C))
		apply_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE, set_curse)
	else
		C.apply_curse(set_curse)
		C.duration += 3000 //time added by additional curses
	return C

/datum/status_effect/necropolis_curse
	id = "necrocurse"
	duration = 6000 //you're cursed for 10 minutes have fun
	tick_interval = 50
	alert_type = null
	var/curse_flags = NONE
	var/effect_last_activation = 0
	var/effect_cooldown = 100
	var/obj/effect/temp_visual/curse/wasting_effect = new

/datum/status_effect/necropolis_curse/hivemind
	id = "hivecurse"
	duration = 600

/datum/status_effect/necropolis_curse/on_creation(mob/living/new_owner, set_curse)
	. = ..()
	if(.)
		apply_curse(set_curse)

/datum/status_effect/necropolis_curse/Destroy()
	if(!QDELETED(wasting_effect))
		qdel(wasting_effect)
		wasting_effect = null
	return ..()

/datum/status_effect/necropolis_curse/on_remove()
	remove_curse(curse_flags)

/datum/status_effect/necropolis_curse/proc/apply_curse(set_curse)
	curse_flags |= set_curse
	if(curse_flags & CURSE_BLINDING)
		owner.overlay_fullscreen("curse", /obj/screen/fullscreen/curse, 1)

/datum/status_effect/necropolis_curse/proc/remove_curse(remove_curse)
	if(remove_curse & CURSE_BLINDING)
		owner.clear_fullscreen("curse", 50)
	curse_flags &= ~remove_curse

/datum/status_effect/necropolis_curse/tick()
	if(owner.stat == DEAD)
		return
	if(curse_flags & CURSE_WASTING)
		wasting_effect.forceMove(owner.loc)
		wasting_effect.setDir(owner.dir)
		wasting_effect.transform = owner.transform //if the owner has been stunned the overlay should inherit that position
		wasting_effect.alpha = 255
		animate(wasting_effect, alpha = 0, time = 32)
		playsound(owner, 'sound/effects/curse5.ogg', 20, TRUE, -1)
		owner.adjustFireLoss(0.75)
	if(effect_last_activation <= world.time)
		effect_last_activation = world.time + effect_cooldown
		if(curse_flags & CURSE_SPAWNING)
			var/turf/spawn_turf
			var/sanity = 10
			while(!spawn_turf && sanity)
				spawn_turf = locate(owner.x + pick(rand(10, 15), rand(-10, -15)), owner.y + pick(rand(10, 15), rand(-10, -15)), owner.z)
				sanity--
			if(spawn_turf)
				var/mob/living/simple_animal/hostile/asteroid/curseblob/C = new (spawn_turf)
				C.set_target = owner
				C.GiveTarget()
		if(curse_flags & CURSE_GRASPING)
			var/grab_dir = turn(owner.dir, pick(-90, 90, 180, 180)) //grab them from a random direction other than the one faced, favoring grabbing from behind
			var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
			if(spawn_turf)
				grasp(spawn_turf)

/datum/status_effect/necropolis_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, TRUE, -1)
	var/turf/ownerloc = get_turf(owner)
	var/obj/projectile/curse_hand/C = new (spawn_turf)
	C.preparePixelProjectile(ownerloc, spawn_turf)
	C.fire()

/obj/effect/temp_visual/curse
	icon_state = "curse"

/obj/effect/temp_visual/curse/Initialize()
	. = ..()
	deltimer(timerid)


/datum/status_effect/gonbolaPacify
	id = "gonbolaPacify"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	alert_type = null

/datum/status_effect/gonbolaPacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	ADD_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	ADD_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")
	to_chat(owner, "<span class='notice'>Я внезапно чувствую покой и отпала необходимость совершать внезапные или опрометчивые действия...</span>")
	return ..()

/datum/status_effect/gonbolaPacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	REMOVE_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	REMOVE_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")

/datum/status_effect/trance
	id = "trance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300
	tick_interval = 10
	examine_text = "<span class='warning'>SUBJECTPRONOUN стоит в ступоре.</span>"
	var/stun = TRUE
	alert_type = /obj/screen/alert/status_effect/trance

/obj/screen/alert/status_effect/trance
	name = "Транс"
	desc = "Все кажется таким отдаленным, и я могу почувствовать, как мои мысли образуют петли в голове...."
	icon_state = "high"

/datum/status_effect/trance/tick()
	if(stun)
		owner.Stun(60, TRUE, TRUE)
	owner.dizziness = 20

/datum/status_effect/trance/on_apply()
	if(!iscarbon(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, .proc/hypnotize)
	ADD_TRAIT(owner, TRAIT_MUTE, "trance")
	owner.add_client_colour(/datum/client_colour/monochrome/trance)
	owner.visible_message("[stun ? "<span class='warning'>[owner] стоит смирно и пялится на точку в далеке.</span>" : ""]", \
	"<span class='warning'>[pick("Чувствую, что мои мысли замедлились....", "У меня внезапно кружится голова....", "У меня такое чувство, что я в середине сна....","Чувствую себя невероятно расслаблено...")]</span>")
	return TRUE

/datum/status_effect/trance/on_creation(mob/living/new_owner, _duration, _stun = TRUE)
	duration = _duration
	stun = _stun
	return ..()

/datum/status_effect/trance/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_MUTE, "trance")
	owner.dizziness = 0
	owner.remove_client_colour(/datum/client_colour/monochrome/trance)
	to_chat(owner, "<span class='warning'>Выхожу из своего транса!</span>")

/datum/status_effect/trance/proc/hypnotize(datum/source, list/hearing_args)
	if(!owner.can_hear())
		return
	if(hearing_args[HEARING_SPEAKER] == owner)
		return
	var/mob/living/carbon/C = owner
	C.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY) //clear previous hypnosis
	addtimer(CALLBACK(C, /mob/living/carbon.proc/gain_trauma, /datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY, hearing_args[HEARING_RAW_MESSAGE]), 10)
	addtimer(CALLBACK(C, /mob/living.proc/Stun, 60, TRUE, TRUE), 15) //Take some time to think about it
	qdel(src)

/datum/status_effect/spasms
	id = "spasms"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null

/datum/status_effect/spasms/tick()
	if(prob(15))
		switch(rand(1,5))
			if(1)
				if((owner.mobility_flags & MOBILITY_MOVE) && isturf(owner.loc))
					to_chat(owner, "<span class='warning'>Мою ногу схватила судорога!</span>")
					step(owner, pick(GLOB.cardinals))
			if(2)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				if(I)
					to_chat(owner, "<span class='warning'>Мой палец схватила судорога!</span>")
					owner.log_message("used [I] due to a Muscle Spasm", LOG_ATTACK)
					I.attack_self(owner)
			if(3)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM

				var/range = 1
				if(istype(owner.get_active_held_item(), /obj/item/gun)) //get targets to shoot at
					range = 7

				var/list/mob/living/targets = list()
				for(var/mob/M in oview(owner, range))
					if(isliving(M))
						targets += M
				if(LAZYLEN(targets))
					to_chat(owner, "<span class='warning'>Мою руку схватила судорога!</span>")
					owner.log_message(" attacked someone due to a Muscle Spasm", LOG_ATTACK) //the following attack will log itself
					owner.ClickOn(pick(targets))
				owner.a_intent = prev_intent
			if(4)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM
				to_chat(owner, "<span class='warning'>Мою руку схватила судорогаs!</span>")
				owner.log_message("attacked [owner.p_them()]self to a Muscle Spasm", LOG_ATTACK)
				owner.ClickOn(owner)
				owner.a_intent = prev_intent
			if(5)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				var/list/turf/targets = list()
				for(var/turf/T in oview(owner, 3))
					targets += T
				if(LAZYLEN(targets) && I)
					to_chat(owner, "<span class='warning'>Мою руку схватила судорога!</span>")
					owner.log_message("threw [I] due to a Muscle Spasm", LOG_ATTACK)
					owner.throw_item(pick(targets))

/datum/status_effect/convulsing
	id = "convulsing"
	duration = 	150
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /obj/screen/alert/status_effect/convulsing

/datum/status_effect/convulsing/on_creation(mob/living/zappy_boy)
	. = ..()
	to_chat(zappy_boy, "<span class='boldwarning'>Чувствую шок, движущийся по моему телу! Мои руки начинают дрожать!</span>")

/datum/status_effect/convulsing/tick()
	var/mob/living/carbon/H = owner
	if(prob(40))
		var/obj/item/I = H.get_active_held_item()
		if(I && H.dropItemToGround(I))
			H.visible_message("<span class='notice'>Рука [H] дёргается и случайно выбрасывает [sklonenie(I.name, VINITELNI, I.gender)]!</span>","<span class='userdanger'>Моя рука внезапно дёргается и из неё выпадает то, что я держу!</span>")
			H.jitteriness += 5

/obj/screen/alert/status_effect/convulsing
	name = "Дрожащие руки"
	desc = "Меня ударили чем-то, и руки не перестают трястись! Похоже, что вещи теперь будут выпадать у меня из рук часто."
	icon_state = "convulsing"

/datum/status_effect/dna_melt
	id = "dna_melt"
	duration = 600
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /obj/screen/alert/status_effect/dna_melt
	var/kill_either_way = FALSE //no amount of removing mutations is gonna save you now

/datum/status_effect/dna_melt/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	to_chat(new_owner, "<span class='boldwarning'>Мое тело не выдержит больше мутаций! Мне нужно, чтобы мои мутации были быстро удалены!</span>")

/datum/status_effect/dna_melt/on_remove()
	if(!ishuman(owner))
		owner.gib() //fuck you in particular
		return
	var/mob/living/carbon/human/H = owner
	H.something_horrible(kill_either_way)

/obj/screen/alert/status_effect/dna_melt
	name = "Генетическая разбивка"
	desc = "Мое тело не выдержит больше мутаций! У меня есть минута, чтобы мои мутации были быстро удалены или меня ждёт страшная судьба!"
	icon_state = "dna_melt"

/datum/status_effect/go_away
	id = "go_away"
	duration = 100
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = /obj/screen/alert/status_effect/go_away
	var/direction

/datum/status_effect/go_away/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	direction = pick(NORTH, SOUTH, EAST, WEST)
	new_owner.setDir(direction)

/datum/status_effect/go_away/tick()
	owner.AdjustStun(1, ignore_canstun = TRUE)
	var/turf/T = get_step(owner, direction)
	owner.forceMove(T)

/obj/screen/alert/status_effect/go_away
	name = "К ЗВЕЗДАМ И ДАЛЬШЕ!"
	desc = "Мне надо идти, меня ждут мои люди!"
	icon_state = "high"

/datum/status_effect/fake_virus
	id = "fake_virus"
	duration = 1800//3 minutes
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = null
	var/msg_stage = 0//so you dont get the most intense messages immediately

/datum/status_effect/fake_virus/tick()
	var/fake_msg = ""
	var/fake_emote = ""
	switch(msg_stage)
		if(0 to 300)
			if(prob(1))
				fake_msg = pick("<span class='warning'>[pick("Моя голова болит.", "Моя голова разрывается.")]</span>",
				"<span class='warning'>[pick("Дышать сложно.", "Моё дыхание становится более тяжелым.")]</span>",
				"<span class='warning'>[pick("У меня кружится голова.", "Перед глазами всё вращается.")]</span>",
				"<span notice='warning'>[pick("Сглатываю излишки слизи.", "Я слегка покашливаю.")]</span>",
				"<span class='warning'>[pick("Моя голова болит.", "Мой разум на мгновение остался пустым.")]</span>",
				"<span class='warning'>[pick("Горло болит.", "Прочищаю своё горло.")]</span>")
		if(301 to 600)
			if(prob(2))
				fake_msg = pick("<span class='warning'>[pick("Моя голова сильно болит.", "Моя голова постоянно разрывается.")]</span>",
				"<span class='warning'>[pick("Моё дыхательное горлышко похоже на соломинку.", "Дышать невероятно сложно.")]</span>",
				"<span class='warning'>Чувствую себя очень [pick("плохо","дурно","слабо")].</span>",
				"<span class='warning'>[pick("Слышу звон в ушах.", "В ушах стреляет.")]</span>",
				"<span class='warning'>Засыпаю на мгновение.</span>")
		else
			if(prob(3))
				if(prob(50))// coin flip to throw a message or an emote
					fake_msg = pick("<span class='userdanger'>[pick("Моя голова болит!", "Чувствую горящий нож в моём мозгу!", "Волна боли заполняет мою голову!")]</span>",
					"<span class='userdanger'>[pick("В груди очень сильно болит!", "Больно дышать!")]</span>",
					"<span class='warning'>[pick("Меня тошнит.", "Меня сейчас вырвет!")]</span>")
				else
					fake_emote = pick("cough", "sniff", "sneeze")

	if(fake_emote)
		owner.emote(fake_emote)
	else if(fake_msg)
		to_chat(owner, fake_msg)

	msg_stage++
