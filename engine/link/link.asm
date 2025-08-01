LinkCommunications:
	call ClearBGPalettes
	ld c, 80
	call DelayFrames
	call ClearScreen
	call ClearSprites
	call UpdateSprites
	xor a
	ldh [hSCX], a
	ldh [hSCY], a
	ld c, 80
	call DelayFrames
	call ClearScreen
	call UpdateSprites
	call LoadStandardFont
	call LoadFontsBattleExtra
	call LoadTradeScreenGFX
	call ApplyAttrAndTilemapInVBlank
	hlcoord 3, 8
	lb bc, 2, 12
	call LinkTextbox
	hlcoord 4, 10
	ld de, String_PleaseWait
	rst PlaceString
	call SetTradeRoomBGPals
	call ApplyAttrAndTilemapInVBlank
	ld hl, wLinkByteTimeout
	xor a
	ld [hli], a
	ld [hl], $50
	; fallthrough

Gen2ToGen2LinkComms:
	call ClearLinkData
	call Link_PrepPartyData_Gen2
	call FixDataForLinkTransfer
	call PrepareForLinkTransfers

	ld hl, wLinkBattleRNPreamble
	ld de, wEnemyMon
	ld bc, SERIAL_RN_PREAMBLE_LENGTH + SERIAL_RNS_LENGTH
	vc_hook ExchangeBytes1
	call Serial_ExchangeBytes
	ld a, SERIAL_NO_DATA_BYTE
	ld [de], a

	ld hl, wLinkData
	ld de, wOTPartyData
	ld bc, wOTPartyDataEnd - wOTPartyData
	vc_hook ExchangeBytes2
	call Serial_ExchangeBytes
	ld a, SERIAL_NO_DATA_BYTE
	ld [de], a

	ld hl, wLinkMisc
	ld de, wPlayerTrademonSpecies
	ld bc, wPlayerTrademonSpecies - wLinkMisc
	vc_hook ExchangeBytes3
	call Serial_ExchangeBytes

	ld a, [wLinkMode]
	cp LINK_TRADECENTER
	jr nz, .not_trading
	ld hl, wLinkPlayerMail
	ld de, wLinkOTMail
	ld bc, wLinkPlayerMailEnd - wLinkPlayerMail
	vc_hook ExchangeBytes4
	call ExchangeBytes

.not_trading
	xor a
	ldh [rIF], a
	ld a, IE_SERIAL | IE_VBLANK
	ldh [rIE], a
	ld e, MUSIC_NONE
	call PlayMusic

	call Link_CopyRandomNumbers
	ld hl, wOTPartyData
	call Link_FindFirstNonControlCharacter_SkipZero
	ld de, wLinkData
	ld bc, NAME_LENGTH + 1 + PARTY_LENGTH + 1 + 2 + (PARTYMON_STRUCT_LENGTH + NAME_LENGTH * 2) * PARTY_LENGTH
	call Link_CopyOTData

	ld de, wPlayerTrademon
	ld hl, wLinkPatchList1
	ld c, 2
.loop1
	ld a, [de]
	inc de
	and a
	jr z, .loop1
	cp SERIAL_PREAMBLE_BYTE
	jr z, .loop1
	cp SERIAL_NO_DATA_BYTE
	jr z, .loop1
	cp SERIAL_PATCH_LIST_PART_TERMINATOR
	jr z, .next1
	push hl
	push bc
	ld b, 0
	dec a
	ld c, a
	add hl, bc
	ld [hl], SERIAL_NO_DATA_BYTE
	pop bc
	pop hl
	jr .loop1

.next1
	ld hl, wLinkPatchList2
	dec c
	jr nz, .loop1

	ld a, [wLinkMode]
	cp LINK_TRADECENTER
	jmp nz, .skip_mail
	ld hl, wLinkOTMail
.loop2
	ld a, [hli]
	cp SERIAL_MAIL_PREAMBLE_BYTE
	jr nz, .loop2
.loop3
	ld a, [hli]
	cp SERIAL_NO_DATA_BYTE
	jr z, .loop3
	cp SERIAL_MAIL_PREAMBLE_BYTE
	jr z, .loop3
	dec hl
	ld de, wLinkOTMail
	ld bc, wLinkDataEnd - wLinkOTMail
	rst CopyBytes
	ld hl, wLinkOTMail
	ld bc, (MAIL_MSG_LENGTH + 1) * PARTY_LENGTH
.loop4
	ld a, [hl]
	cp SERIAL_MAIL_REPLACEMENT_BYTE
	jr nz, .okay1
	ld [hl], SERIAL_NO_DATA_BYTE
.okay1
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop4
	ld de, wOTPlayerMailPatchSet
.loop5
	ld a, [de]
	inc de
	cp SERIAL_PATCH_LIST_PART_TERMINATOR
	jr z, .start_copying_mail
	ld hl, wLinkOTMailMetadata
	dec a
	ld b, 0
	ld c, a
	add hl, bc
	ld [hl], SERIAL_NO_DATA_BYTE
	jr .loop5

.start_copying_mail
	ld hl, wLinkOTMail
	ld de, wLinkReceivedMail
	ld b, PARTY_LENGTH
.copy_mail_loop
	push bc
	ld bc, MAIL_MSG_LENGTH + 1
	rst CopyBytes
	ld a, LOW(MAIL_STRUCT_LENGTH - (MAIL_MSG_LENGTH + 1))
	add e
	ld e, a
	ld a, HIGH(MAIL_STRUCT_LENGTH - (MAIL_MSG_LENGTH + 1))
	adc d
	ld d, a
	pop bc
	dec b
	jr nz, .copy_mail_loop
	ld de, wLinkReceivedMail
	ld b, PARTY_LENGTH
.copy_author_loop
	push bc
	ld a, LOW(MAIL_MSG_LENGTH + 1)
	add e
	ld e, a
	ld a, HIGH(MAIL_MSG_LENGTH + 1)
	adc d
	ld d, a
	ld bc, MAIL_STRUCT_LENGTH - (MAIL_MSG_LENGTH + 1)
	rst CopyBytes
	pop bc
	dec b
	jr nz, .copy_author_loop
	ld b, PARTY_LENGTH
	ld de, wLinkReceivedMail
.fix_mail_loop
	push bc
	ld hl, MAIL_STRUCT_LENGTH
	add hl, de
	ld d, h
	ld e, l
	pop bc
	dec b
	jr nz, .fix_mail_loop
	ld de, wLinkReceivedMailEnd
	xor a
	ld [de], a

.skip_mail
	ld hl, wLinkPlayerName
	ld de, wOTPlayerName
	ld bc, NAME_LENGTH
	rst CopyBytes

	ld a, [hli]
	ld [wOTPartyCount], a

	ld de, wOTPlayerID
	ld bc, 2
	rst CopyBytes

	ld de, wOTPartyMons
	ld bc, wOTPartyDataEnd - wOTPartyMons
	rst CopyBytes

	ld e, MUSIC_NONE
	call PlayMusic
	ld a, [wLinkMode]
	cp LINK_COLOSSEUM
	jr nz, .ready_to_trade
	ld a, [wLinkOtherPlayerGender]
	ld b, CAL
	and a ; PLAYER_MALE
	jr z, .got_other_gender
	assert CAL - 1 == CARRIE
	dec b
	dec a ; PLAYER_FEMALE
	jr z, .got_other_gender
	; PLAYER_ENBY
	ld b, JACKY
.got_other_gender
	ld a, b
	ld [wOtherTrainerClass], a
	call ClearScreen
	call Link_WaitBGMap

	ld hl, wOptions2
	ld a, [hl]
	push af
	and ~(BATTLE_SWITCH | BATTLE_PREDICT)
	ld [hl], a
	ld hl, wOTPlayerName
	ld de, wOTClassName
	ld bc, NAME_LENGTH
	rst CopyBytes
	call ReturnToMapFromSubmenu
	ldh a, [rIE]
	push af
	ldh a, [rIF]
	push af
	xor a
	ldh [rIF], a
	pop af
	ldh [rIF], a

	predef StartBattle

	ldh a, [rIF]
	ld h, a
	xor a
	ldh [rIF], a
	pop af
	ldh [rIE], a
	ld a, h
	ldh [rIF], a
	pop af
	ld [wOptions2], a

	farcall LoadPokemonData
	jmp ExitLinkCommunications

.ready_to_trade
	ld e, MUSIC_ROUTE_30
	call PlayMusic
	jmp InitTradeMenuDisplay

LinkTimeout:
	ld de, .LinkTimeoutText
	ld b, 10
.loop
	call DelayFrame
	call LinkDataReceived
	dec b
	jr nz, .loop
	xor a
	ld [hld], a
	ld [hl], a
	ldh [hVBlank], a
	push de
	hlcoord 0, 12
	lb bc, 4, 18
	push de
	call LinkTextbox
	pop de
	pop hl
	bccoord 1, 14
	call PlaceWholeStringInBoxAtOnce
	ld c, 15
	call FadeToWhite
	call ClearScreen
	ld a, CGB_PLAIN
	call GetCGBLayout
	jmp ApplyAttrAndTilemapInVBlank

.LinkTimeoutText:
	; Too much time has elapsed. Please try again.
	text_far _LinkTimeoutText
	text_end

