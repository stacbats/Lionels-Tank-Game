// =============================================================
// map.asm  -  CharPad map loader, tile expander & charset copy.
//
// Backdrop project dimensions (from .bin file sizes):
//   Charset:  72 chars   (576 bytes  = 72 × 8 bytes per char)
//   Tiles:    18 tiles   (72 bytes   = 18 × 4, each tile is 2×2 chars)
//   Map:      20×12 tile cells (240 bytes, tile indices 0-17)
//   Screen:   40×24 chars after expansion (row 0 = HUD, rows 1-24 = map)
//   Attribs:  72 bytes, low nibble = VIC colour per char
//
// Charset is copied to $2800 (VIC block 5, real RAM in bank 0).
// $1000-$1FFF and $3000-$3FFF are VIC character ROM shadows - do NOT use.
// Sprites end at $2180, so $2800-$2A3F (576 bytes) is safe.
//
// HOW TO USE - in main.asm:
//   1. Keep:  #import "map.asm"
//   2. In GameInit: jsr LoadCharset   (once only - redirects VIC charset)
//   3. In StartGame: jsr DrawMap      (each new round, after KRNL_CLRSCN)
// =============================================================
#importonce
#import "vars.asm"

.const CHARSET_ADDR  = $2800   // destination for 576 bytes of char data
                               // $2800 = VIC block 5 in bank 0 ($2000-$2FFF is real RAM)
                               // Sprites end at $2180, so $2800-$2A3F is safe

.const MAP_COLS      = 20      // map width  in tiles
.const MAP_ROWS      = 12      // map height in tiles
.const SCR_COLS      = 40      // MAP_COLS * 2  (each tile = 2 chars wide)

// Zero-page pointer pairs used by DrawMap
.label scr_ptr_lo    = $fa
.label scr_ptr_hi    = $fb
.label col_ptr_lo    = $fc
.label col_ptr_hi    = $fd

// =============================================================
// LoadCharset
//   Copies 576 bytes of char pixel data to CHARSET_ADDR ($2800).
//   Sets VIC_MEMCTRL: screen=$0400, charset=$2800 ($1A).
// =============================================================
LoadCharset: {
    // 576 bytes = 2 full 256-byte pages + 64 extra bytes
    ldx #0
!p0:
    lda charset_src_data,x
    sta CHARSET_ADDR,x
    inx
    bne !p0-
!p1:
    lda charset_src_data+$100,x
    sta CHARSET_ADDR+$100,x
    inx
    bne !p1-
    // last 64 bytes
    ldx #0
!p2:
    lda charset_src_data+$200,x
    sta CHARSET_ADDR+$200,x
    inx
    cpx #64
    bne !p2-

    // VIC_MEMCTRL = (screen_block << 4) | (charset_block << 1)
    //   Screen  at $0400 → block 1 → 1<<4 = $10
    //   Charset at $2800 → block 5 → 5<<1 = $0A
    //   Result  = $1A
    //
    // NOTE: $3000-$3FFF in VIC bank 0 is a CHARACTER ROM shadow —
    //       VIC reads ROM there regardless of what you write to RAM.
    //       $2800 is real RAM and fully visible to VIC.
    lda #$1a
    sta VIC_MEMCTRL
    rts
}

// =============================================================
// CopyRomCharsToGameset
//   Copies 9 specific ROM chars into game charset slots 72-80.
//   After this, HUD can write slot numbers to screen RAM and
//   the chars render correctly through the game charset — no
//   charset switching needed during gameplay.
//
//   ROM charset: CPU address $E000 (visible when KERNAL mapped in,
//   which is the default: $01 = $37).  Each char = 8 bytes.
//
//   Slot map (written into CHARSET_ADDR + slot*8):
//     72=A  73=B  74=K  75=L  76=N  77=O  78=T  79=pip($51)  80=space
// =============================================================
.const HUD_SLOT_A     = 72
.const HUD_SLOT_B     = 73
.const HUD_SLOT_K     = 74
.const HUD_SLOT_L     = 75
.const HUD_SLOT_N     = 76
.const HUD_SLOT_O     = 77
.const HUD_SLOT_T     = 78
.const HUD_SLOT_PIP   = 79
.const HUD_SLOT_SPC   = 80

