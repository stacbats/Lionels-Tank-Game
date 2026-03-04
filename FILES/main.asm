// =============================================================
// main.asm  -  Entry point, init, and master game loop.
//
// Module layout
// ─────────────
//   vars.asm     → shared constants and zero-page labels
//   sprites.asm  → sprite pixel data + copy/setup routines
//   sound.asm    → SFX and SOS melody
//   hud.asm      → HUD, menu text, victory screen
//   physics.asm  → controls, movement, collision, explosion
//   map.asm      → CharPad binary loader + DrawMap
// =============================================================

// --- Constants & labels must be defined before use ----------
#import "vars.asm"

// --- BASIC stub at $0801: SYS 2061 → jumps to GameInit ------
// BasicUpstart2 MUST be the first thing that emits bytes.
:BasicUpstart2(GameInit)

// --- All module code/data goes here, after the BASIC stub ---
* = $0810 "Main Code"

#import "sprites.asm"
#import "sound.asm"
#import "hud.asm"
#import "physics.asm"
#import "map.asm"

// =============================================================
// GameInit  -  cold start; called by BASIC SYS
// =============================================================
GameInit:
    sei
    lda #$00; sta VIC_IRQMASK   // ensure VIC raster IRQ is off
    lda #$01; sta VIC_IRQFLAG   // clear any pending VIC IRQ flag
    lda #$31; sta IRQ_VEC       // restore KERNAL IRQ vector
    lda #$ea; sta IRQ_VEC_HI
    cli

    jsr KRNL_CLRSCN

    // zero all game variables
    lda #0
    sta game_state
    sta is_dropping
    sta tank_fire
    sta sos_timer
    sta sos_step
    sta color_idx
    sta dir_ball
    lda #1; sta dir_tank

    jsr SoundInit           // SID: full volume, gate off
    jsr CopySpritesToMem    // blit sprite pixel data to $2000
    jsr LoadCharset         // copy Chars.bin → $2800, set VIC_MEMCTRL=$1A
    jsr CopyRomCharsToGameset // copy A,B,K,L,N,O,T,pip into slots 72-80
    jsr UseRomCharset       // switch back to ROM charset for menu text

    lda #0; sta VIC_BORDER; sta VIC_BG

    // show menu
    jsr KRNL_CLRSCN
    jsr DrawMenuText
    jsr SetSpritePtrs_Menu
    jsr SetSpriteColors_Menu

    lda #GS_MENU; sta game_state

    lda #24;  sta SPR0_X
    lda #60;  sta SPR0_Y
    lda #250; sta SPR2_X
    lda #220; sta SPR2_Y
    lda #%00000101; sta VIC_ENABLE

    cli

// =============================================================
// GameLoop  -  runs every raster line 250 tick (≈50 Hz)
// =============================================================
GameLoop:
!wait:
    lda RASTER
    cmp #200            // wait for line 200 - safely below raster IRQ lines (49/56)
    bne !wait-

    lda game_state
    cmp #GS_PLAY;    beq !do_play+
    cmp #GS_MENU;    beq !do_menu+
    cmp #GS_VICTORY; beq !do_victory+
    // GS_EXPL_BALL or GS_EXPL_TANK
    jsr AnimateExplosion
    jmp GameLoop

!do_play:
    jsr PlayGame
    jmp GameLoop

!do_menu:
    jsr MenuLogic
    jmp GameLoop

!do_victory:
    jsr VictoryCountdown
    jmp GameLoop

// =============================================================
// PlayGame  -  one tick of active gameplay
// =============================================================
PlayGame: {
    jsr HandleCollisions
    lda game_state
    cmp #GS_PLAY
    bne !done+
    jsr HandleControls
    jsr UpdatePhysics
!done:
    rts
}

// =============================================================
// MenuLogic  -  animate demo sprites + wait for fire button
// =============================================================
MenuLogic: {
    jsr CycleTitleColors

    lda dir_ball
    bne !ball_left+
    inc SPR0_X
    lda SPR0_X; cmp #250; bne !tank_move+
    lda #1; sta dir_ball; jmp !tank_move+
!ball_left:
    dec SPR0_X
    lda SPR0_X; cmp #24; bne !tank_move+
    lda #0; sta dir_ball

!tank_move:
    lda dir_tank
    bne !tank_left+
    inc SPR2_X
    lda SPR2_X; cmp #250; bne !sos+
    lda #1; sta dir_tank; jmp !sos+
!tank_left:
    dec SPR2_X
    lda SPR2_X; cmp #24; bne !sos+
    lda #0; sta dir_tank

!sos:
    jsr PlaySos

    lda JOY1; and #%00010000; beq !start+
    lda JOY2; and #%00010000; beq !start+
    rts
!start:
    jsr StartGame
    rts
}

// =============================================================
// StartGame  -  menu → first round
// =============================================================
StartGame: {
    jsr SoundOff
    lda #0; sta VIC_ENABLE

    lda #5; sta lives_ball
    lda #5; sta lives_tank

    lda #0
    sta game_state
    sta is_dropping
    sta tank_fire

    lda #$06; sta VIC_BG

    jsr KRNL_CLRSCN
    jsr UseGameCharset      // game charset active for map tiles
    jsr DrawMap
    jsr DrawDecor
    jsr DrawHud

    jsr SetSpritePtrs_Play
    jsr SetSpriteColors_Play

    lda #160; sta SPR0_X
    lda #60;  sta SPR0_Y
    lda #160; sta SPR2_X
    lda #220; sta SPR2_Y

    lda #%00000101; sta VIC_ENABLE
    lda S_COLLISION         // clear stale collision latch
    rts
}

// =============================================================
// GameRestart  -  called by VictoryCountdown when timer hits 0
// =============================================================
GameRestart:
    jmp GameInit
