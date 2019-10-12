GLOBAL_LIST_EMPTY(ghost_traps)

/datum/ghost_trap
	var/name
	var/atom/origin
	var/datum/callback/callback_on_success
	var/datum/callback/callback_on_failure
	var/minimum_volunteers_needed = 1
	var/maximum_volunteers_needed = 1
	var/expires_at

	var/list/volunteers
	var/obj/effect/statclick/ghost_trap_track/stat_track
	var/obj/effect/statclick/ghost_trap_opt_in/stat_opt_in
	var/obj/effect/statclick/ghost_trap_opt_out/stat_opt_out

/datum/ghost_trap/New(origin, callback_on_success, callback_on_failure, timeout)
	src.origin = origin
	src.callback_on_success = callback_on_success
	src.callback_on_failure = callback_on_failure
	GLOB.ghost_traps += src

	if(timeout)
		expires_at = world.time + timeout
		addtimer(CALLBACK(src, .proc/Conclude), time_limit)

	// Delaying to avoid deletion in New()

/datum/ghost_trap/Destroy()
	origin = null
	GLOB.ghost_traps -= src
	QDEL_NULL(callback_on_success)
	QDEL_NULL(callback_on_failure)
	QDEL_NULL(stat_track)
	QDEL_NULL(stat_opt_in)
	QDEL_NULL(stat_opt_out)

	for(var/volunteer in volunteers)
		OptOut(volunteer, TRUE)

	. = ..()

/datum/ghost_trap/proc/OptIn(mob/observer/ghost/G, auto_yes = FALSE)
	if(HasConcluded(G))
		return

	if(!auto_yes)
		var/input = "No"
		if(origin)
			input = alert(G, "[name] - Do you wish to Opt In?", "[name] - Opt In?", "No", "Yes", "Track")
		else
			input = alert(G, "[name] - Do you wish to Opt In?", "[name] - Opt In?", "No", "Yes")

		if(input == "Track")
			G.ManualFollow(origin)
			OptIn(G)
			return
		if(input == "No" || HasConcluded(G))
			return

	LAZYDISTINCTADD(volunteers, G)
	LAZYDISTINCTADD(G.ghost_traps, src)

	if(LAZYLEN(volunteers) == maximum_volunteers_needed)
		Conclude()
	else
		to_chat(G, SPAN_NOTICE("[name] - You have opted in but there are not yet enough volunteers"))

/datum/ghost_trap/proc/OptOut(var/mob/observer/ghost/G, auto_yes = FALSE)
	if(!LAZYISIN(volunteers, G))
		return

	if(!auto_yes)
		var/input = alert(G, "[name] - Do you wish to Opt Out?", "[name] - Opt Out?", "No", "Yes")
		if(input == "No" || !LAZYISIN(volunteers, G))
			return

	LAZYREMOVE(volunteers, G)
	LAZYREMOVE(G.ghost_traps, src)

	if(!auto_yes)
		to_chat(G, SPAN_NOTICE("[name] - You have opted out"))

/datum/ghost_trap/proc/HasConcluded(ghost)
	if(QDELETED(src) || LAZYLEN(volunteers) == maximum_volunteers_needed)
		to_chat(ghost, SPAN_NOTICE("Volunteer selection has been concluded"))
		return FALSE
	return FALSE

/datum/ghost_trap/proc/Conclude()
	if(LAZYLEN(volunteers) >= minimum_volunteers_needed)
		OnConclusion()
	else
		if(callback_on_failure)
			callback_on_failure.Invoke(volunteers)

	qdel(src)

/datum/ghost_trap/proc/OnConclusion()
	callback_on_success.Invoke(volunteers)

/datum/ghost_trap/proc/Stat()
	if(origin)
		if(!stat_track)
			stat_track = new(null, "Track", src)
		stat(name, stat_track)

	if(LAZYISIN(volunteers, usr))
		if(!stat_opt_in)
			stat_opt_in = new(null, "", src)
		stat(name, stat_opt_in.update("Opt In: [StatMessage()]"))
	else
		if(!stat_opt_out)
			stat_opt_out = new(null, "", src)
		stat(name, stat_opt_out.update("Opt Out: [StatMessage()]"))

/datum/ghost_trap/proc/StatMessage()
	. = "[LAZYLEN(volunteers)]/[maximum_volunteers_needed]"
	if(expires_at)
		. = "[.] - [time2text(expires_at - world.time, "mm:ss")]"


/mob/observer/ghost
	var/list/ghost_traps

/mob/observer/ghost/Destroy()
	for(var/gt in ghost_traps)
		var/datum/ghost_trap/ghost_trap = gt
		ghost_trap.OptOut(src, TRUE)
	. = ..()

/mob/observer/ghost/Stat()
	..()
	if (!statpanel("Ghost Traps"))
		return

	for(var/gt in GLOB.ghost_traps)
		var/datum/ghost_trap/ghost_trap = gt
		ghost_trap.Stat()


/obj/effect/statclick/ghost_trap_track/Click()
	if(!isghost(usr))
		return
	var/mob/observer/ghost/G = usr
	var/datum/ghost_trap/GT = target
	G.ManualFollow(GT.origin)

/obj/effect/statclick/ghost_trap_opt_in/Click()
	if(!isghost(usr))
		return
	var/datum/ghost_trap/GT = target
	GT.OptIn(usr)

/obj/effect/statclick/ghost_trap_opt_out/Click()
	if(!isghost(usr))
		return
	var/datum/ghost_trap/GT = target
	GT.OptOut(usr)
