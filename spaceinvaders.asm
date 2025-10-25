               ORG     $3F01

                                        ; set up the graphics mode
                LDA     $FF22
                ANDA    #7
                ORA     #$F0
                STA     $FF22

                STA     $FFC0
                STA     $FFC3
                STA     $FFC5

                LDA     $BC
                JSR     SETPORG
                JSR     PCLS

                JSR     INIT_KEYBOARD

                                        ; Ready to do something in graphics mode!

                JSR     DISPTXT

                LDA     #FORMATION_START_X
                STA     FORMATION_X
                STA     FORMATION_TARGET_X
                LDX     #ROW_CURRENT_X
                LDB     #FORMATION_ROWS
INIT_CURR
                STA     ,X+
                DECB
                BNE     INIT_CURR
                LDA     #FORMATION_START_X
                LDX     #ROW_PREV_X
                LDB     #FORMATION_ROWS
INIT_PREV
                STA     ,X+
                DECB
                BNE     INIT_PREV
                CLRA
                LDX     #ROW_DELAY_COUNTER
                LDB     #FORMATION_ROWS
INIT_DELAY
                STA     ,X+
                DECB
                BNE     INIT_DELAY
                LDX     #ROW_PENDING
                LDB     #FORMATION_ROWS
INIT_PENDING
                STA     ,X+
                DECB
                BNE     INIT_PENDING
                CLRA
                LDX     #ROW_FRAME
                LDB     #FORMATION_ROWS
INIT_FRAME
                STA     ,X+
                DECB
                BNE     INIT_FRAME
                LDA     #1
                LDX     #ROW_DIRTY
                LDB     #FORMATION_ROWS
INIT_DIRTY
                STA     ,X+
                DECB
                BNE     INIT_DIRTY
                LDA     #ALIEN_STEP
                STA     FORMATION_DX
                CLRA
                STA     FORMATION_MOVE_TIMER
                STA     FORMATION_MOVED
                STA     FORMATION_MOVING
                JSR     INIT_ALIENS
                JSR     DRAWFORMATION
                JSR     DRAW_SHIELDS
                JSR     INIT_PLAYER

MAINLOOP
                JSR     WAITVSYNC
                JSR     HANDLE_PLAYER_INPUT
                TSTA
                BNE     EXIT_TO_TEXT
                JSR     UPDATEFORMATION
                JSR     ANIMATEFORMATION
                JSR     UPDATE_PLAYER
                JSR     UPDATE_ALIEN_EXPLOSIONS
                JSR     UPDATE_PLAYER_BULLET
                LDA     FORMATION_MOVED
                BEQ     SKIP_FORMATION_REDRAW
                JSR     ERASEFORMATION
                JSR     DRAWFORMATION
SKIP_FORMATION_REDRAW
                LDA     PLAYER_BULLET_STATE
                BEQ     SKIP_BULLET_DRAW
                JSR     DRAW_PLAYER_BULLET
SKIP_BULLET_DRAW
                BRA     MAINLOOP

                                        ; return to text mode
EXIT_TO_TEXT
                LDA     $FF22
                ANDA    #7
                STA     $FF22
                STA     $FFC2
                STA     $FFC4
                LDA     #$04
                JSR     SETPORG

                RTS                     ; return to basic

SETPORG LSRA
                LDX     #$FFC6
LOOP3   CLRB
                LSRA
                ROLB
                STA     B,X
                LEAX    2,X
                CMPX    #$FFD4
                BNE     LOOP3
                RTS
                                        ; clear the graphics screen
PCLS    LDA     $BC             ; First graphics page
                CLRB                    ; ... convert to 16-bit addr
                TFR     D,X             ; ... and load it into X
                LDY     #$1800          ; Clear 4 graphics pages (6KB)
;        DECB                   ; B = $FF to clear with green, leave at $00 for black
LOOP4   STB     ,X+
                LEAY    -1,Y
                BNE     LOOP4
                RTS

                                        ;; Show the text
DISPTXT LDX     #MSG
                LDA     $BC
                CLRB
                ADDD    #12                     ; set the print location
                TFR     D,Y
LOOP5   PSHS    Y
                LDB     ,X+
                BEQ     LOOP6
LOOP7   SUBB    #$20                    ; Convert ASCII to source character position
                LDU     #FONT                   ; Convert screencode to font addr
                CLRA
                LSLB
                ROLA
                LSLB
                ROLA
                LSLB
                ROLA
                LEAU D,U
                LDB     #8
LOOP8   LDA     ,U+
                EORA    #$00
                STA     ,Y+
                LEAY    31,Y
                DECB
                BNE     LOOP8
                LEAY    -255,Y
                LDB     ,X+
                BNE     LOOP7
                PULS    Y                       ; Next line
                LEAY    256,Y
                BRA     LOOP5
LOOP6   PULS    Y                       ; Clean up stack
		LDX     #MSG2
                LDA     $BC
                CLRB
                ADDD    #0   ; set the print locatiom
                TFR     D,Y
LOOP9   PSHS    Y
                LDB     ,X+
                BEQ     LOOP10
LOOP11   SUBB    #$20                    ; Convert ASCII to source character position
                LDU     #FONT                   ; Convert screencode to font addr
                CLRA
                LSLB
                ROLA
                LSLB
                ROLA
                LSLB
                ROLA
                LEAU D,U
                LDB     #8
LOOP12   LDA     ,U+
                EORA    #$00
                STA     ,Y+
                LEAY    31,Y
                DECB
                BNE     LOOP12
                LEAY    -255,Y
                LDB     ,X+
                BNE     LOOP11
                PULS    Y                       ; Next line
                LEAY    256,Y
                BRA     LOOP9
LOOP10   PULS    Y                       ; Clean up stack
                RTS

