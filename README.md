# Claude Starter Kit

A personal task tracker that lives alongside Claude. You get a web dashboard for managing your day-to-day, and Claude learns how to help you with it.

## What's Inside

**A web dashboard** that runs quietly in the background on your Mac. Open it anytime at http://localhost:8745 to see your daily log, backlog, meeting prep, and active projects.

**Claude integration** - once installed, Claude knows about your tracker. You can ask things like:
- "What's on my plate today?"
- "Add a task: review the Q2 roadmap"
- "Show my backlog"
- "Create a topic for the product launch"
- "Do a weekly review"

Both work on the same files - update something in the dashboard and Claude sees it, and vice versa.

## Install

Open **Terminal** (press Cmd+Space, type "Terminal", hit Enter) and paste this:

```
cd ~/Downloads
curl -L https://github.com/imatza-rh/claude-starter/archive/refs/heads/main.zip -o claude-starter.zip
unzip claude-starter.zip
cd claude-starter-main
bash setup.sh
```

The dashboard opens automatically when it's done. It will also start on its own every time you restart your Mac.

## Quick Tour

The dashboard has five views (use the sidebar to switch):

- **Dashboard** - your day at a glance: what's done, what's open, what needs attention
- **Daily Log** - today's work list. Check things off as you go.
- **Backlog** - your bigger-picture task queue, organized by priority
- **Topics** - workspaces for things that take more than a day (a launch, a research project, a hiring round)
- **Meetings** - jot down discussion topics between meetings so you're always prepped

## Where Your Data Lives

Everything is stored as simple text files in a folder called `~/.claude/tracker/`. Nothing is sent anywhere - it's all on your Mac. You can open these files in any text editor if you ever want to.

## If Something Goes Wrong

**macOS blocks the app** - Go to System Settings > Privacy & Security, scroll down, and click "Allow Anyway" next to the tracker message. Then run `bash setup.sh` again.

**Dashboard won't open** - Paste this in Terminal to restart it:
```
launchctl unload ~/Library/LaunchAgents/com.tracker-web.plist
launchctl load ~/Library/LaunchAgents/com.tracker-web.plist
```

Then open http://localhost:8745 in your browser.

## Uninstall

Paste this in Terminal to remove everything (your data is kept):
```
launchctl unload ~/Library/LaunchAgents/com.tracker-web.plist
rm ~/Library/LaunchAgents/com.tracker-web.plist
rm ~/.local/bin/tracker
rm -rf ~/.claude/skills/tracker
```