ExchangeBytes:
; This is similar to Serial_ExchangeBytes,
; but without a SERIAL_PREAMBLE_BYTE check.
	ld a, TRUE
	ldh [hSerialIgnoringInitialData], a
.loop
	ld a, [hl]
	ldh [hSerialSend], a
	call Serial_ExchangeByte
	push bc
	ld b, a
	inc hl
	ld a, 48
.wait
	dec a
	jr nz, .wait
	ldh a, [hSerialIgnoringInitialData]
	and a
	ld a, b
	pop bc
	jr z, .load
	dec hl
	xor a
	ldh [hSerialIgnoringInitialData], a
	jr .loop

.load
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

String_PleaseWait:
	text "Please wait!"
	done

ClearLinkData:
	ld hl, wLinkData
	ld bc, wLinkDataEnd - wLinkData
.loop
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

FixDataForLinkTransfer:
	ld hl, wLinkBattleRNPreamble
	ld a, SERIAL_PREAMBLE_BYTE
	ld b, wLinkBattleRNs - wLinkBattleRNPreamble
.preamble_loop
	ld [hli], a
	dec b
	jr nz, .preamble_loop

	ld b, SERIAL_RNS_LENGTH
.rn_loop
	call Random
	cp SERIAL_PREAMBLE_BYTE
	jr nc, .rn_loop
	ld [hli], a
	dec b
	jr nz, .rn_loop

	ld hl, wPlayerPatchLists
	ld a, SERIAL_PREAMBLE_BYTE
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld b, 200
	xor a
.loop1
	ld [hli], a
	dec b
	jr nz, .loop1

	ld hl, wLinkPlayerPartyMon1ID - 1
	ld de, wLinkPlayerFixedPartyMon1ID
	lb bc, 0, 0
.loop2
	inc c
	ld a, c
	cp SERIAL_PATCH_LIST_LENGTH + 1
	jr z, .next1
	ld a, b
	dec a
	jr nz, .next2
	push bc
	ld b, 2 + PARTYMON_STRUCT_LENGTH * PARTY_LENGTH - SERIAL_PATCH_LIST_LENGTH + 1
	ld a, c
	cp b
	pop bc
	jr z, .done
.next2
	inc hl
	ld a, [hl]
	cp SERIAL_NO_DATA_BYTE
	jr nz, .loop2
	ld a, c
	ld [de], a
	inc de
	ld [hl], SERIAL_PATCH_LIST_PART_TERMINATOR
	jr .loop2

.next1
	ld a, SERIAL_PATCH_LIST_PART_TERMINATOR
	ld [de], a
	inc de
	lb bc, 1, 0
	jr .loop2

.done
	ld a, SERIAL_PATCH_LIST_PART_TERMINATOR
	ld [de], a
	ret

Link_PrepPartyData_Gen2:
	ld de, wLinkData
	ld a, SERIAL_PREAMBLE_BYTE
	ld b, SERIAL_PREAMBLE_LENGTH
.loop1
	ld [de], a
	inc de
	dec b
	jr nz, .loop1

	ld hl, wPlayerName
	ld bc, NAME_LENGTH
	rst CopyBytes

	ld a, [wPartyCount]
	ld [de], a
	inc de

	ld hl, wPlayerID
	ld bc, 2
	rst CopyBytes

	ld hl, wPartyMon1Species
	ld bc, PARTY_LENGTH * PARTYMON_STRUCT_LENGTH
	rst CopyBytes

	ld hl, wPartyMonOTs
	ld bc, PARTY_LENGTH * NAME_LENGTH
	rst CopyBytes

	ld hl, wPartyMonNicknames
	ld bc, PARTY_LENGTH * MON_NAME_LENGTH
	rst CopyBytes

; Okay, we did all that.  Now, are we in the trade center?
	ld a, [wLinkMode]
	cp LINK_TRADECENTER
	ret nz

; Fill 5 bytes at wLinkPlayerMailPreamble with $20
	ld de, wLinkPlayerMailPreamble
	ld a, $20
	ld c, 5
.loop
	ld [de], a
	inc de
	dec c
	jr nz, .loop

; Copy all the mail messages to wLinkPlayerMailMessages
	ld a, BANK(sPartyMail)
	call GetSRAMBank
	ld hl, sPartyMail
	ld b, PARTY_LENGTH
.loop2
	push bc
	ld bc, MAIL_MSG_LENGTH + 1
	rst CopyBytes
	ld bc, MAIL_STRUCT_LENGTH - (MAIL_MSG_LENGTH + 1)
	add hl, bc
	pop bc
	dec b
	jr nz, .loop2

; Copy the mail metadata to wLinkPlayerMailMetadata
	ld hl, sPartyMail
	ld b, PARTY_LENGTH
.loop3
	push bc
	ld bc, MAIL_MSG_LENGTH + 1
	add hl, bc
	ld bc, MAIL_STRUCT_LENGTH - (MAIL_MSG_LENGTH + 1)
	rst CopyBytes
	pop bc
	dec b
	jr nz, .loop3

	ld b, PARTY_LENGTH
	ld de, sPartyMail
	ld hl, wLinkPlayerMailMessages
.loop4
	push bc
	push hl
	ld de, MAIL_STRUCT_LENGTH
	add hl, de
	ld d, h
	ld e, l
	pop hl
	ld bc, MAIL_MSG_LENGTH + 1
	add hl, bc
	pop bc
	dec b
	jr nz, .loop4
	call CloseSRAM

	ld hl, wLinkPlayerMailMessages
	ld bc, (MAIL_MSG_LENGTH + 1) * PARTY_LENGTH
.loop5
	ld a, [hl]
	cp SERIAL_NO_DATA_BYTE
	jr nz, .skip2
	ld [hl], SERIAL_MAIL_REPLACEMENT_BYTE
.skip2
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop5

	ld hl, wLinkPlayerMailMetadata
	ld de, wLinkPlayerMailPatchSet
	lb bc, (MAIL_STRUCT_LENGTH - (MAIL_MSG_LENGTH + 1)) * PARTY_LENGTH, 0
.loop6
	inc c
	ld a, [hl]
	cp SERIAL_NO_DATA_BYTE
	jr nz, .skip3
	ld [hl], SERIAL_PATCH_LIST_PART_TERMINATOR
	ld a, c
	ld [de], a
	inc de
.skip3
	inc hl
	dec b
	jr nz, .loop6

	ld a, SERIAL_PATCH_LIST_PART_TERMINATOR
	ld [de], a
	ret

Link_CopyOTData:
.loop
	ld a, [hli]
	cp SERIAL_NO_DATA_BYTE
	jr z, .loop
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

Link_CopyRandomNumbers:
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ret z
	ld hl, wEnemyMonSpecies
	call Link_FindFirstNonControlCharacter_AllowZero
	ld de, wLinkBattleRNs
	ld c, SERIAL_RNS_LENGTH
.loop
	ld a, [hli]
	cp SERIAL_NO_DATA_BYTE
	jr z, .loop
	cp SERIAL_PREAMBLE_BYTE
	jr z, .loop
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

Link_FindFirstNonControlCharacter_SkipZero:
.loop
	ld a, [hli]
	and a
	jr z, .loop
	cp SERIAL_PREAMBLE_BYTE
	jr z, .loop
	cp SERIAL_NO_DATA_BYTE
	jr z, .loop
	dec hl
	ret

Link_FindFirstNonControlCharacter_AllowZero:
.loop
	ld a, [hli]
	cp SERIAL_PREAMBLE_BYTE
	jr z, .loop
	cp SERIAL_NO_DATA_BYTE
	jr z, .loop
	dec hl
	ret

Link_WaitBGMap:
	call ApplyTilemapInVBlank
	jmp ApplyAttrAndTilemapInVBlank

InitTradeMenuDisplay:
	call ClearScreen
	call LoadTradeScreenGFX
	call InitTradeSpeciesList
	xor a
	ld hl, wOtherPlayerLinkMode
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld a, 1
	ld [wMenuCursorY], a
	inc a
	ld [wPlayerLinkAction], a
	jmp LinkTrade_PlayerPartyMenu

InitTradeSpeciesList:
	ld hl, .TradeScreenTilemap
	decoord 0, 0
	call Decompress
	call InitLinkTradePalMap
	call PlaceTradePartnerNamesAndParty
	hlcoord 10, 17
	ld de, .Cancel
	rst PlaceString
	ret

.TradeScreenTilemap:
INCBIN "gfx/trade/border.tilemap.lz"

.Cancel:
	text "Cancel"
	done

PlaceTradePartnerNamesAndParty:
	hlcoord 4, 0
	ld de, wPlayerName
	rst PlaceString
	ld a, $13
	ld [bc], a
	hlcoord 4, 8
	ld de, wOTPlayerName
	rst PlaceString
	ld a, $13
	ld [bc], a
	hlcoord 7, 1
	ld a, [wPartyCount]
	ld de, wPartyMons
	call .PlaceSpeciesNames
	hlcoord 7, 9
	ld a, [wOTPartyCount]
	ld de, wOTPartyMons
.PlaceSpeciesNames:
	push bc
	ld b, a
	ld c, 0
.loop
	push hl
	push bc
	ld hl, MON_IS_EGG
	add hl, de
	ld a, c
	call GetPartyLocation
	assert MON_IS_EGG == MON_FORM
	bit MON_IS_EGG_F, [hl]
	ld a, EGG
	jr nz, .got_species
	ld a, [hl]
	ld [wNamedObjectIndex+1], a
	ld hl, MON_SPECIES
	add hl, de
	pop bc
	push bc
	ld a, c
	call GetPartyLocation
	ld a, [hl]