ALIEN_WIDTH         EQU     12
ALIEN_HEIGHT        EQU     8
ALIEN_STEP          EQU     2
ALIEN_NEG_STEP      EQU     -ALIEN_STEP
ALIEN_FRAME_SIZE_BYTES    EQU     ALIEN_HEIGHT*3
ALIEN_FRAME_STRIDE_BYTES  EQU     ALIEN_FRAME_SIZE_BYTES*8
FORMATION_ROWS      EQU     5
FORMATION_COLS      EQU     11
ALIEN_SPACING_X     EQU     16
ALIEN_SPACING_Y     EQU     16
FORMATION_TOP_Y     EQU     32
FORMATION_START_X   EQU     40
FORMATION_LEFT_LIMIT EQU     0
ALIEN_MAX_RIGHT_PAD   EQU     2
FORMATION_LEFT_EDGE_BUFFER EQU     2
FORMATION_RIGHT_EDGE_BUFFER EQU    2
FORMATION_MIN_ROW_OFFSET EQU     2
FORMATION_RIGHT_LIMIT EQU (255-((FORMATION_COLS-1)*ALIEN_SPACING_X)-(ALIEN_WIDTH-1)-ALIEN_MAX_RIGHT_PAD)
FORMATION_LEFT_REVERSAL EQU FORMATION_LEFT_LIMIT+FORMATION_LEFT_EDGE_BUFFER
FORMATION_RIGHT_REVERSAL EQU FORMATION_RIGHT_LIMIT-FORMATION_RIGHT_EDGE_BUFFER
ROW_STAGGER_DELAY   EQU     4
MOVE_INTERVAL_FRAMES_BASE EQU    60
FORMATION_INITIAL_INTERVAL EQU MOVE_INTERVAL_FRAMES_BASE-ROW_STAGGER_DELAY*(FORMATION_ROWS-1) ; ~1s total cadence after row staggering
FORMATION_FAST_INTERVAL EQU 30
PLAYER_HEIGHT       EQU     8
PLAYER_EFFECTIVE_WIDTH EQU  13
PLAYER_LEFT_LIMIT   EQU     2
PLAYER_RIGHT_LIMIT  EQU     (253-(PLAYER_EFFECTIVE_WIDTH-1))
PLAYER_SPEED        EQU     1
PLAYER_START_X      EQU     120
PLAYER_START_Y      EQU     SHIELD_TOP_Y+SHIELD_HEIGHT+16
PLAYER_FRAME_WIDTH_BYTES EQU 3
PLAYER_FRAME_SIZE_BYTES EQU PLAYER_HEIGHT*PLAYER_FRAME_WIDTH_BYTES
PLAYER_BULLET_HEIGHT EQU   8
PLAYER_BULLET_SPEED  EQU   4
PLAYER_BULLET_TOP_LIMIT EQU 8
PLAYER_BULLET_X_OFFSET EQU (PLAYER_EFFECTIVE_WIDTH-1)/2
PLAYER_BULLET_INACTIVE EQU 0
PLAYER_BULLET_ACTIVE EQU 1
ALIEN_EXPLOSION_DURATION EQU 24
ALIEN_HIT_PAUSE_FRAMES EQU ALIEN_EXPLOSION_DURATION
ALIEN_STATE_EMPTY  EQU   0
ALIEN_STATE_ALIVE  EQU   1
ALIEN_STATE_EXPLODING EQU 2
ALIEN_TOTAL_COUNT  EQU   FORMATION_ROWS*FORMATION_COLS
ALIEN_EXPLOSION_X_OFFSET EQU -8
ALIEN_RECORD_STATE       EQU 0
ALIEN_RECORD_TIMER       EQU 1
ALIEN_RECORD_ROW         EQU 2
ALIEN_RECORD_COL         EQU 3
ALIEN_RECORD_ROW_TYPE    EQU 4
ALIEN_RECORD_REL_X       EQU 5
ALIEN_RECORD_REL_Y       EQU 6
ALIEN_RECORD_FLAGS       EQU 7
ALIEN_RECORD_SIZE        EQU 8
ALIEN_ROW_STRIDE         EQU ALIEN_RECORD_SIZE*FORMATION_COLS
PIA0_DATAA     EQU     $FF00
PIA0_CTRLA     EQU     $FF01
PIA0_DATAB     EQU     $FF02
PIA0_CTRLB     EQU     $FF03
KEY_REPEAT_DELAY EQU   $0276
KEY_REPEAT_RATE  EQU   $0277
PLAYER_HELD_NONE EQU   0
PLAYER_HELD_LEFT EQU   1
PLAYER_HELD_RIGHT EQU  2
KEYBOARD_RIGHT_ROW EQU $BF
KEYBOARD_LEFT_ROW  EQU $DF
KEYBOARD_ARROW_COL_MASK EQU $08
SHIELD_COUNT        EQU     4
SHIELD_HEIGHT       EQU     16
SHIELD_WIDTH_BYTES  EQU     3
SHIELD_TOP_Y        EQU     136


WAITVSYNC
                LDA     $FF03
WAITVS1 BMI     WAITVS1         ; wait while VSYNC bit is high
WAITVS2 LDA     $FF03
                BPL     WAITVS2         ; wait for the next VSYNC pulse
                RTS

UPDATEFORMATION
                CLR     FORMATION_MOVED
                LDA     FORMATION_MOVING
                BEQ     UF_CHECK_PAUSE
                LDA     FORMATION_PAUSE_TIMER
                BEQ     UF_MOVE_ACTIVE
                DECA
                STA     FORMATION_PAUSE_TIMER
                RTS
UF_MOVE_ACTIVE
                BSR     PROCESS_ROW_MOVEMENT
                RTS
UF_CHECK_PAUSE
                LDA     FORMATION_PAUSE_TIMER
                BEQ     UF_CHECK_TIMER
                DECA
                STA     FORMATION_PAUSE_TIMER
                RTS
UF_CHECK_TIMER
                LDA     FORMATION_MOVE_TIMER
                INCA
                CMPA    FORMATION_MOVE_INTERVAL
                BLO     UF_STORE_TIMER
                CLRA
                STA     FORMATION_MOVE_TIMER
                LDA     FORMATION_X
                LDB     FORMATION_DX
                ADDA    FORMATION_DX
                TSTB
                BMI     UF_CHECK_LEFT_EDGE
UF_CHECK_RIGHT_EDGE
                CMPA    #FORMATION_RIGHT_REVERSAL
                BLS     UF_SET_TARGET
                LDA     FORMATION_X
                ADDA    #ALIEN_NEG_STEP
                LDB     #ALIEN_NEG_STEP
                BRA     UF_SET_TARGET
UF_CHECK_LEFT_EDGE
                PSHS    A
                ADDA    #FORMATION_MIN_ROW_OFFSET
                CMPA    #FORMATION_LEFT_REVERSAL
                PULS    A
                BHS     UF_SET_TARGET
                LDA     FORMATION_X
                ADDA    #ALIEN_STEP
                LDB     #ALIEN_STEP
UF_SET_TARGET
                STA     FORMATION_TARGET_X
                STB     FORMATION_DX
UF_START_SEQUENCE
                LDA     #1
                LDX     #ROW_PENDING
                LDB     #FORMATION_ROWS
UF_SET_PENDING
                STA     ,X+
                DECB
                BNE     UF_SET_PENDING
                LDA     #ROW_STAGGER_DELAY*(FORMATION_ROWS-1)
                LDX     #ROW_DELAY_COUNTER
                LDB     #FORMATION_ROWS
UF_SET_DELAY
                STA     ,X+
                SUBA    #ROW_STAGGER_DELAY
                DECB
                BNE     UF_SET_DELAY
                LDA     #1
                STA     FORMATION_MOVING
                BSR     PROCESS_ROW_MOVEMENT
                RTS
UF_STORE_TIMER
                STA     FORMATION_MOVE_TIMER
                RTS

PROCESS_ROW_MOVEMENT
                CLRA
                STA     FORMATION_ROW_INDEX
PR_ROW_LOOP
                LDB     FORMATION_ROW_INDEX
                CMPB    #FORMATION_ROWS
                BEQ     PR_CHECK_COMPLETE
                LDX     #ROW_PENDING
                LDA     B,X
                BEQ     PR_NEXT_ROW
                LDX     #ROW_DELAY_COUNTER
                LDA     B,X
                BEQ     PR_MOVE_ROW
                DECA
                STA     B,X
                BRA     PR_NEXT_ROW
PR_MOVE_ROW
                LDA     #1
                STA     FORMATION_MOVED
                LDA     FORMATION_TARGET_X
                LDX     #ROW_CURRENT_X
                STA     B,X
                LDA     #1
                LDX     #ROW_DIRTY
                STA     B,X
                LDX     #ROW_PENDING
                CLR     B,X
                LDX     #ROW_FRAME
                LDA     B,X
                EORA    #1
                STA     B,X
PR_NEXT_ROW
                LDB     FORMATION_ROW_INDEX
                INCB
                STB     FORMATION_ROW_INDEX
                BRA     PR_ROW_LOOP
PR_CHECK_COMPLETE
                LDB     #FORMATION_ROWS
                LDX     #ROW_PENDING
PR_PENDING_SCAN
                LDA     ,X+
                BNE     PR_STILL_PENDING
                DECB
                BNE     PR_PENDING_SCAN
                CLR     FORMATION_MOVING
                LDA     FORMATION_TARGET_X
                STA     FORMATION_X
                RTS
PR_STILL_PENDING
                LDA     #1
                STA     FORMATION_MOVING
                RTS

