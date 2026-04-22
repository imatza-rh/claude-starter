# Claude Starter Kit

A personal task tracker with a web dashboard and Claude integration.
Two ways to manage your work - a visual board you can click around, and Claude who can read and update the same board for you.

## Install

Open **Terminal** (Cmd+Space, type "Terminal", hit Enter).

Paste all 5 lines at once and hit Enter:

```
cd ~/Downloads
curl -L https://github.com/imatza-rh/claude-starter/archive/refs/heads/main.zip -o claude-starter.zip
unzip -o claude-starter.zip
cd claude-starter-main
bash setup.sh
```

Done. The dashboard opens in your browser.

> **Tip:** Bookmark http://localhost:8745 for quick access. That's your dashboard - it runs in the background and starts automatically when your Mac boots.

## What You Get

### The Dashboard (http://localhost:8745)

A web app running locally on your Mac with five views:

**Daily Log** - Your today list. Add tasks, check them off. Anything left open carries forward to tomorrow.

**Backlog** - The bigger picture. Organized into sections: Priority Focus, To Do, Ideas, Follow Up, Waiting On. Drag items between sections as things evolve.

**Topics** - For work that spans multiple days. Think of these as mini-workspaces - a product launch, a hiring round, a feature spec. Each topic has its own tasks, notes, links, and open questions.

**Meetings** - Keep a running list of things to discuss for each recurring meeting. When something comes up mid-week, add it here so you don't forget by the time the meeting rolls around.

**Dashboard** - A summary view: today's progress, active topics, what needs attention.

### Claude Integration

Once installed, Claude (in Cowork or Desktop) knows about your tracker. Just talk to it naturally:

| What you want | What to say |
|---|---|
| See your day | "What's on my plate?" |
| Add a task | "Add a task: write the PRD for notifications" |
| Log something you finished | "I just finished the competitor analysis" |
| Plan a bigger effort | "Create a topic for the Q3 launch" |
| Add to a topic | "Add a task to the launch topic: finalize the timeline" |
| Prep for a meeting | "What do I have for my 1:1?" |
| End-of-week cleanup | "Let's do a weekly review" |
| Quick status | "How's my tracker looking?" |

Claude and the dashboard share the same data. Update one, the other sees it instantly.

## Your Typical Day

**Morning** - Open the dashboard or ask Claude "what's on my plate?" to see where you left off.

**During the day** - Check things off in the dashboard, or tell Claude "I finished X". Add new tasks as they come up.

**Before a meeting** - Check the Meetings view for your discussion topics. Add anything that came up since last time.

**End of week** - Ask Claude "let's do a weekly review." It walks you through open items, stale tasks, and meeting prep.

## Your Data

Everything lives as plain text files on your Mac. Nothing is sent anywhere, no cloud, no account. You own it completely.

If you're curious, the files are in a folder called `~/.claude/tracker/` - but you never need to touch them directly. The dashboard and Claude handle everything.

## If Something Goes Wrong

**macOS blocks the app** - This can happen the first time. Go to **System Settings > Privacy & Security**, scroll down, and click **Allow Anyway**. Then open Terminal and run `bash setup.sh` again.

**Dashboard not loading** - Open Terminal and paste:
```
launchctl unload ~/Library/LaunchAgents/com.tracker-web.plist
launchctl load ~/Library/LaunchAgents/com.tracker-web.plist
```
Then open http://localhost:8745 in your browser.

## Uninstall

Open Terminal and paste this (your data is kept):
```
launchctl unload ~/Library/LaunchAgents/com.tracker-web.plist
rm ~/Library/LaunchAgents/com.tracker-web.plist
rm ~/.local/bin/tracker
rm -rf ~/.claude/skills/tracker
```
