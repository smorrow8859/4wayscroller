IncAsm "VICII.asm"                      ; VICII register includes
IncAsm "macros.asm"                     ; macro includes
IncAsm "spelunk_constants.asm"

;===============================================================================
; BASIC KICKSTART
;===============================================================================
KICKSTART
; Sys call to start the program - 10 SYS (2064)
*=$0801
        BYTE $0E,$08,$0A,$00,$9E,$20,$28,$32,$30,$36,$34,$29,$00,$00,$00

;==============================================================================
; PROGRAM START
;==============================================================================
*=$0810
PRG_START
incasm "spelunk_vic_setup.asm"          ;- turns screen off

;turn screen on
        lda VIC_SCREEN_CONTROL
        and #%11101111                  ; mask for bit 4 - Screen on/off
        ora #%00010000                  ; or in bit 4 - turn screen on
        sta VIC_SCREEN_CONTROL

Screen_Setup
        lda #COLOR_BLACK
        ;sta VIC_BORDER_COLOR            ; Set border and background to black
        sta VIC_BACKGROUND_COLOR        

;        lda #$40                        ; use character #$40 as fill character (bricks)
;        lda #$20 ;space (anything under 128)
;        ldy #COLOR_BLUE                 ; use blue as fill color 
;        jsr ClearScreen                 ; clear screen

        loadPointer ZEROPAGE_POINTER_1, VERSION_TEXT
        lda #1                          
        sta PARAM1                      ; PARAM1 and PARAM2 hold X and Y screen character coords
        sta PARAM2                      ; To write the text at
        lda #COLOR_WHITE                ; PARAM3 hold the color 
        sta PARAM3
        jsr DisplayText

        ;jsr DrawPlayField ;draws walls and floors

;================
; Setup Sprites
#region "SetupSprites"
        lda #%00000011             ; make SPRITE 0 - 1  multicolor
        sta VIC_SPRITE_MULTICOLOR 

        lda #COLOR_ORANGE           ; set shared sprite multicolor 1
        sta VIC_SPRITE_MULTICOLOR_1
        lda #COLOR_LTRED
        sta VIC_SPRITE_MULTICOLOR_2; set shared sprite multicolor 2

        lda #COLOR_YELLOW
        sta VIC_SPRITE_COLOR       ; set sprite 0 color
        
        lda #COLOR_RED          ; Set sprite 1
        sta VIC_SPRITE_COLOR + 1   ; Sprite color registers run concurrently 0-8

        ;SETUP SPRITE 0 START POSITION
        lda #0
        sta VIC_SPRITE_X_EXTEND   ; clear extended X bits

        lda #17
        sta PARAM1              ; Character column 10 (X coord)
        lda #5
        sta PARAM2              ; Character row 10 (Y coord)
        ldx #0                  ; Sprite # in X (0)
        jsr SpriteToCharPos 
        ;apply to sprite 1 - color fill
        inx
        jsr SpriteToCharPos

        ;start with idle animation frame 1
        ldx #0
        lda #SPRITE_BASE + 28 ;Idle Animation Starts at 28
        sta ANIM_START,x
        sta SPRITE_0_PTR
        ldx #1
        lda #SPRITE_BASE + 32
        sta ANIM_START,x
        sta SPRITE_1_PTR
        lda #4
        sta MAX_FRAME
        
        ;enable sprites 
        lda #%00000011          ; Turn on sprites 0 and 1
        sta VIC_SPRITE_ENABLE 
#endregion

;=======================================================================
;  MAIN LOOP
;=======================================================================
; The main loop of the program - timed to the verticle blanking period
;-----------------------------------------------------------------------
        jsr FourWay_Scroller            ; scroll the game map

MainLoop
        jsr WaitFrame                   ; wait for the vertical blank period

        lda #COLOR_LTRED               ; Raster time indicator - turn the border yellow
        sta VIC_BORDER_COLOR            ; before the main loop starts

        jsr UpdateTimers

        jsr ReadJoystick

        ;move player sprite
        jsr MovePlayerSprite

        ;update player sprite animation
        ;jsr UpdatePlayerSpriteDirection
        ;jsr UpdatePlayerAnimationFrames
        ;jsr ApplyingGravity

        ;Debug Info
        jsr DisplayInfo


        lda #COLOR_LTGREEN                ; Restore the border to black - this gives a visual
        sta VIC_BORDER_COLOR            ; on how much 'raster time' you have to work with

        jmp MainLoop 