.got_species
	pop bc
	pop hl
	ld [wNamedObjectIndex], a
	push bc
	push hl
	push de
	push hl
	ld a, c
	ldh [hProduct], a
	call GetPokemonName
	pop hl
	rst PlaceString
	pop de
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	pop bc
	inc c
	dec b
	jr nz, .loop
	pop bc
	ret

LinkTrade_OTPartyMenu:
	ld a, OTPARTYMON
	ld [wMonType], a
	ld a, PAD_A | PAD_UP | PAD_DOWN
	ld [wMenuJoypadFilter], a
	ld a, [wOTPartyCount]
	ld [w2DMenuNumRows], a
	ld a, 1
	ld [w2DMenuNumCols], a
	ld a, 9
	ld [w2DMenuCursorInitY], a
	ld a, 6
	ld [w2DMenuCursorInitX], a
	ld a, 1
	ld [wMenuCursorX], a
	ln a, 1, 0
	ld [w2DMenuCursorOffsets], a
	ld a, $20
	ld [w2DMenuFlags1], a
	xor a
	ld [w2DMenuFlags2], a

LinkTradeOTPartymonMenuLoop:
	call LinkTradeMenu
	ld a, d
	and a
	jmp z, LinkTradePartiesMenuMasterLoop
	bit B_PAD_A, a
	jr z, .not_a_button
	call LinkMonSummaryScreen
	call InitLinkTradePalMap
	call ApplyAttrAndTilemapInVBlank
	jmp LinkTradePartiesMenuMasterLoop

.not_a_button
	bit B_PAD_UP, a
	jr z, .not_d_up
	ld a, [wMenuCursorY]
	ld b, a
	ld a, [wOTPartyCount]
	cp b
	jmp nz, LinkTradePartiesMenuMasterLoop
	xor a
	ld [wMonType], a
	call HideCursor
	push hl
	push bc
	ld bc, NAME_LENGTH
	add hl, bc
	ld [hl], " "
	pop bc
	pop hl
	ld a, [wPartyCount]
	ld [wMenuCursorY], a
	jr LinkTrade_PlayerPartyMenu

.not_d_up
	bit B_PAD_DOWN, a
	jmp z, LinkTradePartiesMenuMasterLoop
	jmp LinkTradeOTPartymonMenuCheckCancel

LinkMonSummaryScreen:
	ld a, [wMenuCursorY]
	dec a
	ld [wCurPartyMon], a
	ld a, [wMonType]
	push af
	farcall OpenPartySummary
	pop af
	ld [wMonType], a
	ld a, [wCurPartyMon]
	inc a
	ld [wMenuCursorY], a
	call LoadTradeScreenGFX
	call Link_WaitBGMap
	call InitTradeSpeciesList
	call SetTradeRoomBGPals
	jmp ApplyAttrAndTilemapInVBlank

LinkTrade_PlayerPartyMenu:
	call InitLinkTradePalMap
	xor a
	ld [wMonType], a
	ld a, PAD_A | PAD_UP | PAD_DOWN
	ld [wMenuJoypadFilter], a
	ld a, [wPartyCount]
	ld [w2DMenuNumRows], a
	ld a, 1
	ld [w2DMenuNumCols], a
	ld a, 1
	ld [w2DMenuCursorInitY], a
	ld a, 6
	ld [w2DMenuCursorInitX], a
	ld a, 1
	ld [wMenuCursorX], a
	ln a, 1, 0
	ld [w2DMenuCursorOffsets], a
	ld a, $20
	ld [w2DMenuFlags1], a
	xor a
	ld [w2DMenuFlags2], a
	call ApplyAttrAndTilemapInVBlank

LinkTradePartymonMenuLoop:
	call LinkTradeMenu
	ld a, d
	and a
	jr z, LinkTradePartiesMenuMasterLoop
	bit B_PAD_A, a
	jmp nz, LinkTrade_TradeSummaryMenu
	bit B_PAD_DOWN, a
	jr z, .not_d_down
	ld a, [wMenuCursorY]
	dec a
	jr nz, LinkTradePartiesMenuMasterLoop
	ld a, OTPARTYMON
	ld [wMonType], a
	call HideCursor
	push hl
	push bc
	ld bc, NAME_LENGTH
	add hl, bc
	ld [hl], " "
	pop bc
	pop hl
	ld a, 1
	ld [wMenuCursorY], a
	jmp LinkTrade_OTPartyMenu

.not_d_down
	bit B_PAD_UP, a
	jr z, LinkTradePartiesMenuMasterLoop
	ld a, [wMenuCursorY]
	ld b, a
	ld a, [wPartyCount]
	cp b
	jr nz, LinkTradePartiesMenuMasterLoop
	call HideCursor
	push hl
	push bc
	ld bc, NAME_LENGTH
	add hl, bc
	ld [hl], " "
	pop bc
	pop hl
	jmp LinkTradePartymonMenuCheckCancel

LinkTradePartiesMenuMasterLoop:
	ld a, [wMonType]
	and a
	jr z, LinkTradePartymonMenuLoop ; PARTYMON
	jmp LinkTradeOTPartymonMenuLoop  ; OTPARTYMON

LinkTradeMenu:
	ld hl, w2DMenuFlags2
	res 7, [hl]
	ldh a, [hBGMapMode]
	push af
	call .loop
	pop af
	ldh [hBGMapMode], a
.GetJoypad:
	push bc
	push af
	ldh a, [hJoyLast]
	and PAD_CTRL_PAD
	ld b, a
	ldh a, [hJoyPressed]
	and PAD_BUTTONS
	or b
	ld b, a
	pop af
	ld a, b
	pop bc
	ld d, a
	ret

.loop
	call .UpdateCursor
	call .UpdateBGMapAndOAM
	call .loop2
	ret nc
	farcall _2DMenuInterpretJoypad
	ret c
	ld a, [w2DMenuFlags1]
	bit 7, a
	ret nz
	call .GetJoypad
	ld b, a
	ld a, [wMenuJoypadFilter]
	and b
	jr z, .loop
	ret

.UpdateBGMapAndOAM:
	ldh a, [hOAMUpdate]
	push af
	ld a, $1
	ldh [hOAMUpdate], a
	call ApplyTilemapInVBlank
	pop af
	ldh [hOAMUpdate], a
	xor a
	ldh [hBGMapMode], a
	ret

.loop2
	call RTC
	call .TryAnims
	ret c
	ld a, [w2DMenuFlags1]
	bit 7, a
	jr z, .loop2
	and a
	ret

.UpdateCursor:
	ld hl, wCursorCurrentTile
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hl]
	cp $16
	jr nz, .not_currently_selected
	ld a, [wCursorOffCharacter]
	ld [hl], a
	push hl
	push bc
	ld bc, MON_NAME_LENGTH
	add hl, bc
	ld [hl], a
	pop bc
	pop hl

.not_currently_selected
	ld a, [w2DMenuCursorInitY]
	ld b, a
	ld a, [w2DMenuCursorInitX]
	ld c, a
	call Coord2Tile
	ld a, [w2DMenuCursorOffsets]
	swap a
	and $f
	ld c, a
	ld a, [wMenuCursorY]
	ld b, a
	xor a
	dec b
	jr z, .skip
.loop3
	add c
	dec b
	jr nz, .loop3

.skip
	ld c, SCREEN_WIDTH
	rst AddNTimes
	ld a, [w2DMenuCursorOffsets]
	and $f
	ld c, a
	ld a, [wMenuCursorX]
	ld b, a
	xor a
	dec b
	jr z, .skip2
.loop4
	add c
	dec b
	jr nz, .loop4

.skip2
	ld c, a
	add hl, bc
	ld a, [hl]
	cp $16
	jr z, .cursor_already_there
	ld [wCursorOffCharacter], a
	ld [hl], $16
	push hl
	push bc
	ld bc, MON_NAME_LENGTH
	add hl, bc
	ld [hl], $16
	pop bc
	pop hl
.cursor_already_there
	ld a, l
	ld [wCursorCurrentTile], a
	ld a, h
	ld [wCursorCurrentTile + 1], a
	ret

.TryAnims:
	ld a, [w2DMenuFlags1]
	bit 6, a
	jr z, .skip_anims
	farcall PlaySpriteAnimationsAndDelayFrame
.skip_anims
	call JoyTextDelay
	call .GetJoypad
	and a
	ret z
	scf
	ret

LinkTrade_TradeSummaryMenu:
	call LoadTileMapToTempTileMap
	ld a, [wMenuCursorY]
	push af
	hlcoord 0, 15
	lb bc, 1, 18
	call LinkTextbox
	hlcoord 2, 16
	ld de, .String_Summary_Trade
	rst PlaceString
	call Link_WaitBGMap