CopyRomCharsToGameset: {
    // Char ROM is at CPU $D000 but hidden behind I/O by default.
    // Set $01 = $31 to disable I/O and expose char ROM at $D000.
    // Restore $01 = $37 afterwards.
    sei                         // no IRQs while I/O is off (SID/VIC inaccessible)
    lda #$31; sta $01           // I/O off → char ROM visible at $D000

    ldx #0
!copy_A:
    lda $d008,x                 // A = char 1, $D000 + 1*8
    sta CHARSET_ADDR + HUD_SLOT_A * 8,x
    inx; cpx #8; bne !copy_A-

    ldx #0
!copy_B:
    lda $d010,x                 // B = char 2, $D000 + 2*8
    sta CHARSET_ADDR + HUD_SLOT_B * 8,x
    inx; cpx #8; bne !copy_B-

    ldx #0
!copy_K:
    lda $d058,x                 // K = char 11, $D000 + 11*8
    sta CHARSET_ADDR + HUD_SLOT_K * 8,x
    inx; cpx #8; bne !copy_K-

    ldx #0
!copy_L:
    lda $d060,x                 // L = char 12, $D000 + 12*8
    sta CHARSET_ADDR + HUD_SLOT_L * 8,x
    inx; cpx #8; bne !copy_L-

    ldx #0
!copy_N:
    lda $d070,x                 // N = char 14, $D000 + 14*8
    sta CHARSET_ADDR + HUD_SLOT_N * 8,x
    inx; cpx #8; bne !copy_N-

    ldx #0
!copy_O:
    lda $d078,x                 // O = char 15, $D000 + 15*8
    sta CHARSET_ADDR + HUD_SLOT_O * 8,x
    inx; cpx #8; bne !copy_O-

    ldx #0
!copy_T:
    lda $d0a0,x                 // T = char 20, $D000 + 20*8
    sta CHARSET_ADDR + HUD_SLOT_T * 8,x
    inx; cpx #8; bne !copy_T-

    ldx #0
!copy_pip:
    lda $d288,x                 // pip $51=81, $D000 + 81*8 = $D288
    sta CHARSET_ADDR + HUD_SLOT_PIP * 8,x
    inx; cpx #8; bne !copy_pip-

    lda #$37; sta $01           // restore: I/O back on
    cli

    // slot 80 = space: 8 zero bytes (blank)
    ldx #0
!copy_spc:
    lda #0
    sta CHARSET_ADDR + HUD_SLOT_SPC * 8,x
    inx; cpx #8; bne !copy_spc-

    rts
}

// =============================================================
// UseRomCharset  -  switch VIC to built-in ROM character set.
//   Call this before drawing any PETSCII text (menus, HUD, etc.)
//   The C64 ROM charset is always in ROM at $E000/$E800 and is
//   automatically visible to VIC as "block 2" in bank 0.
// =============================================================
UseRomCharset: {
    lda #MEMCTRL_ROM        // $15: screen=$0400, charset=ROM
    sta VIC_MEMCTRL
    rts
}

// =============================================================
// UseGameCharset  -  switch VIC back to our CharPad charset at $2800.
//   Call this after text drawing is done, before rendering a game frame.
// =============================================================
UseGameCharset: {
    lda #MEMCTRL_GAME       // $1A: screen=$0400, charset=$2800
    sta VIC_MEMCTRL
    rts
}

// =============================================================
// DrawMap
//   Expands the 20×12 tile map onto screen+colour RAM.
//   Each tile is 2×2 chars. Row 0 (HUD) is untouched.
//
//   Loop body is too large for bne, so we use jmp for back-branch
//   and a jsr DrawCell subroutine to keep things readable.
// =============================================================
DrawMap: {
    lda #0; sta $fe         // $fe = cell index (0..239)
!loop:
    ldx $fe
    jsr DrawCell            // draw one tile
    inc $fe
    lda $fe
    cmp #(MAP_COLS * MAP_ROWS)
    bne !loop-              // bne is fine here - only 8 bytes back
    rts
}

