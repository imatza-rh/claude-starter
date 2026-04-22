# Claude Starter Kit

A personal task tracker with a web dashboard and Claude Cowork/Desktop integration.

## What You Get

- **Web Dashboard** at http://localhost:8745 - visual task board that runs in the background
- **Claude Integration** - ask Claude about your tasks, priorities, and planning
- **Plain Markdown** - your data is simple text files, never locked in a proprietary format

## Setup

Open **Terminal** (press Cmd+Space, type "Terminal", press Enter) and paste these commands:

**Option A: With git**
```bash
git clone https://github.com/imatza-rh/claude-starter.git
cd claude-starter
bash setup.sh
```

**Option B: Without git**

Download the zip from https://github.com/imatza-rh/claude-starter/archive/refs/heads/main.zip, double-click to extract, then:
```bash
cd ~/Downloads/claude-starter-main
bash setup.sh
```

That's it. The web dashboard opens automatically.

## How It Works

### Web Dashboard

The tracker web UI runs in the background and starts automatically when you log in. Open http://localhost:8745 in any browser.

Features:
- **Dashboard** - daily progress, active work, needs attention
- **Daily Log** - rolling work log with checkboxes
- **Backlog** - organized task queue (Priority Focus, To Do, Ideas, etc.)
- **Topics** - workspaces for multi-day efforts
- **Meetings** - recurring meeting prep with discussion topics

### Claude Integration

The tracker skill teaches Claude how to read and write your tracker files. Ask things like:

- "What's on my plate today?"
- "Add a task: review Q2 roadmap draft"
- "Show my backlog"
- "Create a topic for the product launch"
- "Do a weekly review"
- "Mark task 3 done"

Claude and the web dashboard work on the same files - changes from one appear instantly in the other.

## Your Files

All data lives in `~/.claude/tracker/`:

| File | Purpose |
|------|---------|
| `daily-log.md` | Rolling daily work log |
| `backlog.md` | Cross-project task queue with sections |
| `meetings.md` | Recurring meeting prep and outcomes |
| `topics/` | Active work contexts (one folder per topic) |

These are plain markdown files. You can edit them by hand in any text editor.

## Troubleshooting

### "tracker" won't run (macOS security)

If macOS blocks the binary, go to **System Settings > Privacy & Security** and click **Allow Anyway** next to the tracker message. Then run setup.sh again.

Or run this in Terminal:
```bash
xattr -d com.apple.quarantine ~/.local/bin/tracker
```

### Port 8745 already in use

Something else is using that port. Check what:
```bash
lsof -i :8745
```

### Web dashboard not loading

Check if the service is running:
```bash
launchctl list | grep tracker
```

Restart it:
```bash
launchctl unload ~/Library/LaunchAgents/com.tracker-web.plist
launchctl load ~/Library/LaunchAgents/com.tracker-web.plist
```

Check logs:
```bash
cat /tmp/tracker-web.log
```

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.tracker-web.plist
rm ~/Library/LaunchAgents/com.tracker-web.plist
rm ~/.local/bin/tracker
rm -rf ~/.claude/skills/tracker
# Your tracker data in ~/.claude/tracker/ is preserved
```
