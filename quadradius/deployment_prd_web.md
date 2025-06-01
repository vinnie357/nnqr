# Web Deployment PRD - Quadradius

## Overview
Deploy Quadradius as a WebAssembly application playable in modern web browsers.

## Goals
- Zero-installation gameplay
- Cross-platform compatibility via browsers
- Easy sharing and viral potential
- Maintain gameplay quality despite WASM limitations

## Technical Requirements

### Build Requirements
- Rust with wasm32 target
- wasm-bindgen
- wasm-pack or trunk
- Web server for hosting

### Browser Requirements
- Chrome 90+
- Firefox 89+
- Safari 15+
- Edge 90+
- WebGL 2.0 support
- WebAssembly support

## Implementation Steps

### 1. Setup WASM Build Target
```bash
# Add WASM target
rustup target add wasm32-unknown-unknown

# Install build tools
cargo install wasm-pack
cargo install trunk
cargo install basic-http-server
```

### 2. Code Modifications

#### Update Cargo.toml
```toml
[dependencies]
bevy = { version = "0.12", default-features = false, features = [
    "bevy_winit",
    "bevy_render",
    "bevy_sprite",
    "bevy_text",
    "bevy_ui",
    "webgl2",
    "x11"  # Remove this for web
]}

[target.'cfg(target_arch = "wasm32")'.dependencies]
wasm-bindgen = "0.2"
web-sys = "0.3"
console_error_panic_hook = "0.1"
```

#### Add Web Entry Point
```rust
// In main.rs
#[cfg(target_arch = "wasm32")]
use wasm_bindgen::prelude::*;

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen(start)]
pub fn main_web() {
    console_error_panic_hook::set_once();
    main();
}
```

### 3. Asset Loading Changes
```rust
// Conditional asset loading
#[cfg(target_arch = "wasm32")]
const ASSET_FOLDER: &str = "assets/";

#[cfg(not(target_arch = "wasm32"))]
const ASSET_FOLDER: &str = "./assets/";
```

### 4. Build Process

#### Using Trunk (Recommended)
Create `Trunk.toml`:
```toml
[build]
target = "index.html"
release = true
public_url = "/quadradius/"

[watch]
ignore = ["target"]

[serve]
port = 8080
```

Create `index.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quadradius</title>
    <style>
        body {
            margin: 0;
            overflow: hidden;
            background: #000;
        }
        canvas {
            display: block;
        }
    </style>
</head>
<body>
    <link data-trunk rel="rust" data-wasm-opt="z" />
</body>
</html>
```

Build command:
```bash
trunk build --release
```

### 5. Web-Specific Limitations & Solutions

#### No Multithreading
- Bevy's parallel systems disabled
- May impact performance with many entities
- Solution: Optimize systems for single-threaded execution

#### Audio Limitations
- Web Audio API only
- Potential latency/glitches
- Solution: Preload audio, use simple formats

#### File System
- No direct file access
- Solution: Use IndexedDB for save games

#### Memory Constraints
- Browsers limit WASM memory (typically 2GB)
- Solution: Efficient asset management

### 6. Hosting Options

#### GitHub Pages (Free)
```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: jetli/trunk-action@v0.4.0
      - run: trunk build --release --public-url /quadradius/
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

#### Netlify (Free tier)
- Drag & drop deployment
- Custom domain support
- Global CDN

#### Itch.io (Game-focused)
- Built-in game portal
- Payment processing
- Community features

### 7. Performance Optimizations

#### Asset Optimization
- Compress textures (WebP format)
- Minimize asset sizes
- Use texture atlases

#### WASM Optimization
```bash
# Optimize WASM size
wasm-opt -Oz -o output.wasm input.wasm

# Enable LTO in Cargo.toml
[profile.release]
lto = true
opt-level = 'z'  # Optimize for size
```

#### Loading Screen
```javascript
// Show progress while loading WASM
let progress = document.getElementById('progress');
let script = document.createElement('script');
script.src = 'quadradius.js';
script.onprogress = (e) => {
    if (e.lengthComputable) {
        progress.value = (e.loaded / e.total) * 100;
    }
};
```

## Testing Requirements

### Browser Compatibility
- [ ] Chrome (Windows, Mac, Linux)
- [ ] Firefox (Windows, Mac, Linux)
- [ ] Safari (Mac, iOS)
- [ ] Edge (Windows)
- [ ] Mobile browsers (touch controls)

### Performance Testing
- [ ] Load time < 10 seconds on 3G
- [ ] 30+ FPS on low-end devices
- [ ] Memory usage < 500MB

### Feature Testing
- [ ] Game saves persist (IndexedDB)
- [ ] Audio plays correctly
- [ ] Fullscreen support
- [ ] Touch controls (mobile)

## Mobile Considerations
- Touch-friendly UI (minimum 44x44px buttons)
- Viewport meta tag
- Orientation lock (landscape)
- Virtual keyboard handling

## Analytics Integration
```javascript
// Track game events
gtag('event', 'level_complete', {
    'level': currentLevel,
    'score': playerScore
});
```

## Monetization Options
- Web Monetization API
- Optional ads (non-intrusive)
- "Support development" links
- Premium downloadable version

## Security Considerations
- Content Security Policy headers
- HTTPS required for clipboard/audio
- Prevent clickjacking
- Validate all inputs

## Progressive Web App (PWA)
Create `manifest.json`:
```json
{
    "name": "Quadradius",
    "short_name": "Quadradius",
    "start_url": "/",
    "display": "fullscreen",
    "orientation": "landscape",
    "theme_color": "#000000",
    "background_color": "#000000",
    "icons": [
        {
            "src": "icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        }
    ]
}
```

## Estimated Timeline
- WASM setup and build: 1 day
- Web-specific code changes: 2 days
- Testing across browsers: 2 days
- Deployment setup: 1 day
- Mobile optimization: 1 day
- **Total: 7 days**

## Success Metrics
- < 5MB initial download
- < 10 second load time
- 60+ FPS on desktop browsers
- 30+ FPS on mobile
- < 1% JavaScript errors
- 95%+ browser compatibility