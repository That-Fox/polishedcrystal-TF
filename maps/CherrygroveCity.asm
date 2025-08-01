CherrygroveCity_MapScriptHeader:
	def_scene_scripts

	def_callbacks
	callback MAPCALLBACK_NEWMAP, CherrygroveCityFlyPoint

	def_warp_events
	warp_event 23,  3, CHERRYGROVE_MART, 2
	warp_event 29,  3, CHERRYGROVE_POKECENTER_1F, 1
	warp_event 17,  7, CHERRYGROVE_GYM_SPEECH_HOUSE, 1
	warp_event 25,  9, GUIDE_GENTS_HOUSE, 1
	warp_event 31, 11, CHERRYGROVE_EVOLUTION_SPEECH_HOUSE, 1

	def_coord_events
	coord_event 33,  7, 0, CherrygroveGuideGentTrigger
	coord_event 33,  6, 1, CherrygroveRivalTriggerNorth
	coord_event 33,  7, 1, CherrygroveRivalTriggerSouth

	def_bg_events
	bg_event 30,  8, BGEVENT_JUMPTEXT, CherrygroveCitySignText
	bg_event 23,  9, BGEVENT_JUMPTEXT, GuideGentsHouseSignText
	bg_event 13,  5, BGEVENT_JUMPTEXT, CherrygroveCityAdvancedTipsSignText
	bg_event 35,  2, BGEVENT_ITEM + NUGGET, EVENT_CHERRYGROVE_CITY_HIDDEN_NUGGET

	def_object_events
	object_event 32,  6, SPRITE_GRAMPS, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, 0, OBJECTTYPE_SCRIPT, 0, CherrygroveCityGuideGent, EVENT_GUIDE_GENT_IN_HIS_HOUSE
	object_event 39,  6, SPRITE_RIVAL, SPRITEMOVEDATA_STANDING_LEFT, 0, 0, -1, 0, OBJECTTYPE_SCRIPT, 0, ObjectEvent, EVENT_RIVAL_CHERRYGROVE_CITY
	object_event 25, 13, SPRITE_POKEFAN_F, SPRITEMOVEDATA_STANDING_DOWN, 0, 1, -1, PAL_NPC_BLUE, OBJECTTYPE_COMMAND, jumptextfaceplayer, CherrygroveTeacherText_HaveMapCard, -1
	object_event 23,  7, SPRITE_YOUNGSTER, SPRITEMOVEDATA_WALK_LEFT_RIGHT, 0, 1, -1, PAL_NPC_RED, OBJECTTYPE_SCRIPT, 0, CherrygroveYoungsterScript, -1
	object_event  7, 12, SPRITE_FISHER, SPRITEMOVEDATA_STANDING_RIGHT, 0, 0, -1, 0, OBJECTTYPE_SCRIPT, 0, MysticWaterGuy, -1
	pokemon_event 26, 13, PIDGEY, SPRITEMOVEDATA_POKEMON, -1, PAL_NPC_BROWN, CherrygrovePidgeyText, -1

	object_const_def
	const CHERRYGROVECITY_GRAMPS
	const CHERRYGROVECITY_RIVAL

CherrygroveCityFlyPoint:
	setflag ENGINE_FLYPOINT_CHERRYGROVE
	endcallback

CherrygroveGuideGentTrigger:
	applymovement PLAYER, GuideGentPlayerMovement
	setlasttalked CHERRYGROVECITY_GRAMPS
CherrygroveCityGuideGent:
	showtextfaceplayer GuideGentIntroText
	playmusic MUSIC_SHOW_ME_AROUND
	follow CHERRYGROVECITY_GRAMPS, PLAYER
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement1
	showtext GuideGentPokeCenterText
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement2
	turnobject PLAYER, UP
	showtext GuideGentMartText
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement3
	turnobject PLAYER, UP
	showtext GuideGentRoute30Text
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement3_5
	turnobject PLAYER, LEFT
	showtext GuideGentAdvancedTipsText
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement4
	turnobject PLAYER, LEFT
	showtext GuideGentSeaText
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement5
	turnobject PLAYER, UP
	pause 60
	turnobject CHERRYGROVECITY_GRAMPS, LEFT
	turnobject PLAYER, RIGHT
	opentext
	writetext GuideGentGiftText
	promptbutton
	givespecialitem MAP_CARD
	setflag ENGINE_MAP_CARD
	writetext GotMapCardText
	promptbutton
	writetext GuideGentPokegearText
	waitbutton
	closetext
	stopfollow
	playmusic MUSIC_CHERRYGROVE_CITY
	turnobject PLAYER, UP
	applymovement CHERRYGROVECITY_GRAMPS, GuideGentMovement6
	playsound SFX_ENTER_DOOR
	disappear CHERRYGROVECITY_GRAMPS
	clearevent EVENT_GUIDE_GENT_VISIBLE_IN_CHERRYGROVE
	setscene $2
	waitsfx
	end