.joy_loop
	ld a, " "
	ldcoord_a 11, 16
	ld a, PAD_A | PAD_B | PAD_RIGHT
	ld [wMenuJoypadFilter], a
	ld a, 1
	ld [w2DMenuNumRows], a
	ld a, 1
	ld [w2DMenuNumCols], a
	ld a, 16
	ld [w2DMenuCursorInitY], a
	ld a, 1
	ld [w2DMenuCursorInitX], a
	ld a, 1
	ld [wMenuCursorY], a
	ld [wMenuCursorX], a
	ln a, 2, 0
	ld [w2DMenuCursorOffsets], a
	xor a
	ld [w2DMenuFlags1], a
	ld [w2DMenuFlags2], a
	call DoMenuJoypadLoop
	bit B_PAD_RIGHT, a
	jr nz, .d_right
	bit B_PAD_B, a
	jr z, .show_summary
.b_button
	pop af
	ld [wMenuCursorY], a
	call SafeLoadTempTileMapToTileMap
	jmp LinkTrade_PlayerPartyMenu

.d_right
	ld a, " "
	ldcoord_a 1, 16
	ld a, PAD_A | PAD_B | PAD_LEFT
	ld [wMenuJoypadFilter], a
	ld a, 1
	ld [w2DMenuNumRows], a
	ld a, 1
	ld [w2DMenuNumCols], a
	ld a, 16
	ld [w2DMenuCursorInitY], a
	ld a, 11
	ld [w2DMenuCursorInitX], a
	ld a, 1
	ld [wMenuCursorY], a
	ld [wMenuCursorX], a
	ln a, 2, 0
	ld [w2DMenuCursorOffsets], a
	xor a
	ld [w2DMenuFlags1], a
	ld [w2DMenuFlags2], a
	call DoMenuJoypadLoop
	bit B_PAD_LEFT, a
	jr nz, .joy_loop
	bit B_PAD_B, a
	jr nz, .b_button
	jr .try_trade

.show_summary
	pop af
	ld [wMenuCursorY], a
	call LinkMonSummaryScreen
	call SafeLoadTempTileMapToTileMap
	hlcoord 6, 1
	lb bc, 6, 1
	call ClearBox
	hlcoord 17, 1
	lb bc, 6, 1
	call ClearBox
	jmp LinkTrade_PlayerPartyMenu

.try_trade
	call PlaceHollowCursor
	pop af
	ld [wMenuCursorY], a
	dec a
	ld [wCurTradePartyMon], a
	ld [wPlayerLinkAction], a
	call PlaceWaitingTextAndSyncAndExchangeNybble
	ld a, [wOtherPlayerLinkMode]
	cp $f
	jmp z, InitTradeMenuDisplay
	ld [wCurOTTradePartyMon], a
	ld a, [wOtherPlayerLinkMode]
	hlcoord 6, 9
	ld bc, SCREEN_WIDTH
	rst AddNTimes
	ld [hl], "▷"
	ld c, 100
	call DelayFrames
	call ValidateOTTrademon
	jr c, .abnormal
	call CheckAnyOtherAliveMonsForTrade
	jmp nc, LinkTrade
	xor a
	ld [wOtherPlayerLinkAction], a
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	call Link_WaitBGMap
	ld hl, .Text_CantTradeLastMon
	bccoord 1, 14
	call PlaceWholeStringInBoxAtOnce
	jr .cancel_trade

.abnormal
	xor a
	ld [wOtherPlayerLinkAction], a
	ld a, [wCurOTTradePartyMon]
	ld hl, wOTPartyMon1IsEgg
	call GetPartyLocation
	assert MON_IS_EGG == MON_FORM
	bit MON_IS_EGG_F, [hl]
	ld a, EGG
	jr nz, .got_ot_species
	ld a, [hl]
	ld [wNamedObjectIndex+1], a
	ld bc, MON_SPECIES - MON_FORM
	add hl, bc
	ld a, [hl]
.got_ot_species
	ld [wNamedObjectIndex], a
	call GetPokemonName
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	call Link_WaitBGMap
	ld hl, .Text_Abnormal
	bccoord 1, 14
	call PlaceWholeStringInBoxAtOnce

.cancel_trade
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	hlcoord 1, 14
	ld de, String_TooBadTheTradeWasCanceled
	rst PlaceString
	ld a, $1
	ld [wPlayerLinkAction], a
	call PlaceWaitingTextAndSyncAndExchangeNybble
	ld c, 100
	call DelayFrames
	jmp InitTradeMenuDisplay

.Text_CantTradeLastMon:
	; If you trade that #MON, you won't be able to battle.
	text_far _LinkTradeCantBattleText
	text_end

.String_Summary_Trade:
	text "Summary   Trade"
	done

.Text_Abnormal:
	; Your friend's @  appears to be abnormal!
	text_far _LinkAbnormalMonText
	text_end

ValidateOTTrademon:
; Returns carry if level isn't within 1-100.
	ld a, [wCurOTTradePartyMon]
	ld hl, wOTPartyMon1Level
	call GetPartyLocation
	ld a, [hl]

	; Only allow level 1-100.
	dec a
	cp MAX_LEVEL
	ccf
	ret

CheckAnyOtherAliveMonsForTrade:
	ld a, [wCurTradePartyMon]
	ld d, a
	ld a, [wPartyCount]
	ld b, a
	ld c, 0
.loop
	ld a, c
	cp d
	jr z, .next
	ld a, c
	ld hl, wPartyMon1HP
	call GetPartyLocation
	ld a, [hli]
	or [hl]
	jr nz, .done

.next
	inc c
	dec b
	jr nz, .loop
	ld a, [wCurOTTradePartyMon]
	ld hl, wOTPartyMon1HP
	call GetPartyLocation
	ld a, [hli]
	or [hl]
	jr nz, .done
	scf
	ret

.done
	and a
	ret

LinkTradeOTPartymonMenuCheckCancel:
	ld a, [wMenuCursorY]
	dec a
	jmp nz, LinkTradePartiesMenuMasterLoop
	call HideCursor
	push hl
	push bc
	ld bc, NAME_LENGTH
	add hl, bc
	ld [hl], " "
	pop bc
	pop hl
LinkTradePartymonMenuCheckCancel:
.loop1
	ld a, "▶"
	ldcoord_a 9, 17
.loop2
	call JoyTextDelay
	ldh a, [hJoyLast]
	and a
	jr z, .loop2
	bit B_PAD_A, a
	jr nz, .a_button
	push af
	ld a, " "
	ldcoord_a 9, 17
	pop af
	bit B_PAD_UP, a
	jr z, .d_up
	ld a, [wOTPartyCount]
	ld [wMenuCursorY], a
	jmp LinkTrade_OTPartyMenu

.d_up
	ld a, 1
	ld [wMenuCursorY], a
	jmp LinkTrade_PlayerPartyMenu

.a_button
	ld a, "▷"
	ldcoord_a 9, 17
	ld a, $f
	ld [wPlayerLinkAction], a
	call PlaceWaitingTextAndSyncAndExchangeNybble
	ld a, [wOtherPlayerLinkMode]
	cp $f
	jr nz, .loop1
ExitLinkCommunications:
	ld c, 15
	call FadeToWhite
	call ClearScreen
	ld a, CGB_PLAIN
	call GetCGBLayout
	call ApplyAttrAndTilemapInVBlank
	xor a
	ldh [rSB], a
	ldh [hSerialSend], a
	ld a, 1
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	vc_hook ExitLinkCommunications_ret
	ret

LinkTrade:
	xor a
	ld [wOtherPlayerLinkAction], a
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	call Link_WaitBGMap
	ld a, [wCurTradePartyMon]
	ld hl, wPartyMon1IsEgg
	call GetPartyLocation
	assert MON_IS_EGG == MON_FORM
	bit MON_IS_EGG_F, [hl]
	ld a, EGG
	jr nz, .got_party_species
	ld a, [hl]
	ld [wNamedObjectIndex+1], a
	ld a, [wCurTradePartyMon]
	ld hl, wPartyMon1Species
	call GetPartyLocation
	ld a, [hl]
.got_party_species
	ld [wNamedObjectIndex], a
	ld bc, MON_FORM - MON_SPECIES
	add hl, bc
	ld a, [hl]
	and SPECIESFORM_MASK
	ld [wNamedObjectIndex+1], a
	call GetPokemonName
	ld hl, wStringBuffer1
	ld de, wBufferTrademonNickname
	ld bc, MON_NAME_LENGTH
	rst CopyBytes
	ld a, [wCurOTTradePartyMon]
	ld hl, wOTPartyMon1IsEgg
	call GetPartyLocation
	assert MON_IS_EGG == MON_FORM
	bit MON_IS_EGG_F, [hl]
	ld a, EGG
	jr nz, .got_ot_species
	ld a, [hl]
	ld [wNamedObjectIndex+1], a
	ld bc, MON_SPECIES - MON_FORM
	add hl, bc
	ld a, [hl]
.got_ot_species
	ld [wNamedObjectIndex], a
	call GetPokemonName
	ld hl, .TradeThisForThat
	bccoord 1, 14
	call PlaceWholeStringInBoxAtOnce
	call LoadStandardMenuHeader
	hlcoord 10, 7
	lb bc, 3, 7
	call LinkTextbox
	ld de, .TradeCancel
	hlcoord 12, 8
	rst PlaceString
	ld a, 8
	ld [w2DMenuCursorInitY], a
	ld a, 11
	ld [w2DMenuCursorInitX], a
	ld a, 1
	ld [w2DMenuNumCols], a
	ld a, 2
	ld [w2DMenuNumRows], a
	xor a
	ld [w2DMenuFlags1], a
	ld [w2DMenuFlags2], a
	ld a, $20
	ld [w2DMenuCursorOffsets], a
	ld a, PAD_A | PAD_B
	ld [wMenuJoypadFilter], a
	ld a, 1
	ld [wMenuCursorY], a
	ld [wMenuCursorX], a
	call Link_WaitBGMap
	call DoMenuJoypadLoop
	push af
	call ExitMenu
	call ApplyAttrAndTilemapInVBlank
	pop af
	bit 1, a
	jr nz, .canceled
	ld a, [wMenuCursorY]
	dec a
	jr z, .try_trade

