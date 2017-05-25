;===============================================================================
; DIRECTIVES
;===============================================================================
Operator Calc        ; IMPORTANT - calculations are made BEFORE hi/lo bytes
                     ;             in precidence (for expressions and tables)

;-------------------------------------------------------------------------------------------
; VBL WAIT
;-------------------------------------------------------------------------------------------
; Wait for the raster to reach line $f8 - if it's aleady there, wait for
; the next screen blank. This prevents mistimings if the code runs too fast

WaitFrame
        lda VIC_RASTER_LINE  ; fetch the current raster line
        cmp #$F8             ; wait here till line #$f8
        beq WaitFrame           
        
@WaitStep2
        lda VIC_RASTER_LINE
        cmp #$F8
        bne @WaitStep2
        rts

;-------------------------------------------------------------------------------------------
; CLEAR SCREEN
;-------------------------------------------------------------------------------------------
; Clears the screen using a chosen character.
; A = Character to clear the screen with
; Y = Color to fill with
; ------------------------------------------------------------------------------------------
ClearScreen
        ldx #$00                        ; Clear X register
ClearLoop
        sta SCREEN_MEM,x                ; Write the character (in A) at SCREEN_MEM + x
        sta SCREEN_MEM + 250,x          ; at SCREEN_MEM + 250 + x
        sta SCREEN_MEM + 500,x          ; at SCREEN_MEM + 500 + x
        sta SCREEN_MEM + 750,x          ; st SCREEN_MEM + 750 + x
        inx
        cpx #250                        ; is X > 250?
        bne ClearLoop                   ; if not - continue clearing

        tya                             ; transfer Y (color) to A
        ldx #$00                        ; reset x to 0
ColorLoop
        sta COLOR_MEM,x                 ; Do the same for color ram
        sta COLOR_MEM + 250,x
        sta COLOR_MEM + 500,x
        sta COLOR_MEM + 750,x
        inx
        cpx #250
        bne ColorLoop

        rts

;-------------------------------------------------------------------------------------------
; DISPLAY TEXT
;-------------------------------------------------------------------------------------------
; Displays a line of text.      '@' ($00) is the end of text character
;                               '/' ($2f) is the line break character
; ZEROPAGE_POINTER_1 = pointer to text data
; PARAM1 = X
; PARAM2 = Y
; PARAM3 = Color
; Modifies ZEROPAGE_POINTER_2 and ZEROPAGE_POINTER_3
;
; NOTE : all text should be in lower case :  byte 'hello world@' or byte 'hello world',$00
;-------------------------------------------------------------------------------------------

DisplayText

        ldx PARAM2

        lda SCREEN_LINE_OFFSET_TABLE_LO,x

        sta ZEROPAGE_POINTER_2
        sta ZEROPAGE_POINTER_3
        lda SCREEN_LINE_OFFSET_TABLE_HI,x
        sta ZEROPAGE_POINTER_2 + 1

        clc
        adc #>COLOR_DIFF
        sta ZEROPAGE_POINTER_3 + 1

        lda ZEROPAGE_POINTER_2
        clc
        adc PARAM1
        sta ZEROPAGE_POINTER_2
        lda ZEROPAGE_POINTER_2 + 1
        adc #0
        sta ZEROPAGE_POINTER_2 + 1
        lda ZEROPAGE_POINTER_3
        clc
        adc PARAM1
        sta ZEROPAGE_POINTER_3
        lda ZEROPAGE_POINTER_3 + 1
        adc #0
        sta ZEROPAGE_POINTER_3 + 1

        ldy #0
@inlineLoop
        lda (ZEROPAGE_POINTER_1),y              ; test for end of line
        cmp #$00
        beq @endMarkerReached                 
        cmp #$2F                                ; test for line break
        beq @lineBreak
        sta (ZEROPAGE_POINTER_2),y
        lda PARAM3
        sta (ZEROPAGE_POINTER_3),y
        iny
        jmp @inLineLoop

@lineBreak
        iny
        tya
        clc
        adc ZEROPAGE_POINTER_1
        sta ZEROPAGE_POINTER_1
        lda #0
        adc ZEROPAGE_POINTER_1 + 1
        sta ZEROPAGE_POINTER_1 + 1

        inc PARAM2
        
        jmp DisplayText

@endMarkerReached
        rts

;---------------------------------------------------------------------------------------------------
; DISPLAY BYTE DATA
;---------------------------------------------------------------------------------------------------
; Displays the data stored in a given byte on the screen as readable text in hex format (0-F)

