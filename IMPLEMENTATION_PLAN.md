# Implementation Plan: Robust Alien State Tracking

## Overview
This plan addresses the alien removal bug and creates a more resilient system for tracking and rendering game objects.

## Phase 1: Critical Bug Fix (Immediate)

### 1.1 Fix ERASEFORMATION Routine
**File:** spaceinvaders.asm (lines ~460-500)

**Changes:**
```assembly
; BEFORE (BUGGY):
COLLOOP_ERASE
               PSHS    B
               LDB     FORMATION_COL_INDEX
               LDA     B,X     ; Wrong - uses fixed offsets
               ADDA    ROW_BASE_X
               STA     SPRITE_X_POS
               JSR     CLEARSPRITE

; AFTER (FIXED):
COLLOOP_ERASE
               PSHS    B
               JSR     GET_ALIEN_PTR           ; Get actual alien record
               LDA     ALIEN_REC_STATE,U       ; Check if alien exists
               BEQ     SKIP_ERASE_COL          ; Skip if empty
               LDA     ROW_BASE_X
               ADDA    ALIEN_REC_REL_X,U       ; Use actual alien position
               STA     SPRITE_X_POS
               JSR     CLEARSPRITE
SKIP_ERASE_COL
               LDB     FORMATION_COL_INDEX
               INCB
               STB     FORMATION_COL_INDEX
               PULS    B
               DECB
               BNE     COLLOOP_ERASE
```

**Impact:**
- Fixes wrong aliens being erased
- Matches draw and erase logic
- Prevents erasing empty slots

### 1.2 Fix ROW_BASE_X Calculation
**Issue:** Need to ensure ROW_BASE_X in ERASEFORMATION includes type offset

**Changes:**
```assembly
; Add after getting ROW_PREV_X:
               LDB     FORMATION_ROW_INDEX
               LDX     #ALIEN_ROW_TYPES
               LDA     B,X
               STA     CURRENT_ROW_TYPE
               LDX     #ALIEN_TYPE_X_OFFSETS
               LDB     CURRENT_ROW_TYPE
               LDA     B,X
               STA     CURRENT_ROW_OFFSET
               LDB     FORMATION_ROW_INDEX
               LDX     #ROW_PREV_X
               LDA     B,X
               ADDA    CURRENT_ROW_OFFSET     ; Add type offset
               STA     ROW_BASE_X
```

## Phase 2: Enhanced Alien Record Structure

### 2.1 Extend Alien Record with Tracking Fields
**Current record:** 8 bytes
- STATE (0), TIMER (1), ROW (2), COL (3), ROW_TYPE (4), REL_X (5), REL_Y (6), FLAGS (7)

**New record:** 10 bytes
```assembly
ALIEN_RECORD_STATE       EQU 0
ALIEN_RECORD_TIMER       EQU 1
ALIEN_RECORD_ROW         EQU 2
ALIEN_RECORD_COL         EQU 3
ALIEN_RECORD_ROW_TYPE    EQU 4
ALIEN_RECORD_REL_X       EQU 5
ALIEN_RECORD_REL_Y       EQU 6
ALIEN_RECORD_FLAGS       EQU 7
ALIEN_RECORD_PREV_SCREEN_X  EQU 8  ; NEW: Last drawn screen X position
ALIEN_RECORD_DIRTY          EQU 9  ; NEW: Individual dirty flag
ALIEN_RECORD_SIZE        EQU 10     ; Updated size
```

**Benefits:**
- Store exact screen position where alien was last drawn
- Per-alien dirty tracking
- More reliable erase operations

### 2.2 Update INIT_ALIENS
Add initialization:
```assembly
               CLR     ALIEN_REC_PREV_SCREEN_X,U
               CLR     ALIEN_REC_DIRTY,U
```

### 2.3 Update DRAWFORMATION
Store position after drawing:
```assembly
DF_AFTER_DRAW
               LDA     ALIEN_CURRENT_X
               STA     ALIEN_REC_PREV_SCREEN_X,U  ; Store for erase
               CLR     ALIEN_REC_DIRTY,U          ; Clear dirty flag
               INC     FORMATION_COL_INDEX
```

### 2.4 Update ERASEFORMATION
Use stored position:
```assembly
COLLOOP_ERASE
               PSHS    B
               JSR     GET_ALIEN_PTR
               LDA     ALIEN_REC_DIRTY,U          ; Check if needs erase
               BEQ     SKIP_ERASE_COL
               LDA     ALIEN_REC_PREV_SCREEN_X,U  ; Use last drawn position
               STA     SPRITE_X_POS
               JSR     CLEARSPRITE
SKIP_ERASE_COL
               ; ...
```

## Phase 3: State Validation

### 3.1 Add State Transition Validator
**New routine:**
```assembly
; Validates alien state transitions
; Input: A = old state, B = new state, U = alien pointer
; Output: Carry set if valid, clear if invalid
VALIDATE_ALIEN_STATE_CHANGE
               CMPA    #ALIEN_STATE_EMPTY
               BEQ     VAL_FROM_EMPTY
               CMPA    #ALIEN_STATE_ALIVE
               BEQ     VAL_FROM_ALIVE
               CMPA    #ALIEN_STATE_EXPLODING
               BEQ     VAL_FROM_EXPLODING
               BRA     VAL_INVALID

VAL_FROM_EMPTY
               ; Empty can only become Alive (respawn scenarios)
               CMPB    #ALIEN_STATE_ALIVE
               BNE     VAL_INVALID
               BRA     VAL_VALID

VAL_FROM_ALIVE
               ; Alive can become Exploding or Empty
               CMPB    #ALIEN_STATE_EXPLODING
               BEQ     VAL_VALID
               CMPB    #ALIEN_STATE_EMPTY
               BEQ     VAL_VALID
               BRA     VAL_INVALID

VAL_FROM_EXPLODING
               ; Exploding can only become Empty
               CMPB    #ALIEN_STATE_EMPTY
               BEQ     VAL_VALID
               BRA     VAL_INVALID

VAL_INVALID
               ANDCC   #$FE           ; Clear carry
               RTS
VAL_VALID
               ORCC    #$01           ; Set carry
               RTS
```

