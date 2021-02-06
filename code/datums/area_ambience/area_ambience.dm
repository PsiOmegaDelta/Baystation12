/datum/area_ambiance
    VAR_PROTECTED/flags
    VAR_PROTECTED/list/listeners

/datum/area_ambiance/Destroy()
    for(var/listener in listeners)
        RemoveListener(listener)
    return ..()

/datum/area_ambiance/proc/AddListener(mob/observer/virtual/V, area/previous_area)
    SHOULD_NOT_OVERRIDE(TRUE)
    if(LAZYISIN(listeners, V))
        return
    OnAddListener(V, !LAZYLEN(listeners), previous_area)
    LAZYADD(listeners, V)

/datum/area_ambiance/proc/RemoveListener(mob/observer/virtual/V)
    SHOULD_NOT_OVERRIDE(TRUE)
    if(!LAZYISIN(listeners, V))
        return
    LAZYREMOVE(listeners, V)
    OnRemoveListener(V, !LAZYLEN(listeners), new_area)

/datum/area_ambiance/proc/OnAddListener(mob/observer/virtual/V, first_listener, area/previous_area)
    PROTECTED_PROC(TRUE)

/datum/area_ambiance/proc/OnRemoveListener(mob/observer/virtual/V, last_listener, area/new_area)
    PROTECTED_PROC(TRUE)


/datum/area_ambiance/looping
    flags = AREA_AMBIANCE_SKIP_SAME
    VAR_PRIVATE/sounds

/datum/area_ambiance/looping/OnRemoveListener(mob/observer/virtual/V, last_listener, area/new_area)
    if(new_area)
        return // The new

/datum/area_ambiance/timed
    VAR_PRIVATE/min_delay = 1 MINUTE
    VAR_PRIVATE/max_delay = 3 MINUTES
    VAR_PRIVATE/volume = 15
    VAR_PRIVATE/list/sounds
    VAR_PRIVATE/timer_id

/datum/area_ambiance/timed/OnAddListener(mob/observer/virtual/V, first_listener)
    if(first_listener)
        timer_id = addtimer(CALLBACK(src, .proc/PlaySound), prob(min_delay, max_delay), TIMER_STOPPABLE)

/datum/area_ambiance/timed/OnRemoveListener(mob/observer/virtual/V, last_listener)
    if(last_listener)
        deltimer(timer_handle)

/datum/area_ambiance/timed/proc/PlaySound()
    PRIVATE_PROC(TRUE)
    for(var/listener in listeners)
        var/mob/observer/virtual/V = listener
        var/mob/H = V.host
        if(H.get_preference_value(/datum/client_preference/play_ambiance) == GLOB.PREF_YES))
            H.playsound_local(T, sound(pick(ambience), volume = volume, channel = GLOB.timed_ambience_sound_channel))

    timer_id = addtimer(CALLBACK(src, .proc/PlaySound), prob(min_delay, max_delay), TIMER_STOPPABLE)


/area
    PRIVATE_VAR/list/area_ambiances

/area/Destroy()
    QDEL_NULL_LIST(area_ambiances)
    return ..()

/area/proc/AddAmbiance()
    return

/area/proc/RemoveAmbiance()
    return

/area/proc/PlayAmbience(mob/observer/virtual/V, area/previous_area)
    ClearAmbience(V, src)

/area/proc/TransferAmbience(mob/observer/virtual/V, area/previous_area)
    var/types_to_skip
    for(var/area_ambiance in area_ambiances)
        var/datum/area_ambiance/AM = area_ambiance
        if(LAZYISIN(AM.type, types_to_skip))
            CONTINUE
        AM.AddListener(V, previous_area)
        if(AM.flags & AREA_AMBIANCE_SKIP_SAME)
            LAZYADD(types_to_skip, AM.type)

/area/proc/ClearAmbience(mob/observer/virtual/V)
    if(previous_area?.area_ambiances)
        for(var/area_ambiance in previous_area.area_ambiances)
            var/datum/area_ambiance/AM = area_ambiance
            AM.RemoveListener(V)
