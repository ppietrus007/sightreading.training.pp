# Random Selection Generator Enhancements

## Feature Requests

### 1. Key Specification
Allow users to specify a key (e.g., "C major", "G major") and automatically generate all notes from that key's scale.

**Benefits:**
- Easier than typing individual notes
- Ensures notes are in the correct key
- Good for practicing specific keys

**Implementation Options:**

**Option A - Dropdown**: Add key signature dropdown
- Uses existing KeySignature class
- Generates scale automatically (major, minor, etc.)
- Simple and clean UI

**Option B - Text Input**: Parse key from text (e.g., "C major", "Am")
- More flexible
- Requires parsing logic
- Could support multiple scale types

**Recommended**: Option A with scale type dropdown

### 2. Chord Specification
Allow users to specify chords (e.g., "Cmaj7 Dm7 G7") instead of individual notes.

**Benefits:**
- Practice chord progressions
- Learn chord voicings
- Useful for jazz and advanced practice

**Implementation Options:**

**Option A - Text Input**: Parse chord names from textarea
- Format: "Cmaj7 Dm7 G7 Em"
- Uses existing Chord class
- Can specify inversions: "Cmaj7/1" for first inversion

**Option B - Separate Mode**: Add "chord" mode to random sel
- Toggle between notes and chords
- Separate input for each

**Recommended**: Option A - extend existing textarea to support both

## Proposed UI Design

```
Generator: [random sel]

Input type: [notes v] [chords] [key]  (radio buttons or tabs)

--- If "notes" selected ---
notes to use:
[C4 E4 G4 B4                    ]
Hint: Space-separated notes

--- If "chords" selected ---
chords to use:
[Cmaj7 Dm7 Em7 G7               ]
Hint: Space-separated chords (e.g., Cmaj7, Dm, G7)

--- If "key" selected ---
Key: [C v]  Scale: [major v]
Octave range: [4] to [5]

[notes slider]
[hands slider]
[smoothness slider]
```

## Implementation Plan

### Phase 1: Key Specification (Simpler)

1. Add input type selector (radio buttons: notes/chords/key)
2. Add key signature dropdown (C, D, E, F, G, A, B with sharps/flats)
3. Add scale type dropdown (major, natural minor, harmonic minor, melodic minor)
4. Add octave range inputs (min/max octaves)
5. Update RandomSelectionNotes to handle key mode
6. Generate scale notes automatically

### Phase 2: Chord Specification

1. Parse chord names from textarea
2. Use existing Chord class to generate chord notes
3. Support common chord types: M, m, 7, maj7, m7, dim, aug
4. Support inversions (optional)
5. Generator picks random chord and returns its notes

## Questions for User

1. **Key specification**: 
   - Which scale types to support? (major, minor, harmonic minor, melodic minor, blues, etc.)
   - Should it cover multiple octaves or just one?
   - Default to whole staff range or allow user to specify?

2. **Chord specification**:
   - Should chords be played as block chords or arpeggiated?
   - Support inversions?
   - Which chord types are most important? (triads, 7ths, extended chords?)

3. **Combined features**:
   - Should we support chord progressions in specific keys? (e.g., "ii-V-I in C major")
   
Let me know your preferences and I'll implement accordingly!
