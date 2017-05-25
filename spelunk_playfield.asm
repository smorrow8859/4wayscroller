;====================
; DRAW PLAYFIELD
;====================
DrawPlayField
        jsr DisplayDebugConsoleText

                ;------------------------------------------------------------ WALLS
        ; Draw walls on left and right of the screen
                                
        lda #0                  ; X character coord
        sta PARAM1
        lda #3                  ; Y character coord
        sta PARAM2
        lda #15                ;  end Y character coord
        sta PARAM3
        lda #$c0                ; character to draw
        sta PARAM4
        lda #COLOR_YELLOW       ; color to use
        sta PARAM5
        jsr DrawVLine
                                ; Routine doesn't trash PARAM variables so with care
                                ; you can shorten your workload
        lda #39                 ; change X to 39 - other side of the screen
        sta PARAM1
        jsr DrawVLine           ; draw the same line over there
        
                                ; setup for horizontal lines
        lda #1                  ; Top Wall
        sta PARAM1              ; starting at X 1
        lda #3                 
        sta PARAM2              ; starting at Y 3
        lda #39
        sta PARAM3              ; ending at X 39
        jsr DrawHLine

                                ; Bottom Wall (Floor)
        lda #0
        sta PARAM1
        lda #18                 
        sta PARAM2              ; starting at Y 18
        lda #40
        sta PARAM3
        jsr DrawHLine

        ;platform
        lda #15 
        sta PARAM1
        lda #11
        sta PARAM2
        lda #20
        sta PARAM3
        jsr DrawHLine

        ;rope
        ; PARAM1 = start X
        ; PARAM2 = start Y
        ; PARAM3 = end X
        ; PARAM4 = character
        ; PARAM5 = color
        lda #14 
        sta PARAM1
        lda #10
        sta PARAM2
        lda #18
        sta PARAM3
        lda #127
        sta PARAM4
        lda #COLOR_RED       ; color to use
        sta PARAM5
        jsr DrawVLine
        

        

        rts
#endregion


DisplayDebugConsoleText
        ;--------------------------------------------------------- DEBUG TEXT CONSOLE
                                        ; Display the little debug panel showing
                                        ; sprite pos and extended X bit status

                                        ; ZEROPAGE_POINTER_1 contains the address to the text

        ;lda #<CONSOLE_TEXT              ; Load the pointer to the text low byte
        ;sta ZEROPAGE_POINTER_1
        ;lda #>CONSOLE_TEXT              ; Load the pointer to the text high byte
        ;sta ZEROPAGE_POINTER_1 + 1

        loadpointer ZEROPAGE_POINTER_1, CONSOLE_TEXT

        lda #0                          ; PARAM1 contains X screen coord (column)
        sta PARAM1
        lda #20                         ; PARAM2 contains Y screen coord (row)
        sta PARAM2
        lda #COLOR_WHITE                ; PARAM3 contains the color to use
        sta PARAM3
        jsr DisplayText                 ; Then we display the text
        rts
