#!/bin/bash
set -euo pipefail

# Claude Starter Kit - One-command installer
# Installs: tracker web UI + Claude Cowork/Code skill + template files + Tracker app

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
BIN_DIR="$HOME_DIR/.local/bin"
TRACKER_DIR="$HOME_DIR/.claude/tracker"
SKILLS_DIR="$HOME_DIR/.claude/skills/tracker"
CLAUDE_MD="$HOME_DIR/.claude/CLAUDE.md"
PLIST_NAME="com.tracker-web"
PLIST_DIR="$HOME_DIR/Library/LaunchAgents"
TRACKER_URL="http://localhost:8745"
APP_DIR="$HOME_DIR/Applications/Tracker.app"

echo "=== Claude Starter Kit ==="
echo ""

# Check architecture (binary is arm64 only)
if [ "$(uname -m)" != "arm64" ]; then
    echo "ERROR: This kit requires a Mac with Apple Silicon (M1/M2/M3/M4)."
    echo "Your Mac is $(uname -m), which isn't supported."
    exit 1
fi

# 1. Binary
echo "[1/8] Installing tracker binary..."
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/bin/tracker" "$BIN_DIR/tracker"
chmod +x "$BIN_DIR/tracker"
xattr -d com.apple.quarantine "$BIN_DIR/tracker" 2>/dev/null || true
echo "  -> $BIN_DIR/tracker"

# 2. Tracker directory + templates
echo "[2/8] Setting up tracker files..."
mkdir -p "$TRACKER_DIR/topics"
for f in daily-log.md backlog.md meetings.md; do
    if [ ! -f "$TRACKER_DIR/$f" ]; then
        cp "$SCRIPT_DIR/templates/$f" "$TRACKER_DIR/$f"
        echo "  -> Created $TRACKER_DIR/$f"
    else
        echo "  -> $TRACKER_DIR/$f already exists, skipping"
    fi
done

# Add today's date section to fresh daily log
if ! grep -q "^## " "$TRACKER_DIR/daily-log.md" 2>/dev/null; then
    TODAY=$(date +%Y-%m-%d)
    printf "\n## %s\n\n- [x] Set up my personal tracker\n- [ ] Explore the dashboard at http://localhost:8745\n" "$TODAY" >> "$TRACKER_DIR/daily-log.md"
fi

# 3. Skill
echo "[3/8] Installing tracker skill..."
mkdir -p "$SKILLS_DIR"
cp "$SCRIPT_DIR/claude/skills/tracker/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "  -> $SKILLS_DIR/SKILL.md"

# 4. CLAUDE.md
echo "[4/8] Setting up CLAUDE.md..."
mkdir -p "$(dirname "$CLAUDE_MD")"
if [ ! -f "$CLAUDE_MD" ]; then
    cp "$SCRIPT_DIR/claude/CLAUDE.md" "$CLAUDE_MD"
    echo "  -> Created $CLAUDE_MD"
elif ! grep -q "Task Tracker" "$CLAUDE_MD"; then
    echo "" >> "$CLAUDE_MD"
    sed -n '/^## Task Tracker/,$ p' "$SCRIPT_DIR/claude/CLAUDE.md" >> "$CLAUDE_MD"
    echo "  -> Appended tracker section to existing $CLAUDE_MD"
else
    echo "  -> $CLAUDE_MD already has tracker section, skipping"
fi

# 5. Tracker.app (created before service so it exists even if launchctl fails)
echo "[5/8] Creating Tracker app..."
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/MacOS/Tracker" << 'APPSCRIPT'
#!/bin/bash
URL="http://localhost:8745"
if ! curl -s "$URL/api/health" > /dev/null 2>&1; then
    TRACKER_VIEWS="dashboard,daily,backlog,topics,meetings" ~/.local/bin/tracker serve --no-browser &
    for i in 1 2 3 4 5; do
        sleep 1
        curl -s "$URL/api/health" > /dev/null 2>&1 && break
    done
fi
open "$URL"
APPSCRIPT
chmod +x "$APP_DIR/Contents/MacOS/Tracker"

cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Tracker</string>
    <key>CFBundleDisplayName</key>
    <string>Tracker</string>
    <key>CFBundleIdentifier</key>
    <string>com.tracker.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Tracker</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST

if [ -f "$SCRIPT_DIR/bin/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/bin/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi
xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true
mdimport "$APP_DIR" 2>/dev/null || true
echo "  -> $APP_DIR"
echo "     Tip: Cmd+Space, type 'Tracker' to launch. Then keep in Dock!"

# 6. LaunchAgent
echo "[6/8] Setting up auto-start service..."
mkdir -p "$PLIST_DIR"
PLIST_FILE="$PLIST_DIR/$PLIST_NAME.plist"
sed "s|__HOME__|$HOME_DIR|g" "$SCRIPT_DIR/launchd/$PLIST_NAME.plist" > "$PLIST_FILE"
echo "  -> $PLIST_FILE"

# 7. Load service
echo "[7/8] Starting tracker web service..."
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"
echo "  -> Service loaded (auto-starts on login)"

# 8. Open tracker
echo "[8/8] Opening tracker..."
STARTED=false
for i in $(seq 1 6); do
    sleep 1
    if curl -s "$TRACKER_URL/api/health" > /dev/null 2>&1; then
        open "$TRACKER_URL"
        echo "  -> Opened $TRACKER_URL"
        STARTED=true
        break
    fi
done
if [ "$STARTED" = false ]; then
    echo "  -> WARNING: Web server didn't start. Check /tmp/tracker-web.log for errors."
    echo "     You may need to allow the binary in System Settings > Privacy & Security."
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Your tracker is ready:"
echo "  Tracker app:  Cmd+Space, type 'Tracker', hit Enter  (then keep in Dock!)"
echo "  Web UI:       $TRACKER_URL  (always running)"
echo "  Files:        $TRACKER_DIR/"
echo ""
echo "Claude Cowork/Desktop will automatically use the tracker skill"
echo "when you ask about tasks, priorities, or work planning."
echo ""
echo "Try asking Claude: 'what's on my plate today?'"
echo ""

# Check if ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "NOTE: To use the 'tracker' command in Terminal, add this to your shell config:"
    echo ""
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo "  source ~/.zshrc"
    echo ""
fi
