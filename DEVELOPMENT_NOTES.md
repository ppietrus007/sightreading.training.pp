# Development Notes for sightreading.training.pp

## Project Overview

**sightreading.training.pp** is a web application for practicing sight reading music with MIDI keyboard support. The site generates random musical notation and validates user input in real-time.

### Technology Stack

**Backend:**
- **Lapis** - Lua web framework running on OpenResty/nginx
- **MoonScript** - Compiles to Lua (all `.moon` files)
- **PostgreSQL** - Database for users, presets, songs, statistics

**Frontend:**
- **React** - UI framework
- **Sass/SCSS** - CSS preprocessor
- **esbuild** - JavaScript bundler
- **PEG.js** - Parser generator for song notation

**Build System:**
- Originally uses **Tup** (Linux-only)
- On macOS: Manual build process via shell scripts

## Critical Build System Knowledge

### The SCSS Import Problem (FIXED)

**Issue:** The `static/scss/main.scss` file was missing imports for page-specific styles.

**What was wrong:**
```scss
// Only had these imports:
@import "include/common";
@import "../fonts/Raleway/stylesheet";
```

**What it needed (FIXED):**
```scss
@import "include/common";
@import "../fonts/Raleway/stylesheet";

// Page-specific styles (19 imports added):
@import "sight_reading_page";
@import "settings_panel";
@import "has_sidebar";
@import "staff";
@import "keyboard";
@import "slider";
@import "select";
@import "lightbox";
@import "device_picker_lightbox";
@import "midi_selector";
@import "midi_instrument_picker";
@import "stats_lightbox";
@import "ear_training_page";
@import "flash_card_page";
@import "play_along_page";
@import "guide_page";
@import "songs";
@import "song_editor";
@import "stats_page";
```

**Result:** CSS size went from 12KB → 60KB, fixing all layout issues.

### Build Process Components

The build process has 5 main steps that must be executed in order:

#### 1. Compile MoonScript to Lua
```bash
moonc app.moon cache_buster.moon config.moon models.moon
moonc models/ flows/ helpers/ applications/ widgets/ views/
```
- Converts all `.moon` files to `.lua` files
- Required before running the server

#### 2. Generate PEG Parser
```bash
cd static/js/st
npx pegjs -o song_parser_peg.js song_parser_peg.pegjs
```
- Creates `song_parser_peg.js` from grammar definition
- Used for parsing musical notation syntax

#### 3. Generate Staff Assets
```bash
cd static/js/st
(echo 'import * as React from "react"'; for file in ../../staff/*.svg; do echo "export const $(basename "$file" '.svg' | tr '[a-z]' '[A-Z]') = \`$(cat "$file")\`;"; done) > staff_assets.jsx
```
- Converts SVG files into React components
- Creates exports like `CLEF_G`, `CLEF_F`, `SHARP`, `FLAT`, etc.

#### 4. Bundle JavaScript with esbuild
```bash
cd static
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js
```
- **Critical:** Must set `NODE_PATH` to `static/js` for module resolution
- Bundles entire React app into `static/main.js`
- Creates sourcemap for debugging

#### 5. Compile SCSS to CSS
```bash
cd static
sassc -I scss/ scss/main.scss style.css
```
- **Critical:** Output must be `style.css` (not `main.css`)
- The layout template looks for `/static/style.css`
- Must include `-I scss/` for imports to work

## Project Structure

### Backend Architecture

```
app.moon                    # Main routes and request handling
config.moon                 # Environment configuration
models.moon                 # Model registry

models/                     # Database models
  ├── users.moon           # User authentication/profiles
  ├── songs.moon           # Song library
  ├── presets.moon         # User sight-reading settings
  ├── song_user_time.moon  # Practice statistics
  └── hourly_hits.moon     # Analytics

flows/                      # Business logic layer
  ├── login.moon           # Authentication flow
  ├── songs.moon           # Song management
  ├── presets.moon         # Settings management
  └── hits.moon            # Statistics tracking

helpers/                    # Utility functions
  ├── app.moon             # Request helpers
  ├── csrf.moon            # CSRF protection
  ├── keys.moon            # Musical key utilities
  └── shapes.moon          # Data validation

views/                      # Server-side templates
  └── layout.moon          # Base HTML template

widgets/                    # Reusable view components
  └── page.moon            # Page wrapper
```