UPDATE_FORMATION_SPEED
                LDA     ALIENS_REMAINING
                BNE     UFS_LOOKUP
                LDA     #FORMATION_FAST_INTERVAL
                STA     FORMATION_MOVE_INTERVAL
                RTS
UFS_LOOKUP
                DECA
                LDU     #FORMATION_INTERVAL_TABLE
                LEAU    A,U
                LDA     ,U
                STA     FORMATION_MOVE_INTERVAL
                RTS

ANIMATEFORMATION
                RTS

DRAWFORMATION
                CLRA
                STA     FORMATION_ROW_INDEX
                LDB     #FORMATION_ROWS
ROWLOOP_DRAW
                PSHS    B
                LDB     FORMATION_ROW_INDEX
                LDX     #ROW_DIRTY
                LDA     B,X
                LBEQ    SKIP_DRAW_ROW
                LDX     #ALIEN_ROW_TYPES
                LDA     B,X
                STA     CURRENT_ROW_TYPE
                ASLA
                LDX     #ALIEN_TYPE_BASES
                LDU     A,X
                LDX     #ALIEN_TYPE_X_OFFSETS
                LDB     CURRENT_ROW_TYPE
                LDA     B,X
                STA     CURRENT_ROW_OFFSET
                LDB     FORMATION_ROW_INDEX
                LDX     #ROW_CURRENT_X
                LDA     B,X
                ADDA    CURRENT_ROW_OFFSET
                STA     ROW_BASE_X
               LDA     ROW_BASE_X
               ANDA    #7
               TFR     A,B
               LDA     #ALIEN_FRAME_SIZE_BYTES
                MUL
                LEAU    D,U
                LDB     FORMATION_ROW_INDEX
                LDX     #ROW_FRAME
                LDA     B,X
                LDB     #ALIEN_FRAME_STRIDE_BYTES
                MUL
                LEAU    D,U
                STU     CURRENT_ROW_PTR
                LDX     #ROW_PIXEL_OFFSETS
                LDB     FORMATION_ROW_INDEX
                LDA     B,X
                STA     SPRITE_Y_POS
                CLRA
                STA     FORMATION_COL_INDEX
                LDB     #FORMATION_COLS
COLLOOP_DRAW
                PSHS    B
                JSR     GET_ALIEN_PTR
                LDA     ROW_BASE_X
                ADDA    ALIEN_REC_REL_X,U
                STA     ALIEN_CURRENT_X
                STA     SPRITE_X_POS
                LDA     ALIEN_REC_STATE,U
                BEQ     DF_SKIP_DRAW
                CMPA    #ALIEN_STATE_EXPLODING
                BEQ     DF_DRAW_EXPLOSION
                LDU     CURRENT_ROW_PTR
                JSR     BLITSPRITE
                BRA     DF_AFTER_DRAW
DF_DRAW_EXPLOSION
                LDA     SPRITE_X_POS
                PSHS    A
                ADDA    #ALIEN_EXPLOSION_X_OFFSET
                STA     SPRITE_X_POS
                LDU     #ALIEN_EXPLOSION_DATA
                JSR     BLITSPRITE
                PULS    A
                STA     SPRITE_X_POS
                BRA     DF_AFTER_DRAW
DF_SKIP_DRAW
                ; nothing to draw for empty slot
DF_AFTER_DRAW
                INC     FORMATION_COL_INDEX
                PULS    B
                DECB
                BNE     COLLOOP_DRAW
                LDB     FORMATION_ROW_INDEX
                LDX     #ROW_PREV_X
                LDA     ROW_BASE_X
                STA     B,X
                LDX     #ROW_DIRTY
                CLR     B,X
SKIP_DRAW_ROW
                LDB     FORMATION_ROW_INDEX
                INCB
                STB     FORMATION_ROW_INDEX
                PULS    B
                DECB
                LBNE    ROWLOOP_DRAW
                CLR     FORMATION_MOVED
                RTS

ERASEFORMATION
                CLRA
                STA     FORMATION_ROW_INDEX
                LDB     #FORMATION_ROWS
ROWLOOP_ERASE
                PSHS    B
                LDB     FORMATION_ROW_INDEX
                LDX     #ROW_DIRTY
                LDA     B,X
                BEQ     SKIP_ERASE_ROW
               LDX     #ROW_PREV_X
               LDA     B,X
               STA     ROW_BASE_X
               LDB     FORMATION_ROW_INDEX
               LDX     #ROW_PIXEL_OFFSETS
               LDA     B,X
                STA     SPRITE_Y_POS
                CLRA
                STA     FORMATION_COL_INDEX
                LDB     #FORMATION_COLS
COLLOOP_ERASE
               PSHS    B
               LDB     FORMATION_COL_INDEX
               LDA     B,X
               ADDA    ROW_BASE_X
               STA     SPRITE_X_POS
               JSR     CLEARSPRITE
                LDB     FORMATION_COL_INDEX
                INCB
                STB     FORMATION_COL_INDEX
                PULS    B
                DECB
                BNE     COLLOOP_ERASE
SKIP_ERASE_ROW
                LDB     FORMATION_ROW_INDEX
                INCB
                STB     FORMATION_ROW_INDEX
                PULS    B
                DECB
                BNE     ROWLOOP_ERASE
                RTS


DRAW_SHIELDS
                LDB     #SHIELD_COUNT
                LDX     #SHIELD_POSITIONS
SHIELD_LOOP
                LDA     ,X+
                PSHS    B,X,A
                JSR     DRAW_SINGLE_SHIELD
                PULS    A,X,B
                DECB
                BNE     SHIELD_LOOP
                RTS

DRAW_SINGLE_SHIELD
                STA     SHIELD_LEFT_TMP
                LDA     #SHIELD_TOP_Y
                STA     SHIELD_ROW_Y
                LDB     #SHIELD_HEIGHT
                LDU     #SHIELD_DATA
SHIELD_ROW_LOOP
                PSHS    B
                LDA     SHIELD_ROW_Y
                LDB     #32
                MUL
                STD     SPRITE_OFFSET_TMP
                LDA     SHIELD_LEFT_TMP
                LSRA
                LSRA
                LSRA
                TFR     A,B
                CLRA
                ADDD    SPRITE_OFFSET_TMP
                STD     SPRITE_OFFSET_TMP
                LDA     $BC
                CLRB
                ADDD    SPRITE_OFFSET_TMP
                TFR     D,Y
                LDD     ,U++
                STD     ,Y
                LDA     ,U+
                STA     2,Y
                LDA     SHIELD_ROW_Y
                INCA
                STA     SHIELD_ROW_Y
                PULS    B
                DECB
                BNE     SHIELD_ROW_LOOP
                RTS


INIT_PLAYER
                LDA     #PLAYER_START_X
                STA     PLAYER_X
                STA     PLAYER_PREV_X
                LDA     #1
                STA     PLAYER_DIRTY
                JSR     UPDATE_PLAYER
                CLR     PLAYER_BULLET_STATE
                CLR     PLAYER_BULLET_X
                CLR     PLAYER_BULLET_Y
                CLR     PLAYER_BULLET_COLUMN
                CLR     PLAYER_BULLET_DRAW_MASK
                CLR     PLAYER_BULLET_VISIBLE
                RTS


INIT_ALIENS
                LDU     #ALIEN_OBJECTS
                CLRA
                STA     FORMATION_ROW_INDEX
                LDB     #FORMATION_ROWS
IA_ROW_INIT
                PSHS    B
                LDB     FORMATION_ROW_INDEX
                LDX     #ALIEN_ROW_TYPES
                LDA     B,X
                STA     CURRENT_ROW_TYPE
                LDX     #ALIEN_TYPE_X_OFFSETS
                LDB     CURRENT_ROW_TYPE
                LDA     B,X
                STA     CURRENT_ROW_OFFSET
                LDX     #ROW_PIXEL_OFFSETS
                LDB     FORMATION_ROW_INDEX
                LDA     B,X
                STA     ALIEN_ROW_TOP_TMP
                CLR     FORMATION_COL_INDEX
                LDB     #FORMATION_COLS
