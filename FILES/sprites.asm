// =============================================================
// sprites.asm  -  Sprite pixel data + copy routine.
//                 Call CopySpritesToMem once at startup.
// =============================================================
#importonce
#import "vars.asm"

// -------------------------------------------------------------
// CopySpritesToMem
//   Copies all 6 sprite blocks (each 64 bytes) to their fixed
//   memory locations starting at BALLOON_DATA ($2000).
// -------------------------------------------------------------
CopySpritesToMem: {
    ldx #0
!loop:
    lda balloon_data,x
    sta BALLOON_DATA,x
    lda common_shell_data,x
    sta SHELL_DATA,x
    lda tank_sprite_data,x
    sta TANK_DATA,x
    lda exp_f1_data,x
    sta EXPL_F1,x
    lda exp_f2_data,x
    sta EXPL_F2,x
    lda exp_f3_data,x
    sta EXPL_F3,x
    inx
    cpx #64
    bne !loop-
    rts
}

// -------------------------------------------------------------
// SetSpritePtrs_Play  -  point hardware to in-game sprites
// SetSpritePtrs_Menu  -  point hardware to menu demo sprites
// -------------------------------------------------------------
SetSpritePtrs_Play: {
    lda #128; sta BALLOON_PTR
    lda #129; sta SHELL_PTR
    lda #130; sta TANK_PTR
    lda #129; sta TANK_SH_PTR
    lda #0;   sta VIC_SPR_BG   // all sprites in front of background
    rts
}

SetSpritePtrs_Menu: {
    lda #128; sta BALLOON_PTR
    lda #130; sta TANK_PTR
    lda #0;   sta VIC_SPR_BG   // all sprites in front of background
    rts
}

// -------------------------------------------------------------
// SetSpriteColors_Play  -  yellow balloon, white shell, green tank
// SetSpriteColors_Menu  -  same palette for demo
// -------------------------------------------------------------
SetSpriteColors_Play: {
    lda #$07; sta $d027   // spr0 balloon = yellow
    lda #$01; sta $d028   // spr1 shell   = white
    lda #$0c; sta $d029   // spr2 tank    = green
    lda #$01; sta $d02a   // spr3 tank sh = white
    rts
}

SetSpriteColors_Menu: {
    lda #$07; sta $d027
    lda #$0c; sta $d029
    rts
}

// =============================================================
// RAW SPRITE PIXEL DATA  (each block padded to exactly 64 bytes)
// =============================================================

.align $40
balloon_data:
.byte $00,$7E,$00,$01,$9F,$80,$03,$3F,$C0,$02,$7E,$C0,$06,$FF,$60,$07
.byte $FF,$E0,$06,$FF,$60,$07,$FF,$E0,$07,$FF,$E0,$06,$FF,$E0,$03,$7F
.byte $C0,$03,$FF,$C0,$01,$7E,$80,$01,$3C,$80,$00,$99,$00,$00,$42,$00
.byte $00,$42,$00,$00,$00,$00,$00,$5A,$00,$00,$7E,$00,$00,$3C,$00,$07




    // .byte $00,$7e,$00,$01,$ff,$80,$03,$ff,$c0,$07,$18,$e0
    // .byte $0f,$18,$f0,$0f,$18,$f0,$0f,$18,$f0,$07,$00,$e0
    // .byte $0f,$ff,$f0,$0f,$ff,$f0,$05,$ff,$a0,$04,$ff,$20
    // .byte $04,$18,$20,$02,$18,$40,$02,$18,$40,$01,$18,$80
    // .byte $01,$18,$80,$00,$3c,$00,$00,$3c,$00,$00,$3c,$00
    // .byte $00,$18,$00,$00

.align $40
common_shell_data:
    .byte $00,$18,$00,$00,$3c,$00,$00,$3c,$00,$00,$3c,$00
    .byte $00,$3c,$00,$00,$18,$00
    .fill 64-18, 0

.align $40
tank_sprite_data:
.byte $00,$3C,$00,$00,$5A,$00,$00,$24,$00,$00,$18,$00,$00,$18,$00,$00
.byte $18,$00,$03,$99,$C0,$04,$FF,$20,$0B,$DB,$D0,$0F,$3C,$F0,$06,$DB
.byte $60,$0E,$DB,$70,$06,$FF,$60,$0E,$BD,$70,$06,$BD,$60,$0E,$E7,$70
.byte $07,$7E,$E0,$0F,$81,$F0,$0B,$FF,$D0,$0D,$FF,$B0,$07,$99,$E0,$0B



    // .byte $00,$18,$00,$00,$18,$00,$00,$18,$00,$01,$ff,$80
    // .byte $03,$ff,$c0,$03,$ff,$c0,$07,$ff,$e0,$07,$ff,$e0
    // .byte $07,$ff,$e0,$0f,$ff,$f0,$0f,$ff,$f0,$0f,$ff,$f0
    // .byte $0f,$00,$f0,$0f,$00,$f0,$0f,$00,$f0,$0f,$ff,$f0
    // .byte $0f,$ff,$f0,$07,$ff,$e0
    // .fill 64-54, 0

.align $40
exp_f1_data:
    .byte $00,$3c,$00,$00,$7e,$00,$00,$ff,$00,$01,$ff,$80
    .byte $01,$ff,$80,$00,$ff,$00,$00,$7e,$00,$00,$3c,$00
    .fill 64-24, 0

.align $40
exp_f2_data:
    .byte $18,$3c,$18,$3c,$7e,$3c,$7e,$ff,$7e,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$7e,$ff,$7e,$3c,$7e,$3c,$18,$3c,$18
    .fill 64-24, 0

.align $40
exp_f3_data:
    .byte $81,$00,$81,$00,$42,$00,$24,$00,$24,$00,$18,$00
    .byte $00,$18,$00,$24,$00,$24,$00,$42,$00,$81,$00,$81
    .fill 64-24, 0