CherrygroveRivalTriggerSouth:
	moveobject CHERRYGROVECITY_RIVAL, 39, 7
CherrygroveRivalTriggerNorth:
	turnobject PLAYER, RIGHT
	showemote EMOTE_SHOCK, PLAYER, 15
	special Special_FadeOutMusic
	pause 15
	appear CHERRYGROVECITY_RIVAL
	applymovement CHERRYGROVECITY_RIVAL, CherrygroveCity_RivalWalksToYou
	turnobject PLAYER, RIGHT
	playmusic MUSIC_RIVAL_ENCOUNTER
	showtext CherrygroveRivalText_Seen
	winlosstext RivalCherrygroveWinText, RivalCherrygroveLossText
	setlasttalked CHERRYGROVECITY_RIVAL
	loadtrainer RIVAL0, 1
	loadvar VAR_BATTLETYPE, BATTLETYPE_CANLOSE
	startbattle
	setevent EVENT_RIVAL_CHERRYGROVE_CITY
	reloadmap
	sjumpfwd .FinishRival

.FinishRival:
	special DeleteSavedMusic
	playmusic MUSIC_RIVAL_AFTER
	showtext CherrygroveRivalTextAfter1
	playsound SFX_TACKLE
	applymovement PLAYER, CherrygroveCity_RivalPushesYouOutOfTheWay
	applymovement CHERRYGROVECITY_RIVAL, CherrygroveCity_RivalStartsToLeave
	showemote EMOTE_SHOCK, CHERRYGROVECITY_RIVAL, 15
	applymovement CHERRYGROVECITY_RIVAL, CherrygroveCity_RivalComesBack
	turnobject PLAYER, UP
	showtext CherrygroveRivalTextAfter2
	turnobject PLAYER, LEFT
	applymovement CHERRYGROVECITY_RIVAL, CherrygroveCity_RivalExitsStageLeft
	disappear CHERRYGROVECITY_RIVAL
	special HealParty
	setscene $2
	playmusic MUSIC_CHERRYGROVE_CITY
	end

CherrygroveYoungsterScript:
	checkflag ENGINE_POKEDEX
	iftrue_jumptextfaceplayer CherrygroveYoungsterText_HavePokedex
	jumpthistextfaceplayer

	text "Mr.#mon's house"
	line "is still farther"
	cont "up ahead."
	done

MysticWaterGuy:
	checkevent EVENT_GOT_MYSTIC_WATER_IN_CHERRYGROVE
	iftrue_jumptextfaceplayer MysticWaterGuyTextAfter
	faceplayer
	opentext
	writetext MysticWaterGuyTextBefore
	promptbutton
	verbosegiveitem MYSTIC_WATER
	iffalse_endtext
	setevent EVENT_GOT_MYSTIC_WATER_IN_CHERRYGROVE
	jumpthisopenedtext

MysticWaterGuyTextAfter:
	text "Back to fishing"
	line "for me, then."
	done

GuideGentMovement1:
	step_left
	step_left
	step_up
GuideGentPlayerMovement:
	step_left
	turn_head_up
	step_end

GuideGentMovement3:
	step_left
GuideGentMovement2:
	step_left
	step_left
	step_left
	step_left
	step_left
	step_left
	turn_head_up
	step_end

GuideGentMovement3_5:
	step_left
	step_left
	step_down
	step_left
	turn_head_up
	step_end

GuideGentMovement4:
	step_left
	step_left
	step_left
	step_down
	step_down
	turn_head_left
	step_end

GuideGentMovement5:
	step_down
	step_right
	step_right
	step_right
	step_right
	step_right
	step_right
	step_right
	step_right
	step_right
	step_right
	step_down
	step_down
	step_right
	step_right
	step_right
	step_right
	step_right
	turn_head_up
	step_end

GuideGentMovement6:
	step_up
	step_up
	step_end

