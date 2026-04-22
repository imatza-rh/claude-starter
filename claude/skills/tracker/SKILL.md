---
name: tracker
description: "Personal task tracker - daily work log, backlog, topics (active work context), meetings, weekly review, stats. Use when the user asks about today's work, tasks, priorities, backlog, topics, meetings, or weekly planning."
argument-hint: "[daily|backlog|topics|weekly|stats|search|status] [args]"
allowed-tools: Read, Edit, Write, Bash(date:*), Glob, Grep
---

Personal productivity tracker. Routes based on first argument.

**Web UI**: The tracker also has a web dashboard at http://localhost:8745 (if running). Both Claude and the web UI read/write the same markdown files - changes sync instantly.

**If the tracker is mostly empty**: This is a new setup. Don't just say "nothing here" - help the user get started. Suggest adding their first few tasks, creating a topic for something they're working on, or setting up their meeting list. Be welcoming, not clinical.

## Tracker State

Daily log (most recent entries):
```
!head -60 ~/.claude/tracker/daily-log.md 2>/dev/null || echo "(empty)"
```

```
!cat ~/.claude/tracker/backlog.md 2>/dev/null || echo "(empty)"
```

```
!cat ~/.claude/tracker/meetings.md 2>/dev/null || echo "(empty)"
```

Topics (active work context):
```
!for d in ~/.claude/tracker/topics/*/; do [ -f "$d/topic.md" ] && echo "--- $(basename "$d") ---" && head -15 "$d/topic.md"; done 2>/dev/null || echo "(no active topics)"
```

## Conventions

- `[x]` = done, `[ ]` = open
- Indented lines under an item are **notes** (additional context, details)
- Keep entries to one line each
- Daily log sections are **reverse chronological** - newest date first

## Routing

Parse `$ARGUMENTS` and route to the appropriate mode:

### No arguments → Dashboard

Morning overview combining tracker state into a single view.

**Output format:**
```
# Dashboard - <day>, <date>

## Today
<progress-bar> N/M done (X%)
<!-- List today's items with numbers. If no section for today, create
     one and suggest: "Your day is wide open! Want to add a few things
     you're working on?" -->

## Active Topics
<!-- List each topic: name, task progress (done/total), status one-liner.
     Omit if no topics exist. -->

## Backlog Snapshot
<!-- Show non-empty sections with item counts only.
     Example: "Priority Focus: 2 | To Do: 5 | Ideas: 3" -->

## Needs Attention
<!-- Flag: stale daily items (open items from previous days),
     backlog items older than 30 days, topics with all tasks done
     but not closed. Omit if nothing needs attention. -->
```

---

### `daily` → Daily Log

Manage today's daily log at `~/.claude/tracker/daily-log.md`.

Strip the word "daily" from arguments, then:

**No remaining args** - show today's section with numbered items and progress (N/M done). If no section for today, show most recent day.

