
        lda #0                          ; Turn off sprites 
        sta VIC_SPRITE_ENABLE

        lda VIC_SCREEN_CONTROL          ; turn screen off with bit 4
        and #%11101111                  ; mask out bit 4 - Screen on/off
        sta VIC_SCREEN_CONTROL          ; save back - setting bit 4 to off
;-----------------------------------------------------------------------
;  VIC BANK SETUP
;-----------------------------------------------------------------------
#region "VIC Setup"
; To set the VIC bank we have to change the first 2 bits in the
; CIA 2 register. So we want to be careful and only change the
; bits we need to.

        lda VIC_BANK            ; Fetch the status of CIA 2 ($DD00)
        and #%11111100          ; mask for bits 2-8
        ora #%00000010          ; the first 2 bits are your desired VIC bank value
                                ; In this case bank 1 ($4000 - $7FFF)
        sta VIC_BANK

;-----------------------------------------------------------------------
;  CHARACTER SET AND SCREEN MEM
;-----------------------------------------------------------------------
; Within the VIC Bank we can set where we want our screen and character
; set memory to be using the VIC_MEMORY_CONTROL at $D018
; It is important to note that the values given are RELATIVE to the start
; address of the VIC bank you are using.
       
        lda #%00000010   ; bits 1-3 (001) = character memory 2 : $0800 - $0FFF
                         ; bits 4-7 (000) = screen memory 0 : $0000 - $03FF
                         ; this leaves screen 1 intact at $0400 - $07ff

        sta VIC_MEMORY_CONTROL


;        lda VIC_MEMORY_CONTROL  ; set default screeh
;        and #%00001111
;        ora #32                ;00110000 set current screen that you can see to 3072
;        sta VIC_MEMORY_CONTROL  

        ; Because these are RELATIVE to the VIC banks base address (Bank 1 = $4000)
        ; this gives us a base screen memory address of $4000 and a base
        ; character set memory of $4800
        ; 
        ; Sprite pointers are the last 8 bytes of screen memory (25 * 40 = 1000 and
        ; yet each screen reserves 1024 bytes). So Sprite pointers start at
        ; $4000 + $3f8.

        ; Sprite data starts at $5000 - giving the initial image a pointer value of 64
        ; (The sprite data starts at Bank Address + $1000.  $1000 / 64 = 64)
#endregion