CherrygroveCity_RivalWalksToYou:
	step_left
	step_left
	step_left
	step_left
	step_left
	step_end

CherrygroveCity_RivalPushesYouOutOfTheWay:
	run_step_down
	turn_head_left
	step_end

CherrygroveCity_RivalExitsStageLeft:
	run_step_left
	run_step_left
	run_step_left
	run_step_up
	run_step_up
CherrygroveCity_RivalStartsToLeave:
	run_step_left
	run_step_left
	step_end

CherrygroveCity_RivalComesBack:
	run_step_right
	turn_head_down
	step_end

GuideGentIntroText:
	text "You're a rookie"
	line "trainer, aren't"
	cont "you? I can tell!"

	para "That's OK! Every-"
	line "one is a rookie"
	cont "at some point!"

	para "I can teach you"
	line "a few things."
	cont "Follow me!"
	done

GuideGentPokeCenterText:
	text "This is a #mon"
	line "Center. They heal"

	para "your #mon in no"
	line "time at all."

	para "You'll be relying"
	line "on them a lot, so"

	para "you better learn"
	line "about them."
	done

GuideGentMartText:
	text "This is a #mon"
	line "Mart, or just"
	cont "# Mart."

	para "They sell Balls"
	line "for catching wild"

	para "#mon and other"
	line "useful items."
	done

GuideGentRoute30Text:
	text "Route 30 is out"
	line "this way."

	para "Trainers will be"
	line "battling their"

	para "prized #mon"
	line "there."
	done

GuideGentAdvancedTipsText:
	text "Advanced Tips"
	line "signs have this"
	cont "unusual look."

	para "They're full of"
	line "helpful advice."
	done

GuideGentSeaText:
	text "This is the sea,"
	line "as you can see."

	para "Route 32 is just"
	line "across the bay."
	done

GuideGentGiftText:
	text "Here…"

	para "It's my house!"
	line "Thanks for your"
	cont "company."

	para "Let me give you a"
	line "small gift."
	done

GotMapCardText:
	text "<PLAYER>'s #gear"
	line "now has a Map!"
	done

GuideGentPokegearText:
	text "#gear becomes"
	line "more useful as you"
	cont "add Cards."

	para "I wish you luck on"
	line "your journey!"
	done

CherrygroveRivalText_Seen:
	text "…… …… ……"

	para "You got a #mon"
	line "at the Lab."

	para "What a waste."
	line "A wimp like you."

	para "…… …… ……"

	para "Don't you get what"
	line "I'm saying?"

	para "Well, I too, have"
	line "a good #mon."

	para "I'll show you"
	line "what I mean!"
	done

RivalCherrygroveWinText:
	text "Humph. Are you"
	line "happy you won?"
	done

RivalCherrygroveLossText:
	text "Humph. That was a"
	line "waste of time."
	done

CherrygroveRivalTextAfter1:
	text "…… …… ……"

	para "You want to know"
	line "who I am?"

	para "I'm going to be"
	line "the world's great-"
	cont "est #mon"
	cont "trainer."
	done

CherrygroveRivalTextAfter2:
	text "I dropped my"
	line "Trainer Card…"

	para "Hey! Give it"
	line "back!"

	para "Oh no… You saw"
	line "my name…"
	done

CherrygroveTeacherText_HaveMapCard:
	text "When you're with"
	line "#mon, going"
	cont "anywhere is fun."
	done

CherrygroveYoungsterText_HavePokedex:
	text "I battled the"
	line "trainers on the"
	cont "road."

	para "My #mon lost."
	line "They're a mess! I"

	para "must take them to"
	line "a #mon Center."
	done

MysticWaterGuyTextBefore:
	text "A #mon I caught"
	line "had an item."

	para "I think it's"
	line "Mystic Water."

	para "I don't need it,"
	line "so do you want it?"
	done

CherrygrovePidgeyText:
	text "Pidgey: Pijji!"
	done

CherrygroveCitySignText:
	text "Cherrygrove City"

	para "The City of Cute,"
	line "Fragrant Flowers"
	done

GuideGentsHouseSignText:
	text "Guide Gent's House"
	done

CherrygroveCityAdvancedTipsSignText:
	text "Advanced Tips!"

	para "# Marts will"
	line "give you a free"

	para "Premier Ball with"
	line "every purchase of"
	cont "ten # Balls!"
	done