.canceled
	ld a, $1
	ld [wPlayerLinkAction], a
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	hlcoord 1, 14
	ld de, String_TooBadTheTradeWasCanceled
	rst PlaceString
	call PlaceWaitingTextAndSyncAndExchangeNybble
	jr .finish_cancel

.try_trade
	ld a, $2
	ld [wPlayerLinkAction], a
	call PlaceWaitingTextAndSyncAndExchangeNybble
	ld a, [wOtherPlayerLinkMode]
	dec a
	jr nz, .do_trade
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	hlcoord 1, 14
	ld de, String_TooBadTheTradeWasCanceled
	rst PlaceString
.finish_cancel
	ld c, 100
	call DelayFrames
	jmp InitTradeMenuDisplay

.do_trade
	ld hl, sPartyMail
	ld a, [wCurTradePartyMon]
	ld bc, MAIL_STRUCT_LENGTH
	rst AddNTimes
	ld a, BANK(sPartyMail)
	call GetSRAMBank
	ld d, h
	ld e, l
	ld bc, MAIL_STRUCT_LENGTH
	add hl, bc
	ld a, [wCurTradePartyMon]
	ld c, a
.copy_mail
	inc c
	ld a, c
	cp $6
	jr z, .copy_player_data
	push bc
	ld bc, MAIL_STRUCT_LENGTH
	rst CopyBytes
	pop bc
	jr .copy_mail

.copy_player_data
	ld hl, sPartyMail
	ld a, [wPartyCount]
	dec a
	ld bc, MAIL_STRUCT_LENGTH
	rst AddNTimes
	push hl
	ld hl, wLinkPlayerMail
	ld a, [wCurOTTradePartyMon]
	ld bc, MAIL_STRUCT_LENGTH
	rst AddNTimes
	pop de
	ld bc, MAIL_STRUCT_LENGTH
	rst CopyBytes
	call CloseSRAM

; Buffer player data
; nickname
	ld hl, wPlayerName
	ld de, wPlayerTrademonSenderName
	ld bc, NAME_LENGTH
	rst CopyBytes
; species
	ld a, [wCurTradePartyMon]
	assert MON_IS_EGG == MON_FORM
	ld hl, wPartyMon1IsEgg
	call GetPartyLocation
	ld a, [hl]
	ld [wPlayerTrademonForm], a
	bit MON_IS_EGG_F, a
	ld a, EGG
	jr nz, .got_tradeparty_species
	ld a, [wCurTradePartyMon]
	ld hl, wPartyMon1Species
	call GetPartyLocation
	ld a, [hl]
.got_tradeparty_species
	ld [wPlayerTrademonSpecies], a
	push af
; caught data
	xor a
	ld [wPlayerTrademonCaughtData], a
; OT name
	ld a, [wCurTradePartyMon]
	ld hl, wPartyMonOTs
	call SkipNames
	ld de, wPlayerTrademonOTName
	ld bc, NAME_LENGTH
	rst CopyBytes
; ID
	ld hl, wPartyMon1ID
	ld a, [wCurTradePartyMon]
	call GetPartyLocation
	ld a, [hli]
	ld [wPlayerTrademonID], a
	ld a, [hl]
	ld [wPlayerTrademonID + 1], a
; DVs
	ld hl, wPartyMon1DVs
	ld a, [wCurTradePartyMon]
	call GetPartyLocation
	ld a, [hli]
	ld [wPlayerTrademonDVs], a
	ld a, [hli]
	ld [wPlayerTrademonDVs + 1], a
	ld a, [hl]
	ld [wPlayerTrademonDVs + 2], a

; Buffer other player data
; nickname
	ld hl, wOTPlayerName
	ld de, wOTTrademonSenderName
	ld bc, NAME_LENGTH
	rst CopyBytes
; species
	ld a, [wCurOTTradePartyMon]
	assert MON_IS_EGG == MON_FORM
	ld hl, wOTPartyMon1IsEgg
	call GetPartyLocation
	ld a, [hl]
	ld [wOTTrademonForm], a
	bit MON_IS_EGG_F, a
	ld a, EGG
	jr nz, .got_tradeot_species
	ld bc, MON_SPECIES - MON_FORM
	add hl, bc
	ld a, [hl]
.got_tradeot_species
	ld [wOTTrademonSpecies], a
; OT name
	ld a, [wCurOTTradePartyMon]
	ld hl, wOTPartyMonOTs
	call SkipNames
	ld de, wOTTrademonOTName
	ld bc, NAME_LENGTH
	rst CopyBytes
; ID
	ld hl, wOTPartyMon1ID
	ld a, [wCurOTTradePartyMon]
	call GetPartyLocation
	ld a, [hli]
	ld [wOTTrademonID], a
	ld a, [hl]
	ld [wOTTrademonID + 1], a
; DVs
	ld hl, wOTPartyMon1DVs
	ld a, [wCurOTTradePartyMon]
	call GetPartyLocation
	ld a, [hli]
	ld [wOTTrademonDVs], a
	ld a, [hli]
	ld [wOTTrademonDVs + 1], a
	ld a, [hl]
	ld [wOTTrademonDVs + 2], a
; caught data
	xor a
	ld [wOTTrademonCaughtData], a

	ld a, [wCurTradePartyMon]
	ld [wCurPartyMon], a
	ld a, MON_SPECIES
	call GetPartyParamLocationAndValue
	ld [wCurTradePartyMon], a

	xor a ; REMOVE_PARTY
	ld [wPokemonWithdrawDepositParameter], a
	predef RemoveMonFromParty
	ld a, [wPartyCount]
	dec a
	ld [wCurPartyMon], a
	ld a, [wCurOTTradePartyMon]
	push af
	ld hl, wOTPartyMon1Species
	call GetPartyLocation
	ld a, [hl]
	ld [wCurOTTradePartyMon], a
	ld a, EVOLVE_TRADE
	ld [wForceEvolution], a

	ld c, 100
	call DelayFrames
	call ClearTileMap
	call LoadFontsBattleExtra
	ld a, CGB_PLAIN
	call GetCGBLayout
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	jr z, .player_2
	predef TradeAnimation
	jr .done_animation
.player_2
	call TradeAnimationPlayer2
.done_animation
	pop af
	ld c, a
	ld [wCurPartyMon], a
	ld hl, wOTPartyMon1Species
	call GetPartyLocation
	ld a, [hl]
	ld [wCurPartySpecies], a
	ld hl, wOTPartyMon1Species
	ld b, $81
	inc c
	farcall CopyBetweenPartyAndTemp
	farcall AddTempMonToParty
	ld a, [wPartyCount]
	dec a
	ld [wCurPartyMon], a
	farcall EvolvePokemon
	call ClearScreen
	call LoadTradeScreenGFX
	call SetTradeRoomBGPals
	call Link_WaitBGMap

; Check if either of the Pokémon sent was a Mew or Celebi, and send a different
; byte depending on that. Presumably this would've been some prevention against
; illicit trade machines, but it doesn't seem like a very effective one.
; Removing this code breaks link compatibility with the vanilla gen2 games, but
; has otherwise no consequence.
	ld b, 1
	pop af
	ld c, a
	cp MEW
	jr z, .send_checkbyte
	ld a, [wCurPartySpecies]
	cp MEW
	jr z, .send_checkbyte
	ld b, 2
	ld a, c
	cp CELEBI
	jr z, .send_checkbyte
	ld a, [wCurPartySpecies]
	cp CELEBI
	jr z, .send_checkbyte

; Send the byte in a loop until the desired byte has been received.
	ld b, 0
.send_checkbyte
	ld a, b
	ld [wPlayerLinkAction], a
	push bc
	call Serial_PlaceWaitingTextAndSyncAndExchangeNybble
	pop bc
	ld a, b
	and a
	jr z, .save
	ld a, [wOtherPlayerLinkAction]
	cp b
	jr nz, .send_checkbyte

.save
	farcall SaveAfterLinkTrade
	ld c, 40
	call DelayFrames
	hlcoord 0, 12
	lb bc, 4, 18
	call LinkTextbox
	hlcoord 1, 14
	ld de, .TradeCompleted
	rst PlaceString
	call Link_WaitBGMap
	vc_hook Trade_save_game_end
	ld c, 50
	call DelayFrames
	jmp Gen2ToGen2LinkComms

.TradeCancel:
	text "Trade"
	next "Cancel"
	done

.TradeThisForThat:
	; Trade @ for @ ?
	text_far _LinkAskTradeForText
	text_end

.TradeCompleted:
	text "Trade completed!"
	done

String_TooBadTheTradeWasCanceled:
	text "Too bad! The trade"
	next "was canceled!"
	done

LinkTextbox::
	push bc
	push hl

	push hl
	ld a, $20
	ld [hli], a
	inc a ; $21
	call .fill_row
	inc a ; $22
	ld [hl], a
	pop hl

	ld de, SCREEN_WIDTH
	add hl, de
