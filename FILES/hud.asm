// =============================================================
// hud.asm  -  HUD, menu text, victory screen drawing.
// =============================================================
#importonce
#import "vars.asm"
#import "map.asm"

// -------------------------------------------------------------
// DrawDecor  -  no-op now that the CharPad map provides all
//               background scenery.  Kept as a stub so callers
//               don't need updating.
// -------------------------------------------------------------
DrawDecor: {
    rts
}

// -------------------------------------------------------------
// DrawHud  -  top status bar using game charset slots 72-80
//   No charset switching needed - ROM letter shapes were copied
//   into our game charset by CopyRomCharsToGameset at startup.
// -------------------------------------------------------------
DrawHud: {
    // blank top row with space slot
    ldx #39
!clr:
    lda #HUD_SLOT_SPC; sta SCREEN_RAM,x
    lda #$00; sta COLOR_RAM,x
    dex
    bpl !clr-

    // "BALLOON" = B,A,L,L,O,O,N
    lda #HUD_SLOT_B; sta SCREEN_RAM+0
    lda #HUD_SLOT_A; sta SCREEN_RAM+1
    lda #HUD_SLOT_L; sta SCREEN_RAM+2
    lda #HUD_SLOT_L; sta SCREEN_RAM+3
    lda #HUD_SLOT_O; sta SCREEN_RAM+4
    lda #HUD_SLOT_O; sta SCREEN_RAM+5
    lda #HUD_SLOT_N; sta SCREEN_RAM+6
    ldx #0
!col_b:
    lda #$07; sta COLOR_RAM,x   // yellow
    inx; cpx #7; bne !col_b-

    // balloon life pips
    ldx #0
!pips_b:
    cpx lives_ball
    bcs !empty_b+
    lda #HUD_SLOT_PIP
    jmp !set_b+
!empty_b:
    lda #HUD_SLOT_SPC
!set_b:
    sta SCREEN_RAM+8,x
    lda #$07; sta COLOR_RAM+8,x
    inx; cpx #5; bne !pips_b-

    // tank life pips
    ldx #0
!pips_t:
    cpx lives_tank
    bcs !empty_t+
    lda #HUD_SLOT_PIP
    jmp !set_t+
!empty_t:
    lda #HUD_SLOT_SPC
!set_t:
    sta SCREEN_RAM+29,x
    lda #$05; sta COLOR_RAM+29,x
    inx; cpx #5; bne !pips_t-

    // "TANK" = T,A,N,K
    lda #HUD_SLOT_T; sta SCREEN_RAM+35
    lda #HUD_SLOT_A; sta SCREEN_RAM+36
    lda #HUD_SLOT_N; sta SCREEN_RAM+37
    lda #HUD_SLOT_K; sta SCREEN_RAM+38
    ldx #0
!col_t:
    lda #$05; sta COLOR_RAM+35,x  // green
    inx; cpx #4; bne !col_t-

    rts
}

// -------------------------------------------------------------
// DrawMenuText  -  "BALLOON FIGHT" title centred on screen
// -------------------------------------------------------------
DrawMenuText: {
    ldx #0
!loop:
    lda txt_title,x
    sta SCREEN_RAM+493,x
    lda #$01; sta COLOR_RAM+493,x
    inx; cpx #13; bne !loop-
    rts
}

// -------------------------------------------------------------
// CycleTitleColors  -  rainbow scroll over menu title
// -------------------------------------------------------------
CycleTitleColors: {
    inc color_idx
    lda color_idx
    and #$07
    sta color_idx
    ldx #0
!loop:
    txa
    clc
    adc color_idx
    and #$07
    tay
    lda rainbow_table,y
    sta COLOR_RAM+493,x
    inx; cpx #13; bne !loop-
    rts
}

// -------------------------------------------------------------
// DrawVictoryScreen  -  show winner text and position sprite
// -------------------------------------------------------------
DrawVictoryScreen: {
    jsr UseRomCharset       // text uses ROM charset
    jsr KRNL_CLRSCN
    lda #0; sta VIC_BG
    ldx #0
    lda winner; cmp #1; beq !balloon_wins+

!tank_wins:
    lda txt_tank_wins,x
    sta SCREEN_RAM+495,x
    lda #$05; sta COLOR_RAM+495,x
    inx; cpx #9; bne !tank_wins-
    lda #%00000100; sta VIC_ENABLE
    lda #175; sta SPR2_X
    lda #115; sta SPR2_Y
    rts

!balloon_wins:
    lda txt_ball_wins,x
    sta SCREEN_RAM+494,x
    lda #$07; sta COLOR_RAM+494,x
    inx; cpx #12; bne !balloon_wins-
    lda #%00000001; sta VIC_ENABLE
    lda #175; sta SPR0_X
    lda #115; sta SPR0_Y
    rts
}

// =============================================================
// DATA
// =============================================================
rainbow_table:  .byte 2,10,7,1,3,14,6,4

mnt_chars:
    .byte 78,160,77, 78,160,160,77, 78,160,160,160,77
    .byte 160,160,160,160,160, 160,160,160,160,160
    .byte 160,160,160,160,160, 0
mnt_offsets:
    .word 330,331,332, 369,370,371,372, 408,409,410,411,412
    .word 448,449,450,451,452, 488,489,490,491,492
    .word 528,529,530,531,532, 568,569,570,571,572
mnt_colors:
    .byte $01,$01,$01, $01,$0f,$0f,$01, $0f,$0f,$0f,$0f,$0f
    .byte $0f,$0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f,$0f
    .byte $0f,$0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f,$0f

txt_title:      .byte 2,1,12,12,15,15,14,32,6,9,7,8,20
txt_balloon:    .byte 2,1,12,12,15,15,14
txt_tank:       .byte 20,1,14,11
txt_ball_wins:  .byte 2,1,12,12,15,15,14,32,23,9,14,19
txt_tank_wins:  .byte 20,1,14,11,32,23,9,14,19