IA_COL_INIT
                PSHS    B
                LDA     #ALIEN_STATE_ALIVE
                STA     ALIEN_REC_STATE,U
                CLR     ALIEN_REC_TIMER,U
                LDA     FORMATION_ROW_INDEX
                STA     ALIEN_REC_ROW,U
                LDA     FORMATION_COL_INDEX
                STA     ALIEN_REC_COL,U
                LDA     CURRENT_ROW_TYPE
                STA     ALIEN_REC_ROW_TYPE,U
                LDB     FORMATION_COL_INDEX
                LDA     B,X
                STA     ALIEN_REC_REL_X,U
                LDA     ALIEN_ROW_TOP_TMP
                STA     ALIEN_REC_REL_Y,U
                CLR     ALIEN_REC_FLAGS,U
                LEAU    ALIEN_RECORD_SIZE,U
                LDB     FORMATION_COL_INDEX
                INCB
                STB     FORMATION_COL_INDEX
                PULS    B
                DECB
                BNE     IA_COL_INIT
                LDB     FORMATION_ROW_INDEX
                INCB
                STB     FORMATION_ROW_INDEX
                PULS    B
                DECB
                BNE     IA_ROW_INIT
                LDA     #ALIEN_TOTAL_COUNT
                STA     ALIENS_REMAINING
                CLR     FORMATION_PAUSE_TIMER
                JSR     UPDATE_FORMATION_SPEED
                RTS


HANDLE_PLAYER_INPUT
                JSR     [$A000]
                TSTA
                BEQ     HPI_CHECK_HELD
                CMPA    #$08
                BEQ     HPI_NEW_LEFT
                CMPA    #$09
                BEQ     HPI_NEW_RIGHT
                CMPA    #$20
                BEQ     HPI_FIRE
                RTS
HPI_NEW_LEFT
                LDA     #PLAYER_HELD_LEFT
                STA     PLAYER_HELD_STATE
                BSR     PLAYER_MOVE_LEFT
                CLRA
                RTS
HPI_NEW_RIGHT
                LDA     #PLAYER_HELD_RIGHT
                STA     PLAYER_HELD_STATE
                BSR     PLAYER_MOVE_RIGHT
                CLRA
                RTS
HPI_FIRE
                JSR     PLAYER_FIRE
                CLRA
                RTS
HPI_CHECK_HELD
                LDA     PLAYER_HELD_STATE
                BEQ     HPI_NONE
                PSHS    A
                BITA    #PLAYER_HELD_LEFT
                BEQ     HPI_CHECK_RIGHT_HELD
                LDB     #KEYBOARD_LEFT_ROW
                BRA     HPI_SCAN_HELD
HPI_CHECK_RIGHT_HELD
                BITA    #PLAYER_HELD_RIGHT
                BEQ     HPI_RELEASE_POP
                LDB     #KEYBOARD_RIGHT_ROW
HPI_SCAN_HELD
                STB     PIA0_DATAB
                LDB     PIA0_DATAA
                LDB     PIA0_DATAA
                LDA     #$FF
                STA     PIA0_DATAB
                PULS    A
                BITB    #KEYBOARD_ARROW_COL_MASK
                BNE     HPI_RELEASE
                BITA    #PLAYER_HELD_LEFT
                BEQ     HPI_HELD_MOVE_RIGHT
                BSR     PLAYER_MOVE_LEFT
                CLRA
                RTS
HPI_HELD_MOVE_RIGHT
                BSR     PLAYER_MOVE_RIGHT
                CLRA
                RTS
HPI_RELEASE_POP
                PULS    A
HPI_RELEASE
                CLR     PLAYER_HELD_STATE
HPI_NONE
                CLRA
                RTS


PLAYER_MOVE_LEFT
                LDB     PLAYER_X
                CMPB    #PLAYER_LEFT_LIMIT
                BLS     PML_DONE
                STB     PLAYER_PREV_X
                SUBB    #PLAYER_SPEED
                CMPB    #PLAYER_LEFT_LIMIT
                BHS     PML_STORE
                LDB     #PLAYER_LEFT_LIMIT
PML_STORE
                STB     PLAYER_X
                LDA     #1
                STA     PLAYER_DIRTY
PML_DONE
                RTS


PLAYER_MOVE_RIGHT
                LDB     PLAYER_X
                CMPB    #PLAYER_RIGHT_LIMIT
                BHS     PMR_DONE
                STB     PLAYER_PREV_X
                ADDB    #PLAYER_SPEED
                CMPB    #PLAYER_RIGHT_LIMIT
                BLS     PMR_STORE
                LDB     #PLAYER_RIGHT_LIMIT
PMR_STORE
                STB     PLAYER_X
                LDA     #1
                STA     PLAYER_DIRTY
PMR_DONE
                RTS


INIT_KEYBOARD
                LDA     #0
                STA     KEY_REPEAT_DELAY
                LDA     #1
                STA     KEY_REPEAT_RATE
                LDA     #$FF
                STA     PIA0_DATAB
                CLR     PLAYER_HELD_STATE
                RTS


UPDATE_PLAYER
                LDA     PLAYER_DIRTY
                BEQ     UP_DONE
                LDA     PLAYER_PREV_X
                STA     SPRITE_X_POS
                LDA     #PLAYER_START_Y
                STA     SPRITE_Y_POS
                JSR     CLEARSPRITE
                LDA     PLAYER_X
                STA     SPRITE_X_POS
                LDA     #PLAYER_START_Y
                STA     SPRITE_Y_POS
                LDU     #PLAYER_SHIP_DATA
                LDA     PLAYER_X
                ANDA    #7
                TFR     A,B
                LDA     #PLAYER_FRAME_SIZE_BYTES
                MUL
                LEAU    D,U
                JSR     BLITSPRITE
                LDA     PLAYER_X
                STA     PLAYER_PREV_X
                CLR     PLAYER_DIRTY
UP_DONE
                RTS


PLAYER_FIRE
                LDA     PLAYER_BULLET_STATE
                BNE     PF_DONE
                LDA     #PLAYER_BULLET_ACTIVE
                STA     PLAYER_BULLET_STATE
                LDB     PLAYER_X
                ADDB    #PLAYER_BULLET_X_OFFSET
                STB     PLAYER_BULLET_X
                LDA     #PLAYER_START_Y-PLAYER_BULLET_HEIGHT
                STA     PLAYER_BULLET_Y
                LDA     PLAYER_BULLET_X
                ANDA    #7
                TFR     A,B
                LDX     #PIXEL_BIT_MASKS
                LDA     B,X
                STA     PLAYER_BULLET_DRAW_MASK
                LDA     PLAYER_BULLET_X
                LSRA
                LSRA
                LSRA
                STA     PLAYER_BULLET_COLUMN
PF_DONE
                RTS


DRAW_PLAYER_BULLET
                LDA     PLAYER_BULLET_Y
                LDB     #32
                MUL
                STD     SPRITE_OFFSET_TMP
                LDA     SPRITE_OFFSET_TMP+1
                ADDA    PLAYER_BULLET_COLUMN
                STA     SPRITE_OFFSET_TMP+1
                BCC     DPB_NC
                INC     SPRITE_OFFSET_TMP
DPB_NC
                LDA     $BC
                CLRB
                TFR     D,Y
                LDD     SPRITE_OFFSET_TMP
                LEAY    D,Y
                LDB     #PLAYER_BULLET_HEIGHT
                LDX     #PLAYER_BULLET_BACKUP