.loop
	push hl
	ld a, $23
	ld [hli], a
	ld a, " "
	call .fill_row
	ld [hl], $24
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	dec b
	jr nz, .loop

	ld a, $25
	ld [hli], a
	inc a ; $26
	call .fill_row
	inc a ; $27
	ld [hl], a

	pop hl
	pop bc
	ld de, wAttrmap - wTilemap
	add hl, de
	inc b
	inc b
	inc c
	inc c
	ld a, $7
.row
	push bc
	push hl
.col
	ld [hli], a
	dec c
	jr nz, .col
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	pop bc
	dec b
	jr nz, .row
	ret

.fill_row:
	ld d, c
.row_loop
	ld [hli], a
	dec d
	jr nz, .row_loop
	ret

PlaceWaitingTextAndSyncAndExchangeNybble:
	call LoadStandardMenuHeader
	hlcoord 5, 10
	lb bc, 1, 9
	call LinkTextbox
	hlcoord 6, 11
	ld de, .Waiting
	rst PlaceString
	call ApplyTilemapInVBlank
	call ApplyAttrAndTilemapInVBlank
	ld c, 50
	call DelayFrames
	call Serial_SyncAndExchangeNybble
	call ExitMenu
	jmp ApplyAttrAndTilemapInVBlank

.Waiting:
	text "Waiting…!"
	done

LoadTradeScreenGFX:
	ld hl, TradeScreenGFX
	ld de, vTiles2
	lb bc, BANK(TradeScreenGFX), 40
	jmp DecompressRequest2bpp

SetTradeRoomBGPals:
	farcall LoadLinkTradePalette
	farcall ApplyPals
	jmp SetDefaultBGPAndOBP

WaitForOtherPlayerToExit:
	ld c, 3
	call DelayFrames
	ld a, CONNECTION_NOT_ESTABLISHED
	ldh [hSerialConnectionStatus], a
	xor a
	ldh [rSB], a
	ldh [hSerialReceive], a
	ld a, $1
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	ld c, 3
	call DelayFrames
	xor a
	ldh [rSB], a
	ldh [hSerialReceive], a
	xor a ; redundant?
	ldh [rSC], a
	ld a, SC_START | SC_EXTERNAL
	ldh [rSC], a
	ld c, 3
	call DelayFrames
	xor a
	ldh [rSB], a
	ldh [hSerialReceive], a
	ldh [rSC], a
	ld c, 3
	call DelayFrames
	ld a, CONNECTION_NOT_ESTABLISHED
	ldh [hSerialConnectionStatus], a
	ldh a, [rIF]
	push af
	xor a
	ldh [rIF], a
	ld a, IE_SERIAL | IE_VBLANK
	ldh [rIE], a
	pop af
	ldh [rIF], a
	ld hl, wLinkTimeoutFrames
	xor a
	ld [hli], a
	ld [hl], a
	ldh [hVBlank], a
	ld [wLinkMode], a
	vc_hook Wireless_term_exit
	ret

Special_SetBitsForLinkTradeRequest:
	ld a, LINK_TRADECENTER - 1
	ld [wPlayerLinkAction], a
	ld [wChosenCableClubRoom], a
	ret

Special_SetBitsForBattleRequest:
	ld a, LINK_COLOSSEUM - 1
	ld [wPlayerLinkAction], a
	ld [wChosenCableClubRoom], a
	ret

Special_WaitForLinkedFriend:
	ld a, [wPlayerLinkAction]
	and a
	jr z, .no_link_action
	ld a, $2
	ldh [rSB], a
	xor a
	ldh [hSerialReceive], a
	xor a ; redundant?
	ldh [rSC], a
	ld a, SC_START | SC_EXTERNAL
	vc_hook Link_fake_connection_status
	vc_assert hSerialConnectionStatus == $ffcb, \
		"hSerialConnectionStatus is no longer located at 00:ffcb."
	ldh [rSC], a
	call DelayFrame
	call DelayFrame
	call DelayFrame

.no_link_action
	ld a, $2
	ld [wLinkTimeoutFrames + 1], a
	ld a, SERIAL_PATCH_LIST_PART_TERMINATOR
	ld [wLinkTimeoutFrames], a
.loop
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .connected
	cp USING_EXTERNAL_CLOCK
	jr z, .connected
	ld a, CONNECTION_NOT_ESTABLISHED
	ldh [hSerialConnectionStatus], a
	ld a, $2
	ldh [rSB], a
	xor a
	ldh [hSerialReceive], a
	xor a ; redundant?
	ldh [rSC], a
	ld a, SC_START | SC_EXTERNAL
	ldh [rSC], a
	ld hl, wLinkTimeoutFrames
	dec [hl]
	jr nz, .not_done
	inc hl
	dec [hl]
	jr z, .done

.not_done
	ld a, $1
	ldh [rSB], a
	ld a, $1
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	call DelayFrame
	jr .loop

.connected
	call LinkDataReceived
	call DelayFrame
	call LinkDataReceived
	ld c, $32
	call DelayFrames
	ld a, $1
	ldh [hScriptVar], a
	ret

.done
	xor a
	ldh [hScriptVar], a
	ret

Special_CheckLinkTimeout:
	ld a, $1
	ld [wPlayerLinkAction], a
	ld hl, wLinkTimeoutFrames
	ld a, $3
	ld [hli], a
	xor a
	ld [hl], a
	call ApplyTilemapInVBlank
	ld a, $2
	ldh [hVBlank], a
	call DelayFrame
	call DelayFrame
	call Link_CheckCommunicationError
	xor a
	ldh [hVBlank], a
	ldh a, [hScriptVar]
	and a
	ret nz
	jmp Link_ResetSerialRegistersAfterLinkClosure

CheckLinkTimeout_Gen2:
	ld a, $5
	ld [wPlayerLinkAction], a
	ld hl, wLinkTimeoutFrames
	ld a, $3
	ld [hli], a
	xor a
	ld [hl], a
	call ApplyTilemapInVBlank
	ld a, $2
	ldh [hVBlank], a
	call DelayFrame
	call DelayFrame
	call Link_CheckCommunicationError
	ldh a, [hScriptVar]
	and a
	jr z, .vblank
	ld bc, -1
.wait
	dec bc
	ld a, b
	or c
	jr nz, .wait
	ld a, [wOtherPlayerLinkMode]
	cp $5
	jr nz, .script_var
	ld a, $6
	ld [wPlayerLinkAction], a
	ld hl, wLinkTimeoutFrames
	vc_patch Wireless_net_delay_7
if DEF(VIRTUAL_CONSOLE)
	ld a, $3
else
	ld a, 1
endc
	vc_patch_end
	ld [hli], a
	ld [hl], $32
	call Link_CheckCommunicationError
	ld a, [wOtherPlayerLinkMode]
	cp $6
	jr z, .vblank

.script_var
	xor a
	ldh [hScriptVar], a
	ret

.vblank
	xor a
	ldh [hVBlank], a
	ret

Link_CheckCommunicationError:
	xor a
	ldh [hSerialReceivedNewData], a
	vc_hook Wireless_prompt
	ld hl, wLinkTimeoutFrames
	ld a, [hli]
	ld l, [hl]
	ld h, a
	push hl
	call .CheckConnected
	pop hl
	jr nz, .load_true
	call .AcknowledgeSerial
	call .ConvertDW
	call .CheckConnected
	jr nz, .load_true
	call .AcknowledgeSerial
	xor a
	jr .load_scriptvar

.load_true
	ld a, $1

.load_scriptvar
	ldh [hScriptVar], a
	ld hl, wLinkTimeoutFrames
	xor a
	ld [hli], a
	ld [hl], a
	ret

.CheckConnected:
	call Serial_SyncAndExchangeNybble
	ld hl, wLinkTimeoutFrames
	vc_hook Wireless_net_recheck
	ld a, [hli]
	inc a
	ret nz
	ld a, [hl]
	inc a
	ret

.AcknowledgeSerial:
	vc_patch Wireless_net_delay_5
if DEF(VIRTUAL_CONSOLE)
	ld b, 26
else
	ld b, 10
endc
	vc_patch_end
.loop
	call DelayFrame
	call LinkDataReceived
	dec b
	jr nz, .loop
	ret

.ConvertDW:
	dec h
	srl h
	rr l
	srl h
	rr l
	inc h
	ld a, h
	ld [wLinkTimeoutFrames], a
	ld a, l
	ld [wLinkTimeoutFrames + 1], a
	ret

Special_TryQuickSave:
	ld a, [wChosenCableClubRoom]
	push af
	farcall Link_SaveGame
	vc_hook Wireless_TryQuickSave_block_input_1
	ld a, TRUE
	jr nc, .return_result
	vc_hook Wireless_TryQuickSave_block_input_2
	xor a ; FALSE
.return_result
	ldh [hScriptVar], a
	pop af
	ld [wChosenCableClubRoom], a
	ret

PrepareForLinkTransfers:
	call CheckLinkTimeout_Gen2
	ldh a, [hScriptVar]
	and a
	jmp z, LinkTimeout
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .player_1

	ld c, 3
	call DelayFrames
	xor a
	ldh [hSerialSend], a
	inc a
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	call DelayFrame
	xor a
	ldh [hSerialSend], a
	inc a
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a

