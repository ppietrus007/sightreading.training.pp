# Sightreading.training System Architecture

## Table of Contents
1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [System Architecture](#system-architecture)
4. [Backend Architecture](#backend-architecture)
5. [Frontend Architecture](#frontend-architecture)
6. [Data Flow](#data-flow)
7. [MIDI Integration](#midi-integration)
8. [Database Schema](#database-schema)

## Overview

Sightreading.training is a web-based music education application that helps users practice sight-reading, learn songs, and train musical skills. The system uses a hybrid backend (Lua/MoonScript on OpenResty/Nginx) with a React frontend.

## Technology Stack

### Backend
- **Web Server**: OpenResty (Nginx + LuaJIT)
- **Web Framework**: Lapis (Lua/MoonScript web framework)
- **Language**: MoonScript (compiles to Lua)
- **Database**: PostgreSQL 14
- **ORM**: Lapis models (built-in)

### Frontend
- **Framework**: React 18.2
- **Language**: JavaScript (JSX)
- **Bundler**: esbuild
- **Routing**: React Router v6
- **Styling**: SCSS (compiled with sassc)
- **Music Rendering**: Two.js (vector graphics)
- **Audio**: SoundFont Player, Web MIDI API

### Build Tools
- **MoonScript Compiler**: moonc
- **JavaScript Bundler**: esbuild
- **CSS Preprocessor**: sassc
- **Parser Generator**: PEG.js
- **Package Managers**: LuaRocks (Lua), npm (JavaScript)

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          CLIENT BROWSER                          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    React Application                      │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────────┐  │  │
│  │  │   Pages    │  │ Components  │  │  Music Libraries │  │  │
│  │  │            │  │             │  │                  │  │  │
│  │  │ • Sight    │  │ • Staff     │  │ • NoteList      │  │  │
│  │  │   Reading  │  │ • Keyboard  │  │ • ChordList     │  │  │
│  │  │ • Ear      │  │ • Settings  │  │ • MusicTheory   │  │  │
│  │  │   Training │  │ • Lightbox  │  │ • Generators    │  │  │
│  │  │ • Flash    │  │             │  │                  │  │  │
│  │  │   Cards    │  │             │  │                  │  │  │
│  │  │ • Play     │  │             │  │                  │  │  │
│  │  │   Along    │  │             │  │                  │  │  │
│  │  └────────────┘  └─────────────┘  └──────────────────┘  │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐│  │
│  │  │              Web MIDI API Integration                 ││  │
│  │  │  • MIDI Input/Output                                  ││  │
│  │  │  • Device Selection                                   ││  │
│  │  │  • Message Forwarding                                 ││  │
│  │  └──────────────────────────────────────────────────────┘│  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Web Audio API                          │  │
│  │  • SoundFont Playback                                     │  │
│  │  • Audio Synthesis                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/HTTPS
                              │ WebSocket (future)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          SERVER SIDE                             │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              OpenResty (Nginx + LuaJIT)                   │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │              Lapis Web Framework                    │  │  │
│  │  │  (Compiled from MoonScript to Lua)                  │  │  │
│  │  │                                                      │  │  │
│  │  │  ┌──────────────┐  ┌──────────────┐               │  │  │
│  │  │  │   Routes     │  │   Flows      │               │  │  │
│  │  │  │              │  │              │               │  │  │
│  │  │  │ • /          │  │ • login      │               │  │  │
│  │  │  │ • /login     │  │ • presets    │               │  │  │
│  │  │  │ • /register  │  │ • songs      │               │  │  │
│  │  │  │ • /stats     │  │ • hits       │               │  │  │
│  │  │  │ • /api/*     │  │ • formatter  │               │  │  │
│  │  │  └──────────────┘  └──────────────┘               │  │  │
│  │  │                                                      │  │  │
│  │  │  ┌──────────────┐  ┌──────────────┐               │  │  │
│  │  │  │   Models     │  │   Helpers    │               │  │  │
│  │  │  │              │  │              │               │  │  │
│  │  │  │ • Users      │  │ • CSRF       │               │  │  │
│  │  │  │ • Songs      │  │ • Keys       │               │  │  │
│  │  │  │ • Presets    │  │ • Shapes     │               │  │  │
│  │  │  │ • HourlyHits │  │ • Models     │               │  │  │
│  │  │  └──────────────┘  └──────────────┘               │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              │ SQL                               │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    PostgreSQL 14                          │  │
│  │                                                            │  │
│  │  Tables:                                                   │  │
│  │  • users                                                   │  │
│  │  • songs                                                   │  │
│  │  │  presets                                               │  │
│  │  • hourly_hits                                            │  │
│  │  • song_user_times                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Backend Architecture

### Request Flow

```
Client Request
     │
     ▼
┌─────────────────┐
│  Nginx/OpenResty│
│   (Port 9090)   │
└─────────────────┘
     │
     ▼
┌─────────────────┐
│  Lapis Router   │  ← Routes defined in app.moon
└─────────────────┘
     │
     ├─── Static Files (/static/*) → Served directly by Nginx
     │
     ├─── API Routes (/api/*)
     │         │
     │         ▼
     │    ┌────────────┐
     │    │   Flows    │  ← Business logic (login, presets, etc.)
     │    └────────────┘
     │         │
     │         ▼
     │    ┌────────────┐
     │    │   Models   │  ← Database access layer
     │    └────────────┘
     │         │
     │         ▼
     │    ┌────────────┐
     │    │ PostgreSQL │
     │    └────────────┘
     │
     └─── Page Routes (/, /login, /stats, etc.)
               │
               ▼
          ┌────────────┐
          │   Views    │  ← Server-side templates
          └────────────┘
               │
               ▼
          HTML Response (with embedded React app)
```

### MoonScript/Lua Compilation

```
┌──────────────────┐
│  app.moon        │  MoonScript source file
│  models/*.moon   │
│  flows/*.moon    │
│  helpers/*.moon  │
└──────────────────┘
         │
         │ moonc compiler
         ▼
┌──────────────────┐
│  app.lua         │  Compiled Lua files
│  models/*.lua    │
│  flows/*.lua     │
│  helpers/*.lua   │
└──────────────────┘
         │
         │ LuaJIT execution
         ▼
┌──────────────────┐
│  Running Server  │  Executed by OpenResty
└──────────────────┘
```

### Key Backend Components

1. **app.moon**: Main application entry point
   - Defines routes
   - Configures middleware
   - Sets up session management

2. **models/**: Database models (ORM)
   - `users.moon`: User authentication and profiles
   - `songs.moon`: Song data and metadata
   - `presets.moon`: User-saved generator presets
   - `hourly_hits.moon`: Analytics tracking
   - `song_user_times.moon`: User practice statistics

3. **flows/**: Business logic modules
   - `login.moon`: Authentication flow
   - `presets.moon`: Preset management
   - `songs.moon`: Song CRUD operations
   - `hits.moon`: Analytics recording
   - `formatter.moon`: Data formatting utilities

4. **helpers/**: Utility functions
   - `csrf.moon`: CSRF token generation/validation
   - `keys.moon`: Music theory helpers
   - `shapes.moon`: Data validation schemas
   - `models.moon`: Model utilities

## Frontend Architecture

### Component Hierarchy

```
<App> (BrowserRouter)
  │
  ├─ <Layout>
  │    │
  │    ├─ <Header>
  │    │    └─ MIDI device status, user menu
  │    │
  │    └─ <Routes>
  │         │
  │         ├─ "/" → <SightReadingPage>
  │         │         │
  │         │         ├─ <SettingsPanel>
  │         │         │    ├─ Staff selector
  │         │         │    ├─ Generator selector
  │         │         │    └─ Key signature selector
  │         │         │
  │         │         ├─ <Staff> (G/F/Grand)
  │         │         │    ├─ <StaffNotes>
  │         │         │    │    ├─ <WholeNotes>
  │         │         │    │    └─ <LedgerLines>
  │         │         │    │
  │         │         │    └─ Key signature display
  │         │         │
  │         │         └─ <Keyboard>
  │         │              └─ Virtual piano keys
  │         │
  │         ├─ "/ear-training/*" → <EarTrainingPage>
  │         │                      ├─ Interval recognition
  │         │                      └─ Melody playback
  │         │
  │         ├─ "/flash-cards/*" → <FlashCardPage>
  │         │                     ├─ Note math
  │         │                     └─ Chord identification
  │         │
  │         ├─ "/play-along/*" → <PlayAlongPage>
  │         │                    ├─ Song selector
  │         │                    ├─ Song editor
  │         │                    └─ Playback controls
  │         │
  │         ├─ "/stats" → <StatsPage>
  │         ├─ "/login" → <LoginPage>
  │         └─ "/register" → <RegisterPage>
  │
  └─ Lightbox System
       ├─ <DevicePickerLightbox> (MIDI device selection)
       ├─ <StatsLightbox> (detailed statistics)
       └─ Custom lightboxes per page
```

### Music Rendering Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Music Domain Layer                     │
│                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   NoteList   │  │  ChordList   │  │    Scales    │  │
│  │              │  │              │  │              │  │
│  │ • Note array │  │ • Chord array│  │ • Major      │  │
│  │ • Matching   │  │ • Matching   │  │ • Minor      │  │
│  │ • Filtering  │  │ • Generation │  │ • Blues      │  │
│  └──────────────┘  └──────────────┘  │ • Chromatic  │  │
│                                       └──────────────┘  │
│                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │KeySignature  │  │  Generators  │  │    Chord     │  │
│  │              │  │              │  │              │  │
│  │ • Count      │  │ • Random     │  │ • Intervals  │  │
│  │ • Accidentals│  │ • Triads     │  │ • Inversions │  │
│  │ • Enharmonic │  │ • Sevenths   │  │ • Shapes     │  │
│  └──────────────┘  │ • Progression│  └──────────────┘  │
│                     └──────────────┘                     │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                  Rendering Layer                          │
│                                                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │              <Staff> Components                   │   │
│  │                                                    │   │
│  │  <GStaff>  → Treble clef (G clef)                │   │
│  │  <FStaff>  → Bass clef (F clef)                  │   │
│  │  <GrandStaff> → Both staves combined             │   │
│  └──────────────────────────────────────────────────┘   │
│                           │                               │
│                           ▼                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │           <StaffNotes> Component                  │   │
│  │                                                    │   │
│  │  • Converts NoteList to visual notes             │   │
│  │  • Calculates positions on staff                 │   │
│  │  • Handles ledger lines                          │   │
│  │  • Renders accidentals                           │   │
│  └──────────────────────────────────────────────────┘   │
│                           │                               │
│                           ▼                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │              SVG Rendering                        │   │
│  │                                                    │   │
│  │  • Staff lines (5 horizontal lines)              │   │
│  │  • Clef symbols (from SVG assets)                │   │
│  │  • Note heads (whole/half/quarter)               │   │
│  │  • Accidentals (sharps/flats/naturals)           │   │
│  │  • Ledger lines (extended lines)                 │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

## Data Flow

### MIDI Input to Note Display

```
1. Physical MIDI Device
        │
        │ MIDI messages
        ▼
2. Browser Web MIDI API
        │
        │ navigator.requestMIDIAccess()
        ▼
3. <Layout> Component (app.jsx)
        │
        │ onMidiMessage(message)
        ▼
4. Current Page Ref
        │ (e.g., SightReadingPage)
        │
        │ onMidiMessage(message)
        ▼
5. Parse MIDI Message
        │
        │ NOTE_EVENTS[type] = "noteOn" | "noteOff"
        │ noteName(pitch) → e.g., "Eb5"
        ▼
6. Update State
        │
        │ pressNote(note) → setState({ heldNotes: {...} })
        │ releaseNote(note) → setState({ heldNotes: {...} })
        ▼
7. React Re-render
        │
        │ heldNotes prop → <Staff>
        ▼
8. Staff Rendering
        │
        │ <StaffNotes> filters and renders held notes
        │ Grey notes shown for incorrect presses
        │ Green highlight for correct notes
        ▼
9. Visual Feedback on Staff
```

### Note Generation and Checking

```
1. User selects settings
        │
        │ Generator (random, triads, etc.)
        │ Key signature (C, Eb, etc.)
        │ Staff (treble, bass, grand)
        ▼
2. Generate Notes
        │
        │ refreshNoteList()
        │ generator.create()
        ▼
3. NoteList/ChordList created
        │
        │ fillBuffer(10) → generates 10 notes ahead
        │ currentColumn() → gets current note(s) to play
        ▼
4. Display on Staff
        │
        │ <Staff> renders current and upcoming notes
        ▼
5. User plays notes on MIDI keyboard
        │
        │ MIDI → pressNote() → heldNotes updated
        ▼
6. Check if correct
        │
        │ checkPress() → notes.matchesHead(touchedNotes)
        ▼
7a. CORRECT            7b. INCORRECT
    │                      │
    │ Hit!                 │ Miss!
    ▼                      ▼
    notes.shift()          noteShaking = true
    notes.pushRandom()     (visual feedback)
    stats.hitNotes()       stats.missNotes()
    │                      │
    ▼                      ▼
    Show next note         Keep current note
```

## MIDI Integration

### Device Selection and Connection

```
┌──────────────────────────────────────────────────────────┐
│                  MIDI Device Management                   │
│                                                            │
│  1. User clicks MIDI icon                                 │
│     │                                                      │
│     ▼                                                      │
│  2. <DevicePickerLightbox> opens                         │
│     │                                                      │
│     ├─ Input Devices:                                     │
│     │  ┌──────────────────────────────────────┐         │
│     │  │ [ ] Roland Digital Piano              │         │
│     │  │ [x] MIDI Fighter Twister             │         │
│     │  │ [ ] Virtual MIDI Keyboard            │         │
│     │  └──────────────────────────────────────┘         │
│     │                                                      │
│     ├─ Output Devices:                                    │
│     │  ┌──────────────────────────────────────┐         │
│     │  │ ( ) None                              │         │
│     │  │ (•) Internal (SoundFont)             │         │
│     │  │ ( ) MIDI Out to External Device      │         │
│     │  └──────────────────────────────────────┘         │
│     │                                                      │
│     ├─ Options:                                           │
│     │  [x] Forward MIDI to output                        │
│     │                                                      │
│     ▼                                                      │
│  3. Save configuration                                    │
│     │                                                      │
│     ├─ Write to local storage (config.js)                │
│     ├─ Set midiInput.onmidimessage handler               │
│     ├─ Initialize output channel                          │
│     │                                                      │
│     ▼                                                      │
│  4. MIDI flow active                                      │
│     │                                                      │
│     Input → onMidiMessage() → Current Page               │
│                │                                           │
│                └─ (if forward enabled) → Output Device    │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

### MIDI Message Flow

```
MIDI Hardware → Web MIDI API → Lapis MIDIInput Wrapper
                                        │
                    ┌───────────────────┴───────────────────┐
                    │                                         │
                    ▼                                         ▼
            Note On/Off Handler                    Sustain Pedal Handler
                    │                                         │
                    ▼                                         ▼
            pressNote()/releaseNote()              pedalOn()/pedalOff()
                    │                                         │
                    ▼                                         ▼
            Update heldNotes state              Manage sustained notes
                    │                                         │
                    └───────────────────┬───────────────────┘
                                        │
                                        ▼
                              React State Update
                                        │
                                        ▼
                                Staff Re-renders
                                        │
                                        ▼
                              Visual Feedback
```

## Database Schema

```
┌────────────────────────────────────────────────────────────┐
│                          users                              │
├────────────────────────────────────────────────────────────┤
│ id               SERIAL PRIMARY KEY                         │
│ username         VARCHAR(255) UNIQUE NOT NULL              │
│ encrypted_password VARCHAR(255) NOT NULL                    │
│ email            VARCHAR(255)                               │
│ created_at       TIMESTAMP                                  │
│ updated_at       TIMESTAMP                                  │
└────────────────────────────────────────────────────────────┘
                    │
                    │ 1:N
                    ▼
┌────────────────────────────────────────────────────────────┐
│                        presets                              │
├────────────────────────────────────────────────────────────┤
│ id               SERIAL PRIMARY KEY                         │
│ user_id          INTEGER REFERENCES users(id)              │
│ name             VARCHAR(255)                               │
│ preset_data      TEXT (JSON)                               │
│ created_at       TIMESTAMP                                  │
│ updated_at       TIMESTAMP                                  │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                          songs                              │
├────────────────────────────────────────────────────────────┤
│ id               SERIAL PRIMARY KEY                         │
│ user_id          INTEGER REFERENCES users(id)              │
│ title            VARCHAR(255) NOT NULL                      │
│ artist           VARCHAR(255)                               │
│ song_data        TEXT (LML format)                         │
│ created_at       TIMESTAMP                                  │
│ updated_at       TIMESTAMP                                  │
└────────────────────────────────────────────────────────────┘
                    │
                    │ 1:N
                    ▼
┌────────────────────────────────────────────────────────────┐
│                   song_user_times                           │
├────────────────────────────────────────────────────────────┤
│ id               SERIAL PRIMARY KEY                         │
│ song_id          INTEGER REFERENCES songs(id)              │
│ user_id          INTEGER REFERENCES users(id)              │
│ play_time        INTEGER (seconds)                         │
│ created_at       TIMESTAMP                                  │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                      hourly_hits                            │
├────────────────────────────────────────────────────────────┤
│ id               SERIAL PRIMARY KEY                         │
│ hour             TIMESTAMP (rounded to hour)               │
│ page             VARCHAR(255)                               │
│ hits             INTEGER                                    │
│ created_at       TIMESTAMP                                  │
└────────────────────────────────────────────────────────────┘
```

## Performance Considerations

### Frontend Optimization
1. **React.PureComponent**: Used for components that frequently re-render (Staff, StaffNotes)
2. **Direct DOM manipulation**: For high-frequency updates (staff offset during scrolling)
3. **Memoization**: Cached generator instances and note calculations
4. **Code splitting**: Lazy loading for different page routes

### Backend Optimization
1. **LuaJIT**: Just-in-time compilation for Lua code
2. **Nginx caching**: Static asset caching with proper headers
3. **Connection pooling**: PostgreSQL connection reuse
4. **Minimal server-side rendering**: Most UI rendered client-side

### MIDI Performance
1. **Direct state updates**: Bypass React for immediate visual feedback
2. **Debouncing**: Prevent excessive re-renders from rapid MIDI messages
3. **Efficient note matching**: O(1) lookups using object keys

## Security Features

1. **CSRF Protection**: Token-based CSRF prevention on all POST requests
2. **Password Hashing**: bcrypt for secure password storage
3. **Session Management**: Secure session cookies with Lapis session middleware
4. **Input Validation**: Server-side validation using tableshape
5. **SQL Injection Prevention**: Parameterized queries through Lapis ORM

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Production Server                     │
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Nginx (Reverse Proxy)                │  │
│  │              Port 80/443 (HTTPS)                  │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                               │
│                          ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │          OpenResty + Lapis Application            │  │
│  │              (LuaJIT Runtime)                     │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                               │
│                          ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │            PostgreSQL Database                    │  │
│  │           (with connection pooling)               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                           │
│  Static Assets served by Nginx:                          │
│  • /static/main.js (bundled React app)                  │
│  • /static/style.css (compiled SCSS)                    │
│  • /static/soundfonts/ (audio samples)                  │
│  • /static/img/ (images)                                │
└─────────────────────────────────────────────────────────┘
```

## Future Enhancements

1. **WebSocket Integration**: Real-time multiplayer features
2. **Progressive Web App**: Offline support with service workers
3. **WebAssembly**: Performance-critical music processing
4. **Cloud Storage**: Sync user data across devices
5. **Mobile Apps**: Native iOS/Android versions
6. **Advanced Analytics**: Machine learning for personalized recommendations

## References

- [Lapis Documentation](http://leafo.net/lapis/)
- [OpenResty Documentation](https://openresty.org/)
- [React Documentation](https://react.dev/)
- [Web MIDI API](https://webaudio.github.io/web-midi-api/)
- [Two.js Documentation](https://two.js.org/)
