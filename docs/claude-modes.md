# Claude Code writing modes

Two output styles and one skill, stowed from the `claude` package. The goal is
concise, unambiguous technical output in work sessions, without dragging that
same clamp into personal or conceptual conversations.

## What is in the package

```
claude/.claude/
  output-styles/
    technical-ste.md          # name: "Technical (STE)"
    open.md                   # name: "Open"
  skills/
    ste-writing/
      SKILL.md                # model- and user-invocable rewrite skill
      ste-lint.py             # optional heuristic checker
  statusline.sh               # shows the active mode
```

`stow claude` folds into the existing `~/.claude/` and symlinks only
`skills`, `output-styles`, and `statusline.sh`. It leaves
`~/.claude/settings.json`, `CLAUDE.md`, and the runtime dirs (`sessions`,
`history.jsonl`, `cache`) untouched and untracked.

`scripts/stow-audit.sh` skips `.claude/` paths in every other package, because
those are gitignored per-project settings dirs. It carries an explicit
exception for this package, which is itself a `.claude/` tree. Without that
exception the audit silently reported zero drift for all five files.

## The three layers

**Output style** modifies the system prompt for every turn of a session. This
is the mode switch. Claude Code reads it once at session start, so a change
takes effect after `/clear` or in the next session.

**Skill** loads only when invoked. `/ste-writing`, or Claude loads it when you
ask for a document rewrite. Use it on artifacts, not on conversation.

**CLAUDE.md** stays what it was: facts about this machine and the working
agreement. It does not carry style.

## Technical (STE)

`keep-coding-instructions: true`, so Claude Code's engineering behaviour stays.
The style only changes how Claude writes.

Rules come from ASD-STE100 Simplified Technical English: short common words,
active voice with a named actor, one idea per sentence, no semicolons, no em
dashes, no marketing adjectives, answer before reasoning.

The section that does the most work is **Ambiguity**: name the referent instead
of opening with a bare "this", give the quantity instead of "several", give the
full path on first mention, and state which component acts.

## Open

`keep-coding-instructions: false`, so the software-engineering system prompt is
dropped entirely. For philosophy, concepts, emotion, and unfinished ideas.

It explicitly countermands the STE rules and the `ste-writing` skill, because
STE removes voice by design and voice is the point in this mode. It asks for
real disagreement rather than agreeable noise, for speculation labelled as
speculation, and for uncertainty held open instead of resolved for the sake of
a tidy ending.

**Status: first pass.** This file needs a fuller instruction set and is not
settled. Expand it rather than treating it as done.

## Which mode am I in

The status line shows it. `claude/.claude/statusline.sh` reads
`.output_style.name` from the JSON that Claude Code sends on stdin and prints
the mode first:

```
[STE] Opus · dotfiles ⎇ master · 12%
[OPEN] Opus · thinking · 4%
```

STE prints cyan, OPEN prints magenta, anything else prints its own name in
yellow so a wrong or missing style is obvious. Wired up in
`~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
```

`/status` also lists the active style.

## Switching

Set the mode before a conversation, not during it. Claude Code reads the output
style once at session start, so any change needs `/clear` or a new session.

**Global default** in `~/.claude/settings.json` (untracked):

```json
{ "outputStyle": "Technical (STE)" }
```

**Per repository.** Claude Code reads `.claude/settings.json` from the **git
repository root**, resolved through worktrees. One file covers every
subdirectory of that repo. There is no per-subdirectory mode inside a repo.

Three exceptions put the file in the directory you start Claude in instead:
outside a git repository, when the repository root is your home directory, and
in Agent SDK sessions. The first exception is the one in use here.

**`~/Documents/Notes/`** is the Obsidian vault and the designated Open-mode
space. It is not a git repo, so it carries its own pin:

```json
// ~/Documents/Notes/.claude/settings.json
{ "outputStyle": "Open" }
```

Caveat that follows from the same exception: outside a git repo the settings
file is read from the directory you start Claude in, not from a parent. Start
Claude at the vault root. A session started in `Notes/Philosophy/` does not
inherit the pin. Two fixes if that becomes annoying: copy the file into each
subdirectory, or `git init` the vault so one file at the root covers all of it.

**One session only:** `claude --settings '{"outputStyle":"Open"}'`. Command line
arguments beat every settings file except managed settings.

**Interactively:** `/config`, then **Output style**. It writes to
`.claude/settings.local.json` at the repo root and applies after `/clear`.

Precedence, highest first: managed, command line, `.claude/settings.local.json`,
`.claude/settings.json`, `~/.claude/settings.json`.

In this repo, `.claude/` is gitignored (`.gitignore` line 67), so a
project-level override here stays untracked. The global default already
selects Technical (STE), so `dotfiles` needs no override.

Subagents do not inherit an output style. They run their own system prompt. A
fork is the exception, because a fork inherits the parent prompt.

## The linter

`ste-lint.py` counts violations per 100 words. It is optional and off by
default. Run it only for a before/after on a document you are rewriting:

```
python3 ~/.claude/skills/ste-writing/ste-lint.py before.md after.md
```

Read the score as a rough proxy. It counts strings, not sense. It calls any
`be` plus past participle passive, calls "provides" a nominalization, and
cannot tell a banned word from a banned word inside a quotation. Consequence:
`technical-ste.md` scores 7.05 while `problems.md` scores 3.52, purely because
the style file quotes the words it bans. Deltas between two versions of one
text mean something. Absolute scores across different files do not.

## Origin

Distilled from https://github.com/woosal1337/blog/tree/main/videos/ep01-the-cure-for-ai-slop
(episode: "The cure for AI slop is a 1986 aircraft manual"). That kit ships the
skill and the linter. The dual-mode split, the ambiguity rules, and the
demotion of the linter are local additions.

The kit reports a 74% lint-score drop on Claude and 50% on gpt-5.5 against a
baseline. Note that the score is produced by the linter shipped in the same
repo, so it partly measures conformance to its own rules. The skill is candid
about the ceiling: it fixes the form of slop and cannot make a hollow paragraph
true.

Spec: ASD-STE100 Issue 9, free at https://asd-ste100.org