DPB_LOOP
                LDA     ,Y
                STA     ,X+
                ORA     PLAYER_BULLET_DRAW_MASK
                STA     ,Y
                LEAY    32,Y
                DECB
                BNE     DPB_LOOP
                LDA     #1
                STA     PLAYER_BULLET_VISIBLE
                RTS


ERASE_PLAYER_BULLET
                LDA     PLAYER_BULLET_Y
                LDB     #32
                MUL
                STD     SPRITE_OFFSET_TMP
                LDA     SPRITE_OFFSET_TMP+1
                ADDA    PLAYER_BULLET_COLUMN
                STA     SPRITE_OFFSET_TMP+1
                BCC     EPB_NC
                INC     SPRITE_OFFSET_TMP
EPB_NC
                LDA     $BC
                CLRB
                TFR     D,Y
                LDD     SPRITE_OFFSET_TMP
                LEAY    D,Y
                LDB     #PLAYER_BULLET_HEIGHT
                LDX     #PLAYER_BULLET_BACKUP
EPB_LOOP
                LDA     ,X+
                STA     ,Y
                LEAY    32,Y
                DECB
                BNE     EPB_LOOP
                CLR     PLAYER_BULLET_VISIBLE
                RTS


UPDATE_PLAYER_BULLET
                LDA     PLAYER_BULLET_STATE
                BEQ     UPB_DONE
                LDA     PLAYER_BULLET_VISIBLE
                BEQ     UPB_SKIP_ERASE
                JSR     ERASE_PLAYER_BULLET
                BRA     UPB_AFTER_ERASE
UPB_SKIP_ERASE
                CLR     PLAYER_BULLET_VISIBLE
UPB_AFTER_ERASE
                LDA     PLAYER_BULLET_Y
                CMPA    #PLAYER_BULLET_TOP_LIMIT
                BLS     UPB_DEACTIVATE
                SUBA    #PLAYER_BULLET_SPEED
                STA     PLAYER_BULLET_Y
                CMPA    #PLAYER_BULLET_TOP_LIMIT
                BLS     UPB_DEACTIVATE
                JSR     CHECK_PLAYER_BULLET_COLLISION
                LDA     PLAYER_BULLET_STATE
                BEQ     UPB_DONE
                RTS
UPB_DEACTIVATE
                CLR     PLAYER_BULLET_STATE
                RTS
UPB_DONE
                RTS


GET_ALIEN_PTR
                PSHS    D
                LDB     FORMATION_ROW_INDEX
                LDU     #ALIEN_OBJECTS
                BEQ     GAP_ROW_READY
GAP_ROW_STEP
                LEAU    ALIEN_ROW_STRIDE,U
                DECB
                BNE     GAP_ROW_STEP
GAP_ROW_READY
                LDA     FORMATION_COL_INDEX
                LDB     #ALIEN_RECORD_SIZE
                MUL
                LEAU    D,U
                PULS    D
                RTS


CHECK_PLAYER_BULLET_COLLISION
                LDA     PLAYER_BULLET_STATE
                LBEQ    CPBC_DONE
                LDA     PLAYER_BULLET_Y
                STA     PLAYER_BULLET_TOP_TMP
                ADDA    #PLAYER_BULLET_HEIGHT-1
                STA     PLAYER_BULLET_BOTTOM_TMP
                CLRA
CPBC_ROW_LOOP
                CMPA    #FORMATION_ROWS
                LBHS    CPBC_DONE
                STA     FORMATION_ROW_INDEX
                TFR     A,B
                LDX     #ROW_PIXEL_OFFSETS
                LDA     B,X
                STA     ALIEN_ROW_TOP_TMP
                ADDA    #ALIEN_HEIGHT-1
                STA     ALIEN_ROW_BOTTOM_TMP
                LDA     PLAYER_BULLET_TOP_TMP
                CMPA    ALIEN_ROW_BOTTOM_TMP
                LBGT    CPBC_NEXT_ROW
                LDA     PLAYER_BULLET_BOTTOM_TMP
                CMPA    ALIEN_ROW_TOP_TMP
                LBLT    CPBC_NEXT_ROW
                LDB     FORMATION_ROW_INDEX
                LDX     #ALIEN_ROW_TYPES
                LDA     B,X
                STA     CURRENT_ROW_TYPE
                LDX     #ALIEN_TYPE_X_OFFSETS
                LDB     CURRENT_ROW_TYPE
                LDA     B,X
                STA     CURRENT_ROW_OFFSET
                LDB     FORMATION_ROW_INDEX
                LDX     #ROW_CURRENT_X
                LDA     B,X
                ADDA    CURRENT_ROW_OFFSET
                STA     ROW_BASE_X
                CLR     FORMATION_COL_INDEX
                LDB     #FORMATION_COLS
                LDX     #COL_PIXEL_OFFSETS
CPBC_COL_LOOP
                PSHS    B
                JSR     GET_ALIEN_PTR
                LDA     ALIEN_REC_STATE,U
                CMPA    #ALIEN_STATE_ALIVE
                BNE     CPBC_SKIP_COL
                LDA     ROW_BASE_X
                ADDA    ALIEN_REC_REL_X,U
                STA     ALIEN_CURRENT_X
                LDB     PLAYER_BULLET_X
                CMPB    ALIEN_CURRENT_X
                BLO     CPBC_SKIP_COL
                LDB     ALIEN_CURRENT_X
                ADDB    #ALIEN_WIDTH-1
                STB     ALIEN_RIGHT_TMP
                LDB     PLAYER_BULLET_X
                CMPB    ALIEN_RIGHT_TMP
                BHI     CPBC_SKIP_COL
                LDA     #ALIEN_STATE_EXPLODING
                STA     ALIEN_REC_STATE,U
                LDA     #ALIEN_EXPLOSION_DURATION
                STA     ALIEN_REC_TIMER,U
                LDA     #ALIEN_HIT_PAUSE_FRAMES
                STA     FORMATION_PAUSE_TIMER
                CLR     FORMATION_MOVE_TIMER
                LDA     #1
                STA     FORMATION_MOVED
                PSHS    B
                LDB     FORMATION_ROW_INDEX
                LDA     #1
                LDX     #ROW_DIRTY
                STA     B,X
                PULS    B
                CLR     PLAYER_BULLET_STATE
                PULS    B
                RTS
CPBC_SKIP_COL
                LDB     FORMATION_COL_INDEX
                INCB
                STB     FORMATION_COL_INDEX
                PULS    B
                DECB
                BNE     CPBC_COL_LOOP
CPBC_NEXT_ROW
                LDA     FORMATION_ROW_INDEX
                INCA
                LBRA    CPBC_ROW_LOOP
                RTS

                RTS
CPBC_DONE
                RTS


UPDATE_ALIEN_EXPLOSIONS
                LDU     #ALIEN_OBJECTS
                LDB     #ALIEN_TOTAL_COUNT
                BEQ     UAE_DONE
UAE_OBJECT_LOOP
                LDA     ALIEN_REC_TIMER,U
                BEQ     UAE_NEXT_OBJECT
                DECA
                STA     ALIEN_REC_TIMER,U
                BNE     UAE_NEXT_OBJECT
                LDA     ALIEN_REC_STATE,U
                CMPA    #ALIEN_STATE_EXPLODING
                BNE     UAE_NEXT_OBJECT
                CLR     ALIEN_REC_STATE,U
                LDA     #1
                STA     FORMATION_MOVED
                PSHS    B
                LDA     ALIEN_REC_ROW,U
                TFR     A,B
                LDA     #1
                LDX     #ROW_DIRTY
                STA     B,X
                PULS    B
                LDA     ALIENS_REMAINING
                BEQ     UAE_NEXT_OBJECT
                DECA
                STA     ALIENS_REMAINING
                JSR     UPDATE_FORMATION_SPEED
