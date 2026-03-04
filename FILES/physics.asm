// =============================================================
// physics.asm  -  Collision detection, sprite movement,
//                 controls and explosion animation logic.
//
// Depends on: vars.asm, sound.asm, hud.asm, map.asm, sprites.asm
// =============================================================
#importonce
#import "vars.asm"
#import "sprites.asm"
#import "sound.asm"
#import "hud.asm"
#import "map.asm"

// -------------------------------------------------------------
// HandleCollisions  -  check sprite-sprite collision register
//   Returns with Z=1 if no collision (caller can skip logic).
// -------------------------------------------------------------
HandleCollisions: {
    lda S_COLLISION
    sta col_val
    beq !none+

    // shell hit tank  (sprites 1+2 = bits 2+3 = %00001100... wait,
    //   bit mask: spr1=bit1 spr2=bit2 spr3=bit3)
    //   tank(spr2) + shell(spr1)  -> bits 1&2 set = %00000110
    and #%00000110
    cmp #%00000110
    beq !tank_hit+

    lda col_val
    and #%00001001          // balloon(spr0) + tank_shell(spr3) -> bits 0&3
    cmp #%00001001
    beq !ball_hit+

    lda col_val
    and #%00001010          // balloon(spr0+bit0 ... or shell spr1+spr3?)
    cmp #%00001010          // close-contact collision
    beq !cc_hit+

    // no matching collision
!none:
    rts                     // Z=1 on rts when beq not taken means no action

!tank_hit:
    dec lives_tank
    lda #GS_EXPL_TANK; sta game_state
    lda #45;           sta expl_timer
    jsr SfxExplosion
    lda #0; sta is_dropping; sta tank_fire
    lda VIC_ENABLE; and #%11110101; sta VIC_ENABLE
    rts

!ball_hit:
    dec lives_ball
    lda #GS_EXPL_BALL; sta game_state
    lda #45;           sta expl_timer
    jsr SfxExplosion
    lda #0; sta is_dropping; sta tank_fire
    lda VIC_ENABLE; and #%11110101; sta VIC_ENABLE
    rts

!cc_hit:
    lda #0; sta is_dropping; sta tank_fire
    jsr SfxExplosion
    lda VIC_ENABLE; and #%11110101; sta VIC_ENABLE
    rts
}

// -------------------------------------------------------------
// HandleControls  -  read both joysticks and update sprites
// -------------------------------------------------------------
HandleControls: {
    // --- Joystick 1: move balloon left/right + drop bomb ---
    lda JOY1
    and #%00000100          // left
    bne !j1_r+
    dec SPR0_X
!j1_r:
    lda JOY1
    and #%00001000          // right
    bne !j1_fire+
    inc SPR0_X
!j1_fire:
    lda JOY1
    and #%00010000          // fire
    bne !j2+
    lda is_dropping
    bne !j2+
    lda #1; sta is_dropping
    lda VIC_ENABLE; ora #%00000010; sta VIC_ENABLE
    jsr SfxBalloon

    // --- Joystick 2: move tank left/right + fire shell ---
!j2:
    lda JOY2
    and #%00000100          // left
    bne !j2_r+
    dec SPR2_X
!j2_r:
    lda JOY2
    and #%00001000          // right
    bne !j2_fire+
    inc SPR2_X
!j2_fire:
    lda JOY2
    and #%00010000          // fire
    bne !done+
    lda tank_fire; bne !done+
    lda #1; sta tank_fire
    lda SPR2_X; sta SPR3_X
    lda #210;   sta SPR3_Y
    lda VIC_ENABLE; ora #%00001000; sta VIC_ENABLE
    jsr SfxTank
!done:
    rts
}

// -------------------------------------------------------------
// UpdatePhysics  -  move bomb down, shell up, sync positions
// -------------------------------------------------------------
UpdatePhysics: {
    // bomb falls
    lda is_dropping
    beq !sync_bomb+
    inc SPR1_Y
    lda SPR1_Y
    cmp #250
    bcc !tank_shell+
    // bomb hit ground
    lda #0; sta is_dropping
    lda VIC_ENABLE; and #%11111101; sta VIC_ENABLE

    // bomb always tracks balloon X
!sync_bomb:
    lda SPR0_X; sta SPR1_X
    lda SPR0_Y; clc; adc #21; sta SPR1_Y

    // tank shell rises
!tank_shell:
    lda tank_fire
    beq !sync_shell+
    dec SPR3_Y
    dec SPR3_Y
    lda SPR3_Y
    cmp #30
    bcs !done+
    // shell off top
    lda #0; sta tank_fire
    lda VIC_ENABLE; and #%11110111; sta VIC_ENABLE
    rts

    // shell always tracks tank X
!sync_shell:
    lda SPR2_X; sta SPR3_X
    lda SPR2_Y; sta SPR3_Y
!done:
    rts
}

// -------------------------------------------------------------
// AnimateExplosion  -  cycle through 3 explosion frames then
//                      either resume play or show victory.
//   Called by the main loop when game_state = GS_EXPL_*
// -------------------------------------------------------------
AnimateExplosion: {
    lda expl_timer
    cmp #30; bcs !f1+
    cmp #15; bcs !f2+
    jmp !f3+
!f1:
    lda #131; jmp !apply+
!f2:
    lda #132; jmp !apply+
!f3:
    lda #133
!apply:
    ldx game_state
    cpx #GS_EXPL_BALL
    beq !balloon+
    sta TANK_PTR
    jmp !tick+
!balloon:
    sta BALLOON_PTR
!tick:
    dec expl_timer
    bne !done+

    // explosion finished
    jsr SoundOff
    jsr KRNL_CLRSCN

    lda lives_ball; beq !tank_wins+
    lda lives_tank; beq !ball_wins+

    // both still alive - resume round
    lda #GS_PLAY; sta game_state
    jsr UseGameCharset
    jsr DrawMap
    jsr DrawDecor
    jsr DrawHud
    jsr SetSpritePtrs_Play
    jsr SetSpriteColors_Play
    lda #%00000101; sta VIC_ENABLE
    rts

!tank_wins:
    lda #2; sta winner
    jmp !show_victory+
!ball_wins:
    lda #1; sta winner
!show_victory:
    lda #GS_VICTORY;   sta game_state
    lda #250;          sta victory_timer
    jsr DrawVictoryScreen
!done:
    rts
}

// -------------------------------------------------------------
// VictoryCountdown  -  wait then restart
// -------------------------------------------------------------
VictoryCountdown: {
    dec victory_timer
    lda victory_timer
    bne !done+
    lda #0
    sta VIC_ENABLE
    jsr SoundOff
    jmp GameRestart     // forward ref → defined in main.asm, resolves at link time
!done:
    rts
}
