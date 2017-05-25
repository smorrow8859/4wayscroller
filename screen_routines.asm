;===============================================================================
;                                                               SCREEN ROUTINES
;===============================================================================
;                                                            Peter 'Sig' Hewett
;                                                                       - 2016
;-------------------------------------------------------------------------------
; Routines to draw on or modify the screen
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
;                                                         DRAW VERTICAL LINE
;-------------------------------------------------------------------------------
; DrawVLine - draws a vertical line with a specified color and character.
;             it's not optimized or terribly pretty but it lets you reuse your
;             PARAM variables to draw another line straight away
;
; PARAM1 = start X
; PARAM2 = start Y
; PARAM3 = end Y
; PARAM4 = character
; PARAM5 = color
;-------------------------------------------------------------------------------
#region "DrawVLine"

DrawVLine
        ldx PARAM2                              ; fetch the start address in X (Y coord)
        ldy PARAM1                              ; setup Y register for column (X coord)
@loop
        lda SCREEN_LINE_OFFSET_TABLE_LO,x       ; Fetch the address of the start line and
        sta ZEROPAGE_POINTER_1                  ; store it in ZEROPAGE_POINTER_1
        sta ZEROPAGE_POINTER_2                  ; ZEROPAGE_POINTER_2 will hold the color address
        lda SCREEN_LINE_OFFSET_TABLE_HI,x
        sta ZEROPAGE_POINTER_1 + 1

        clc
        adc #>COLOR_DIFF                        ; add the difference to color memory
        sta ZEROPAGE_POINTER_2 + 1              ; ZEROPAGE_POINTER_2 now has the correct address

        lda PARAM4                              ; load the character
        sta (ZEROPAGE_POINTER_1),y              ; write the character to the screen position
        lda PARAM5                              ; load the color
        sta (ZEROPAGE_POINTER_2),Y              ; write it to color ram

        inx
        clc                                     ; increment X
        cpx PARAM3                              ; check against the end position
        bcc @loop                               ; if not equal - loop back
        
        rts

#endregion
;-------------------------------------------------------------------------------
;                                                         DRAW HORIZONTAL LINE
;-------------------------------------------------------------------------------
; DrawVLine - draws a horizontal line with a specified color and character.
;             it's not optimized or terribly pretty but it lets you reuse your
;             PARAM variables to draw another line straight away
;
; PARAM1 = start X
; PARAM2 = start Y
; PARAM3 = end X
; PARAM4 = character
; PARAM5 = color
;-------------------------------------------------------------------------------
#region "DrawHLine"

DrawHLine
        ldx PARAM2                      ; load the Y coordinate for the lookup tables
        ldy PARAM1                      ; start X coord in Y register

@loop
        lda SCREEN_LINE_OFFSET_TABLE_LO,x       ; load the screen line address
        sta ZEROPAGE_POINTER_1
        sta ZEROPAGE_POINTER_2                  ; fetch the low byte for the color address
        lda SCREEN_LINE_OFFSET_TABLE_HI,x
        sta ZEROPAGE_POINTER_1 + 1

        clc
        adc #>COLOR_DIFF                ; add the difference to color ram
        sta ZEROPAGE_POINTER_2 + 1

        lda PARAM4
        sta (ZEROPAGE_POINTER_1),y
        lda PARAM5
        sta (ZEROPAGE_POINTER_2),y

        iny                             ; increment y (our X coordinate
        clc
        cpy PARAM3                      ; compare it to PARAM3 - end X coordinate
        bcc @loop                       ; if less than, loop back

        rts
#endregion        

