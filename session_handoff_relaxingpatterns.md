# Session Handoff — RelaxingPatterns Website
<!-- Continuity doc for the next session, in Claude Code -->

## Where this left off
Built in claude.ai (web), not yet in git. Four-page static site + governance
schema updates, all content-complete except the App Store link (can't be
set until the app is published). Folder layout as you've set it up:

```
[project root]/
├── CLAUDE.md                         (renamed from T1-CLAUDE.md)
├── governance/
│   ├── T2_intelligence.md
│   └── T3_appdev.md
└── website/
    ├── index.html
    ├── marketing.html
    ├── support.html
    ├── privacy.html
    ├── styles.css
    └── project_instructions_relaxingpatterns_site.md
```

## First things to do in Claude Code

1. **Confirm CLAUDE.md placement.** Claude Code auto-loads `CLAUDE.md` at
   the project root — not from inside `website/` or `governance/`.
   - Rename `T1-CLAUDE.md` → `CLAUDE.md` at project root, if not done yet
   - Reference the governance files from there with
     `@governance/T2_intelligence.md` and `@governance/T3_appdev.md`
     rather than folding them in wholesale — keeps the root file short
     and the schema files independently versionable
   - If `T1-CLAUDE.md` currently sits in `governance/` alongside T2/T3
     rather than at root, that's the one placement that actually matters:
     move it out before the first commit, since Claude Code won't
     traverse into `governance/` looking for it on its own

2. **git init + first commit**, if not already done. Suggested `.gitignore`
   for a static site this simple: essentially nothing needed beyond OS
   cruft (`.DS_Store`) unless a build step gets added later.

3. **Pick a Pages deploy mode** (see `T3_appdev.md`'s Deployment
   invariants) — either `/docs` on `main` or a dedicated `gh-pages`
   branch. If going the `/docs` route, the `website/` contents move into
   `docs/` at the repo root (GitHub Pages looks for `index.html` at the
   root of whichever source you point it at).

4. **Enable Pages** in repo settings once pushed, verify the live URL
   loads all four pages and that nav/footer links resolve correctly
   (relative paths assume all four HTML files sit in the same directory).

## What's genuinely done vs. still open
Done: all page copy, four-page structure, Privacy Policy content (real —
confirmed no analytics/crash reporting/third-party SDKs), contact email
(jason@jasonrosenblum.com) on Support and Privacy, Privacy Policy dated
July 4, 2026, "clean professional" design pass (see T3_appdev.md).

Still open: App Store link (blocked on the app actually shipping), repo
name/GitHub destination (your call, not mine to guess).

## Note on governance file scope
T1's coding-scope line was corrected this session (previously read
"not applicable to this project," which contradicted T2's own Domain
Registry). If a stale copy of the original T1 exists anywhere in the
project folder from before this session, the corrected version is the one
that should end up at root.
