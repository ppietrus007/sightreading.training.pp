# Sightreading.training Build Process Documentation

## Table of Contents
1. [Overview](#overview)
2. [Build System Architecture](#build-system-architecture)
3. [MoonScript to Lua Compilation](#moonscript-to-lua-compilation)
4. [JavaScript Build Pipeline](#javascript-build-pipeline)
5. [CSS Build Pipeline](#css-build-pipeline)
6. [Asset Generation](#asset-generation)
7. [Complete Build Flow](#complete-build-flow)
8. [Development vs Production](#development-vs-production)
9. [Troubleshooting](#troubleshooting)

## Overview

The sightreading.training project uses a hybrid build system with multiple compilation stages:

1. **MoonScript → Lua** (Backend)
2. **JSX/JavaScript → Bundled JavaScript** (Frontend)
3. **SCSS → CSS** (Styling)
4. **PEG Grammar → JavaScript Parser** (Song parser)
5. **SVG → JavaScript Constants** (Staff assets)

The build process is orchestrated by a shell script (`build.sh`) that coordinates all these transformations.

## Build System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Source Files                            │
│                                                               │
│  Backend              Frontend              Assets           │
│  ├─ *.moon           ├─ *.jsx              ├─ *.scss        │
│  │  • app.moon      │  • main.jsx          │  • main.scss   │
│  │  • models/       │  • components/       │  • *.scss      │
│  │  • flows/        │  • pages/            │                │
│  │  • helpers/      │                      ├─ *.svg         │
│  │                  ├─ *.js                │  • clefs       │
│  │                  │  • music.js          │  • notes       │
│  │                  │  • generators.js     │                │
│  │                  │                      ├─ *.pegjs       │
│  │                  │                      │  • song_parser │
│  │                                         │                │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ build.sh
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Build Tools Pipeline                       │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  moonc   │  │  esbuild │  │  sassc   │  │  pegjs   │  │
│  │(MoonScript│  │ (Bundler)│  │   (CSS)  │  │ (Parser) │  │
│  │ Compiler)│  │          │  │          │  │          │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│       │             │              │              │         │
│       ▼             ▼              ▼              ▼         │
│  *.lua files    main.js        style.css    parser.js     │
│                 (bundled)      (compiled)   (generated)    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Deployed Application                      │
│                                                               │
│  Backend Runtime        Frontend Assets                      │
│  ├─ Lua files           ├─ main.js (React bundle)           │
│  │  (executed by        ├─ style.css                        │
│  │   LuaJIT/OpenResty)  ├─ soundfonts/                      │
│  │                      ├─ img/                              │
│  │                      └─ staff/                            │
└─────────────────────────────────────────────────────────────┘
```

## MoonScript to Lua Compilation

### What is MoonScript?

MoonScript is a programming language that compiles to Lua. It provides:
- More concise syntax (similar to CoffeeScript/Python)
- Object-oriented programming features
- Class system with inheritance
- List comprehensions
- String interpolation

### Compilation Process

```
┌──────────────────────────────────────────────────────────────┐
│             MoonScript Source (*.moon)                        │
│                                                                │
│  class MyModel extends Model                                  │
│    @primary_key: "id"                                         │
│    @table_name: "my_models"                                   │
│                                                                │
│    get_items: =>                                              │
│      db.select "* from items where user_id = ?", @id         │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ moonc compiler
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              Compiled Lua (*.lua)                             │
│                                                                │
│  local MyModel                                                │
│  do                                                            │
│    local _class_0                                             │
│    local _parent_0 = Model                                    │
│    local _base_0 = {                                          │
│      get_items = function(self)                               │
│        return db.select(                                      │
│          "* from items where user_id = ?",                    │
│          self.id                                              │
│        )                                                       │
│      end                                                       │
│    }                                                           │
│    _base_0.__index = _base_0                                  │
│    setmetatable(_base_0, _parent_0.__base)                    │
│    -- ... (more generated code)                               │
│  end                                                           │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ OpenResty/LuaJIT
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                   Runtime Execution                           │
│                                                                │
│  • LuaJIT Just-In-Time compilation                           │
│  • Executed within OpenResty/Nginx worker processes          │
│  • Direct integration with PostgreSQL via pgmoon              │
└──────────────────────────────────────────────────────────────┘
```

### Build Command

```bash
# Compile individual files
moonc app.moon cache_buster.moon config.moon models.moon

# Compile entire directories (recursive)
moonc models/ flows/ helpers/ applications/ widgets/ views/
```

### File Structure

```
Project Root/
├── app.moon                    → app.lua
├── config.moon                 → config.lua
├── models/
│   ├── users.moon             → models/users.lua
│   ├── songs.moon             → models/songs.lua
│   └── presets.moon           → models/presets.lua
├── flows/
│   ├── login.moon             → flows/login.lua
│   ├── songs.moon             → flows/songs.lua
│   └── presets.moon           → flows/presets.lua
└── helpers/
    ├── csrf.moon              → helpers/csrf.lua
    └── keys.moon              → helpers/keys.lua
```

**Important Notes:**
- `.moon` files are source files (checked into git)
- `.lua` files are generated (NOT checked into git)
- OpenResty loads and executes the `.lua` files
- The Lua files are regenerated on every build

## JavaScript Build Pipeline

### Overview

The frontend JavaScript uses React with JSX and is bundled using esbuild, a fast JavaScript bundler written in Go.

### Build Flow

```
┌──────────────────────────────────────────────────────────────┐
│           JavaScript Source Files (*.jsx, *.js)               │
│                                                                │
│  static/js/st/
│  ├── main.jsx                 ← Entry point
│  ├── components/
│  │   ├── app.jsx
│  │   ├── keyboard.jsx
│  │   ├── pages/
│  │   │   ├── sight_reading_page.jsx
│  │   │   ├── ear_training_page.jsx
│  │   │   └── play_along_page.jsx
│  │   └── sight_reading/
│  │       └── settings_panel.jsx
│  ├── music.js                ← Music theory library
│  ├── generators.js           ← Note generators
│  ├── note_list.js
│  └── midi.js                 ← MIDI handling
└──────────────────────────────────────────────────────────────┘
                            │
                            │ esbuild
                            │
          ┌─────────────────┴─────────────────┐
          │                                     │
          ▼                                     ▼
┌──────────────────┐              ┌──────────────────┐
│   main.js        │              │   main.js.map    │
│   (bundled)      │              │   (source map)   │
│                  │              │                  │
│ • All JSX→JS     │              │ • Debug mapping  │
│ • Tree shaking   │              │ • Line numbers   │
│ • Minification   │              │ • Original files │
│ • React bundled  │              │                  │
│ • Dependencies   │              │                  │
│   combined       │              │                  │
└──────────────────┘              └──────────────────┘
```

### Build Command

```bash
cd static
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx \
  --bundle \
  --sourcemap \
  --outfile=main.js \
  --log-level=warning
```

### Key Features

1. **JSX Transformation**: Converts JSX syntax to JavaScript
   ```jsx
   // Source JSX
   <button onClick={handleClick}>Click me</button>
   
   // Compiled JavaScript
   React.createElement("button", { onClick: handleClick }, "Click me")
   ```

2. **Module Bundling**: Combines all imports into a single file
   ```javascript
   // Multiple source files
   import React from "react"
   import Keyboard from "./components/keyboard"
   import {noteName} from "./music"
   
   // ↓ Bundled into single main.js file
   ```

3. **Tree Shaking**: Removes unused code
4. **Source Maps**: Maps compiled code back to source for debugging
5. **Fast Builds**: esbuild is significantly faster than Webpack/Parcel

### Module Resolution

The `NODE_PATH` environment variable tells Node.js where to find modules:

```bash
NODE_PATH=$(pwd)/js
# Now imports like "st/music" resolve to "js/st/music.js"
```

This allows imports like:
```javascript
import {KeySignature} from "st/music"
import Keyboard from "st/components/keyboard"
```

## CSS Build Pipeline

### SCSS to CSS Compilation

```
┌──────────────────────────────────────────────────────────────┐
│                SCSS Source Files (*.scss)                     │
│                                                                │
│  static/scss/
│  ├── main.scss               ← Entry point
│  ├── include/
│  │   ├── _variables.scss     ← Shared variables
│  │   └── _mixins.scss        ← Reusable mixins
│  ├── sight_reading_page.scss
│  ├── ear_training_page.scss
│  ├── keyboard.scss
│  └── staff.scss
└──────────────────────────────────────────────────────────────┘
                            │
                            │ sassc compiler
                            │
          ┌─────────────────┴─────────────────┐
          │                                     │
          │ Features:                           │
          │ • Variables ($color-primary)        │
          │ • Nesting (hierarchical rules)     │
          │ • Mixins (@include button-style)   │
          │ • Imports (@import "variables")    │
          │ • Math operations (width: 100% / 3)│
          │                                     │
          ▼                                     │
┌──────────────────┐                           │
│   style.css      │                           │
│   (compiled)     │                           │
│                  │                           │
│ • Plain CSS      │                           │
│ • All imports    │                           │
│   resolved       │                           │
│ • Variables      │                           │
│   substituted    │                           │
│ • Nested rules   │                           │
│   flattened      │                           │
└──────────────────┘                           │
```

### Build Command

```bash
cd static
sassc -I scss/ scss/main.scss style.css
```

The `-I scss/` flag sets the include path for `@import` statements.

### Example Compilation

```scss
// SCSS Source (main.scss)
$primary-color: #007bff;
$border-radius: 4px;

.button {
  background: $primary-color;
  border-radius: $border-radius;
  
  &:hover {
    background: darken($primary-color, 10%);
  }
  
  &.large {
    padding: 12px 24px;
  }
}
```

```css
/* Compiled CSS */
.button {
  background: #007bff;
  border-radius: 4px;
}

.button:hover {
  background: #0056b3;
}

.button.large {
  padding: 12px 24px;
}
```

## Asset Generation

### 1. PEG Parser Generation

Converts a grammar file into a JavaScript parser for the custom song format (LML).

```
┌──────────────────────────────────────────────────────────┐
│      song_parser_peg.pegjs (Grammar Definition)           │
│                                                            │
│  song = title? tempos? elements                           │
│  element = note / rest / chord                            │
│  note = pitch duration? accidental?                       │
│  pitch = [A-G] octave?                                    │
│  duration = "1" / "2" / "4" / "8" / "16"                │
│  // ... more grammar rules                                │
└──────────────────────────────────────────────────────────┘
                            │
                            │ pegjs
                            ▼
┌──────────────────────────────────────────────────────────┐
│      song_parser_peg.js (Generated Parser)                │
│                                                            │
│  • parse(input) function                                  │
│  • Tokenization logic                                     │
│  • Syntax tree construction                               │
│  • Error handling                                         │
└──────────────────────────────────────────────────────────┘
```

**Build Command:**
```bash
cd static/js/st
npx pegjs -o song_parser_peg.js song_parser_peg.pegjs
```

### 2. SVG Asset Generation

Converts SVG files into JavaScript constants for use in React.

```
┌──────────────────────────────────────────────────────────┐
│              SVG Source Files                             │
│                                                            │
│  static/staff/
│  ├── clef_g.svg      (Treble clef)                       │
│  ├── clef_f.svg      (Bass clef)                         │
│  ├── sharp.svg       (# symbol)                          │
│  ├── flat.svg        (♭ symbol)                          │
│  └── quarter_note.svg                                     │
└──────────────────────────────────────────────────────────┘
                            │
                            │ Shell script
                            │ (reads SVG content)
                            ▼
┌──────────────────────────────────────────────────────────┐
│      staff_assets.jsx (Generated Constants)               │
│                                                            │
│  import * as React from "react"                           │
│                                                            │
│  export const CLEF_G = `<svg>...</svg>`;                 │
│  export const CLEF_F = `<svg>...</svg>`;                 │
│  export const SHARP = `<svg>...</svg>`;                  │
│  export const FLAT = `<svg>...</svg>`;                   │
│  export const QUARTER_NOTE = `<svg>...</svg>`;           │
└──────────────────────────────────────────────────────────┘
```

**Build Command:**
```bash
cd static/js/st
(echo 'import * as React from "react"'; \
 for file in ../../staff/*.svg; do \
   echo "export const $(basename "$file" '.svg' | tr '[a-z]' '[A-Z]') = \`$(cat "$file")\`;"; \
 done) > staff_assets.jsx
```

This generates a file like:
```javascript
import * as React from "react"
export const CLEF_G = `<svg xmlns="http://www.w3.org/2000/svg">...</svg>`;
export const CLEF_F = `<svg xmlns="http://www.w3.org/2000/svg">...</svg>`;
// ... more exports
```

## Complete Build Flow

### Sequential Execution

The `build.sh` script executes all build steps in order:

```
┌─────────────────────────────────────────────────────────┐
│                   START: ./build.sh                      │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 1: Compile MoonScript                              │
│  ─────────────────────────────────────────────────      │
│  moonc app.moon cache_buster.moon config.moon models.moon│
│  moonc models/ flows/ helpers/ applications/             │
│        widgets/ views/                                   │
│                                                           │
│  Output: *.lua files                                     │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 2: Generate PEG Parser                             │
│  ─────────────────────────────────────────────────      │
│  cd static/js/st                                         │
│  npx pegjs -o song_parser_peg.js song_parser_peg.pegjs  │
│                                                           │
│  Output: song_parser_peg.js                              │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 3: Generate Staff Assets                           │
│  ─────────────────────────────────────────────────      │
│  (echo 'import * as React from "react"';                │
│   for file in ../../staff/*.svg; do                     │
│     echo "export const $(basename...) = \`$(cat...)\`;" │
│   done) > staff_assets.jsx                               │
│                                                           │
│  Output: staff_assets.jsx                                │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 4: Bundle JavaScript                               │
│  ─────────────────────────────────────────────────      │
│  cd static                                               │
│  NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx \      │
│    --bundle --sourcemap --outfile=main.js               │
│                                                           │
│  Output: main.js, main.js.map                            │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 5: Compile SCSS                                    │
│  ─────────────────────────────────────────────────      │
│  cd static                                               │
│  sassc -I scss/ scss/main.scss style.css                │
│                                                           │
│  Output: style.css                                       │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   BUILD COMPLETE                         │
│                                                           │
│  Application ready to run:                               │
│  • Backend: Lua files for OpenResty                     │
│  • Frontend: main.js + style.css                        │
│  • Assets: SVG constants, PEG parser                    │
└─────────────────────────────────────────────────────────┘
```

### Complete build.sh Script

```bash
#!/bin/bash
set -e  # Exit on error

echo "Building sightreading.training..."

# ============================================
# STEP 1: Compile MoonScript files
# ============================================
echo "Compiling MoonScript..."
moonc app.moon cache_buster.moon config.moon models.moon
moonc models/ flows/ helpers/ applications/ widgets/ views/

# ============================================
# STEP 2: Build frontend assets
# ============================================
echo "Building frontend assets..."

# Generate PEG parser
cd static/js/st
npx pegjs -o song_parser_peg.js song_parser_peg.pegjs

# Generate staff assets from SVG files
(echo 'import * as React from "react"'; \
 for file in ../../staff/*.svg; do \
   echo "export const $(basename "$file" '.svg' | tr '[a-z]' '[A-Z]') = \`$(cat "$file")\`;"; \
 done) > staff_assets.jsx
cd ../../..

# Bundle JavaScript with esbuild
cd static
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx \
  --bundle \
  --sourcemap \
  --outfile=main.js \
  --log-level=warning

# Compile SCSS to CSS
sassc -I scss/ scss/main.scss style.css
cd ..

echo "Build complete!"
```

## Development vs Production

### Development Build

**Characteristics:**
- Source maps enabled for debugging
- Non-minified code for readability
- Fast incremental builds
- Hot module replacement (if using a dev server)

**Typical workflow:**
```bash
# 1. Start development build
./build.sh

# 2. Start Lapis server
lapis server

# 3. Make changes to source files

# 4. Rebuild (only changed parts)
./build.sh

# 5. Refresh browser to see changes
```

### Production Build

**Optimizations needed:**
1. **JavaScript minification**: Add `--minify` to esbuild
2. **CSS minification**: Use `sassc --style compressed`
3. **Remove source maps**: Omit `--sourcemap` flag
4. **Cache busting**: Use `cache_buster.moon` to generate unique filenames
5. **Asset compression**: Enable gzip in Nginx config

**Production build.sh additions:**
```bash
# Production JavaScript build
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx \
  --bundle \
  --minify \
  --outfile=main.js \
  --log-level=warning

# Production CSS build
sassc --style compressed -I scss/ scss/main.scss style.css
```

### Deployment Workflow

```
┌─────────────────────────────────────────────────────────┐
│  1. Development                                          │
│  ─────────────────────────────────────────────────      │
│  • Edit source files                                     │
│  • Run ./build.sh                                        │
│  • Test locally with lapis server                        │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  2. Commit & Push                                        │
│  ─────────────────────────────────────────────────      │
│  git add .                                               │
│  git commit -m "description"                             │
│  git push origin master                                  │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  3. Deploy to Production                                 │
│  ─────────────────────────────────────────────────      │
│  • SSH to production server                              │
│  • git pull                                              │
│  • ./build.sh (production mode)                          │
│  • lapis build production                                │
│  • Restart OpenResty                                     │
└─────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Common Build Errors

#### 1. MoonScript Compilation Errors

**Error:** `moonc: command not found`

**Solution:**
```bash
# Install moonscript via luarocks
luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules install moonscript

# Add to path
eval $(luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules path)
```

**Error:** `Syntax error in app.moon`

**Solution:**
- Check MoonScript syntax (indentation is significant!)
- Look for missing colons, incorrect class definitions
- Use `moonc -l app.moon` to check for syntax errors without compiling

#### 2. JavaScript Build Errors

**Error:** `Cannot find module 'st/music'`

**Solution:**
```bash
# Ensure NODE_PATH is set correctly
cd static
NODE_PATH=$(pwd)/js npx esbuild ...
```

**Error:** `esbuild: command not found`

**Solution:**
```bash
# Install dependencies
npm install
```

**Error:** `Transform failed with 1 error: ERROR: Unexpected "<"`

**Solution:**
- This usually means JSX syntax isn't being recognized
- Ensure files with JSX have `.jsx` extension
- Check for missing import statements

#### 3. CSS Build Errors

**Error:** `sassc: command not found`

**Solution:**
```bash
# Install sassc
brew install sassc
```

**Error:** `Error: File to import not found or unreadable: variables`

**Solution:**
- Check the `-I` include path: `sassc -I scss/ ...`
- Ensure the imported file exists
- Check file path in `@import` statement

#### 4. Asset Generation Errors

**Error:** `pegjs: command not found`

**Solution:**
```bash
# Install dev dependencies
npm install
```

**Error:** `staff_assets.jsx is empty`

**Solution:**
- Check that SVG files exist in `static/staff/`
- Verify the shell script syntax
- Run the command manually to debug

### Build Performance Tips

1. **Incremental Builds**: Only rebuild what changed
   ```bash
   # Only rebuild frontend
   cd static && NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js
   
   # Only rebuild CSS
   cd static && sassc -I scss/ scss/main.scss style.css
   ```

2. **Watch Mode**: Auto-rebuild on file changes
   ```bash
   # For JavaScript (esbuild has built-in watch)
   cd static && NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js --watch
   
   # For SCSS (use nodemon or similar)
   npm install -g nodemon
   nodemon --watch static/scss -e scss --exec "cd static && sassc -I scss/ scss/main.scss style.css"
   ```

3. **Parallel Builds**: Run independent tasks simultaneously
   ```bash
   # Using GNU parallel or &
   moonc models/ & moonc flows/ & moonc helpers/ & wait
   ```

### Debugging Generated Code

#### Lua Files

1. Check generated `.lua` files for correctness
2. Add `print()` statements for debugging
3. Check Lapis logs: `tail -f logs/error.log`

#### JavaScript Bundle

1. Use source maps in browser DevTools
2. Search for your original code in the Sources tab
3. Set breakpoints in JSX files (not main.js)

#### CSS Output

1. Check compiled `style.css` for expected rules
2. Use browser DevTools to inspect applied styles
3. Look for CSS specificity issues

### Clean Build

If you encounter persistent issues, try a clean build:

```bash
# Remove all generated files
rm -f app.lua config.lua models.moon *.lua
rm -f models/*.lua flows/*.lua helpers/*.lua
rm -f applications/*.lua widgets/*.lua views/*.lua views/*/*.lua
rm -f static/main.js static/main.js.map static/style.css
rm -f static/js/st/song_parser_peg.js static/js/st/staff_assets.jsx

# Rebuild everything
./build.sh
```

### File Watching Issues

If files aren't being picked up:

1. **Check file permissions**: `ls -la <file>`
2. **Verify file paths**: Ensure paths are relative to correct directory
3. **Check gitignore**: Make sure source files aren't ignored
4. **Clear caches**: Restart your editor/IDE

### Memory Issues

For large projects:

```bash
# Increase Node.js memory limit
NODE_OPTIONS="--max-old-space-size=4096" ./build.sh
```

## Summary

The sightreading.training build process involves:

1. **MoonScript → Lua**: Backend code compilation
2. **JSX/JS → Bundle**: Frontend React app bundling
3. **SCSS → CSS**: Stylesheet compilation  
4. **Asset Generation**: Parser and SVG constants

Key points to remember:

- `.moon` and `.jsx` files are source (committed to git)
- `.lua`, `.js` bundles, and `.css` are generated (not committed)
- Run `./build.sh` after any source code changes
- Use source maps for debugging
- Production builds need additional optimization flags

For more information, see:
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [SETUP.md](SETUP.md) - Development environment setup
- [Lapis Documentation](http://leafo.net/lapis/)
- [esbuild Documentation](https://esbuild.github.io/)