.player_1:
	ld e, MUSIC_NONE
	call PlayMusic
	vc_patch Wireless_net_delay_6
if DEF(VIRTUAL_CONSOLE)
	ld c, 26
else
	ld c, 3
endc
	vc_patch_end
	call DelayFrames
	xor a
	ldh [rIF], a
	ld a, IE_SERIAL
	ldh [rIE], a
	ret

PerformLinkChecks:
	xor a
	ld bc, 10
	ld hl, wLinkReceivedPolishedMiscBuffer
	rst ByteFill

	; This acts as the old Special_CheckBothSelectedSameRoom.
	; We send a dummy byte here that will cause old versions
	; of Polished Crystal's CheckBothSelectedSameRoom function
	; to fail.
	ld a, LINK_ROOM_DUMMY - 1
	call Link_ExchangeNybble
	cp LINK_ROOM_DUMMY - 1
	jmp nz, .OldVersionDetected

	; Prepare for multiple byte transfers
	ldh a, [rIF]
	push af
	ldh a, [rIE]
	push af
	call PrepareForLinkTransfers

	; Perform game ID byte transfer.
	; hl needs to be set to wLinkPolishedMiscBuffer
	; so we load the values in reverse.
	ld hl, wLinkPolishedMiscBuffer + 2
	ld a, LINK_GAME_ID
	ld [hld], a
	ld a, SERIAL_POLISHED_PREAMBLE_BYTE
	ld [hld], a
	ld [hl], SERIAL_PREAMBLE_BYTE
	ld de, wLinkReceivedPolishedMiscBuffer
	; bc is the number of bytes we should transfer.
	; It needs to account for the maximum number of
	; preamble bytes that can be sent plus the number
	; of data bytes.
	ld bc, SERIAL_POLISHED_MAX_PREAMBLE_LENGTH + 1
	call Serial_ExchangeBytes

	; Save other game ID and check link compatibility
	call .SkipPreambleBytes
	ld [wLinkOtherPlayerGameID], a
	; Is other game ID == our game ID?
	cp LINK_GAME_ID
	jr z, .game_id_ok
	; Is other game ID != the other compatible game ID?
	cp OTHER_GAME_ID
	jmp nz, .WrongGameID
	; The other game ID can be traded with but not battled
	ld a, [wChosenCableClubRoom]
	cp LINK_COLOSSEUM - 1
	jmp z, .WrongGameID
.game_id_ok

	; Perform version and room byte transfers
	ld hl, wLinkPolishedMiscBuffer + 6
	ld a, [wChosenCableClubRoom]
	ld [hld], a
	ld a, LOW(LINK_MIN_TRADE_VERSION)
	ld [hld], a
	ld a, HIGH(LINK_MIN_TRADE_VERSION)
	ld [hld], a
	ld a, LOW(LINK_VERSION)
	ld [hld], a
	ld a, HIGH(LINK_VERSION)
	ld [hld], a
	ld a, SERIAL_POLISHED_PREAMBLE_BYTE
	ld [hld], a
	ld [hl], SERIAL_PREAMBLE_BYTE
	ld de, wLinkReceivedPolishedMiscBuffer
	ld bc, SERIAL_POLISHED_MAX_PREAMBLE_LENGTH + 5
	call Serial_ExchangeBytes

	; Save version and room bytes
	call .SkipPreambleBytes
	ld [wLinkOtherPlayerVersion], a
	ld a, [de]
	ld [wLinkOtherPlayerVersion + 1], a
	inc de
	ld a, [de]
	ld [wLinkOtherPlayerMinTradeVersion], a
	inc de
	ld a, [de]
	ld [wLinkOtherPlayerMinTradeVersion + 1], a
	inc de
	ld a, [de]
	ld b, a
	; Check correct room
	ld a, [wChosenCableClubRoom]
	cp b
	jr nz, .WrongRoom
	inc a
	ld [wLinkMode], a
	; Check version
	call CheckCorrectLinkVersion
	cp TRUE
	jr c, .WrongVersion
	jr nz, .WrongMinVersion

	; Perform options byte transfers
	ld hl, wLinkPolishedMiscBuffer + 3
	ld a, [wInitialOptions2]
	ld [hld], a
	ld a, [wInitialOptions]
	ld [hld], a
	ld a, SERIAL_POLISHED_PREAMBLE_BYTE
	ld [hld], a
	ld [hl], SERIAL_PREAMBLE_BYTE
	ld de, wLinkReceivedPolishedMiscBuffer
	ld bc, SERIAL_POLISHED_MAX_PREAMBLE_LENGTH + 2
	call Serial_ExchangeBytes
	xor a
	ldh [rIF], a
	ld a, IE_SERIAL | IE_VBLANK
	ldh [rIE], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ld c, 66
	call z, DelayFrames

	ld a, [wLinkMode]
	cp LINK_TRADECENTER
	jr z, .skip_options
	; Perform options check
	call .SkipPreambleBytes
	ld b, a
	ld a, [wInitialOptions]
	xor b
	and LINK_OPTMASK
	jr nz, .WrongOptions
	ld a, [de]
	ld b, a
	ld a, [wInitialOptions2]
	xor b
	and EV_OPTMASK
	jr nz, .WrongOptions
.skip_options

	; Process link opponent gender
	ld a, [wPlayerGender]
	call Link_ExchangeNybble
	ld [wLinkOtherPlayerGender], a
	xor a
	ldh [hVBlank], a
	; fallthrough
.Success
	inc a ; LINK_ERR_SUCCESS
	jr .return_result_restore_interrupts

.OldVersionDetected
	xor a ; LINK_ERR_OLD_PC_DETECT
	; fallthrough
.return_result:
	ldh [hScriptVar], a
	ret

.WrongGameID
	ld a, LINK_ERR_MISMATCH_GAME_ID
	jr .return_result_restore_interrupts

.WrongVersion
	ld a, LINK_ERR_MISMATCH_VERSION
	jr .return_result_restore_interrupts

.WrongMinVersion
	cp 3
	ld a, LINK_ERR_VERSION_TOO_LOW
	jr z, .return_result_restore_interrupts
	inc a ; LINK_ERR_OTHER_VERSION_TOO_LOW
	jr .return_result_restore_interrupts

.WrongOptions
	ld a, LINK_ERR_MISMATCH_GAME_OPTIONS
	jr .return_result_restore_interrupts

.WrongRoom
	ld a, LINK_ERR_INCOMPATIBLE_ROOMS
	; fallthrough
.return_result_restore_interrupts
	ldh [hScriptVar], a
	pop af
	ldh [rIE], a
	pop af
	ldh [rIF], a
	ld e, MUSIC_POKEMON_CENTER
	jmp PlayMusic

.SkipPreambleBytes
; This sub function skips over the no longer
; needed preamble bytes.
	ld de, wLinkReceivedPolishedMiscBuffer
.loop
	ld a, [de]
	inc de
	cp SERIAL_POLISHED_PREAMBLE_BYTE
	jr nz, .loop
	ld a, [de]
	inc de
	ret

CheckCorrectLinkVersion:
	ld hl, wLinkOtherPlayerVersion
	ld a, [wLinkMode]
	cp LINK_TRADECENTER
	jr z, .trade_center

	; Is other game version == LINK_VERSION?
	ld a, [hli]
	cp HIGH(LINK_VERSION)
	jr nz, .version_not_equal
	ld a, [hl]
	cp LOW(LINK_VERSION)
	jr z, .success
	jr .version_not_equal

.trade_center
	; Is other game version >= LINK_MIN_TRADE_VERSION?
	ld a, [hli]
	cp HIGH(LINK_MIN_TRADE_VERSION)
	jr z, .continue
	jr c, .other_game_below_min_version
.continue
	ld a, [hl]
	cp LOW(LINK_MIN_TRADE_VERSION)
	jr z, .check_other_min_version
	jr c, .other_game_below_min_version

.check_other_min_version
	; Is LINK_VERSION >= other game min trade version?
	ld hl, wLinkOtherPlayerMinTradeVersion
	ld a, [hli]
	cp HIGH(LINK_VERSION)
	jr z, .continue_2
	jr nc, .below_trade_min_version
.continue_2
	ld a, [hl]
	cp LOW(LINK_VERSION)
	jr z, .success
	jr nc, .below_trade_min_version
	;fallthrough
.success
	xor a
	inc a
	ret
.version_not_equal
	xor a
	ret
.other_game_below_min_version
	ld a, 2
	ret
.below_trade_min_version
	ld a, 3
	ret

Link_ExchangeNybble:
	call Link_EnsureSync
	push af
	call LinkDataReceived
	call DelayFrame
	call LinkDataReceived
	pop af
	ret

Special_TradeCenter:
	vc_hook Wireless_TradeCenter
	ld a, LINK_TRADECENTER
	jr _Special_LinkCommunications

Special_Colosseum:
	vc_hook Wireless_Colosseum
	ld a, LINK_COLOSSEUM
_Special_LinkCommunications:
	ld [wLinkMode], a
	call DisableSpriteUpdates
	call LinkCommunications
	call EnableSpriteUpdates
	xor a
	ldh [hVBlank], a
	ret

Special_CloseLink:
	xor a
	ld [wLinkMode], a
	ld c, $3
	call DelayFrames
	vc_hook Wireless_room_check
	; fallthrough

