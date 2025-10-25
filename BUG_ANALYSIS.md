# Alien Removal Bug Analysis

## Problem Description
Aliens are not being removed correctly when shot. Wrong aliens (typically top-left aliens) disappear when lower aliens are hit, sometimes entire rows are affected.

## Root Cause

### The Bug in ERASEFORMATION (line ~470)

**Current buggy code:**
```assembly
COLLOOP_ERASE
               PSHS    B
               LDB     FORMATION_COL_INDEX
               LDA     B,X     ; X points to COL_PIXEL_OFFSETS - WRONG!
               ADDA    ROW_BASE_X
               STA     SPRITE_X_POS
               JSR     CLEARSPRITE
```

**Problem:** The erase routine uses `COL_PIXEL_OFFSETS` (fixed column positions) instead of reading the actual alien's position from `ALIEN_REC_REL_X` in the alien record.

### How It Should Work

**DRAWFORMATION (line ~380) - CORRECT:**
```assembly
COLLOOP_DRAW
               PSHS    B
               JSR     GET_ALIEN_PTR      ; Get pointer to alien record
               LDA     ROW_BASE_X
               ADDA    ALIEN_REC_REL_X,U  ; Use actual alien position!
               STA     ALIEN_CURRENT_X
               STA     SPRITE_X_POS
```

The draw routine correctly gets the alien's pointer and reads its `ALIEN_REC_REL_X` field.

### Why This Causes Random Aliens to Disappear

1. **DRAWFORMATION** draws aliens at their correct positions using `ALIEN_REC_REL_X`
2. **ERASEFORMATION** erases at fixed column offsets from `COL_PIXEL_OFFSETS`
3. When these don't match, the erase clears the wrong screen locations
4. This can accidentally erase parts of other aliens or miss the target alien entirely
5. The mismatch gets worse as the formation moves and aliens have different positions

## Impact

- Shooting an alien at column 3 might erase the sprite at a fixed column offset
- That fixed offset might overlap with an alien at column 0
- The shot alien isn't fully erased, the wrong alien gets partially cleared
- State tracking says one alien is dead, but visually different aliens disappear

## Solution Overview

### Immediate Fix
Make `ERASEFORMATION` mirror `DRAWFORMATION` by:
1. Getting the alien record pointer for each column
2. Reading the actual position from `ALIEN_REC_REL_X`
3. Only erasing aliens that actually exist (state != EMPTY)

### Enhanced State Tracking
Add robustness:
1. Track previous draw position per alien (not just per row)
2. Validate state transitions
3. Add bounds checking for positions
4. Consider separate erase list for changed aliens

## Proposed Implementation

### Phase 1: Critical Fix (ERASEFORMATION)
- Modify COLLOOP_ERASE to call GET_ALIEN_PTR
- Read ALIEN_REC_REL_X,U instead of COL_PIXEL_OFFSETS
- Only erase if previous state != EMPTY

### Phase 2: Add Per-Alien Tracking
- Add ALIEN_RECORD_PREV_X field to alien record
- Update on every draw
- Use for erase positioning

### Phase 3: Validation Layer
- Add state transition validator
- Bounds check all positions
- Debug mode to trace state changes

### Phase 4: Optimized Dirty Tracking
- Track dirty flags per alien, not just per row
- Build erase/draw lists before rendering
- Reduce unnecessary screen operations