UAE_NEXT_OBJECT
                LEAU    ALIEN_RECORD_SIZE,U
                DECB
                BNE     UAE_OBJECT_LOOP
UAE_DONE
                RTS


ALIEN_ROW_TYPES FCB     0,1,1,2,2
ALIEN_TYPE_BASES        FDB     ALIEN_TOP_DATA,ALIEN_MID_DATA,ALIEN_BOTTOM_DATA
ALIEN_TYPE_X_OFFSETS   FCB     4,3,2

ROW_PIXEL_OFFSETS       FCB     FORMATION_TOP_Y+(0*ALIEN_SPACING_Y),FORMATION_TOP_Y+(1*ALIEN_SPACING_Y),FORMATION_TOP_Y+(2*ALIEN_SPACING_Y),FORMATION_TOP_Y+(3*ALIEN_SPACING_Y),FORMATION_TOP_Y+(4*ALIEN_SPACING_Y)
COL_PIXEL_OFFSETS       FCB     0*ALIEN_SPACING_X,1*ALIEN_SPACING_X,2*ALIEN_SPACING_X,3*ALIEN_SPACING_X,4*ALIEN_SPACING_X,5*ALIEN_SPACING_X,6*ALIEN_SPACING_X,7*ALIEN_SPACING_X,8*ALIEN_SPACING_X,9*ALIEN_SPACING_X,10*ALIEN_SPACING_X

BLITSPRITE
               PSHS    U
               LDA     SPRITE_Y_POS
               LDB     #32
               MUL
               STD     SPRITE_OFFSET_TMP
               LDA     SPRITE_X_POS
               LSRA
               LSRA
               LSRA
               TFR     A,B
               CLRA
               ADDD    SPRITE_OFFSET_TMP
               STD     SPRITE_OFFSET_TMP
               LDA     $BC
               CLRB
               ADDD    SPRITE_OFFSET_TMP
               TFR     D,Y
               LDB     #ALIEN_HEIGHT
ROWLOOP_BLIT
               PSHS    B
               LDA     ,U+
               BEQ     BLIT_SKIP0
               ORA     ,Y
               STA     ,Y
BLIT_SKIP0
               LDA     ,U+
               BEQ     BLIT_SKIP1
               ORA     1,Y
               STA     1,Y
BLIT_SKIP1
               LDA     ,U+
               BEQ     BLIT_SKIP2
               ORA     2,Y
               STA     2,Y
BLIT_SKIP2
               LEAY    32,Y
               PULS    B
               DECB
               BNE     ROWLOOP_BLIT
               PULS    U
               RTS

CLEARSPRITE
               LDA     SPRITE_Y_POS
               LDB     #32
               MUL
               STD     SPRITE_OFFSET_TMP
               LDA     SPRITE_X_POS
               LSRA
               LSRA
               LSRA
               TFR     A,B
               CLRA
               ADDD    SPRITE_OFFSET_TMP
               STD     SPRITE_OFFSET_TMP
               LDA     $BC
               CLRB
               ADDD    SPRITE_OFFSET_TMP
               TFR     D,Y
               LDB     #ALIEN_HEIGHT
CLEAR_ROW_LOOP
               PSHS    B
               CLR     ,Y
               CLR     1,Y
               CLR     2,Y
               LEAY    32,Y
               PULS    B
               DECB
               BNE     CLEAR_ROW_LOOP
               RTS

PLAYER_SHIP_DATA
                FCB     $02,$00,$00
                FCB     $07,$00,$00
                FCB     $07,$00,$00
                FCB     $7F,$F0,$00
                FCB     $FF,$F8,$00
                FCB     $FF,$F8,$00
                FCB     $FF,$F8,$00
                FCB     $FF,$F8,$00
                FCB     $01,$00,$00
                FCB     $03,$80,$00
                FCB     $03,$80,$00
                FCB     $3F,$F8,$00
                FCB     $7F,$FC,$00
                FCB     $7F,$FC,$00
                FCB     $7F,$FC,$00
                FCB     $7F,$FC,$00
                FCB     $00,$80,$00
                FCB     $01,$C0,$00
                FCB     $01,$C0,$00
                FCB     $1F,$FC,$00
                FCB     $3F,$FE,$00
                FCB     $3F,$FE,$00
                FCB     $3F,$FE,$00
                FCB     $3F,$FE,$00
                FCB     $00,$40,$00
                FCB     $00,$E0,$00
                FCB     $00,$E0,$00
                FCB     $0F,$FE,$00
                FCB     $1F,$FF,$00
                FCB     $1F,$FF,$00
                FCB     $1F,$FF,$00
                FCB     $1F,$FF,$00
                FCB     $00,$20,$00
                FCB     $00,$70,$00
                FCB     $00,$70,$00
                FCB     $07,$FF,$00
                FCB     $0F,$FF,$80
                FCB     $0F,$FF,$80
                FCB     $0F,$FF,$80
                FCB     $0F,$FF,$80
                FCB     $00,$10,$00
                FCB     $00,$38,$00
                FCB     $00,$38,$00
                FCB     $03,$FF,$80
                FCB     $07,$FF,$C0
                FCB     $07,$FF,$C0
                FCB     $07,$FF,$C0
                FCB     $07,$FF,$C0
                FCB     $00,$08,$00
                FCB     $00,$1C,$00
                FCB     $00,$1C,$00
                FCB     $01,$FF,$C0
                FCB     $03,$FF,$E0
                FCB     $03,$FF,$E0
                FCB     $03,$FF,$E0
                FCB     $03,$FF,$E0
                FCB     $00,$04,$00
                FCB     $00,$0E,$00
                FCB     $00,$0E,$00
                FCB     $00,$FF,$E0
                FCB     $01,$FF,$F0
                FCB     $01,$FF,$F0
                FCB     $01,$FF,$F0
                FCB     $01,$FF,$F0