Link_ResetSerialRegistersAfterLinkClosure:
	ld c, 3
	call DelayFrames
	ld a, CONNECTION_NOT_ESTABLISHED
	ldh [hSerialConnectionStatus], a
	ld a, $2
	ldh [rSB], a
	xor a
	ldh [hSerialReceive], a
	ldh [rSC], a
	ret

Special_FailedLinkToPast:
	ld c, 40
	call DelayFrames
	ld a, $e
	; fallthrough

Link_EnsureSync:
	add $d0
	ld [wLinkPlayerSyncBuffer], a
	ld [wLinkPlayerSyncBuffer + 1], a
	ld a, $2
	ldh [hVBlank], a
	call DelayFrame
	call DelayFrame
.receive_loop
	call Serial_ExchangeSyncBytes
	ld a, [wLinkReceivedSyncBuffer]
	ld b, a
	and $f0
	cp $d0
	jr z, .done
	ld a, [wLinkReceivedSyncBuffer + 1]
	ld b, a
	and $f0
	cp $d0
	jr nz, .receive_loop

.done
	xor a
	ldh [hVBlank], a
	ld a, b
	and $f
	ret

Special_CableClubCheckWhichChris:
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	ld a, $1
	jr z, .yes
	dec a

.yes
	ldh [hScriptVar], a
	ret

InitLinkTradePalMap:
	hlcoord 0, 0, wAttrmap
	lb bc, 16, 2
	ld a, $4
	call .fill_box
	ld a, $3
	ldcoord_a 0, 1, wAttrmap
	ldcoord_a 0, 14, wAttrmap
	hlcoord 2, 0, wAttrmap
	lb bc, 8, 18
	ld a, $5
	call .fill_box
	hlcoord 2, 8, wAttrmap
	lb bc, 8, 18
	ld a, $6
	call .fill_box
	hlcoord 0, 16, wAttrmap
	lb bc, 2, SCREEN_WIDTH
	ld a, $4
	call .fill_box
	ld a, $3
	lb bc, 6, 1
	hlcoord 6, 1, wAttrmap
	call .fill_box
	ld a, $3
	lb bc, 6, 1
	hlcoord 17, 1, wAttrmap
	call .fill_box
	ld a, $3
	lb bc, 6, 1
	hlcoord 6, 9, wAttrmap
	call .fill_box
	ld a, $3
	lb bc, 6, 1
	hlcoord 17, 9, wAttrmap
	call .fill_box
	ld a, $2
	hlcoord 2, 16, wAttrmap
	ld [hli], a
	ld a, $7
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], $2
	hlcoord 2, 17, wAttrmap
	ld a, $3
	ld bc, 6
	rst ByteFill
	ret

.fill_box:
.row
	push bc
	push hl
.col
	ld [hli], a
	dec c
	jr nz, .col
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	pop bc
	dec b
	jr nz, .row
	ret

; hl = send data
; de = receive data
; bc = length of data
Serial_ExchangeBytes::
	ld a, $1
	ldh [hSerialIgnoringInitialData], a
.loop
	ld a, [hl]
	ldh [hSerialSend], a
	call Serial_ExchangeByte
	push bc
	ld b, a
	inc hl
	ld a, 48
.wait48
	dec a
	jr nz, .wait48
	ldh a, [hSerialIgnoringInitialData]
	and a
	ld a, b
	pop bc
	jr z, .load
	dec hl
	cp SERIAL_PREAMBLE_BYTE
	jr nz, .loop
	xor a
	ldh [hSerialIgnoringInitialData], a
	jr .loop

.load
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

Serial_ExchangeByte::
	xor a
	ldh [hSerialReceivedNewData], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .loop
	ld a, $1
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a

.loop
	ldh a, [hSerialReceivedNewData]
	and a
	jr nz, .ok
	ldh a, [hSerialConnectionStatus]
	dec a
	jr nz, .doNotIncrementTimeoutCounter
	call CheckwLinkTimeoutFramesNonzero
	jr z, .doNotIncrementTimeoutCounter
	call .delay_15_cycles
	push hl
	ld hl, wLinkTimeoutFrames + 1
	inc [hl]
	jr nz, .no_rollover_up
	dec hl
	inc [hl]

.no_rollover_up
	pop hl
	call CheckwLinkTimeoutFramesNonzero
	jr nz, .loop
	jr SerialDisconnected

.doNotIncrementTimeoutCounter
	ldh a, [rIE]
	and IE_SERIAL | IE_TIMER | IE_VBLANK
	cp IE_SERIAL
	jr nz, .loop
	ld a, [wLinkByteTimeout]
	dec a ; no-optimize inefficient WRAM increment/decrement
	ld [wLinkByteTimeout], a
	jr nz, .loop
	ld a, [wLinkByteTimeout + 1]
	dec a ; no-optimize inefficient WRAM increment/decrement
	ld [wLinkByteTimeout + 1], a
	jr nz, .loop
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	jr z, .ok

	ld a, 255
.delay_255_cycles
	dec a
	jr nz, .delay_255_cycles

.ok
	xor a
	ldh [hSerialReceivedNewData], a
	ldh a, [rIE]
	and IE_SERIAL | IE_TIMER | IE_VBLANK
	sub IE_SERIAL
	jr nz, .skipReloadingTimeoutCounter2

	;xor a
	ld [wLinkByteTimeout], a
	ld a, $50
	ld [wLinkByteTimeout + 1], a

.skipReloadingTimeoutCounter2
	ldh a, [hSerialReceive]
	cp SERIAL_NO_DATA_BYTE
	ret nz
	call CheckwLinkTimeoutFramesNonzero
	jr z, .done
	push hl
	ld hl, wLinkTimeoutFrames + 1
	ld a, [hl]
	dec a
	ld [hld], a
	inc a
	jr nz, .no_rollover
	dec [hl]

.no_rollover
	pop hl
	call CheckwLinkTimeoutFramesNonzero
	jr z, SerialDisconnected

.done
	ldh a, [rIE]
	and IE_SERIAL | IE_TIMER | IE_VBLANK
	cp IE_SERIAL
	ld a, SERIAL_NO_DATA_BYTE
	ret z
	ld a, [hl]
	ldh [hSerialSend], a
	call DelayFrame
	jmp Serial_ExchangeByte

.delay_15_cycles
	ld a, 15
.delay_15_cycles_loop
	dec a
	jr nz, .delay_15_cycles_loop
	ret

CheckwLinkTimeoutFramesNonzero::
	push hl
	ld hl, wLinkTimeoutFrames
	ld a, [hli]
	or [hl]
	pop hl
	ret

SerialDisconnected::
; a is always 0 when this is called
	dec a
	ld [wLinkTimeoutFrames], a
	ld [wLinkTimeoutFrames + 1], a
	ret

; This is used to check that both players entered the same Cable Club room.
Serial_ExchangeSyncBytes::
	ld hl, wLinkPlayerSyncBuffer
	ld de, wLinkReceivedSyncBuffer
	ld c, $2
	ld a, $1
	ldh [hSerialIgnoringInitialData], a
.loop
	call DelayFrame
	ld a, [hl]
	ldh [hSerialSend], a
	call Serial_ExchangeByte
	ld b, a
	inc hl
	ldh a, [hSerialIgnoringInitialData]
	and a
	ld a, 0 ; no-optimize a = 0
	ldh [hSerialIgnoringInitialData], a
	jr nz, .loop
	ld a, b
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

Serial_PlaceWaitingTextAndSyncAndExchangeNybble::
	call LoadTileMapToTempTileMap
	call PlaceWaitingText
	call Serial_SyncAndExchangeNybble
	jmp SafeLoadTempTileMapToTileMap

PlaceWaitingText::
	hlcoord 4, 10
	lb bc, 1, 10

	ld a, [wBattleMode]
	and a
	jr z, .notinbattle

	call Textbox
	jr .proceed

.notinbattle
	call LinkTextbox

.proceed
	hlcoord 5, 11
	ld de, .Waiting
	rst PlaceString
	ld c, 50
	jmp DelayFrames

.Waiting:
	db "Waiting…!@"

Serial_SyncAndExchangeNybble::
	vc_hook Wireless_WaitLinkTransfer
	ld a, $ff
	ld [wOtherPlayerLinkAction], a
.loop
	call LinkTransfer
	call DelayFrame
	call CheckwLinkTimeoutFramesNonzero
	jr z, .check
	push hl
	ld hl, wLinkTimeoutFrames + 1
	dec [hl]
	jr nz, .skip
	dec hl
	dec [hl]
	jr nz, .skip
	pop hl
	xor a
	jmp SerialDisconnected

.skip
	pop hl

.check
	ld a, [wOtherPlayerLinkAction]
	inc a
	jr z, .loop

	vc_patch Wireless_net_delay_1
if DEF(VIRTUAL_CONSOLE)
	ld b, 26
else
	ld b, 10
endc
	vc_patch_end
.receive
	call DelayFrame
	call LinkTransfer
	dec b
	jr nz, .receive

	vc_patch Wireless_net_delay_2
if DEF(VIRTUAL_CONSOLE)
	ld b, 26
else
	ld b, 10
endc
	vc_patch_end
.acknowledge
	call DelayFrame
	call LinkDataReceived
	dec b
	jr nz, .acknowledge

	ld a, [wOtherPlayerLinkAction]
	ld [wOtherPlayerLinkMode], a
	vc_hook Wireless_WaitLinkTransfer_ret
	ret