### 3.2 Wrapper for Safe State Changes
```assembly
; Safely change alien state with validation
; Input: A = new state, U = alien pointer
SET_ALIEN_STATE
               PSHS    A,B
               LDB     ALIEN_REC_STATE,U      ; Current state
               TFR     A,B                    ; New state to B
               TFR     B,A                    ; Old state to A for validation
               JSR     VALIDATE_ALIEN_STATE_CHANGE
               BCC     SAS_INVALID
               PULS    A,B
               STA     ALIEN_REC_STATE,U
               ; Mark as dirty
               LDA     #1
               STA     ALIEN_REC_DIRTY,U
               RTS
SAS_INVALID
               ; Could add error handling/logging here
               PULS    A,B
               RTS
```

### 3.3 Update Collision Detection
Replace direct state writes:
```assembly
; OLD:
               LDA     #ALIEN_STATE_EXPLODING
               STA     ALIEN_REC_STATE,U

; NEW:
               LDA     #ALIEN_STATE_EXPLODING
               JSR     SET_ALIEN_STATE
```

## Phase 4: Optimized Rendering Pipeline

### 4.1 Dirty List Building
Create lists of objects that need update:
```assembly
; Build list of aliens that need redraw
BUILD_DIRTY_LIST
               LDU     #ALIEN_OBJECTS
               LDX     #DIRTY_ALIEN_LIST
               CLR     DIRTY_ALIEN_COUNT
               LDB     #ALIEN_TOTAL_COUNT
BDL_LOOP
               LDA     ALIEN_REC_DIRTY,U
               BEQ     BDL_SKIP
               STU     ,X++                   ; Store pointer
               INC     DIRTY_ALIEN_COUNT
BDL_SKIP
               LEAU    ALIEN_RECORD_SIZE,U
               DECB
               BNE     BDL_LOOP
               RTS

DIRTY_ALIEN_LIST        RMB     ALIEN_TOTAL_COUNT*2  ; Pointers
DIRTY_ALIEN_COUNT       FCB     0
```

### 4.2 Optimized Redraw
```assembly
; Only redraw dirty aliens
REDRAW_DIRTY_ALIENS
               LDA     DIRTY_ALIEN_COUNT
               BEQ     RDA_DONE
               LDX     #DIRTY_ALIEN_LIST
RDA_LOOP
               LDU     ,X++
               ; Erase at previous position
               LDA     ALIEN_REC_PREV_SCREEN_X,U
               STA     SPRITE_X_POS
               LDA     ALIEN_REC_REL_Y,U
               STA     SPRITE_Y_POS
               JSR     CLEARSPRITE
               ; Draw at current position
               ; ... draw logic ...
               DEC     DIRTY_ALIEN_COUNT
               BNE     RDA_LOOP
RDA_DONE
               RTS
```

## Phase 5: Debug and Testing Utilities

### 5.1 Debug State Dumper
```assembly
; Dump alien state to screen (for debugging)
DEBUG_DUMP_ALIEN_STATE
               ; Show alien count, positions, states
               ; Useful for testing
               RTS
```

### 5.2 Integrity Checker
```assembly
; Verify all alien data is consistent
CHECK_ALIEN_INTEGRITY
               ; Validate all pointers
               ; Check state consistency
               ; Verify position bounds
               RTS
```

## Implementation Order

1. **Day 1: Critical Fix**
   - Fix ERASEFORMATION (Phase 1.1, 1.2)
   - Test basic alien removal
   - Commit: "Fix alien erase position bug"

2. **Day 2: Enhanced Tracking**
   - Implement Phase 2.1-2.4
   - Test with extended record
   - Commit: "Add per-alien position tracking"

3. **Day 3: Validation**
   - Implement Phase 3.1-3.3
   - Add validation to all state changes
   - Commit: "Add state transition validation"

4. **Day 4: Optimization**
   - Implement Phase 4.1-4.2
   - Performance testing
   - Commit: "Optimize rendering pipeline"

5. **Day 5: Testing & Debug**
   - Implement Phase 5
   - Comprehensive testing
   - Commit: "Add debug utilities"

## Testing Checklist

- [ ] Shoot aliens in different columns
- [ ] Shoot aliens in different rows
- [ ] Shoot edge aliens (leftmost, rightmost)
- [ ] Shoot while formation is moving
- [ ] Shoot while formation changes direction
- [ ] Shoot multiple aliens rapidly
- [ ] Clear entire rows
- [ ] Clear entire columns
- [ ] Verify ALIENS_REMAINING count
- [ ] Check memory usage (record size increase)
- [ ] Performance test (frame rate impact)

## Rollback Plan

If issues arise:
1. Revert to Phase 1 only (critical fix)
2. Extended tracking is optional enhancement
3. Can disable validation in production
4. Optimized pipeline is optional

## Memory Impact

- Current alien storage: 55 aliens × 8 bytes = 440 bytes
- New alien storage: 55 aliens × 10 bytes = 550 bytes
- Additional overhead: 110 bytes + dirty list (110 bytes) = 220 bytes
- Total increase: ~220 bytes (acceptable on CoCo)