ALIEN_TOP_DATA
               FCB     $18,$00,$00,$3C,$00,$00,$7E,$00
               FCB     $00,$DB,$00,$00,$FF,$00,$00,$24
               FCB     $00,$00,$5A,$00,$00,$A5,$00,$00
               FCB     $0C,$00,$00,$1E,$00,$00,$3F,$00
               FCB     $00,$6D,$80,$00,$7F,$80,$00,$12
               FCB     $00,$00,$2D,$00,$00,$52,$80,$00
               FCB     $06,$00,$00,$0F,$00,$00,$1F,$80
               FCB     $00,$36,$C0,$00,$3F,$C0,$00,$09
               FCB     $00,$00,$16,$80,$00,$29,$40,$00
               FCB     $03,$00,$00,$07,$80,$00,$0F,$C0
               FCB     $00,$1B,$60,$00,$1F,$E0,$00,$04
               FCB     $80,$00,$0B,$40,$00,$14,$A0,$00
               FCB     $01,$80,$00,$03,$C0,$00,$07,$E0
               FCB     $00,$0D,$B0,$00,$0F,$F0,$00,$02
               FCB     $40,$00,$05,$A0,$00,$0A,$50,$00
               FCB     $00,$C0,$00,$01,$E0,$00,$03,$F0
               FCB     $00,$06,$D8,$00,$07,$F8,$00,$01
               FCB     $20,$00,$02,$D0,$00,$05,$28,$00
               FCB     $00,$60,$00,$00,$F0,$00,$01,$F8
               FCB     $00,$03,$6C,$00,$03,$FC,$00,$00
               FCB     $90,$00,$01,$68,$00,$02,$94,$00
               FCB     $00,$30,$00,$00,$78,$00,$00,$FC
               FCB     $00,$01,$B6,$00,$01,$FE,$00,$00
               FCB     $48,$00,$00,$B4,$00,$01,$4A,$00
               FCB     $18,$00,$00,$3C,$00,$00,$7E,$00
               FCB     $00,$DB,$00,$00,$FF,$00,$00,$24
               FCB     $00,$00,$42,$00,$00,$24,$00,$00
               FCB     $0C,$00,$00,$1E,$00,$00,$3F,$00
               FCB     $00,$6D,$80,$00,$7F,$80,$00,$12
               FCB     $00,$00,$21,$00,$00,$12,$00,$00
               FCB     $06,$00,$00,$0F,$00,$00,$1F,$80
               FCB     $00,$36,$C0,$00,$3F,$C0,$00,$09
               FCB     $00,$00,$10,$80,$00,$09,$00,$00
               FCB     $03,$00,$00,$07,$80,$00,$0F,$C0
               FCB     $00,$1B,$60,$00,$1F,$E0,$00,$04
               FCB     $80,$00,$08,$40,$00,$04,$80,$00
               FCB     $01,$80,$00,$03,$C0,$00,$07,$E0
               FCB     $00,$0D,$B0,$00,$0F,$F0,$00,$02
               FCB     $40,$00,$04,$20,$00,$02,$40,$00
               FCB     $00,$C0,$00,$01,$E0,$00,$03,$F0
               FCB     $00,$06,$D8,$00,$07,$F8,$00,$01
               FCB     $20,$00,$02,$10,$00,$01,$20,$00
               FCB     $00,$60,$00,$00,$F0,$00,$01,$F8
               FCB     $00,$03,$6C,$00,$03,$FC,$00,$00
               FCB     $90,$00,$01,$08,$00,$00,$90,$00
               FCB     $00,$30,$00,$00,$78,$00,$00,$FC
               FCB     $00,$01,$B6,$00,$01,$FE,$00,$00
               FCB     $48,$00,$00,$84,$00,$00,$48,$00

ALIEN_MID_DATA
               FCB     $21,$00,$00,$12,$00,$00,$3F,$00
               FCB     $00,$6D,$80,$00,$FF,$C0,$00,$BF
               FCB     $40,$00,$A1,$40,$00,$12,$00,$00
               FCB     $10,$80,$00,$09,$00,$00,$1F,$80
               FCB     $00,$36,$C0,$00,$7F,$E0,$00,$5F
               FCB     $A0,$00,$50,$A0,$00,$09,$00,$00
               FCB     $08,$40,$00,$04,$80,$00,$0F,$C0
               FCB     $00,$1B,$60,$00,$3F,$F0,$00,$2F
               FCB     $D0,$00,$28,$50,$00,$04,$80,$00
               FCB     $04,$20,$00,$02,$40,$00,$07,$E0
               FCB     $00,$0D,$B0,$00,$1F,$F8,$00,$17
               FCB     $E8,$00,$14,$28,$00,$02,$40,$00
               FCB     $02,$10,$00,$01,$20,$00,$03,$F0
               FCB     $00,$06,$D8,$00,$0F,$FC,$00,$0B
               FCB     $F4,$00,$0A,$14,$00,$01,$20,$00
               FCB     $01,$08,$00,$00,$90,$00,$01,$F8
               FCB     $00,$03,$6C,$00,$07,$FE,$00,$05
               FCB     $FA,$00,$05,$0A,$00,$00,$90,$00
               FCB     $00,$84,$00,$00,$48,$00,$00,$FC
               FCB     $00,$01,$B6,$00,$03,$FF,$00,$02
               FCB     $FD,$00,$02,$85,$00,$00,$48,$00
               FCB     $00,$42,$00,$00,$24,$00,$00,$7E
               FCB     $00,$00,$DB,$00,$01,$FF,$80,$01
               FCB     $7E,$80,$01,$42,$80,$00,$24,$00
               FCB     $21,$00,$00,$92,$40,$00,$BF,$40
               FCB     $00,$ED,$C0,$00,$FF,$C0,$00,$21
               FCB     $00,$00,$40,$80,$00,$21,$00,$00
               FCB     $10,$80,$00,$49,$20,$00,$5F,$A0
               FCB     $00,$76,$E0,$00,$7F,$E0,$00,$10
               FCB     $80,$00,$20,$40,$00,$10,$80,$00
               FCB     $08,$40,$00,$24,$90,$00,$2F,$D0
               FCB     $00,$3B,$70,$00,$3F,$F0,$00,$08
               FCB     $40,$00,$10,$20,$00,$08,$40,$00
               FCB     $04,$20,$00,$12,$48,$00,$17,$E8
               FCB     $00,$1D,$B8,$00,$1F,$F8,$00,$04
               FCB     $20,$00,$08,$10,$00,$04,$20,$00
               FCB     $02,$10,$00,$09,$24,$00,$0B,$F4
               FCB     $00,$0E,$DC,$00,$0F,$FC,$00,$02
               FCB     $10,$00,$04,$08,$00,$02,$10,$00
               FCB     $01,$08,$00,$04,$92,$00,$05,$FA
               FCB     $00,$07,$6E,$00,$07,$FE,$00,$01
               FCB     $08,$00,$02,$04,$00,$01,$08,$00
               FCB     $00,$84,$00,$02,$49,$00,$02,$FD
               FCB     $00,$03,$B7,$00,$03,$FF,$00,$00
               FCB     $84,$00,$01,$02,$00,$00,$84,$00
               FCB     $00,$42,$00,$01,$24,$80,$01,$7E
               FCB     $80,$01,$DB,$80,$01,$FF,$80,$00
               FCB     $42,$00,$00,$81,$00,$00,$42,$00

ALIEN_BOTTOM_DATA
               FCB     $0F,$00,$00,$7F,$E0,$00,$FF,$F0
               FCB     $00,$E6,$70,$00,$FF,$F0,$00,$19
               FCB     $80,$00,$26,$40,$00,$10,$80,$00
               FCB     $07,$80,$00,$3F,$F0,$00,$7F,$F8
               FCB     $00,$73,$38,$00,$7F,$F8,$00,$0C
               FCB     $C0,$00,$13,$20,$00,$08,$40,$00
               FCB     $03,$C0,$00,$1F,$F8,$00,$3F,$FC
               FCB     $00,$39,$9C,$00,$3F,$FC,$00,$06
               FCB     $60,$00,$09,$90,$00,$04,$20,$00
               FCB     $01,$E0,$00,$0F,$FC,$00,$1F,$FE
               FCB     $00,$1C,$CE,$00,$1F,$FE,$00,$03
               FCB     $30,$00,$04,$C8,$00,$02,$10,$00
               FCB     $00,$F0,$00,$07,$FE,$00,$0F,$FF
               FCB     $00,$0E,$67,$00,$0F,$FF,$00,$01
               FCB     $98,$00,$02,$64,$00,$01,$08,$00
               FCB     $00,$78,$00,$03,$FF,$00,$07,$FF
               FCB     $80,$07,$33,$80,$07,$FF,$80,$00
               FCB     $CC,$00,$01,$32,$00,$00,$84,$00
               FCB     $00,$3C,$00,$01,$FF,$80,$03,$FF
               FCB     $C0,$03,$99,$C0,$03,$FF,$C0,$00
               FCB     $66,$00,$00,$99,$00,$00,$42,$00
               FCB     $00,$1E,$00,$00,$FF,$C0,$01,$FF
               FCB     $E0,$01,$CC,$E0,$01,$FF,$E0,$00
               FCB     $33,$00,$00,$4C,$80,$00,$21,$00
               FCB     $0F,$00,$00,$7F,$E0,$00,$FF,$F0
               FCB     $00,$E6,$70,$00,$FF,$F0,$00,$19
               FCB     $80,$00,$36,$C0,$00,$C0,$30,$00
               FCB     $07,$80,$00,$3F,$F0,$00,$7F,$F8
               FCB     $00,$73,$38,$00,$7F,$F8,$00,$0C
               FCB     $C0,$00,$1B,$60,$00,$60,$18,$00
               FCB     $03,$C0,$00,$1F,$F8,$00,$3F,$FC
               FCB     $00,$39,$9C,$00,$3F,$FC,$00,$06
               FCB     $60,$00,$0D,$B0,$00,$30,$0C,$00
               FCB     $01,$E0,$00,$0F,$FC,$00,$1F,$FE
               FCB     $00,$1C,$CE,$00,$1F,$FE,$00,$03
               FCB     $30,$00,$06,$D8,$00,$18,$06,$00
               FCB     $00,$F0,$00,$07,$FE,$00,$0F,$FF
               FCB     $00,$0E,$67,$00,$0F,$FF,$00,$01
               FCB     $98,$00,$03,$6C,$00,$0C,$03,$00
               FCB     $00,$78,$00,$03,$FF,$00,$07,$FF
               FCB     $80,$07,$33,$80,$07,$FF,$80,$00
               FCB     $CC,$00,$01,$B6,$00,$06,$01,$80
               FCB     $00,$3C,$00,$01,$FF,$80,$03,$FF
               FCB     $C0,$03,$99,$C0,$03,$FF,$C0,$00
               FCB     $66,$00,$00,$DB,$00,$03,$00,$C0
               FCB     $00,$1E,$00,$00,$FF,$C0,$01,$FF
               FCB     $E0,$01,$CC,$E0,$01,$FF,$E0,$00
               FCB     $33,$00,$00,$6D,$80,$01,$80,$60