; X = screen line                - Yes, this is a little arse-backwards (X and Y) but I don't think
; Y = screen column                addressing modes allow me to swap them around
; A = byte to display
; MODIFIES : ZEROPAGE_POINTER_1, ZEROPAGE_POINTER_3, PARAM4
;---------------------------------------------------------------------------------------------------
#region "DisplayByte"
DisplayByte

        sta PARAM4                                      ; store the byte to display in PARAM4

        lda SCREEN_LINE_OFFSET_TABLE_LO,x               ; look up the address for the screen line
        sta ZEROPAGE_POINTER_1                          ; store lower byte for address for screen
        sta ZEROPAGE_POINTER_3                          ; and color
        lda SCREEN_LINE_OFFSET_TABLE_HI,x               ; store high byte for screen
        sta ZEROPAGE_POINTER_1 + 1
        clc
        adc #>COLOR_DIFF                                ; add the difference to color mem
        sta ZEROPAGE_POINTER_3 + 1                      ; for the color address high byte

        lda PARAM4                                      ; load the byte to be displayed
        and #$0F                                        ; mask for the lower half (0-F)
        adc #$30                                        ; add $30 (48) to display character set
                                                        ; numbers

        clc                                             ; clear carry flag
        cmp #$3A                                        ; less than the code for A (10)?
        bcc @writeDigit                                  ; Go to the next digit
        
        sbc #$39                                        ; if so we set the character code back to
                                                        ; display A-F ($01 - $0A)

@writeDigit                                              
        iny                                             ; increment the position on the line                                       
        sta (ZEROPAGE_POINTER_1),y                      ; write the character code
        lda #COLOR_WHITE                                ; set the color to white
        sta (ZEROPAGE_POINTER_3),y                      ; write the color to color ram

        dey                                             ; decrement the position on the line
        lda PARAM4                                      ; fetch the byte to DisplayText
        and #$F0                                        ; mask for the top 4 bits (00 - F0)
        lsr                                             ; shift it right to a value of 0-F
        lsr
        lsr
        lsr
        adc #$30                                        ; from here, it's the same
        
        clc
        cmp #$3A                                        ; check for A-F
        bcc @lastDigit
        sbc #$39

@lastDigit
        sta (ZEROPAGE_POINTER_1),y                      ; write character and color
        lda #COLOR_WHITE
        sta (ZEROPAGE_POINTER_3),y

        rts

#endregion
;---------------------------------------------------------------------------------------------------
        


;---------------------------------------------------------------------------------------------------
; Screen Line Offset Tables
; Query a line with lda (POINTER TO TABLE),x (where x holds the line number)
; and it will return the screen address for that line

; C64 PRG STUDIO has a lack of expression support that makes creating some tables very problematic
; Be aware that you can only use ONE expression after a defined constant, no braces, and be sure to
; account for order of precedence.

; For these tables you MUST have the Operator Calc directive set at the top of your main file
; or have it checked in options or BAD THINGS WILL HAPPEN!! It basically means that calculations
; will be performed BEFORE giving back the hi/lo byte with '>' rather than the default of
; hi/lo byte THEN the calculation
                                                  
SCREEN_LINE_OFFSET_TABLE_LO        
          byte <SCREEN_MEM + 0
          byte <SCREEN_MEM + 40
          byte <SCREEN_MEM + 80
          byte <SCREEN_MEM + 120
          byte <SCREEN_MEM + 160
          byte <SCREEN_MEM + 200
          byte <SCREEN_MEM + 240
          byte <SCREEN_MEM + 280
          byte <SCREEN_MEM + 320
          byte <SCREEN_MEM + 360
          byte <SCREEN_MEM + 400
          byte <SCREEN_MEM + 440
          byte <SCREEN_MEM + 480
          byte <SCREEN_MEM + 520
          byte <SCREEN_MEM + 560
          byte <SCREEN_MEM + 600
          byte <SCREEN_MEM + 640
          byte <SCREEN_MEM + 680
          byte <SCREEN_MEM + 720
          byte <SCREEN_MEM + 760
          byte <SCREEN_MEM + 800
          byte <SCREEN_MEM + 840
          byte <SCREEN_MEM + 880
          byte <SCREEN_MEM + 920
          byte <SCREEN_MEM + 960

SCREEN_LINE_OFFSET_TABLE_HI
          byte >SCREEN_MEM + 0
          byte >SCREEN_MEM + 40
          byte >SCREEN_MEM + 80
          byte >SCREEN_MEM + 120
          byte >SCREEN_MEM + 160
          byte >SCREEN_MEM + 200
          byte >SCREEN_MEM + 240
          byte >SCREEN_MEM + 280
          byte >SCREEN_MEM + 320
          byte >SCREEN_MEM + 360
          byte >SCREEN_MEM + 400
          byte >SCREEN_MEM + 440
          byte >SCREEN_MEM + 480
          byte >SCREEN_MEM + 520
          byte >SCREEN_MEM + 560
          byte >SCREEN_MEM + 600
          byte >SCREEN_MEM + 640
          byte >SCREEN_MEM + 680
          byte >SCREEN_MEM + 720
          byte >SCREEN_MEM + 760
          byte >SCREEN_MEM + 800
          byte >SCREEN_MEM + 840
          byte >SCREEN_MEM + 880
          byte >SCREEN_MEM + 920
          byte >SCREEN_MEM + 960