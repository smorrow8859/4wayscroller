

;---------------------------------------------------------------------------------------------------
; JOYSTICK
JOY_X                           ; current positon of Joystick(2)
        byte $00                ; -1 0 or +1
JOY_Y
        byte $00                ; -1 0 or +1

BUTTON_PRESSED                  ; holds 1 when the button is held down
        byte $00
BUTTON_ACTION                   ; holds 1 when a single press is made (button released)
        byte $00
;-------------------------------------------------------------------------------------------
; READ JOY 2
;-------------------------------------------------------------------------------------------
; Trying this a different way this time.  Rather than hitting the joystick registers then
; doing something every time - The results will be stored in JOY_X and JOY_Y with values
; -1 to 1 , with 0 meaning 'no input' - I should be able to just add this to a sprite for a
; simple move, while still being able to do an easy check for more complicated movement
; later on
;-------------------------------------------------------------------------------------------
#region "ReadJoystick"

ReadJoystick

        lda #$00                        ; Reset JOY X and Y variables
        sta JOY_X
        sta JOY_Y

        lda #$02                        ; Test for Down
        bit JOY_2
        bne @NotDown
        lda #$01
        sta JOY_Y
        jmp @NotUp                      ; Can't be up AND down
@NotDown
        lda #$01                        ; Test for Up
        bit JOY_2
        bne @NotUp
        lda #-1
        sta JOY_Y
@NotUp                                  ; Test for Left
        lda #$04
        bit JOY_2
        bne @NotLeft
        lda #-1
        sta JOY_X
        rts                             ; Can't be left AND right - no more tests

@NotLeft                                ; Test for Right
        lda #$08
        bit JOY_2
        bne @NotRight
        lda #$01
        sta JOY_X
        rts                             ; no more checks

@NotRight                               ; Nothing pressed
         rts

#endregion

;-------------------------------------------------------------------------------------------
;  JOYSTICK BUTTON PRESSED
;-------------------------------------------------------------------------------------------
; Notifies the state of the fire button on JOYSTICK 2.
; BUTTON_ACTION is set to one on a single press (that is when the button is released)
; BUTTON_PRESSED is set to 1 while the button is held down.
; So either a long press, or a single press can be accounted for.
; TODO I might put a 'press counter' in here to test how long the button is down for..
;-------------------------------------------------------------------------------------------
#region "JoyButton"

JoyButton

        lda #1                ; checks for a previous button action
        cmp BUTTON_ACTION     ; and clears it if set
        bne @buttonTest

        lda #0                                  
        sta BUTTON_ACTION

@buttonTest
        lda #$10              ; test bit #4 in JOY_2 Register
        bit JOY_2
        bne @buttonNotPressed
        
        lda #1                ; if it's pressed - save the result
        sta BUTTON_PRESSED    ; and return - we want a single press
        rts                   ; so we need to wait for the release

@buttonNotPressed

        lda BUTTON_PRESSED    ; and check to see if it was pressed first
        bne @buttonAction     ; if it was we go and set BUTTON_ACTION
        rts

@buttonAction
        lda #0
        sta BUTTON_PRESSED
        lda #1
        sta BUTTON_ACTION

        rts

#endregion        