;=======================================================================
MovePlayerSprite
#region "MovePlayerSprite"
        ldx #$00
        lda SPRITE_DIRECTION,x
        sta PREV_SPRITE_DIRECTION,x
                                       ; Fetch Joystick X and move horizontally

        ldx #$00                        ; Sprite 0 in X
        lda JOY_X                       ; fetch Joystick X position
        sta SPRITE_DIRECTION,x          ; store this in SPRITE_DIRECTION for sprite 0
                    
                                        ; now we test this data from the joystick. it can only
                                        ; be -1 o or 1 for left - still or right

        cmp #0                          ; 0 = no input in X axis
        beq @testUpDown                 ; so we can go on to test the Y axis


        bmi @moveLeft                   ; Our joystick reader treats this as a signed bytes
                                        ; so we use BMI (BRanch Minus) rather than BCC or BCS
        jsr CanMoveRight
        bne @testUpDown
        
        ldx #0
        jsr MoveSpriteRight             ; Joystick X positive - move right
        inx 
        jsr MoveSpriteRight
        dex
        jmp @testUpDown

@moveLeft
        ldx #0
        jsr CanMoveLeft                 ; check to see if we can move left
        bne @testUpDown                 ; if blocked - no can move that way

        ldx #0
        jsr MoveSpriteLeft              ; Joystick X negative - move left
        inx 
        jsr MoveSpriteLeft
        dex

@testUpDown
                                        ; Now that we're using a delta system, I can't do a simple
                                        ; update by adding the Joystick Y axis to the VIC_SPRITE_Y
                                        ; we MUST go through the SpriteMove routines.

        lda JOY_Y                       ; Fetch the Joystick Y axis value (-1 0 or 1)
        cmp #$00                        ; if 0 then it's not moved - so we're done
        beq @done

        bmi @moveUp                     ; if Joystick is negative, then we move up

        ldx #0
        jsr CanMoveDown
        bne @done
        jsr MoveSpriteDown              ; if it's positive, we move it down
        inx 
        jsr MoveSpriteDown
        dex

        jmp @done                       ; and move on to the animation
 
@moveUp
        ldx #0
        ;jsr CanMoveUp
        jsr CanMoveUp2
        bne @done
        jsr MoveSpriteUp
        inx 
        jsr MoveSpriteUp
        dex

@done 
        rts
#endregion


;===============================

UpdatePlayerAnimationFrames
        lda TIMER                  
        and #%0000011
        beq @UpdateANIM_FRAME
        rts
@UpdateANIM_FRAME
        ldx #0
        inc ANIM_FRAME,x
        inc ANIM_FRAME,x+1
        lda ANIM_FRAME,x
        cmp MAX_FRAME
        beq reset_ANIM_FRAME
        rts

reset_ANIM_FRAME
        ldx #0
        lda #0
        sta ANIM_FRAME,x
        ldx #1
        sta ANIM_FRAME,x
        jmp return
        rts

;=====================================
UpdatePlayerSpriteDirection
        ldx #$00
        clc
        lda PREV_SPRITE_DIRECTION,x
        cmp SPRITE_DIRECTION,x
        bne reset_ANIM_FRAME ;if the player has just changed directions
return        
;        ldx #0
;        clc
;        lda PREV_SPRITE_DIRECTION,x
;        cmp SPRITE_DIRECTION,x
;        beq @SetPointers ;only change pointers if direction has changed
;       
        ldx #0
        clc
        lda SPRITE_DIRECTION,x
        bmi @WalkLeft
        beq @Idle
        jsr @WalkRight
@SetPointers
        ldx #0
        lda ANIM_START,x
        clc
        adc ANIM_FRAME,x
        sta SPRITE_0_PTR
        ldx #1
        lda ANIM_START,x 
        clc
        adc ANIM_FRAME,x
        sta SPRITE_1_PTR
        rts
