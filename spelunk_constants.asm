;===============================================================================
; CONSTANTS
;===============================================================================
; Defining things as constants, as above, makes things both easier to read
; and also makes things easier to change.
;--------------------------------------------------------------------------------
#region "Constants"

SCREEN_MEM = $4000                   ; Bank 1 - Screen 0
COLOR_MEM  = $D800                   ; Color mem never changes
CHAR_MEM   = $4800                   ; Base of character set memory
SPRITE_MEM = $5000                   ; Base of sprite memory

COLOR_DIFF = COLOR_MEM - SCREEN_MEM  ; difference between color and screen ram
                                     ; a workaround for CBM PRG STUDIOs poor
                                     ; expression handling

SPRITE_POINTER_BASE = SCREEN_MEM + $3f8 ; last 8 bytes of screen mem

SPRITE_BASE = 64                        ; the pointer to the first image

SPRITE_0_PTR = SPRITE_POINTER_BASE + 0  ; Sprite pointers
SPRITE_1_PTR = SPRITE_POINTER_BASE + 1
SPRITE_2_PTR = SPRITE_POINTER_BASE + 2
SPRITE_3_PTR = SPRITE_POINTER_BASE + 3
SPRITE_4_PTR = SPRITE_POINTER_BASE + 4
SPRITE_5_PTR = SPRITE_POINTER_BASE + 5
SPRITE_6_PTR = SPRITE_POINTER_BASE + 6
SPRITE_7_PTR = SPRITE_POINTER_BASE + 7

SPRITE_DELTA_OFFSET_X = 7               ; Offset from SPRITE coords to Delta Char coords
SPRITE_DELTA_OFFSET_Y = 13              ; approx the center of the sprite


NUMBER_OF_SPRITES_DIV_4 = 3           ; This is for my personal version, which
                                      ; loads sprites and characters under IO ROM

#endregion

;===============================================================================
; ZERO PAGE VARIABLES
;===============================================================================
#region "ZeroPage"
PARAM1 = $03                 ; These will be used to pass parameters to routines
PARAM2 = $04                 ; when you can't use registers or other reasons
PARAM3 = $05                            
PARAM4 = $06                 ; essentially, think of these as extra data registers
PARAM5 = $07

ZEROPAGE_POINTER_1 = $17     ; Similar only for pointers that hold a word long address
ZEROPAGE_POINTER_2 = $19
ZEROPAGE_POINTER_3 = $21
ZEROPAGE_POINTER_4 = $23

#endregion