### Frontend Architecture

```
static/js/st/
  ├── main.jsx             # Entry point (imports app.jsx)
  ├── app.jsx              # React app initialization
  ├── components/          # React components
  │   ├── app.jsx          # Main app component
  │   └── [other components]
  ├── song_parser_peg.pegjs # Musical notation grammar
  └── staff_assets.jsx     # Generated SVG exports (don't edit)

static/scss/
  ├── main.scss            # Main stylesheet (imports all others)
  ├── include/
  │   └── common.scss      # CSS variables and mixins
  ├── sight_reading_page.scss  # Main page layout
  ├── settings_panel.scss      # Settings sidebar
  ├── has_sidebar.scss         # Sidebar layout system
  ├── staff.scss               # Musical staff styling
  ├── keyboard.scss            # Piano keyboard
  └── [16 other page-specific files]
```

## Key Files and Their Roles

### `views/layout.moon` - Template System
- Generates base HTML structure
- **Critical:** References `/static/style.css` and `/static/main.js`
- Includes cache buster parameter for assets
- Loads different assets based on environment (dev vs production)

### `static/js/st/main.jsx` - Frontend Entry
```jsx
import {init} from "st/app"
init(window.ST_initial_session)
```
- Simple entry point that initializes the app
- Relies on module resolution via NODE_PATH

### `cache_buster.moon` - Asset Versioning
- Generates unique timestamps for cache busting
- Used in template: `?#{buster}` on asset URLs

## Adding New Features

### Adding a New Page/View

1. **Create MoonScript view:**
   ```bash
   # Create views/new_page.moon
   moonc views/new_page.moon
   ```

2. **Add route in app.moon:**
   ```moonscript
   "/new_page": =>
     render: "new_page"
   ```

3. **If it needs styles, create SCSS:**
   ```bash
   # Create static/scss/new_page.scss
   ```

4. **Import in main.scss:**
   ```scss
   @import "new_page";
   ```

5. **Rebuild:**
   ```bash
   ./build.sh
   ```

### Adding Frontend Components

1. **Create component in `static/js/st/components/`**
2. **Import in parent component**
3. **Rebuild JavaScript:**
   ```bash
   cd static
   NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js
   ```

### Modifying Styles

1. **Edit SCSS files in `static/scss/`**
2. **Ensure your file is imported in `main.scss`** (check the import list!)
3. **Rebuild CSS:**
   ```bash
   cd static
   sassc -I scss/ scss/main.scss style.css
   ```

### Adding Database Models

1. **Create model in `models/`:**
   ```moonscript
   -- models/new_model.moon
   import Model from require "lapis.db.model"
   
   class NewModel extends Model
     @timestamp: true  -- Adds created_at, updated_at
     @primary_key: "id"
   ```

2. **Register in `models.moon`:**
   ```moonscript
   NewModel: require "models.new_model"
   ```

3. **Create migration:**
   ```bash
   lapis generate migration create_new_model
   ```

4. **Edit migration file and run:**
   ```bash
   lapis migrate
   ```

5. **Compile MoonScript:**
   ```bash
   moonc models/
   ```

## Common Development Tasks

### Starting Development

```bash
# 1. Start PostgreSQL
brew services start postgresql@14

# 2. Set up environment
eval $(luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules path)

# 3. Build everything
./build.sh

# 4. Start server
lapis server

# 5. Visit http://localhost:9090
```

### Making Changes

**Backend (MoonScript) changes:**
```bash
moonc <changed-file>.moon
# Server auto-reloads, no restart needed
```

**Frontend (React/JSX) changes:**
```bash
cd static
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js
# Refresh browser
```

**Style (SCSS) changes:**
```bash
cd static
sassc -I scss/ scss/main.scss style.css
# Refresh browser
```

**Full rebuild:**
```bash
./build.sh
```

### Testing

```bash
# Run backend tests
busted

# Check for syntax errors in MoonScript
moonc -l app.moon models/ flows/ helpers/
```