@Idle
        ldx #0
        lda #SPRITE_BASE + 28 ;Idle Animation Starts at 28
        sta ANIM_START,x
        ldx #1
        lda #SPRITE_BASE + 32
        sta ANIM_START,x
        lda #4
        sta MAX_FRAME
        jmp @SetPointers

@WalkLeft
        ldx #0
        lda #SPRITE_BASE + 14 
        sta ANIM_START,x
        ldx #1
        lda #SPRITE_BASE + 21
        sta ANIM_START,x
        lda #7
        sta MAX_FRAME
        jmp @SetPointers

@WalkRight
        ldx #0
        lda #SPRITE_BASE + 0 
        sta ANIM_START,x
        ldx #1
        lda #SPRITE_BASE + 7
        sta ANIM_START,x
        lda #7
        sta MAX_FRAME
        jmp @SetPointers



;-----------------------------------------------------------------------
;DISPLAY INFO
;-----------------------------------------------------------------------
; Updates the info in our Debug 'console'
;-----------------------------------------------------------------------
#region "DisplayInfo"
DisplayInfo
        lda JOY_X                       ; only display if changed position
        bne DisplayInfoNow                 
        lda JOY_Y
        bne DisplayInfoNow
        rts
;-DEBUGGING INFO - Screen pos and extended bit
DisplayInfoNow

;@displayPos                                    ; Display the debug data
        lda SPRITE_POS_X                        ; Byte to be displayed
        ldx #20                                 ; Y position to display at (row)                                 
        ldy #7                                  ; X position to display at (column)
        jsr DisplayByte                         ; Display the byte

        lda SPRITE_POS_Y
        ldx #20
        ldy #18
        jsr DisplayByte
                                                ; check the extended x bit
        lda SPRITE_POS_X_EXTEND
        and #$01                                ; mask bit one
        bne @extend                             ; if it's set, display an *

        lda #' '                                ; if not, display a space
        sta SCREEN_MEM + #810
        lda #COLOR_WHITE
        sta COLOR_MEM + #810
        jmp @displayCharCoords                  ; display the next bunch of info
        
@extend

        lda #'*'
        sta SCREEN_MEM + #810
        lda #COLOR_WHITE
        sta COLOR_MEM + #810

;- DISPLAY CHAR X and Y POS AND DELTA
@displayCharCoords
        lda SPRITE_CHAR_POS_X           ; Address of data to display
        ldx #20                         ; Y position
        ldy #28                         ; X position
        jsr DisplayByte                 ; Call the display routine

        lda SPRITE_CHAR_POS_Y           ; Address of data to display
        ldx #20                         ; Y position
        ldy #37                         ; X position
        jsr DisplayByte                 ; Call the display routine

        lda SPRITE_POS_X_DELTA          ; Address of data to display
        ldx #21                         ; Y position
        ldy #7                          ; X position
        jsr DisplayByte                 ; Call the display routine

        lda SPRITE_POS_Y_DELTA          ; Address of data to display
        ldx #21                         ; Y position
        ldy #18                         ; X position
        jsr DisplayByte                 ; Call the display routine

        jsr UpdatePCHAR
        lda pchar
        ldx #21                         ; Y position
        ldy #28                         ; X position
        jsr DisplayByte                 ; Call the display routine

        rts

#endregion

UpdatePCHAR
        ldx #0
        ldy SPRITE_CHAR_POS_Y,x                 ; get the sprite Y char coordinate
        lda SCREEN_LINE_OFFSET_TABLE_LO,y       ; fetch the address of that line
        sta ZEROPAGE_POINTER_1
        lda SCREEN_LINE_OFFSET_TABLE_HI,y
        sta ZEROPAGE_POINTER_1 + 1

        ldy SPRITE_CHAR_POS_X,x                 ; fetch the sprite X char coordinate
        lda (ZEROPAGE_POINTER_1),y
        sta pchar ;this is for debug
        rts

ApplyingGravity
        lda pchar
        cmp #127
        beq @isrope
        ldx #0
        jsr CanMoveDown
        bne @skip
        jsr MoveSpriteDown
        ldx #1
        jsr MoveSpriteDown
