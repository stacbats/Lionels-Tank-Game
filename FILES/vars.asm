// =============================================================
// vars.asm  -  Shared constants, zero-page labels & VIC/SID
//              addresses used across all modules.
//              #importonce ensures this is only processed once
//              even when pulled in by multiple modules.
// =============================================================
#importonce

// --- KERNAL ---
.const KRNL_CLRSCN   = $e544

// --- VIC-II ---
.const SCREEN_RAM    = $0400
.const COLOR_RAM     = $d800
.const VIC_ENABLE    = $d015
.const VIC_SPR_BG    = $d01b   // sprite-background priority: 0=sprite in front
.const RASTER        = $d012
.const VIC_CTRL1     = $d011   // bit 7 = raster line bit 8
.const VIC_IRQFLAG   = $d019   // VIC IRQ status (write 1 to acknowledge)
.const VIC_IRQMASK   = $d01a   // VIC IRQ enable mask
.const CIA1_ICR      = $dc0d   // CIA1 interrupt control (disable timer IRQs)
.const IRQ_VEC       = $0314   // KERNAL IRQ vector (lo)
.const IRQ_VEC_HI    = $0315   // KERNAL IRQ vector (hi)
.const S_COLLISION   = $d01e
.const VIC_BORDER    = $d020
.const VIC_BG        = $d021
.const VIC_SPR_COL   = $d025   // sprite multicolour 1
.const VIC_MEMCTRL   = $d018   // VIC memory bank / charset ptr
.const MEMCTRL_ROM   = $15     // screen=$0400, VIC reads built-in ROM charset
.const MEMCTRL_GAME  = $1a     // screen=$0400, charset=$2800 (our CharPad chars)

// --- JOYSTICKS ---
.const JOY1          = $dc01
.const JOY2          = $dc00

// --- SPRITE DATA DESTINATIONS (6 × 64-byte blocks at $2000) ---
.const BALLOON_DATA  = $2000   // block 128
.const SHELL_DATA    = $2040   // block 129
.const TANK_DATA     = $2080   // block 130
.const EXPL_F1       = $20c0   // block 131
.const EXPL_F2       = $2100   // block 132
.const EXPL_F3       = $2140   // block 133

// --- SPRITE POINTERS (screen-RAM top) ---
.const BALLOON_PTR   = $07f8
.const SHELL_PTR     = $07f9
.const TANK_PTR      = $07fa
.const TANK_SH_PTR   = $07fb

// --- SPRITE HARDWARE REGISTERS ---
.const SPR0_X        = $d000
.const SPR0_Y        = $d001
.const SPR1_X        = $d002
.const SPR1_Y        = $d003
.const SPR2_X        = $d004
.const SPR2_Y        = $d005
.const SPR3_X        = $d006
.const SPR3_Y        = $d007

// --- SID ---
.const SID_V1_FREQ_L = $d400
.const SID_V1_FREQ_H = $d401
.const SID_V1_CTRL   = $d404
.const SID_V1_AD     = $d405
.const SID_V1_SR     = $d406
.const SID_VOLUME    = $d418

// =============================================================
// ZERO-PAGE VARIABLES
// All game modules share this layout - do not duplicate.
// =============================================================
.label is_dropping    = $02   // 1 = balloon bomb falling
.label tank_fire      = $04   // 1 = tank shell active
.label expl_timer     = $05   // explosion frame countdown
.label game_state     = $06   // 0=play 1=b_expl 2=t_expl 3=victory 4=menu
.label col_val        = $07   // sprite collision scratch
.label lives_ball     = $08
.label lives_tank     = $09
.label winner         = $0a   // 1=balloon 2=tank
.label dir_ball       = $0b   // menu demo direction
.label dir_tank       = $0c
.label sos_timer      = $0d
.label sos_step       = $0e
.label color_idx      = $0f
.label victory_timer  = $10

// --- GAME STATES (named constants for readability) ---
.const GS_PLAY        = 0
.const GS_EXPL_BALL   = 1
.const GS_EXPL_TANK   = 2
.const GS_VICTORY     = 3
.const GS_MENU        = 4
