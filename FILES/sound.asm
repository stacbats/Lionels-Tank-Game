// =============================================================
// sound.asm  -  All SFX and SOS melody routines.
// =============================================================
#importonce
#import "vars.asm"

// -------------------------------------------------------------
// SfxBalloon  -  high-pitched drop tone
// SfxTank     -  lower fire tone
// SfxExplosion - short noise burst with decay
// -------------------------------------------------------------
SfxBalloon: {
    lda #$00; sta SID_V1_CTRL
    lda #$20; sta SID_V1_FREQ_H
    lda #$11; sta SID_V1_CTRL
    rts
}

SfxTank: {
    lda #$00; sta SID_V1_CTRL
    lda #$08; sta SID_V1_FREQ_H
    lda #$81; sta SID_V1_CTRL
    rts
}

SfxExplosion: {
    lda #$00; sta SID_V1_CTRL
    lda #$05; sta SID_V1_FREQ_H
    lda #$0f; sta SID_V1_AD
    lda #$44; sta SID_V1_SR
    lda #$81; sta SID_V1_CTRL
    rts
}

// -------------------------------------------------------------
// SoundInit  -  max volume, gate off
// SoundOff   -  silence (gate off only)
// -------------------------------------------------------------
SoundInit: {
    lda #15; sta SID_VOLUME
    lda #0;  sta SID_V1_CTRL
    rts
}

SoundOff: {
    lda #0; sta SID_V1_CTRL
    rts
}

// -------------------------------------------------------------
// PlaySos  -  Morse S-O-S looping background melody.
//             Call once per game-loop tick from menu state.
// -------------------------------------------------------------
PlaySos: {
    lda sos_timer
    beq !next+
    dec sos_timer
    rts
!next:
    ldx sos_step
    lda sos_data,x
    cmp #$ff
    bne !set+
    ldx #0               // wrap back to start
    stx sos_step
    lda sos_data,x
!set:
    sta sos_timer
    txa
    and #$01
    bne !stop+
    // even step = tone on
    lda #$00; sta SID_V1_FREQ_L
    lda #$45; sta SID_V1_FREQ_H
    lda #$11; sta SID_V1_CTRL
    jmp !done+
!stop:
    lda #$10; sta SID_V1_CTRL
!done:
    inc sos_step
    rts
}

// =============================================================
// DATA
// =============================================================
sos_data:
    // S  (3 short)       O  (3 long)       S  (3 short)   end
    .byte 5,5, 5,5, 5,15, 15,5, 15,5, 15,15, 5,5, 5,5, 5,60, $ff
