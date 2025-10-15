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
