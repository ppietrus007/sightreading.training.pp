# Setup Guide for sightreading.training.pp

This document provides instructions for setting up the development environment for the sightreading.training project.

## Prerequisites

- macOS (tested on macOS Sequoia)
- Homebrew package manager
- Git

## Installation Steps

### 1. Install System Dependencies

```bash
# Add OpenResty tap to Homebrew
brew tap openresty/brew

# Install OpenResty (required for GeoIP module)
brew install geoip --force
brew reinstall openresty/brew/openresty

# Install PostgreSQL 14
brew install postgresql@14

# Install LuaRocks (Lua package manager)
brew install luarocks

# Start PostgreSQL service
brew services start postgresql@14
```

**Note:** Tup build system is not available for macOS, so we'll use alternative build methods.

### 2. Install Local Lua Dependencies

```bash
# Create local lua_modules directory
mkdir -p lua_modules

# Install Lua packages locally to the project
# (Replace /opt/homebrew/opt/openresty/luajit with your OpenResty LuaJIT path if different)

luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules install lapis
luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules install moonscript
luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules install bcrypt
luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules install tableshape
```

### 3. Install JavaScript Dependencies

```bash
npm install
```

### 4. Configure Environment

Add the local Lua modules to your path by adding this to your shell config (~/.zshrc or ~/.bash_profile):

```bash
# Add local Lua modules to path
eval $(luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules path)
```

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

### 5. Set Up Database

```bash
# Create the database
createdb -U postgres sightreading

# Load the schema
psql -U postgres sightreading < schema.sql

# Run migrations
eval $(luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules path)
lapis migrate
```

### 6. Build the Project

**Note:** The Tup build system is only available on Linux. On macOS, use the following manual build steps:

#### Install Build Dependencies

```bash
# Install sassc for compiling SCSS
brew install sassc
```

#### Compile All Files

```bash
# 1. Compile all MoonScript files to Lua
moonc app.moon cache_buster.moon config.moon models.moon
moonc models/ flows/ helpers/ applications/ widgets/ views/

# 2. Generate the PEG parser
cd static/js/st
npx pegjs -o song_parser_peg.js song_parser_peg.pegjs
cd ../../..

# 3. Generate staff assets
cd static/js/st
(echo 'import * as React from "react"'; for file in ../../staff/*.svg; do echo "export const $(basename "$file" '.svg' | tr '[a-z]' '[A-Z]') = \`$(cat "$file")\`;"; done) > staff_assets.jsx
cd ../../..

# 4. Build JavaScript bundle
cd static
NODE_PATH=/Users/pawel/Documents/GitHub/sightreading.training.pp/static/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js --log-level=warning
cd ..

# 5. Compile SCSS to CSS
cd static
sassc -I scss/ scss/main.scss main.css
cd ..
```

#### Quick Rebuild Script

For convenience, you can create a `build.sh` script:

```bash
#!/bin/bash
set -e

echo "Building sightreading.training..."

# Compile MoonScript files
echo "Compiling MoonScript..."
moonc app.moon cache_buster.moon config.moon models.moon
moonc models/ flows/ helpers/ applications/ widgets/ views/

# Build frontend assets
echo "Building frontend assets..."

# PEG parser
cd static/js/st
npx pegjs -o song_parser_peg.js song_parser_peg.pegjs

# Staff assets
(echo 'import * as React from "react"'; for file in ../../staff/*.svg; do echo "export const $(basename "$file" '.svg' | tr '[a-z]' '[A-Z]') = \`$(cat "$file")\`;"; done) > staff_assets.jsx
cd ../../..

# JavaScript bundle
cd static
NODE_PATH=$(pwd)/js npx esbuild js/st/main.jsx --bundle --sourcemap --outfile=main.js --log-level=warning

# CSS
sassc -I scss/ scss/main.scss style.css
cd ..

echo "Build complete!"
```

Make it executable:
```bash
chmod +x build.sh
```

### 7. Run the Development Server

```bash
# Start Lapis development server (runs on port 9090)
lapis server
```

Visit http://localhost:9090 in your browser.

## Useful Commands

### Database Management

```bash
# Create test database
make test_db

# Create database backup
make checkpoint

# Restore from latest backup
make restore_checkpoint

# Update schema.sql from current database
make schema.sql
```

### Linting

```bash
# Lint MoonScript files
make lint

# Lint JavaScript files
make lint_js
# or
npm run lint_js
```

### Running Tests

```bash
# Install busted (Lua test framework)
luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules install busted

# Run tests
busted
```

## Troubleshooting

### OpenResty Installation Issues

If you encounter GeoIP errors during OpenResty installation:
1. Install geoip with `brew install geoip --force` (even though it's deprecated)
2. Then reinstall OpenResty with `brew reinstall openresty/brew/openresty`

### Database Connection Issues

Make sure PostgreSQL is running:
```bash
brew services list
brew services start postgresql@14
```

### Lua Module Path Issues

If Lua modules aren't found:
```bash
# Ensure you've run this in your current shell session:
eval $(luarocks --lua-dir=/opt/homebrew/opt/openresty/luajit --tree=lua_modules path)
```

### Port Already in Use

If port 9090 is already in use, you can change it in `config.moon`:
```moonscript
port 9090  # Change this to another port
```

## Project Structure

- `app.moon` - Main application routes
- `models/` - Database models (Users, Songs, Presets, etc.)
- `flows/` - Business logic (login, songs, presets, etc.)
- `helpers/` - Utility functions
- `static/js/st/` - React frontend application
- `static/scss/` - Stylesheets
- `views/` - Server-side templates
- `lua_modules/` - Local Lua dependencies (not committed to git)

## Additional Resources

- [Lapis Documentation](http://leafo.net/lapis/)
- [MoonScript Documentation](https://moonscript.org/)
- [OpenResty Documentation](https://openresty.org/)
- [Project README](README.md)
