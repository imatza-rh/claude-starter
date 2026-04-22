#!/bin/bash
set -euo pipefail

# Claude Starter Kit - One-command installer
# Installs: tracker web UI + Claude Cowork/Code skill + template files

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
BIN_DIR="$HOME_DIR/.local/bin"
TRACKER_DIR="$HOME_DIR/.claude/tracker"
SKILLS_DIR="$HOME_DIR/.claude/skills/tracker"
CLAUDE_MD="$HOME_DIR/.claude/CLAUDE.md"
PLIST_NAME="com.tracker-web"
PLIST_DIR="$HOME_DIR/Library/LaunchAgents"

echo "=== Claude Starter Kit ==="
echo ""

# 1. Binary
echo "[1/7] Installing tracker binary..."
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/bin/tracker" "$BIN_DIR/tracker"
chmod +x "$BIN_DIR/tracker"
xattr -d com.apple.quarantine "$BIN_DIR/tracker" 2>/dev/null || true
echo "  -> $BIN_DIR/tracker"

# 2. Tracker directory + templates
echo "[2/7] Setting up tracker files..."
mkdir -p "$TRACKER_DIR"
for f in daily-log.md backlog.md meetings.md; do
    if [ ! -f "$TRACKER_DIR/$f" ]; then
        cp "$SCRIPT_DIR/templates/$f" "$TRACKER_DIR/$f"
        echo "  -> Created $TRACKER_DIR/$f"
    else
        echo "  -> $TRACKER_DIR/$f already exists, skipping"
    fi
done

# 3. Skill
echo "[3/7] Installing tracker skill..."
mkdir -p "$SKILLS_DIR"
cp "$SCRIPT_DIR/claude/skills/tracker/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "  -> $SKILLS_DIR/SKILL.md"

# 4. CLAUDE.md
echo "[4/7] Setting up CLAUDE.md..."
if [ ! -f "$CLAUDE_MD" ]; then
    mkdir -p "$(dirname "$CLAUDE_MD")"
    cp "$SCRIPT_DIR/claude/CLAUDE.md" "$CLAUDE_MD"
    echo "  -> Created $CLAUDE_MD"
else
    echo "  -> $CLAUDE_MD already exists, skipping"
    echo "     (You can manually merge from $SCRIPT_DIR/claude/CLAUDE.md)"
fi

# 5. LaunchAgent
echo "[5/7] Setting up auto-start service..."
mkdir -p "$PLIST_DIR"
PLIST_FILE="$PLIST_DIR/$PLIST_NAME.plist"
sed "s|__HOME__|$HOME_DIR|g" "$SCRIPT_DIR/launchd/$PLIST_NAME.plist" > "$PLIST_FILE"
echo "  -> $PLIST_FILE"

# 6. Load service
echo "[6/7] Starting tracker web service..."
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"
echo "  -> Service loaded (auto-starts on login)"

# 7. Open browser
echo "[7/7] Opening tracker..."
sleep 1
if curl -s http://localhost:8745/api/health > /dev/null 2>&1; then
    open "http://localhost:8745"
    echo "  -> Opened http://localhost:8745"
else
    echo "  -> Waiting for server to start..."
    for i in $(seq 1 5); do
        sleep 1
        if curl -s http://localhost:8745/api/health > /dev/null 2>&1; then
            open "http://localhost:8745"
            echo "  -> Opened http://localhost:8745"
            break
        fi
    done
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Your tracker is ready:"
echo "  Web UI:  http://localhost:8745  (always running in background)"
echo "  Files:   $TRACKER_DIR/"
echo ""
echo "Claude Cowork/Desktop will automatically use the tracker skill"
echo "when you ask about tasks, priorities, or work planning."
echo ""
echo "Try asking Claude: 'what's on my plate today?'"
echo ""

# Check if ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "NOTE: To use the tracker command in Terminal, add this to your shell config:"
    echo ""
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo "  source ~/.zshrc"
    echo ""
fi