@skip
        rts
@isrope
        jsr CanMoveUp2
        rts
;=======================================================================
; ROUTINES
;=======================================================================
incasm "spelunk_screen_memory_routines.asm"
incasm "spelunk_joystick_routines.asm"
incasm "spelunk_sprite_routines.asm"
incasm "collision_routines.asm"
incasm "screen_routines.asm"
incasm "spelunk_playfield.asm"

;===============================================================================
; CHARSET AND SPRITE DATA
;===============================================================================
; Charset and Sprite data directly loaded here.
DATA_INCLUDES
*=$4800

;incbin "Chars.cst",0,255
;incbin "spscroll_chars.raw"

         ;byte 60,102,110,110,96,98,60,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         
;        byte 24,60,102,126,102,102,102,0
;        byte 124,102,102,124,102,102,124,0
;        byte 60,102,96,96,96,102,60,0
         
         byte 120,108,102,102,102,108,120,0
         byte 126,96,96,120,96,96,126,0
         byte 126,96,96,120,96,96,96,0
         byte 60,102,96,110,102,102,60,0
         byte 102,102,102,126,102,102,102,0
         byte 60,24,24,24,24,24,60,0
         byte 30,12,12,12,12,108,56,0
         byte 102,108,120,112,120,108,102,0
         byte 96,96,96,96,96,96,126,0
         byte 99,119,127,107,99,99,99,0
         byte 102,118,126,126,110,102,102,0
         byte 60,102,102,102,102,102,60,0
         byte 124,102,102,124,96,96,96,0
         byte 60,102,102,102,102,60,14,0
         byte 124,102,102,124,120,108,102,0
         byte 60,102,96,60,6,102,60,0
         byte 126,24,24,24,24,24,24,0
         byte 102,102,102,102,102,102,60,0
         byte 102,102,102,102,102,60,24,0
         byte 99,99,99,107,127,119,99,0
         byte 102,102,60,24,60,102,102,0
         byte 102,102,102,60,24,24,24,0
         byte 126,6,12,24,48,96,126,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 126,127,94,55,94,42,84,0
         byte 62,94,46,92,46,84,42,0
         byte 63,95,47,93,46,85,42,0
         byte 252,254,188,110,188,212,168,0
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 170,126,126,86,126,126,126,126
         byte 170,126,126,86,126,126,126,126
         byte 126,126,126,126,86,126,126,85
         byte 126,126,126,126,86,126,126,85
         byte 0,3,6,12,24,48,96,0
         byte 60,102,110,118,102,102,60,0
         byte 24,24,56,24,24,24,126,0
         byte 60,102,6,12,48,96,126,0
         byte 60,102,6,28,6,102,60,0
         byte 6,14,30,102,127,6,6,0
         byte 126,96,124,6,6,102,60,0
         byte 60,102,96,124,102,102,60,0
         byte 126,102,12,24,24,24,24,0
         byte 60,102,102,60,102,102,60,0
         byte 60,102,102,62,6,102,60,0
         byte 20,20,20,106,111,47,47,47
         byte 20,20,20,169,249,248,248,216
         byte 47,47,47,111,106,20,20,20
         byte 216,248,248,249,169,20,20,20
         byte 20,20,20,66,75,47,47,47
         byte 20,20,84,129,225,248,248,248
         byte 47,47,47,75,66,20,20,20
         byte 248,248,248,225,129,20,20,20
         byte 20,20,20,65,65,20,255,255
         byte 20,20,20,65,65,20,255,255
         byte 255,255,20,65,65,20,20,20
         byte 255,255,20,65,65,20,20,20
         byte 23,23,23,67,67,23,23,23
         byte 212,212,212,193,193,212,212,212
         byte 23,23,23,67,67,23,23,23
         byte 212,212,212,193,193,212,212,212
         byte 20,20,20,65,106,43,43,47
         byte 20,20,20,65,169,232,232,248
         byte 47,43,43,106,65,20,20,20
         byte 248,232,232,169,65,20,20,20
         byte 20,20,20,65,65,20,20,63
         byte 20,20,20,65,65,20,52,204
         byte 52,20,20,65,65,20,20,20
         byte 204,52,20,65,65,20,20,20
         byte 20,20,20,65,170,149,157,157
         byte 20,20,20,65,169,88,216,216
         byte 157,157,149,170,65,20,20,20
         byte 216,216,88,169,65,20,20,20
         byte 20,20,20,65,106,37,39,39
         byte 20,20,20,65,169,88,216,88
         byte 37,39,37,101,106,20,20,20
         byte 88,216,216,89,169,20,20,20
         byte 20,20,20,65,65,23,23,23
         byte 20,20,20,65,65,212,212,212
         byte 23,23,23,65,65,20,20,20
         byte 212,212,212,65,65,20,20,20
         byte 20,55,55,102,119,55,38,55
         byte 20,220,220,153,221,220,152,220
         byte 55,38,55,119,102,55,55,20
         byte 220,152,220,221,153,220,220,20
         byte 20,238,238,238,85,85,238,238
         byte 20,236,236,237,85,84,236,236
         byte 238,85,85,238,238,238,20,20
         byte 236,84,84,237,237,236,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 20,20,20,65,65,20,20,20
         byte 240,240,240,240,0,0,0,0
         byte 240,240,240,240,15,15,15,15
         byte 20,20,22,66,77,28,55,63
         byte 20,20,170,170,77,28,220,252
         byte 237,221,221,221,221,29,63,23
         byte 187,183,119,119,119,116,252,212
         byte 63,255,214,213,127,63,214,214
         byte 20,20,212,241,113,52,216,216
         byte 213,213,63,127,214,213,255,63
         byte 216,216,24,73,249,248,24,24
         byte 3,63,237,221,221,221,221,221
         byte 212,252,187,183,119,119,119,119
         byte 55,55,28,77,66,22,20,20
         byte 220,220,28,77,170,170,20,20
         byte 36,36,47,111,97,36,39,39
         byte 252,252,91,87,253,252,91,91
         byte 39,39,28,77,67,23,20,20
         byte 87,87,252,253,91,87,252,252
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 0,0,0,0,0,0,0,0
         byte 129,231,231,231,231,231,231,255
         byte 153,153,153,153,153,153,195,255
         byte 153,153,153,153,153,195,231,255
         byte 156,156,156,148,128,136,156,255
         byte 153,153,195,231,195,153,153,255
         byte 153,153,153,195,231,231,231,255
         byte 129,249,243,231,207,159,129,255
         byte 195,207,207,207,207,207,195,255
         byte 243,237,207,131,207,157,3,255
         byte 195,243,243,243,243,243,195,255
         byte 255,231,195,129,231,231,231,231
         byte 255,239,207,128,128,207,239,255
         byte 255,255,255,255,255,255,255,255
         byte 231,231,231,231,255,255,231,255
         byte 153,153,153,255,255,255,255,255
         byte 153,153,0,153,0,153,153,255
         byte 231,193,159,195,249,131,231,255
         byte 157,153,243,231,207,153,185,255
         byte 195,153,195,199,152,153,192,255
         byte 249,243,231,255,255,255,255,255
         byte 243,231,207,207,207,231,243,255
         byte 207,231,243,243,243,231,207,255
         byte 255,153,195,0,195,153,255,255
         byte 255,231,231,129,231,231,255,255
         byte 255,255,255,255,255,231,231,207
         byte 255,255,255,129,255,255,255,255
         byte 255,255,255,255,255,231,231,255
         byte 255,252,249,243,231,207,159,255
         byte 195,153,145,137,153,153,195,255
         byte 231,231,199,231,231,231,129,255
         byte 195,153,249,243,207,159,129,255
         byte 195,153,249,227,249,153,195,255
         byte 249,241,225,153,128,249,249,255
         byte 129,159,131,249,249,153,195,255
         byte 195,153,159,131,153,153,195,255
         byte 129,153,243,231,231,231,231,255
         byte 195,153,153,195,153,153,195,255
         byte 195,153,153,193,249,153,195,255
         byte 255,255,231,255,255,231,255,255
         byte 255,255,231,255,255,231,231,207
         byte 241,231,207,159,207,231,241,255
         byte 255,255,129,255,129,255,255,255
         byte 143,231,243,249,243,231,143,255
         byte 195,153,249,243,231,255,231,255
         byte 255,255,255,0,0,255,255,255
         byte 247,227,193,128,128,227,193,255
         byte 231,231,231,231,231,231,231,231
         byte 255,255,255,0,0,255,255,255
         byte 255,255,0,0,255,255,255,255
         byte 255,0,0,255,255,255,255,255
         byte 255,255,255,255,0,0,255,255
         byte 207,207,207,207,207,207,207,207
         byte 243,243,243,243,243,243,243,243
         byte 255,255,255,31,15,199,231,231
         byte 231,231,227,240,248,255,255,255
         byte 231,231,199,15,31,255,255,255
         byte 63,63,63,63,63,63,0,0
         byte 63,31,143,199,227,241,248,252
         byte 252,248,241,227,199,143,31,63
         byte 0,0,63,63,63,63,63,63
         byte 0,0,252,252,252,252,252,252
         byte 255,195,129,129,129,129,195,255
         byte 255,255,255,255,255,0,0,255
         byte 201,128,128,128,193,227,247,255
         byte 159,159,159,159,159,159,159,159
         byte 255,255,255,248,240,227,231,231
         byte 60,24,129,195,195,129,24,60
         byte 255,195,129,153,153,129,195,255
         byte 231,231,153,153,231,231,195,255
         byte 249,249,249,249,249,249,249,249
         byte 247,227,193,128,193,227,247,255
         byte 231,231,231,0,0,231,231,231
         byte 63,63,207,207,63,63,207,207
         byte 231,231,231,231,231,231,231,231
         byte 255,255,252,193,137,201,201,255
         byte 0,128,192,224,240,248,252,254
         byte 255,255,255,255,255,255,255,255
         byte 15,15,15,15,15,15,15,15
         byte 255,255,255,255,0,0,0,0
         byte 0,255,255,255,255,255,255,255
         byte 255,255,255,255,255,255,255,0
         byte 63,63,63,63,63,63,63,63
         byte 51,51,204,204,51,51,204,204
         byte 252,252,252,252,252,252,252,252
         byte 255,255,255,255,51,51,204,204
         byte 0,1,3,7,15,31,63,127
         byte 252,252,252,252,252,252,252,252
         byte 231,231,231,224,224,231,231,231
         byte 255,255,255,255,240,240,240,240
         byte 231,231,231,224,224,255,255,255
         byte 255,255,255,7,7,231,231,231
         byte 255,255,255,255,255,255,0,0
         byte 255,255,255,224,224,231,231,231
         byte 231,231,231,0,0,255,255,255
         byte 255,255,255,0,0,231,231,231
         byte 231,231,231,7,7,231,231,231
         byte 63,63,63,63,63,63,63,63
         byte 31,31,31,31,31,31,31,31
         byte 248,248,248,248,248,248,248,248
         byte 0,0,255,255,255,255,255,255
         byte 0,0,0,255,255,255,255,255
         byte 255,255,255,255,255,0,0,0
         byte 252,252,252,252,252,252,0,0
         byte 255,255,255,255,15,15,15,15
         byte 240,240,240,240,255,255,255,255
         byte 231,231,231,7,7,255,255,255
         byte 15,15,15,15,255,255,255,255


incbin "spelunk_sprites.spt",1,60,true    ;spelunker  -   SPRITES 0 - 59

* = $5ef8
;* = $4400
;rom_memory

        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
;        ; sprite pointer part of the screen
        byte 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32


incasm "scroll_map.asm"

;-------------------------------------------------------------------------------
; PROGRAM DATA
;-------------------------------------------------------------------------------
; All program data and variables fall in after the Sprite data
VERSION_TEXT
        byte 'mlp framework v1.3 - rope test@',$00
pchar byte $00 ;the character under the player sprite
CONSOLE_TEXT
        byte ' xpos:$     ypos:$    chrx:$   chry:$   /'
        byte ' dltx:$     dlty:$    pchr:$            @',$00    
