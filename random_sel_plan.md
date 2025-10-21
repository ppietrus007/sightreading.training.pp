# Random Selection Generator Feature Plan

## Overview

Add a new "random sel" generator button that allows users to specify a custom set of notes/chords from which the generator will randomly pick. This gives users precise control over the note pool while maintaining randomness.

## Design Decisions

### 1. Editor Interface Location
**Choice**: Textarea input in the settings panel (Option A)
- Appears below the generator buttons when "random sel" is active
- Simple and direct - no need for modals/lightboxes
- Consistent with other generator inputs

### 2. Input Format
**Choice**: Simple space-separated note format (Option A)
- Example: `C4 E4 G4 B4` or `C4 D4 E4 F4 G4 A4 B4`
- Easy for users to understand and type
- Can be extended to support LML format in future if needed

### 3. Scope
**Choice**: Notes mode only (initial implementation)
- Works with treble, bass, and grand staff
- Chord mode support can be added in phase 2
- Respects smoothness and hands settings like the standard random generator

### 4. Persistence
**Choice**: Store in generator settings
- Saved with presets (like other generator options)
- Persists across sessions via the existing settings mechanism
- Restores last-used selection when switching back to "random sel"

## Technical Architecture

### Files to Modify

1. **`static/js/st/data.jsx`**
   - Add new generator definition in `GENERATORS` array
   - Configure inputs (notes textarea, standard options)
   - Wire up to new generator class

2. **`static/js/st/generators.js`**
   - Create new `RandomSelectionNotes` class
   - Extends the existing `Generator` base class
   - Parses user input and picks random notes from the pool

3. **`static/js/st/components/sight_reading/settings_panel.jsx`**
   - Add support for "textarea" input type in `GeneratorSettings`
   - Render textarea for note/chord input

### New Generator Class

```javascript
export class RandomSelectionNotes extends Generator {
  constructor(userNotes, opts={}) {
    super(opts)
    this.generator = new MersenneTwister()
    this.userNotes = userNotes  // array of note strings like ["C4", "E4", "G4"]
    this.notesPerColumn = opts.notes || 1
    this.hands = opts.hands || 2
  }
  
  // Uses same handGroups logic as RandomNotes
  // Picks from user-specified notes instead of scale
}
```

### Input Configuration

```javascript
{
  name: "random sel",
  mode: "notes",
  inputs: [
    {
      name: "customNotes",
      label: "notes to use",
      type: "textarea",
      hint: "Enter space-separated notes (e.g., C4 E4 G4 B4)",
      default: "C4 D4 E4 F4 G4 A4 B4 C5"
    },
    {
      name: "notes",
      type: "range",
      min: 1,
      max: 5,
    },
    {
      name: "hands",
      type: "range",
      default: 2,
      min: 1,
      max: 2,
    },
    smoothInput,
    // Note: No noteRange input since user specifies exact notes
  ]
}
```

## Implementation Steps

### Phase 1: Core Functionality

1. ✅ **Create plan document** (this file)

2. ✅ **Add generator definition**
   - Added "random sel" entry to GENERATORS in `data.jsx`
   - Defined input fields (textarea for notes, standard controls)

3. ✅ **Create generator class**
   - Added `RandomSelectionNotes` class to `generators.js`
   - Parses space-separated note strings with validation
   - Filters invalid notes using regex pattern
   - Inherits from RandomNotes for hand grouping and smoothness

4. ✅ **Add textarea input support**
   - Modified `GeneratorSettings` in `settings_panel.jsx`
   - Added `renderTextarea` method
   - Handles multi-line input with hint text

5. ✅ **Build and test**
   - Successfully compiled with `./build.sh`
   - Tested in browser with custom note combinations
   - Validation works correctly - filters invalid notes gracefully
   - Generator produces notes from specified pool

### Phase 2: Enhancements (Future)

- Add visual note picker (clickable piano keyboard)
- Support chord mode
- Add LML format support for complex patterns
- Add validation and error messages for invalid notes
- Add preset templates (common scales, arpeggios, etc.)

## User Experience Flow

1. User clicks "Configure" button
2. User selects "random sel" from Generator section
3. Textarea appears with label "notes to use"
4. User types space-separated notes: `C4 E4 G4 B4 D5`
5. User adjusts other settings (notes per column, hands, smoothness)
6. Generator randomly picks from specified notes
7. Settings can be saved as a preset for later use

## Edge Cases & Validation

### Input Parsing
- Trim whitespace from input
- Filter out empty strings
- Validate note format (letter + optional accidental + octave number)
- Handle invalid notes gracefully (show warning or ignore)

### Note Pool Size
- Minimum 1 note required
- If pool too small for hands setting, use what's available
- If pool smaller than notes-per-column, cap at pool size

### Empty Input
- Show helpful message if no notes specified
- Provide default note set (e.g., C major scale)

## Testing Checklist

- [ ] Generator button appears in notes mode only
- [ ] Textarea renders when "random sel" is selected
- [ ] Can enter space-separated notes
- [ ] Generator picks from specified notes
- [ ] Smoothness setting works
- [ ] Hands setting works (1 or 2 hands)
- [ ] Notes-per-column setting works
- [ ] Can save as preset
- [ ] Preset loads correctly
- [ ] Works with treble staff
- [ ] Works with bass staff
- [ ] Works with grand staff
- [ ] Invalid notes handled gracefully

## Success Criteria

1. "random sel" button appears in Generator section
2. Clicking it shows textarea for note input
3. User can type notes like "C4 E4 G4"
4. Generator produces random notes from the specified pool
5. All standard generator options work (smoothness, hands, etc.)
6. Settings persist in presets
7. No console errors
8. UI remains responsive and intuitive

## Technical Notes

### Note Parsing
Use existing `parseNote()` function from `st/music` to validate notes.

### Reusing Existing Logic
The `RandomNotes` class already has excellent logic for:
- Distributing notes across hands (`handGroups` method)
- Picking notes with distribution (`pickNDist` method)
- Smoothness via base `Generator` class

The new `RandomSelectionNotes` class can reuse most of this logic, just changing the source note pool.

### State Management
Generator settings are stored in component state and passed to preset system. No changes needed to state management infrastructure.

## Future Considerations

- Visual note selector (piano keyboard interface)
- Import/export note sets
- Share note sets with other users
- Preset library of common patterns
- Support for chord voicings
- Pattern generation (ascending/descending, etc.)
