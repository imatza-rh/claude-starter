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

# Check macOS + Apple Silicon
if [ "$(uname -s)" != "Darwin" ]; then
    echo "ERROR: This kit requires macOS. You're running $(uname -s)."
    exit 1
fi
if [ "$(uname -m)" != "arm64" ]; then
    echo "ERROR: This kit requires Apple Silicon (M1/M2/M3/M4)."
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
for f in daily-log.md backlog.md meetings.md quarterly.md; do
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
    YESTERDAY=$(date -v-1d +%Y-%m-%d)
    cat >> "$TRACKER_DIR/daily-log.md" << DAILYEOF

## $TODAY

- [x] Set up personal tracker and Claude integration
- [ ] Finalize PRD for self-serve onboarding
- [ ] Review design mocks for settings page

## $YESTERDAY

- [x] Wrote user interview questions for push notifications
- [x] Prepped stakeholder update deck for Friday
- [x] Reviewed 3 design iterations for onboarding flow
- [ ] Draft Q3 roadmap priorities
  Pushed to next week - waiting on eng capacity estimates
DAILYEOF
fi

# Create sample topic if none exist
if [ -z "$(ls -A "$TRACKER_DIR/topics" 2>/dev/null)" ]; then
    TOPIC_DIR="$TRACKER_DIR/topics/mobile-push-notifications"
    mkdir -p "$TOPIC_DIR"
    CREATED=$(date -v-2d +%Y-%m-%d)
    cat > "$TOPIC_DIR/topic.md" << TOPICEOF
# Mobile Push Notifications

<!-- status: active -->
<!-- created: $CREATED | updated: $TODAY -->

(Example topic - replace with your own project or delete this one.)

Q3 priority #1. Extending our in-app notification system to mobile push.
VP approved budget for user research in Q2 - starting with discovery.

## Status
**State**: Research & discovery
**Next**: Schedule first round of user interviews

## Tasks
- [x] Review competitor push notification UX (Slack, Linear, Notion)
- [x] Pull analytics on email notification open rates by category
- [ ] Write user interview guide for push notification preferences
- [ ] Schedule 8 user interviews across segments
- [ ] Define notification categories and default preferences
- [ ] Draft PRD with eng for technical feasibility review
- [ ] Design opt-in flow mockups with design team

## Notes
- Email open rate is 23% overall, but 67% for payment-related - users DO want alerts, just not all of them
- Competitor analysis: Slack lets users set per-channel preferences, Linear does smart batching
- Key risk: alert fatigue. Need granular controls from day 1

## Links
(Add links to your docs, specs, and research here)

## Questions
- [x] What's the technical lift for push vs in-app? -> Eng says 4-6 weeks with existing infra
- [ ] Should we support Android and iOS simultaneously or phase?
- [ ] Do we need a notification preferences page or inline controls?
TOPICEOF
    echo "  -> Created sample topic: mobile-push-notifications"
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
    TRACKER_VIEWS="dashboard,daily,backlog,topics,meetings,quarterly" ~/.local/bin/tracker serve --no-browser &
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