**With remaining args:**
- `+` TEXT → add `- [ ]` entry under today (create date section if missing, format: `## YYYY-MM-DD`, newest first)
- `x` + number → mark that item `[x]` (count from top of today's section)
- `rm` + number → remove that item (with confirmation)
- `carry` → move all `[ ]` items from previous days to today
- `note` + number + text → add as indented line under item
- `reorder` N M → move item at position N to position M
- Any other text → add as `- [x]` (completed) entry under today

**Date section format**: `## YYYY-MM-DD` headers in reverse chronological order.

Examples:
- `/tracker daily` → show today
- `/tracker daily + draft Q2 roadmap` → add open task
- `/tracker daily x3` → mark item 3 done
- `/tracker daily carry` → carry forward open items
- `/tracker daily reviewed competitor analysis` → add as completed

Keep output minimal.

---

### `backlog` → Backlog

Manage the backlog at `~/.claude/tracker/backlog.md`.

Strip the word "backlog" from arguments, then:

**No remaining args** - show all non-empty sections with item counts.

**With remaining args:**
- `+ <section>: <item>` → add to section (loose match: "week"/"this"→This Week, "next"→Next Up, "idea"/"research"→Ideas & Research, "stake"/"request"→Stakeholder Requests, "wait"/"block"→Waiting On). Append `<!-- added: YYYY-MM-DD -->` for age tracking.
- `rm <text>` → remove matching item (partial match OK, with confirmation)
- `done <text>` → move to Done section
- `move <text> to <section>` → move item between sections
- `search <text>` → fuzzy search across all backlog items

Examples:
- `/tracker backlog` → show all
- `/tracker backlog + week: write user interview questions` → add to This Week
- `/tracker backlog + idea: explore push notification patterns` → add to Ideas
- `/tracker backlog done interview questions` → mark done
- `/tracker backlog move "interview" to next` → move to Next Up

Keep output minimal.

---

### `topics` → Active Work Context

Manage topic workspaces at `~/.claude/tracker/topics/`. Each topic is a directory containing `topic.md` for tracking in-progress work that spans multiple sessions.

**When to create a topic**: work spans 2+ sessions, has multiple moving parts, needs context accumulation.

Strip the word "topics" from arguments, then:

**No remaining args** - list all topics with name, status, task progress (done/total), age.

**`new <name>`** - create topic directory with `topic.md`:

```markdown
# <Topic Title>
<!-- status: active -->
<!-- created: YYYY-MM-DD | updated: YYYY-MM-DD -->

<Brief context - what this is about.>

## Status
**State**: <initial state>
**Next**: <first action>

## Tasks
- [ ] item

## Notes
- observation

## Links
- [Label](url) - description

## Questions
- [ ] open question
```

Only include sections that have content. Directory name: kebab-case.

**`<name>`** - show full topic content (fuzzy match on directory name)
**`<name> + <text>`** - add task (`- [ ]` under Tasks)
**`<name> x<N>`** - mark task N done, log completion to daily-log
**`<name> note <text>`** - add note under Notes
**`<name> link <url> <desc>`** - add link under Links
**`<name> q <text>`** - add question (`- [ ]` under Questions)
**`<name> answer <N> <text>`** - answer question N: mark `[x]`, add `-> answer` below
**`<name> done`** - close topic: handle open items (move to backlog or drop), delete directory
**`<name> pause`** - set status to paused
**`<name> resume`** - set status back to active

Examples:
- `/tracker topics` → list all
- `/tracker topics new q2-roadmap` → create
- `/tracker topics roadmap + schedule stakeholder interviews` → add task
- `/tracker topics roadmap x2` → mark task 2 done
- `/tracker topics roadmap done` → close topic

Keep output minimal.

---

### `weekly` → Weekly Review

Walk through each area interactively:

**1. Daily Log Cleanup**
- Show all open `[ ]` items across all days
- Ask: mark done, carry forward, move to backlog, or drop?
- Suggest archiving entries older than 30 days

**2. Topics Sweep**
- List all topics: name, status, age, task progress
- For each: still relevant? pause? close?

**3. Backlog Review**
- Show each non-empty section with item counts
- Flag items older than 30 days (from `<!-- added: -->` metadata)
- Ask: still relevant? reprioritize? drop?

**4. Meetings Prep**
- Show meeting topics
- Ask: add anything from this week? Archive discussed items?

**5. Summary**
- Brief summary of changes made

---

### `stats` → Statistics

```
## Daily Completion (last 7 days)
<!-- Table: Date | Done | Open | Rate -->

## Backlog by Section
<!-- Section: count -->

## Active Topics
<!-- Name: done/total tasks — age in days -->

## Tracker Health
<!-- Total items, oldest unresolved item, days since last entry -->
```

---

### `search` → Search

Search across all tracker files. Show matches grouped by source (daily-log, backlog, topics, meetings) with context.

---

### `status` → Quick Status

One-line summary: `<date>: N/M done (X%) | B backlog | T topics | S stale`