## Important Gotchas

### 1. Module Resolution in JavaScript
**Problem:** `import from "st/app"` fails with module not found

**Solution:** Always set NODE_PATH when running esbuild:
```bash
cd static
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js
```

### 2. CSS File Name
**Problem:** CSS changes not appearing

**Solution:** Output file MUST be `style.css` (not `main.css`):
```bash
sassc -I scss/ scss/main.scss style.css
```

The template in `views/layout.moon` looks for `/static/style.css`.

### 3. SCSS Import Order
**Problem:** New SCSS file styles not appearing

**Solution:** Add import to `static/scss/main.scss`:
```scss
@import "your_new_file";
```

### 4. MoonScript Auto-reload
**Note:** Lapis watches compiled Lua files, not MoonScript files.

**Workflow:**
1. Edit `.moon` file
2. Run `moonc <file>.moon` to compile to `.lua`
3. Server detects `.lua` change and reloads

### 5. Generated Files (Don't Edit Directly)
These files are auto-generated during build:
- `static/js/st/staff_assets.jsx` - Generated from SVG files
- `static/js/st/song_parser_peg.js` - Generated from `.pegjs` grammar
- All `.lua` files - Compiled from `.moon` files

## Environment Configuration

### Development vs Production

The app checks `config._name` to determine environment:

**Development mode** (`config.moon`):
```moonscript
config "development", ->
  port 9090
  -- Uses /static/style.css and /static/main.js
```

**Production mode**:
```moonscript
config "production", ->
  -- Uses /static/style.min.css and /static/main.min.js
```

To force production assets in dev (for testing):
- Add `?prod_assets=1` to URL

## Database Schema

Key tables:
- `users` - User accounts and authentication
- `presets` - User's sight-reading configuration
- `songs` - Song library with notation
- `song_user_time` - Practice session statistics
- `hourly_hits` - Analytics/hit tracking

To update schema after changes:
```bash
make schema.sql
```

## Debugging Tips

### View Lua Compilation Errors
```bash
moonc -l <file>.moon
```

### Check SCSS Compilation
```bash
sassc -I scss/ scss/main.scss /dev/null
# Will show syntax errors without creating output
```

### Inspect JavaScript Bundle
```bash
# The sourcemap allows debugging original source
# Look for main.js.map in static/
```

### Server Logs
```bash
tail -f logs/error.log
tail -f logs/access.log
```

### Database Queries
```bash
psql -U postgres sightreading
```

## Quick Reference Commands

```bash
# Full rebuild
./build.sh

# Start server
lapis server

# Stop server
lapis term

# Database migrations
lapis migrate

# Create migration
lapis generate migration migration_name

# Compile single MoonScript file
moonc file.moon

# Compile directory
moonc models/

# Lint MoonScript
make lint

# Run tests
busted

# Update schema
make schema.sql
```

## Resources

- [Lapis Documentation](http://leafo.net/lapis/)
- [MoonScript Language Guide](https://moonscript.org/)
- [OpenResty](https://openresty.org/)
- [React Documentation](https://react.dev/)
- [Sass/SCSS Guide](https://sass-lang.com/guide)
- [PEG.js Documentation](https://pegjs.org/)

## Current System State

**Working Features:**
- ✅ Full sight reading interface with musical staff
- ✅ MIDI keyboard input support
- ✅ Settings panel with all configuration options
- ✅ Piano keyboard display
- ✅ User authentication (login/register)
- ✅ Preset saving/loading
- ✅ Statistics tracking
- ✅ Multiple pages (Staff, Ear Training, Flash Cards, Play Along, Guide)

**Build System:**
- ✅ All SCSS files properly imported in main.scss
- ✅ CSS compiling correctly (60KB output)
- ✅ JavaScript bundling with proper NODE_PATH
- ✅ PEG parser generation
- ✅ SVG asset generation
- ✅ Automated build script (./build.sh)

**Server:**
- ✅ Running on http://localhost:9090
- ✅ Auto-reload on Lua file changes
- ✅ PostgreSQL database connected
- ✅ All routes working

Ready for feature development! 🚀