// -------------------------------------------------------------
// DrawCell  -  draw one 2×2 tile at cell index in $fe
//   Reads:  map_data[$fe] → tile index → 4 chars from tile_data
//   Writes: chars + colours to screen/colour RAM via tables
// -------------------------------------------------------------
DrawCell: {
    ldx $fe

    // fetch 4 char indices for this tile
    lda map_data,x
    asl                     // tile_index × 4
    asl
    tay
    lda tile_data,y;   sta $f6   // top-left  char
    lda tile_data+1,y; sta $f7   // top-right char
    lda tile_data+2,y; sta $f8   // bot-left  char
    lda tile_data+3,y; sta $f9   // bot-right char

    // load screen & colour pointers for this cell
    lda scr_tbl_lo,x; sta scr_ptr_lo
    lda scr_tbl_hi,x; sta scr_ptr_hi
    lda col_tbl_lo,x; sta col_ptr_lo
    lda col_tbl_hi,x; sta col_ptr_hi

    // top row
    ldy #0
    lda $f6
    sta (scr_ptr_lo),y
    tax
    lda char_attrib_data,x; and #$0f
    sta (col_ptr_lo),y

    ldy #1
    lda $f7
    sta (scr_ptr_lo),y
    tax
    lda char_attrib_data,x; and #$0f
    sta (col_ptr_lo),y

    // advance pointers one row down (+40)
    lda scr_ptr_lo; clc; adc #SCR_COLS; sta scr_ptr_lo
    bcc !s+; inc scr_ptr_hi
!s:
    lda col_ptr_lo; clc; adc #SCR_COLS; sta col_ptr_lo
    bcc !c+; inc col_ptr_hi
!c:
    // bottom row
    ldy #0
    lda $f8
    sta (scr_ptr_lo),y
    tax
    lda char_attrib_data,x; and #$0f
    sta (col_ptr_lo),y

    ldy #1
    lda $f9
    sta (scr_ptr_lo),y
    tax
    lda char_attrib_data,x; and #$0f
    sta (col_ptr_lo),y

    rts
}


// =============================================================
// PRECOMPUTED ADDRESS TABLES  (KickAss .for loops, built at
// assemble time — zero runtime cost, no division needed on CPU)
//
//   Cell n is at tile_row = n/20, tile_col = n%20
//   Top-left screen byte = SCREEN_RAM + 40 + tile_row*2*40 + tile_col*2
//                                       ^skip HUD row 0
// =============================================================
.var scrBase = SCREEN_RAM + SCR_COLS   // skip row 0 (HUD)
.var clrBase = COLOR_RAM  + SCR_COLS

scr_tbl_lo:
.for (var r = 0; r < MAP_ROWS; r++) {
    .for (var c = 0; c < MAP_COLS; c++) {
        .byte <(scrBase + r * 2 * SCR_COLS + c * 2)
    }
}
scr_tbl_hi:
.for (var r = 0; r < MAP_ROWS; r++) {
    .for (var c = 0; c < MAP_COLS; c++) {
        .byte >(scrBase + r * 2 * SCR_COLS + c * 2)
    }
}
col_tbl_lo:
.for (var r = 0; r < MAP_ROWS; r++) {
    .for (var c = 0; c < MAP_COLS; c++) {
        .byte <(clrBase + r * 2 * SCR_COLS + c * 2)
    }
}
col_tbl_hi:
.for (var r = 0; r < MAP_ROWS; r++) {
    .for (var c = 0; c < MAP_COLS; c++) {
        .byte >(clrBase + r * 2 * SCR_COLS + c * 2)
    }
}

// =============================================================
// EMBEDDED BINARY DATA
// =============================================================
charset_src_data:
    .import binary "backdrop - Chars.bin"        // 576 bytes — 72 chars × 8

char_attrib_data:
    .import binary "backdrop - CharAttribs.bin"  // 72 bytes  — 1 per char

tile_data:
    .import binary "backdrop - Tiles.bin"        // 72 bytes  — 18 tiles × 4

map_data:
    .import binary "backdrop - Map.bin"          // 240 bytes — 20×12 tile indices