ALIEN_BLANK
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FCB     $00,$00,$00,$00,$00,$00,$00,$00
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
               FDB     $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

PIXEL_BIT_MASKS
               FCB     $80,$40,$20,$10,$08,$04,$02,$01

ALIEN_EXPLOSION_DATA
               FCB     $00,$05,$14
               FCB     $00,$02,$A8
               FCB     $00,$01,$10
               FCB     $00,$0C,$06
               FCB     $00,$01,$10
               FCB     $00,$02,$A8
               FCB     $00,$05,$14
               FCB     $00,$00,$00

FORMATION_INTERVAL_TABLE
               FCB     30,30,30,30,31,31,31,31,32,32,32,32,33,33,33,33,34,34,34,34,35,35,35,35,36,36,36,37,37,37,37,38,38,38,38,39,39,39,39,40,40,40,40,41,41,41,41,42,42,42,42,43,43,43,44

FORMATION_X     FCB     0
FORMATION_DX    FCB     0
FORMATION_ROW_INDEX     FCB     0
FORMATION_COL_INDEX     FCB     0
FORMATION_MOVE_TIMER    FCB     0
FORMATION_MOVED FCB     0
FORMATION_TARGET_X      FCB     0
FORMATION_MOVING        FCB     0
PLAYER_X        FCB     0
PLAYER_PREV_X   FCB     0
PLAYER_DIRTY    FCB     0
PLAYER_HELD_STATE       FCB     PLAYER_HELD_NONE
PLAYER_BULLET_STATE     FCB     PLAYER_BULLET_INACTIVE
PLAYER_BULLET_X FCB     0
PLAYER_BULLET_Y FCB     0
PLAYER_BULLET_COLUMN    FCB     0
PLAYER_BULLET_DRAW_MASK FCB     0
PLAYER_BULLET_VISIBLE   FCB     0
PLAYER_BULLET_BACKUP    RMB     PLAYER_BULLET_HEIGHT
PLAYER_BULLET_TOP_TMP   FCB     0
PLAYER_BULLET_BOTTOM_TMP FCB    0
ALIEN_ROW_TOP_TMP       FCB     0
ALIEN_ROW_BOTTOM_TMP    FCB     0
ALIEN_CURRENT_X         FCB     0
ALIEN_RIGHT_TMP         FCB     0
ALIENS_REMAINING FCB     0
FORMATION_MOVE_INTERVAL FCB     0
FORMATION_PAUSE_TIMER   FCB     0

ROW_CURRENT_X   RMB     FORMATION_ROWS
ROW_PREV_X      RMB     FORMATION_ROWS
ROW_DELAY_COUNTER       RMB     FORMATION_ROWS
ROW_PENDING     RMB     FORMATION_ROWS
ROW_DIRTY       RMB     FORMATION_ROWS
ROW_FRAME       RMB     FORMATION_ROWS

ALIEN_OBJECTS   RMB     ALIEN_TOTAL_COUNT*ALIEN_RECORD_SIZE

SPRITE_X_POS    FCB     0
SPRITE_Y_POS    FCB     0
CURRENT_ROW_TYPE FCB     0
CURRENT_ROW_OFFSET FCB   0
ROW_BASE_X      FCB     0
ROW_BASE_REMAINDER FCB  0
SPRITE_OFFSET_TMP       RMB     2
CURRENT_ROW_PTR RMB     2
SHIELD_LEFT_TMP FCB     0
SHIELD_ROW_Y    FCB     0

SHIELD_POSITIONS        FCB     32,88,144,200

SHIELD_DATA
                FCB     $03,$FF,$F0
                FCB     $07,$FF,$F8
                FCB     $0F,$FF,$FC
                FCB     $1F,$FF,$FE
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$FF,$FF
                FCB     $3F,$80,$FF
                FCB     $3F,$00,$7F
                FCB     $3E,$00,$3F
                FCB     $3E,$00,$3F

MSG     FCC     "HI-SCORE"
       FCB     0,0
MSG2    FCC     "SCORE"
       FCB     0,0
MSG3    FCC     "SPACE INVADERS"
       FCB     0,0

;=============================================================================
; SOUND ROUTINES - Call these manually when you want sound effects
;=============================================================================

DAC_PORT        EQU     $FF20           ; 6-bit DAC for sound

; Play one step of the alien march (4-note descending pattern)
PLAY_ALIEN_STEP
                LDX     #ALIEN_MARCH_NOTES
                LDA     SOUND_STEP_INDEX
                LDB     A,X
                LDY     #$0020
STEP_OUTER
                LDA     #$3F
                STA     DAC_PORT
                NOP
                NOP
                CLR     DAC_PORT
                LEAY    -1,Y
                BNE     STEP_OUTER
                LDA     SOUND_STEP_INDEX
                INCA
                ANDA    #3
                STA     SOUND_STEP_INDEX
                RTS

; Play laser shot sound (rising pitch)
PLAY_LASER
                LDB     #10
                LDY     #$0010
LASER_LOOP
                PSHS    B,Y
                LDA     #$3F
                STA     DAC_PORT
LASER_DELAY
                LEAY    -1,Y
                BNE     LASER_DELAY
                CLR     DAC_PORT
                PULS    B,Y
                LEAY    -2,Y
                DECB
                BNE     LASER_LOOP
                RTS

; Play explosion sound (descending noise)
PLAY_EXPLOSION
                LDB     #15
                LDY     #$0040
EXPL_LOOP
                PSHS    B,Y
                LDA     #$3F
                STA     DAC_PORT
EXPL_DELAY
                LEAY    -1,Y
                BNE     EXPL_DELAY
                CLR     DAC_PORT
                PULS    B,Y
                LEAY    2,Y
                DECB
                BNE     EXPL_LOOP
                RTS

ALIEN_MARCH_NOTES
                FCB     40,45,50,55

SOUND_STEP_INDEX        FCB     0

FONT    INCLUDEBIN "spaceinvaders_font.bin"
