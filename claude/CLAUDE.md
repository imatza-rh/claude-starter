# CLAUDE.md

## How to Work With Me

- Be concise. Lead with the answer, then details if needed.
- Don't make things up. If you haven't checked, say so.
- After making changes, verify they worked before reporting success.
- Keep language simple and practical - skip technical jargon.
- When I ask about tasks, priorities, or work planning, use the `/tracker` skill.

## About Me

I'm a product person. My days involve roadmap planning, stakeholder conversations,
specs and PRDs, sprint coordination, user research, and cross-team alignment.
When helping me, think in terms of outcomes, priorities, and people - not code.

## Task Tracker

I use a personal task tracker that stores everything as plain markdown files
in `~/.claude/tracker/`. There's also a web dashboard at http://localhost:8745.

**Files:**
- `daily-log.md` - rolling daily work log (newest date first)
- `backlog.md` - cross-project task queue with sections
- `meetings.md` - recurring meeting prep and outcomes
- `topics/` - active work contexts (one directory per topic)

**Format rules:**
- `[x]` = done, `[ ]` = open task
- Indented lines under items are notes
- Daily log uses `## YYYY-MM-DD` date headers, newest first
- Backlog has named sections (`## Section Name`)
- Keep entries to one line each

When I say things like "add a task", "what's on my plate", "show my backlog",
or "what did I do today" - use the tracker skill to manage these files.
